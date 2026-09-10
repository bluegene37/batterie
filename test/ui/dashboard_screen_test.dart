import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batterie/controllers/battery_alarm_controller.dart';
import 'package:batterie/models/battery_info.dart';
import 'package:batterie/services/alarm_service.dart';
import 'package:batterie/services/settings_service.dart';
import 'package:batterie/ui/dashboard_screen.dart';

class MockAlarmService extends AlarmService {
  @override
  Future<void> startAlarm({
    required String soundType,
    String? customPath,
    double volume = 1.0,
  }) async {}

  @override
  Future<void> stopAlarm() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DashboardScreen renders battery info, thresholds, and controls', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final mockAlarm = MockAlarmService();
    final settingsService = SettingsService();
    final controller = BatteryAlarmController(
      alarmService: mockAlarm,
      settingsService: settingsService,
    );
    await controller.init();

    controller.evaluateBattery(const BatteryInfo(
      percentage: 75,
      isCharging: false,
      source: PowerSource.battery,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          controller: controller,
          onMinimizeToTray: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify battery gauge rendering
    expect(find.text('75%'), findsOneWidget);
    expect(find.textContaining('Discharging'), findsWidgets);

    // Verify threshold list
    expect(find.text('Alarm Thresholds'), findsOneWidget);
    expect(find.text('Add Threshold'), findsOneWidget);

    // Verify alarm controls
    expect(find.text('Alarm Sound & Volume'), findsOneWidget);
    expect(find.text('Test Alarm'), findsOneWidget);

    // Verify no ringing banner when idle
    expect(find.text('BATTERY ALARM TRIGGERED!'), findsNothing);

    // Now simulate battery dropping to 20%
    controller.evaluateBattery(const BatteryInfo(
      percentage: 20,
      isCharging: false,
      source: PowerSource.battery,
    ));

    await tester.pumpAndSettle();

    // Verify ringing banner appears!
    expect(find.text('BATTERY ALARM TRIGGERED!'), findsOneWidget);
    expect(find.text('Snooze (5m)'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('DashboardScreen allows switching visual themes (Glass vs Paper)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final mockAlarm = MockAlarmService();
    final settingsService = SettingsService();
    final controller = BatteryAlarmController(
      alarmService: mockAlarm,
      settingsService: settingsService,
    );
    await controller.init();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          controller: controller,
          onMinimizeToTray: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default theme is macGlass
    expect(find.text('Glass'), findsOneWidget);
    expect(find.text('Paper'), findsOneWidget);

    // Tap Paper theme
    await tester.tap(find.text('Paper'));
    await tester.pumpAndSettle();

    expect(controller.visualTheme.name, 'paperInk');

    // Tap Glass theme
    await tester.tap(find.text('Glass'));
    await tester.pumpAndSettle();

    expect(controller.visualTheme.name, 'macGlass');
  });
}
