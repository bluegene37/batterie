import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AlarmService {
  AudioPlayer? _player;
  bool _isRinging = false;
  Timer? _testTimer;

  // ignore: prefer_initializing_formals
  AlarmService({AudioPlayer? player}) : _player = player;

  AudioPlayer get player => _player ??= AudioPlayer();

  bool get isRinging => _isRinging;

  static const Map<String, String> presetSounds = {
    'siren': 'assets/sounds/siren.wav',
    'digital': 'assets/sounds/digital_alarm.wav',
    'digital_alarm': 'assets/sounds/digital_alarm.wav',
    'bell': 'assets/sounds/bell.wav',
  };

  /// Human readable names for the built-in presets, in menu order.
  static const Map<String, String> presetLabels = {
    'siren': 'Urgent Siren',
    'digital': 'Digital Alarm',
    'bell': 'Alert Bell',
  };

  /// Maps stored sound ids (including legacy aliases) to a preset id that
  /// exists in [presetLabels], or 'custom'.
  static String normalizeSoundType(String soundType) {
    final lower = soundType.toLowerCase();
    if (lower == 'custom') return 'custom';
    if (lower == 'digital_alarm') return 'digital';
    return presetLabels.containsKey(lower) ? lower : 'siren';
  }

  /// Display name for a rule's sound: preset label, or the custom file name.
  static String describeSound(String soundType, String? customPath) {
    final normalized = normalizeSoundType(soundType);
    if (normalized == 'custom') {
      if (customPath == null || customPath.isEmpty) return 'Custom file';
      return customPath.split(RegExp(r'[\\/]')).last;
    }
    return presetLabels[normalized]!;
  }

  static String resolveAssetPath(String soundType) {
    return presetSounds[soundType.toLowerCase()] ?? 'assets/sounds/siren.wav';
  }

  static double clampVolume(double volume) {
    return volume.clamp(0.0, 1.0);
  }

  Future<void> startAlarm({
    required String soundType,
    String? customPath,
    double volume = 1.0,
  }) async {
    try {
      _testTimer?.cancel();
      await player.stop();

      final safeVolume = clampVolume(volume);
      await player.setVolume(safeVolume);
      await player.setReleaseMode(ReleaseMode.loop);

      if (customPath != null && customPath.isNotEmpty) {
        await player.play(DeviceFileSource(customPath));
      } else {
        final assetPath = resolveAssetPath(soundType);
        // Note: audioplayers AssetSource resolves relative to assets/
        final relativePath = assetPath.startsWith('assets/')
            ? assetPath.substring('assets/'.length)
            : assetPath;
        await player.play(AssetSource(relativePath));
      }

      _isRinging = true;
    } catch (e) {
      debugPrint('Error starting alarm: $e');
    }
  }

  Future<void> testAlarm({
    required String soundType,
    String? customPath,
    double volume = 1.0,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onComplete,
  }) async {
    try {
      await startAlarm(
        soundType: soundType,
        customPath: customPath,
        volume: volume,
      );

      _testTimer?.cancel();
      _testTimer = Timer(duration, () async {
        await stopAlarm();
        onComplete?.call();
      });
    } catch (e) {
      debugPrint('Error running test alarm: $e');
      onComplete?.call();
    }
  }

  Future<void> stopAlarm() async {
    try {
      _testTimer?.cancel();
      await _player?.stop();
      _isRinging = false;
    } catch (e) {
      debugPrint('Error stopping alarm: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    final safeVolume = clampVolume(volume);
    try {
      await _player?.setVolume(safeVolume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  void dispose() {
    _testTimer?.cancel();
    _player?.dispose();
  }
}
