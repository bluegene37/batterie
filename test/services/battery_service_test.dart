import 'package:flutter_test/flutter_test.dart';
import 'package:batterie/models/battery_info.dart';
import 'package:batterie/services/battery_service.dart';

void main() {
  group('BatteryService parser tests', () {
    test('Parses macOS pmset discharging output accurately', () {
      const pmsetOutput = '''Now drawing from 'Battery Power'
 -InternalBattery-0 (id=1234567)\t18%; discharging; 1:42 remaining present: true''';

      final info = BatteryService.parsePmsetOutput(pmsetOutput);
      expect(info, isNotNull);
      expect(info!.percentage, equals(18));
      expect(info.isCharging, isFalse);
      expect(info.source, equals(PowerSource.battery));
      expect(info.timeRemaining, equals('1:42'));
      expect(info.isDischarging, isTrue);
    });

    test('Parses macOS pmset charging on AC Power output accurately', () {
      const pmsetOutput = '''Now drawing from 'AC Power'
 -InternalBattery-0 (id=1234567)\t85%; charging; 0:35 remaining present: true''';

      final info = BatteryService.parsePmsetOutput(pmsetOutput);
      expect(info, isNotNull);
      expect(info!.percentage, equals(85));
      expect(info.isCharging, isTrue);
      expect(info.source, equals(PowerSource.ac));
      expect(info.isDischarging, isFalse);
    });

    test('Parses macOS pmset charged (100% on AC Power) accurately', () {
      const pmsetOutput = '''Now drawing from 'AC Power'
 -InternalBattery-0 (id=1234567)\t100%; charged; 0:00 remaining present: true''';

      final info = BatteryService.parsePmsetOutput(pmsetOutput);
      expect(info, isNotNull);
      expect(info!.percentage, equals(100));
      expect(info.isCharging, isTrue);
      expect(info.source, equals(PowerSource.ac));
    });

    test('Parses Windows CIM output accurately', () {
      const cimDischarging = '''
EstimatedChargeRemaining : 42
BatteryStatus            : 1
''';

      final info = BatteryService.parseWindowsCimOutput(cimDischarging);
      expect(info, isNotNull);
      expect(info!.percentage, equals(42));
      expect(info.isCharging, isFalse);
      expect(info.source, equals(PowerSource.battery));

      const cimCharging = '''
EstimatedChargeRemaining : 90
BatteryStatus            : 2
''';
      final chargingInfo = BatteryService.parseWindowsCimOutput(cimCharging);
      expect(chargingInfo, isNotNull);
      expect(chargingInfo!.percentage, equals(90));
      expect(chargingInfo.isCharging, isTrue);
      expect(chargingInfo.source, equals(PowerSource.ac));
    });
  });
}
