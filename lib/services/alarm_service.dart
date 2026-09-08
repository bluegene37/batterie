import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AlarmService {
  final AudioPlayer _player;
  bool _isRinging = false;
  Timer? _testTimer;

  AlarmService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  bool get isRinging => _isRinging;

  static const Map<String, String> presetSounds = {
    'siren': 'assets/sounds/siren.wav',
    'digital': 'assets/sounds/digital_alarm.wav',
    'digital_alarm': 'assets/sounds/digital_alarm.wav',
    'bell': 'assets/sounds/bell.wav',
  };

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
      await _player.stop();

      final safeVolume = clampVolume(volume);
      await _player.setVolume(safeVolume);
      await _player.setReleaseMode(ReleaseMode.loop);

      if (customPath != null && customPath.isNotEmpty) {
        await _player.play(DeviceFileSource(customPath));
      } else {
        final assetPath = resolveAssetPath(soundType);
        // Note: audioplayers AssetSource resolves relative to assets/
        final relativePath = assetPath.startsWith('assets/')
            ? assetPath.substring('assets/'.length)
            : assetPath;
        await _player.play(AssetSource(relativePath));
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
      await _player.stop();
      _isRinging = false;
    } catch (e) {
      debugPrint('Error stopping alarm: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    final safeVolume = clampVolume(volume);
    try {
      await _player.setVolume(safeVolume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  void dispose() {
    _testTimer?.cancel();
    _player.dispose();
  }
}
