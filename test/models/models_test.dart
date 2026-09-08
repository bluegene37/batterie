import 'package:flutter_test/flutter_test.dart';
import 'package:batterie/models/battery_info.dart';
import 'package:batterie/models/threshold_rule.dart';
import 'package:batterie/models/alarm_state.dart';

void main() {
  group('ThresholdRule tests', () {
    test('ThresholdRule serializes and deserializes correctly', () {
      final rule = ThresholdRule(
        id: 'rule-1',
        percentage: 15,
        label: 'Urgent Battery',
        isEnabled: true,
        soundType: 'siren',
        customSoundPath: null,
      );

      final json = rule.toJson();
      final fromJson = ThresholdRule.fromJson(json);

      expect(fromJson.id, equals('rule-1'));
      expect(fromJson.percentage, equals(15));
      expect(fromJson.label, equals('Urgent Battery'));
      expect(fromJson.isEnabled, isTrue);
      expect(fromJson.soundType, equals('siren'));
      expect(fromJson.customSoundPath, isNull);
    });

    test('ThresholdRule copyWith updates fields correctly', () {
      final rule = ThresholdRule(
        id: 'rule-2',
        percentage: 20,
        label: 'Warning',
        isEnabled: true,
        soundType: 'bell',
      );

      final updated = rule.copyWith(percentage: 25, isEnabled: false);
      expect(updated.percentage, equals(25));
      expect(updated.isEnabled, isFalse);
      expect(updated.label, equals('Warning'));
      expect(updated.soundType, equals('bell'));
    });
  });

  group('BatteryInfo tests', () {
    test('BatteryInfo status description works for discharging and charging', () {
      final discharging = BatteryInfo(
        percentage: 18,
        isCharging: false,
        source: PowerSource.battery,
      );
      expect(discharging.percentage, equals(18));
      expect(discharging.isDischarging, isTrue);
      expect(discharging.statusText, contains('18%'));
      expect(discharging.statusText, contains('Discharging'));

      final charging = BatteryInfo(
        percentage: 85,
        isCharging: true,
        source: PowerSource.ac,
      );
      expect(charging.isCharging, isTrue);
      expect(charging.isDischarging, isFalse);
      expect(charging.statusText, contains('85%'));
      expect(charging.statusText, contains('Charging'));
    });
  });

  group('AlarmState tests', () {
    test('AlarmState tracks ringing and snooze correctly', () {
      final idle = AlarmState.idle();
      expect(idle.status, equals(AlarmStatus.idle));
      expect(idle.isRinging, isFalse);
      expect(idle.isSnoozed, isFalse);

      final rule = ThresholdRule(
        id: 'rule-10',
        percentage: 10,
        label: 'Critical',
        isEnabled: true,
        soundType: 'siren',
      );

      final ringing = AlarmState.ringing(rule);
      expect(ringing.status, equals(AlarmStatus.ringing));
      expect(ringing.isRinging, isTrue);
      expect(ringing.triggeredRule?.percentage, equals(10));

      final snoozeUntil = DateTime.now().add(const Duration(minutes: 5));
      final snoozed = ringing.toSnoozed(snoozeUntil);
      expect(snoozed.status, equals(AlarmStatus.snoozed));
      expect(snoozed.isRinging, isFalse);
      expect(snoozed.isSnoozed, isTrue);
      expect(snoozed.snoozeUntil, equals(snoozeUntil));
    });
  });
}
