import 'dart:async';
// Gene - Oct 24, 2026: Added dart:io for environment test detection.
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/alarm_state.dart';
import '../models/battery_info.dart';
import '../models/threshold_rule.dart';
import '../services/alarm_service.dart';
import '../services/battery_service.dart';
import '../services/settings_service.dart';
// Gene - Oct 24, 2026: Added UpdateInfo and UpdateService imports for auto-update capabilities.
import '../models/update_info.dart';
import '../services/update_service.dart';

class BatteryAlarmController extends ChangeNotifier {
  final BatteryService? _batteryService;
  final AlarmService _alarmService;
  final SettingsService _settingsService;
  // Gene - Oct 24, 2026: Added UpdateService dependency.
  final UpdateService _updateService;

  StreamSubscription<BatteryInfo>? _batterySubscription;

  /// Called when a rule starts ringing.
  VoidCallback? onAlarmTriggered;

  /// Called when a ringing alarm stops for any reason (dismiss, snooze,
  /// charger connected).
  VoidCallback? onAlarmEnded;

  BatteryInfo _batteryInfo = const BatteryInfo(
    percentage: 100,
    isCharging: true,
    source: PowerSource.ac,
  );

  AlarmState _alarmState = AlarmState.idle();
  List<ThresholdRule> _thresholdRules = [];
  double _volume = 1.0;
  String _defaultSound = 'siren';
  String? _customSoundPath;
  int _snoozeMinutes = 5;
  int _repeatCount = 3;
  ThemeMode _themeMode = ThemeMode.light;

  // Anti-flapping hysteresis tracking
  String? _lastDismissedRuleId;
  int? _highestPercentageSinceDismiss;

  bool _isTesting = false;

  // Gene - Oct 24, 2026: Added state variables for application updates.
  UpdateInfo? _updateInfo;
  UpdateStatus _updateStatus = UpdateStatus.idle;
  double _downloadProgress = 0.0;
  String? _updateErrorMessage;
  bool _autoUpdateEnabled = true;
  bool _isUpdateBannerDismissed = false;
  Timer? _updateInitialTimer;
  Timer? _updateCheckTimer;

  // Gene - Oct 24, 2026: Added UpdateService injection parameter to constructor. Preserved previous constructor below.
  // BatteryAlarmController({
  //   BatteryService? batteryService,
  //   AlarmService? alarmService,
  //   SettingsService? settingsService,
  //   // ignore: prefer_initializing_formals
  // })  : _batteryService = batteryService,
  //       _alarmService = alarmService ?? AlarmService(),
  //       _settingsService = settingsService ?? SettingsService();
  BatteryAlarmController({
    BatteryService? batteryService,
    AlarmService? alarmService,
    SettingsService? settingsService,
    UpdateService? updateService,
    // ignore: prefer_initializing_formals
  })  : _batteryService = batteryService,
        _alarmService = alarmService ?? AlarmService(),
        _settingsService = settingsService ?? SettingsService(),
        _updateService = updateService ?? UpdateService();

  BatteryInfo get batteryInfo => _batteryInfo;
  AlarmState get alarmState => _alarmState;
  List<ThresholdRule> get thresholdRules => List.unmodifiable(_thresholdRules);
  double get volume => _volume;
  String get defaultSound => _defaultSound;
  String? get customSoundPath => _customSoundPath;
  int get snoozeMinutes => _snoozeMinutes;
  int get repeatCount => _repeatCount;
  bool get isTesting => _isTesting;
  ThemeMode get themeMode => _themeMode;
  // Gene - Oct 24, 2026: Getters for update state.
  UpdateInfo? get updateInfo => _updateInfo;
  UpdateStatus get updateStatus => _updateStatus;
  double get downloadProgress => _downloadProgress;
  String? get updateErrorMessage => _updateErrorMessage;
  bool get autoUpdateEnabled => _autoUpdateEnabled;
  bool get isUpdateBannerDismissed => _isUpdateBannerDismissed;
  bool get hasUpdateAvailable =>
      _updateInfo != null && !_isUpdateBannerDismissed;

  // Gene - Oct 24, 2026: Extended init with optional scheduleUpdateChecks parameter. Preserved previous init signature below.
  // Future<void> init() async {
  Future<void> init({bool scheduleUpdateChecks = true}) async {
    _thresholdRules = await _settingsService.loadThresholds();
    _volume = await _settingsService.loadVolume();
    _defaultSound = await _settingsService.loadDefaultSound();
    _customSoundPath = await _settingsService.loadCustomSoundPath();
    // Gene - Oct 16, 2026: Also ensure threshold rules with custom sounds migrate external paths to container paths if copied. Preserved previous customSoundPath logic below.
    // // Gene - Oct, 07, 2026: If an existing custom sound path was set, ensure it is safely inside container
    // if (_customSoundPath != null && _customSoundPath!.isNotEmpty) {
    //   final safePath = await SettingsService.copyCustomSoundFile(_customSoundPath!);
    //   if (safePath != _customSoundPath) {
    //     _customSoundPath = safePath;
    //     await _settingsService.saveCustomSoundPath(safePath);
    //   }
    // }
    if (_customSoundPath != null && _customSoundPath!.isNotEmpty) {
      final safePath = await SettingsService.copyCustomSoundFile(_customSoundPath!);
      if (safePath != _customSoundPath) {
        _customSoundPath = safePath;
        await _settingsService.saveCustomSoundPath(safePath);
      }
    }
    bool thresholdsUpdated = false;
    for (int i = 0; i < _thresholdRules.length; i++) {
      final rule = _thresholdRules[i];
      if (rule.customSoundPath != null && rule.customSoundPath!.isNotEmpty) {
        final safePath = await SettingsService.copyCustomSoundFile(rule.customSoundPath!);
        if (safePath != rule.customSoundPath) {
          _thresholdRules[i] = ThresholdRule(
            id: rule.id,
            percentage: rule.percentage,
            label: rule.label,
            isEnabled: rule.isEnabled,
            soundType: rule.soundType,
            customSoundPath: safePath,
          );
          thresholdsUpdated = true;
        }
      }
    }
    if (thresholdsUpdated) {
      await _settingsService.saveThresholds(_thresholdRules);
    }
    _snoozeMinutes = await _settingsService.loadSnoozeMinutes();
    _repeatCount = await _settingsService.loadRepeatCount();
    _themeMode = await _settingsService.loadThemeMode();
    // Gene - Oct 24, 2026: Load auto-update setting and initiate update checks outside unit tests.
    _autoUpdateEnabled = await _settingsService.loadAutoUpdateEnabled();
    if (scheduleUpdateChecks && !Platform.environment.containsKey('FLUTTER_TEST')) {
      _updateInitialTimer = Timer(const Duration(seconds: 3), () {
        checkForUpdates();
      });
      _updateCheckTimer = Timer.periodic(const Duration(hours: 6), (_) {
        checkForUpdates();
      });
    }

    if (_batteryService != null) {
      _batteryInfo = _batteryService.currentInfo;
      _batterySubscription = _batteryService.onBatteryChanged.listen((info) {
        evaluateBattery(info);
      });
      evaluateBattery(_batteryInfo);
    }
    notifyListeners();
  }

  void evaluateBattery(BatteryInfo info) {
    _batteryInfo = info;

    // Track highest percentage reached while discharging to reset dismissed thresholds
    if (_highestPercentageSinceDismiss == null ||
        info.percentage > _highestPercentageSinceDismiss!) {
      _highestPercentageSinceDismiss = info.percentage;
    }

    // Auto-silence when connected to AC power
    if (info.isCharging || info.source == PowerSource.ac) {
      if (_alarmState.isRinging || _alarmState.isSnoozed) {
        final wasRinging = _alarmState.isRinging;
        _alarmService.stopAlarm();
        _alarmState = AlarmState.idle();
        if (wasRinging) onAlarmEnded?.call();
      }
      _lastDismissedRuleId = null;
      _highestPercentageSinceDismiss = info.percentage;
      notifyListeners();
      return;
    }

    // If snoozed, check if snooze expired
    if (_alarmState.isSnoozed) {
      final snoozeUntil = _alarmState.snoozeUntil;
      if (snoozeUntil != null && DateTime.now().isAfter(snoozeUntil)) {
        // Snooze expired, allow re-trigger
        _alarmState = AlarmState.idle();
      } else {
        // Still snoozed, do not ring
        notifyListeners();
        return;
      }
    }

    // If currently ringing, keep ringing
    if (_alarmState.isRinging) {
      notifyListeners();
      return;
    }

    // Evaluate enabled thresholds
    // Find all matching rules where battery percentage <= rule percentage
    final matchingRules = _thresholdRules
        .where((r) => r.isEnabled && info.percentage <= r.percentage)
        .toList();

    if (matchingRules.isEmpty) {
      notifyListeners();
      return;
    }

    // Pick most critical (lowest percentage threshold)
    matchingRules.sort((a, b) => a.percentage.compareTo(b.percentage));
    final targetRule = matchingRules.first;

    // Anti-flapping: If this exact rule was dismissed and battery hasn't recovered above it, skip
    if (_lastDismissedRuleId == targetRule.id &&
        _highestPercentageSinceDismiss != null &&
        _highestPercentageSinceDismiss! <= targetRule.percentage) {
      notifyListeners();
      return;
    }

    // Trigger Alarm!
    _alarmState = AlarmState.ringing(targetRule);
    final sound = targetRule.soundType.isNotEmpty ? targetRule.soundType : _defaultSound;
    // Gene - Oct, 07, 2026: Only pass customPath when sound is 'custom' to prevent overriding preset sounds
    // final customPath = targetRule.customSoundPath ?? _customSoundPath;
    final customPath = sound == 'custom'
        ? (targetRule.customSoundPath ?? _customSoundPath)
        : null;

    _alarmService.startAlarm(
      soundType: sound,
      customPath: customPath,
      volume: _volume,
      repeatCount: _repeatCount,
      onComplete: () {
        if (_alarmState.isRinging) {
          dismiss();
        }
      },
    );

    onAlarmTriggered?.call();
    notifyListeners();
  }

  void snooze({int? minutes}) {
    if (!_alarmState.isRinging) return;

    final durationMinutes = minutes ?? _snoozeMinutes;
    _alarmService.stopAlarm();
    final until = DateTime.now().add(Duration(minutes: durationMinutes));
    _alarmState = _alarmState.toSnoozed(until);
    onAlarmEnded?.call();
    notifyListeners();
  }

  void dismiss() {
    final wasRinging = _alarmState.isRinging;
    _alarmService.stopAlarm();
    if (_alarmState.triggeredRule != null) {
      _lastDismissedRuleId = _alarmState.triggeredRule!.id;
      _highestPercentageSinceDismiss = _batteryInfo.percentage;
    }
    _alarmState = AlarmState.idle();
    if (wasRinging) onAlarmEnded?.call();
    notifyListeners();
  }

  /// Plays [soundType] (or [customPath]) briefly so the user can audition a
  /// sound while editing a threshold.
  Future<void> previewSound({
    required String soundType,
    String? customPath,
    Duration duration = const Duration(seconds: 2),
  }) async {
    if (_alarmState.isRinging) return;
    // Gene - Oct, 07, 2026: Only pass customPath when soundType is 'custom'
    // await _alarmService.testAlarm(
    //   soundType: soundType,
    //   customPath: customPath,
    //   volume: _volume,
    //   duration: duration,
    // );
    await _alarmService.testAlarm(
      soundType: soundType,
      customPath: soundType == 'custom' ? customPath : null,
      volume: _volume,
      duration: duration,
    );
  }

  Future<void> testAlarm({Duration duration = const Duration(seconds: 3)}) async {
    _isTesting = true;
    notifyListeners();

    // Gene - Oct, 07, 2026: Only pass customPath when defaultSound is 'custom' to ensure preset testing works
    // await _alarmService.testAlarm(
    //   soundType: _defaultSound,
    //   customPath: _customSoundPath,
    //   volume: _volume,
    //   duration: duration,
    //   onComplete: () {
    //     _isTesting = false;
    //     notifyListeners();
    //   },
    // );
    await _alarmService.testAlarm(
      soundType: _defaultSound,
      customPath: _defaultSound == 'custom' ? _customSoundPath : null,
      volume: _volume,
      duration: duration,
      onComplete: () {
        _isTesting = false;
        notifyListeners();
      },
    );
  }

  Future<void> addThreshold(
    int percentage,
    String label, {
    String? soundType,
    String? customSoundPath,
  }) async {
    final sound = soundType ?? _defaultSound;
    final newRule = ThresholdRule(
      id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
      percentage: percentage.clamp(1, 99),
      label: label.trim().isEmpty ? '$percentage% Alert' : label.trim(),
      isEnabled: true,
      soundType: sound,
      customSoundPath: sound == 'custom'
          ? (customSoundPath ?? _customSoundPath)
          : null,
    );
    _thresholdRules.add(newRule);
    _thresholdRules.sort((a, b) => b.percentage.compareTo(a.percentage));
    await _settingsService.saveThresholds(_thresholdRules);
    evaluateBattery(_batteryInfo);
    notifyListeners();
  }

  Future<void> updateThreshold(ThresholdRule rule) async {
    final index = _thresholdRules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _thresholdRules[index] = rule;
      _thresholdRules.sort((a, b) => b.percentage.compareTo(a.percentage));
      await _settingsService.saveThresholds(_thresholdRules);
      evaluateBattery(_batteryInfo);
      notifyListeners();
    }
  }

  Future<void> removeThreshold(String id) async {
    _thresholdRules.removeWhere((r) => r.id == id);
    await _settingsService.saveThresholds(_thresholdRules);
    evaluateBattery(_batteryInfo);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _settingsService.saveVolume(_volume);
    await _alarmService.setVolume(_volume);
    notifyListeners();
  }

  Future<void> setDefaultSound(String sound) async {
    _defaultSound = sound;
    await _settingsService.saveDefaultSound(sound);
    notifyListeners();
  }

  Future<void> setCustomSoundPath(String? path) async {
    // Gene - Oct, 07, 2026: Copy custom audio file into sandbox container before saving
    // _customSoundPath = path;
    // await _settingsService.saveCustomSoundPath(path);
    // notifyListeners();
    String? safePath = path;
    if (path != null && path.isNotEmpty) {
      safePath = await SettingsService.copyCustomSoundFile(path);
    }
    _customSoundPath = safePath;
    await _settingsService.saveCustomSoundPath(safePath);
    notifyListeners();
  }

  Future<void> setSnoozeMinutes(int minutes) async {
    _snoozeMinutes = minutes;
    await _settingsService.saveSnoozeMinutes(minutes);
    notifyListeners();
  }

  Future<void> setRepeatCount(int count) async {
    _repeatCount = count;
    await _settingsService.saveRepeatCount(count);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _settingsService.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> toggleThemeMode({Brightness? currentBrightness}) async {
    final effectiveBrightness = currentBrightness ??
        (_themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);
    final nextMode = effectiveBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  @visibleForTesting
  void setSimulatedSnoozeExpired() {
    if (_alarmState.isSnoozed) {
      _alarmState = _alarmState.toSnoozed(DateTime.now().subtract(const Duration(seconds: 1)));
    }
  }

  // Gene - Oct 24, 2026: Methods for checking, installing, and managing application updates.
  Future<void> checkForUpdates({bool manual = false}) async {
    if (_updateStatus == UpdateStatus.downloading ||
        _updateStatus == UpdateStatus.installing) {
      return;
    }

    _updateStatus = UpdateStatus.checking;
    _updateErrorMessage = null;
    notifyListeners();

    try {
      final update = await _updateService.checkForUpdates();
      if (update != null) {
        _updateInfo = update;
        _updateStatus = UpdateStatus.available;
        _isUpdateBannerDismissed = false;
        notifyListeners();

        // If auto-update is enabled and the alarm is not ringing, install automatically
        if (_autoUpdateEnabled && !_alarmState.isRinging) {
          await installUpdate();
        }
      } else {
        _updateStatus = UpdateStatus.upToDate;
        notifyListeners();

        if (manual) {
          // Reset status to idle after brief up-to-date feedback
          Future.delayed(const Duration(seconds: 4), () {
            if (_updateStatus == UpdateStatus.upToDate) {
              _updateStatus = UpdateStatus.idle;
              notifyListeners();
            }
          });
        }
      }
    } catch (e) {
      _updateStatus = UpdateStatus.error;
      _updateErrorMessage = 'Update check failed: $e';
      notifyListeners();
    }
  }

  Future<void> installUpdate() async {
    final update = _updateInfo;
    if (update == null) return;
    if (_updateStatus == UpdateStatus.downloading ||
        _updateStatus == UpdateStatus.installing) {
      return;
    }

    // Do not interrupt while an alarm is ringing
    if (_alarmState.isRinging) {
      debugPrint('Update paused: alarm is actively ringing.');
      return;
    }

    _updateStatus = UpdateStatus.downloading;
    _downloadProgress = 0.0;
    _updateErrorMessage = null;
    notifyListeners();

    try {
      final downloadedFile = await _updateService.downloadReleaseAsset(
        update,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      _updateStatus = UpdateStatus.installing;
      notifyListeners();

      final success = await _updateService.installUpdate(downloadedFile);
      if (!success) {
        _updateStatus = UpdateStatus.error;
        _updateErrorMessage = 'Failed to apply update.';
        notifyListeners();
      }
    } catch (e) {
      _updateStatus = UpdateStatus.error;
      _updateErrorMessage = 'Download failed: $e';
      notifyListeners();
    }
  }

  void dismissUpdateBanner() {
    _isUpdateBannerDismissed = true;
    notifyListeners();
  }

  Future<void> setAutoUpdateEnabled(bool enabled) async {
    if (_autoUpdateEnabled == enabled) return;
    _autoUpdateEnabled = enabled;
    await _settingsService.saveAutoUpdateEnabled(enabled);
    notifyListeners();

    if (enabled && _updateInfo != null && !_alarmState.isRinging) {
      await installUpdate();
    }
  }

  // Gene - Oct 24, 2026: Cancel update check timer on dispose. Preserved previous dispose below.
  // @override
  // void dispose() {
  //   _batterySubscription?.cancel();
  //   _alarmService.dispose();
  //   super.dispose();
  // }
  @override
  void dispose() {
    _updateInitialTimer?.cancel();
    _updateCheckTimer?.cancel();
    _batterySubscription?.cancel();
    _alarmService.dispose();
    super.dispose();
  }
}
