import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:batterie/services/alarm_service.dart';

class FakeAudioPlayer extends Fake implements AudioPlayer {
  final _completeController = StreamController<void>.broadcast();
  int playCallCount = 0;
  ReleaseMode? currentReleaseMode;
  // Gene - Oct, 07, 2026: Added lastPlayedSource tracking to verify played sound source
  // bool isStopped = false;
  //
  // @override
  // Stream<void> get onPlayerComplete => _completeController.stream;
  //
  // @override
  // Future<void> play(
  //   Source source, {
  //   double? volume,
  //   double? balance,
  //   AudioContext? ctx,
  //   Duration? position,
  //   PlayerMode? mode,
  // }) async {
  //   playCallCount++;
  //   isStopped = false;
  // }
  bool isStopped = false;
  Source? lastPlayedSource;

  @override
  Stream<void> get onPlayerComplete => _completeController.stream;

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    playCallCount++;
    lastPlayedSource = source;
    isStopped = false;
  }

  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {
    currentReleaseMode = mode;
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> stop() async {
    isStopped = true;
  }

  @override
  Future<void> dispose() async {
    await _completeController.close();
  }

  void triggerComplete() {
    _completeController.add(null);
  }
}

void main() {
  group('AlarmService unit tests', () {
    test('Resolves preset sound asset paths accurately', () {
      expect(AlarmService.resolveAssetPath('siren'), equals('assets/sounds/siren.wav'));
      expect(AlarmService.resolveAssetPath('digital'), equals('assets/sounds/digital_alarm.wav'));
      expect(AlarmService.resolveAssetPath('digital_alarm'), equals('assets/sounds/digital_alarm.wav'));
      expect(AlarmService.resolveAssetPath('bell'), equals('assets/sounds/bell.wav'));
      // Unknown defaults to siren
      expect(AlarmService.resolveAssetPath('unknown'), equals('assets/sounds/siren.wav'));
    });

    test('Clamps volume accurately between 0.0 and 1.0', () {
      expect(AlarmService.clampVolume(1.5), equals(1.0));
      expect(AlarmService.clampVolume(-0.2), equals(0.0));
      expect(AlarmService.clampVolume(0.75), equals(0.75));
    });

    test('Plays in loop mode when repeatCount is 0 (continuous)', () async {
      final fakePlayer = FakeAudioPlayer();
      final service = AlarmService(player: fakePlayer);

      await service.startAlarm(soundType: 'siren', repeatCount: 0);

      expect(fakePlayer.currentReleaseMode, equals(ReleaseMode.loop));
      expect(fakePlayer.playCallCount, equals(1));
      expect(service.isRinging, isTrue);

      await service.stopAlarm();
      expect(service.isRinging, isFalse);
      expect(fakePlayer.isStopped, isTrue);
    });

    test('Plays specified repeat count and fires onComplete when finished', () async {
      final fakePlayer = FakeAudioPlayer();
      final service = AlarmService(player: fakePlayer);
      bool completed = false;

      await service.startAlarm(
        soundType: 'bell',
        repeatCount: 2,
        onComplete: () {
          completed = true;
        },
      );

      expect(fakePlayer.currentReleaseMode, equals(ReleaseMode.stop));
      expect(fakePlayer.playCallCount, equals(1));
      expect(service.isRinging, isTrue);
      expect(completed, isFalse);

      // 1st completion -> should trigger 2nd play
      fakePlayer.triggerComplete();
      await pumpEventQueue();
      expect(fakePlayer.playCallCount, equals(2));
      expect(service.isRinging, isTrue);
      expect(completed, isFalse);

      // 2nd completion -> should finish, stop alarm, and fire onComplete
      fakePlayer.triggerComplete();
      await pumpEventQueue();
      expect(completed, isTrue);
      expect(service.isRinging, isFalse);
      expect(fakePlayer.isStopped, isTrue);
    });

    // Gene - Oct, 07, 2026: Added tests verifying preset sounds take precedence over customPath unless soundType is 'custom'
    test('Plays preset sound when soundType is a preset even if customPath is present', () async {
      final fakePlayer = FakeAudioPlayer();
      final service = AlarmService(player: fakePlayer);

      await service.startAlarm(
        soundType: 'bell',
        customPath: '/non/existent/custom_file.mp3',
        repeatCount: 0,
      );

      expect(fakePlayer.lastPlayedSource, isA<AssetSource>());
      expect((fakePlayer.lastPlayedSource as AssetSource).path, equals('sounds/bell.wav'));
    });

    test('Falls back to preset siren asset when custom soundType is specified but file does not exist', () async {
      final fakePlayer = FakeAudioPlayer();
      final service = AlarmService(player: fakePlayer);

      await service.startAlarm(
        soundType: 'custom',
        customPath: '/definitely/non_existent/path/alarm.wav',
        repeatCount: 0,
      );

      expect(fakePlayer.lastPlayedSource, isA<AssetSource>());
      expect((fakePlayer.lastPlayedSource as AssetSource).path, equals('sounds/siren.wav'));
    });
  });
}

