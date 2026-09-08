import 'package:flutter_test/flutter_test.dart';
import 'package:batterie/services/alarm_service.dart';

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
  });
}
