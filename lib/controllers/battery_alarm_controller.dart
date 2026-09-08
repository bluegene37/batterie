import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alarm_state.dart';
import '../models/battery_info.dart';
import '../models/threshold_rule.dart';
import '../services/alarm_service.dart';
import '../services/battery_service.dart';
import '../services/settings_service.dart';

class BatteryAlarmController extends ChangeNotifier {
  final BatteryService? _batteryService;
  final AlarmService _alarmService;
  final SettingsService _settingsService;

  StreamSubscription<BatteryInfo>? _batterySubscription;
  VoidCallback? onAlarmTriggered;

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

  // Anti-flapping hysteresis tracking
  String? _lastDismissedRuleId;
  int? _highestPercentageSinceDismiss;

  bool _isTesting = false;

  BatteryAlarmController({
    BatteryService? batteryService,
    AlarmService? alarmService,
    SettingsService? settingsService,
  })  : _batteryService = batteryService,
        _alarmService = alarmService ?? AlarmService(),
        _settingsService = settingsService ?? SettingsService();

  BatteryInfo get batteryInfo => _batteryInfo;
  AlarmState get alarmState => _alarmState;
  List<ThresholdRule> get thresholdRules => List.unmodifiable(_thresholdRules);
  double get volume => _volume;
  String get defaultSound => _defaultSound;
  String? get customSoundPath => _customSoundPath;
  int get snoozeMinutes => _snoozeMinutes;
  bool get isTesting => _isTesting;

  Future<void> init() async {
    _thresholdRules = await _settingsService.loadThresholds();
    _volume = await _settingsService.loadVolume();
    _defaultSound = await _settingsService.loadDefaultSound();
    _snoozeMinutes = await _settingsService.loadSnoozeMinutes();

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
        _alarmService.stopAlarm();
        _alarmState = AlarmState.idle();
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
    final customPath = targetRule.customSoundPath ?? _customSoundPath;

    _alarmService.startAlarm(
      soundType: sound,
      customPath: customPath,
      volume: _volume,
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
    notifyListeners();
  }

  void dismiss() {
    _alarmService.stopAlarm();
    if (_alarmState.triggeredRule != null) {
      _lastDismissedRuleId = _alarmState.triggeredRule!.id;
      _highestPercentageSinceDismiss = _batteryInfo.percentage;
    }
    _alarmState = AlarmState.idle();
    notifyListeners();
  }

  Future<void> testAlarm({Duration duration = const Duration(seconds: 3)}) async {
    _isTesting = true;
    notifyListeners();

    await _alarmService.testAlarm(
      soundType: _defaultSound,
      customPath: _customSoundPath,
      volume: _volume,
      duration: duration,
      onComplete: () {
        _isTesting = false;
        notifyListeners();
      },
    );
  }

  Future<void> addThreshold(int percentage, String label) async {
    final newRule = ThresholdRule(
      id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
      percentage: percentage.clamp(1, 99),
      label: label.trim().isEmpty ? '$percentage% Alert' : label.trim(),
      isEnabled: true,
      soundType: _defaultSound,
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
    _customSoundPath = path;
    notifyListeners();
  }

  Future<void> setSnoozeMinutes(int minutes) async {
    _snoozeMinutes = minutes;
    await _settingsService.saveSnoozeMinutes(minutes);
    notifyListeners();
  }

  @visibleForTesting
  void setSimulatedSnoozeExpired() {
    if (_alarmState.isSnoozed) {
      _alarmState = _alarmState.toSnoozed(DateTime.now().subtract(const Duration(seconds: 1)));
    }
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _alarmService.dispose();
    super.dispose();
  }
}
