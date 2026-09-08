import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batterie/controllers/battery_alarm_controller.dart';
import 'package:batterie/models/alarm_state.dart';
import 'package:batterie/models/battery_info.dart';
import 'package:batterie/models/threshold_rule.dart';
import 'package:batterie/services/alarm_service.dart';
import 'package:batterie/services/settings_service.dart';

class MockAlarmService extends AlarmService {
  bool alarmStarted = false;
  bool alarmStopped = false;
  String? lastSound;
  double? lastVolume;

  @override
  bool get isRinging => alarmStarted && !alarmStopped;

  @override
  Future<void> startAlarm({
    required String soundType,
    String? customPath,
    double volume = 1.0,
  }) async {
    alarmStarted = true;
    alarmStopped = false;
    lastSound = soundType;
    lastVolume = volume;
  }

  @override
  Future<void> stopAlarm() async {
    alarmStopped = true;
    alarmStarted = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BatteryAlarmController unit tests', () {
    late MockAlarmService mockAlarm;
    late SettingsService settingsService;
    late BatteryAlarmController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockAlarm = MockAlarmService();
      settingsService = SettingsService();
      controller = BatteryAlarmController(
        alarmService: mockAlarm,
        settingsService: settingsService,
      );
      await controller.init();
    });

    test('Triggers alarm when battery drops <= threshold while discharging', () {
      expect(controller.alarmState.isRinging, isFalse);

      // Battery at 50% discharging -> no alarm
      controller.evaluateBattery(const BatteryInfo(
        percentage: 50,
        isCharging: false,
        source: PowerSource.battery,
      ));
      expect(controller.alarmState.isRinging, isFalse);
      expect(mockAlarm.alarmStarted, isFalse);

      // Battery drops to 20% discharging -> triggers 20% warning rule!
      controller.evaluateBattery(const BatteryInfo(
        percentage: 20,
        isCharging: false,
        source: PowerSource.battery,
      ));
      expect(controller.alarmState.isRinging, isTrue);
      expect(controller.alarmState.triggeredRule?.percentage, equals(20));
      expect(mockAlarm.alarmStarted, isTrue);
    });

    test('Auto-silences immediately when plugged into AC power', () {
      // Trigger alarm at 18%
      controller.evaluateBattery(const BatteryInfo(
        percentage: 18,
        isCharging: false,
        source: PowerSource.battery,
      ));
      expect(controller.alarmState.isRinging, isTrue);

      // User plugs in charger -> charging becomes true
      controller.evaluateBattery(const BatteryInfo(
        percentage: 18,
        isCharging: true,
        source: PowerSource.ac,
      ));

      expect(controller.alarmState.status, equals(AlarmStatus.idle));
      expect(controller.alarmState.isRinging, isFalse);
      expect(mockAlarm.alarmStopped, isTrue);
    });

    test('Anti-flapping: dismiss prevents re-triggering until lower threshold', () {
      // Trigger at 20%
      controller.evaluateBattery(const BatteryInfo(
        percentage: 20,
        isCharging: false,
        source: PowerSource.battery,
      ));
      expect(controller.alarmState.isRinging, isTrue);

      // User dismisses
      controller.dismiss();
      expect(controller.alarmState.isRinging, isFalse);
      expect(mockAlarm.alarmStopped, isTrue);

      // Next poll at 19% (still above 10% critical) -> does NOT re-trigger
      controller.evaluateBattery(const BatteryInfo(
        percentage: 19,
        isCharging: false,
        source: PowerSource.battery,
      ));
      expect(controller.alarmState.isRinging, isFalse);

      // Next poll drops to 10% -> triggers critical alarm!
      controller.evaluateBattery(const BatteryInfo(
        percentage: 10,
        isCharging: false,
        source: PowerSource.battery,
      ));
      expect(controller.alarmState.isRinging, isTrue);
      expect(controller.alarmState.triggeredRule?.percentage, equals(10));
    });

    test('Snooze silences alarm and re-triggers when expired', () {
      // Trigger at 15%
      controller.evaluateBattery(const BatteryInfo(
        percentage: 15,
        isCharging: false,
        source: PowerSource.battery,
      ));
      expect(controller.alarmState.isRinging, isTrue);

      // Snooze for 5 minutes
      controller.snooze(minutes: 5);
      expect(controller.alarmState.status, equals(AlarmStatus.snoozed));
      expect(controller.alarmState.isRinging, isFalse);

      // Check battery while snooze is active -> remains snoozed
      controller.evaluateBattery(const BatteryInfo(
        percentage: 14,
        isCharging: false,
        source: PowerSource.battery,
      ));
      expect(controller.alarmState.isSnoozed, isTrue);
      expect(controller.alarmState.isRinging, isFalse);

      // Simulate snooze expiration
      controller.setSimulatedSnoozeExpired();
      controller.evaluateBattery(const BatteryInfo(
        percentage: 14,
        isCharging: false,
        source: PowerSource.battery,
      ));
      expect(controller.alarmState.isRinging, isTrue);
    });

    test('Add, update, remove threshold rules updates and persists rules', () async {
      expect(controller.thresholdRules.length, equals(2));

      await controller.addThreshold(15, 'Urgent 15%');
      expect(controller.thresholdRules.length, equals(3));
      expect(controller.thresholdRules.any((r) => r.percentage == 15), isTrue);

      final rule15 = controller.thresholdRules.firstWhere((r) => r.percentage == 15);
      await controller.updateThreshold(rule15.copyWith(label: 'Super Urgent'));
      expect(
        controller.thresholdRules.firstWhere((r) => r.id == rule15.id).label,
        equals('Super Urgent'),
      );

      await controller.removeThreshold(rule15.id);
      expect(controller.thresholdRules.length, equals(2));
      expect(controller.thresholdRules.any((r) => r.id == rule15.id), isFalse);
    });
  });
}
