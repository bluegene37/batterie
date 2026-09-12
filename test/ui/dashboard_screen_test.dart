import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batterie/controllers/battery_alarm_controller.dart';
import 'package:batterie/models/battery_info.dart';
import 'package:batterie/services/alarm_service.dart';
import 'package:batterie/services/settings_service.dart';
import 'package:batterie/services/tray_window_service.dart';
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

class FakeTrayWindowService extends TrayWindowService {
  double? reportedHeight;

  @override
  Future<void> updateContentHeight(double contentHeight) async {
    reportedHeight = contentHeight;
  }
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

    // The takeover pulses forever, so pump a frame instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify the alarm takeover replaces the dashboard.
    expect(find.text('BATTERY ALARM TRIGGERED!'), findsOneWidget);
    expect(find.text('Snooze (5m)'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('Alarm Thresholds'), findsNothing);
    expect(find.text('Alarm Sound & Volume'), findsNothing);

    // Dismiss returns to the normal dashboard.
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('BATTERY ALARM TRIGGERED!'), findsNothing);
    expect(find.text('Alarm Thresholds'), findsOneWidget);
  });

  testWidgets('Snoozed alarm shows the dashboard with a snooze banner', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = BatteryAlarmController(
      alarmService: MockAlarmService(),
      settingsService: SettingsService(),
    );
    await controller.init();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(controller: controller, onMinimizeToTray: () {}),
      ),
    );
    await tester.pumpAndSettle();

    controller.evaluateBattery(const BatteryInfo(
      percentage: 9,
      isCharging: false,
      source: PowerSource.battery,
    ));
    await tester.pump();
    await tester.tap(find.text('Snooze (5m)'));
    await tester.pumpAndSettle();

    expect(find.text('Alarm Snoozed (5m)'), findsOneWidget);
    expect(find.text('Alarm Thresholds'), findsOneWidget);
    expect(find.text('BATTERY ALARM TRIGGERED!'), findsNothing);
  });

  testWidgets('Menu bar footnote renders and is wrapped in Flexible to prevent overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = BatteryAlarmController(
      alarmService: MockAlarmService(),
      settingsService: SettingsService(),
    );
    await controller.init();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(controller: controller, onMinimizeToTray: () {}),
      ),
    );
    await tester.pumpAndSettle();

    final footnoteFinder = find.textContaining('Lives in menu bar');
    expect(footnoteFinder, findsOneWidget);
    expect(
      find.ancestor(of: footnoteFinder, matching: find.byType(Flexible)),
      findsOneWidget,
    );
  });

  testWidgets('Footnote Row does not overflow at 356px width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 356,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ExcludeSemantics(
                    child: Icon(Icons.coffee_rounded, size: 13),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Lives in menu bar • Closing window keeps monitoring active',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Theme toggle button toggles controller theme mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = BatteryAlarmController(
      alarmService: MockAlarmService(),
      settingsService: SettingsService(),
    );
    await controller.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: controller.themeMode,
        home: DashboardScreen(controller: controller, onMinimizeToTray: () {}),
      ),
    );
    await tester.pumpAndSettle();

    // Default is light
    expect(controller.themeMode, equals(ThemeMode.light));

    // Find theme toggle button and tap
    final themeToggleFinder = find.byTooltip('Switch to dark mode (Dark Roast)');
    expect(themeToggleFinder, findsOneWidget);

    await tester.tap(themeToggleFinder);
    await tester.pumpAndSettle();

    expect(controller.themeMode, equals(ThemeMode.dark));
  });

  testWidgets('DashboardScreen measures content height and informs TrayWindowService', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = BatteryAlarmController(
      alarmService: MockAlarmService(),
      settingsService: SettingsService(),
    );
    await controller.init();
    final fakeTray = FakeTrayWindowService();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          controller: controller,
          trayService: fakeTray,
          onMinimizeToTray: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeTray.reportedHeight, isNotNull);
    // Content height including all widgets is well above 400px
    expect(fakeTray.reportedHeight!, greaterThan(400.0));
  });
}
