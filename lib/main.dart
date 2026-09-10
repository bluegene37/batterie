import 'package:flutter/material.dart';
import 'controllers/battery_alarm_controller.dart';
import 'services/battery_service.dart';
import 'services/tray_window_service.dart';
import 'theme/app_theme.dart';
import 'ui/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final batteryService = BatteryService();
  final controller = BatteryAlarmController(batteryService: batteryService);
  final trayService = TrayWindowService();

  await controller.init();

  await trayService.init(
    onShow: () {},
    onTest: () => controller.testAlarm(),
    onQuit: () {
      controller.dispose();
      batteryService.dispose();
    },
  );

  // Hook controller to tray & window
  controller.onAlarmTriggered = () async {
    await trayService.bringToFront();
    await trayService.updateTray(controller.batteryInfo, true);
  };

  controller.addListener(() {
    trayService.updateTray(
      controller.batteryInfo,
      controller.alarmState.isRinging,
    );
  });

  runApp(BatteryAlarmApp(
    controller: controller,
    trayService: trayService,
  ));
}

class BatteryAlarmApp extends StatelessWidget {
  final BatteryAlarmController controller;
  final TrayWindowService trayService;

  const BatteryAlarmApp({
    super.key,
    required this.controller,
    required this.trayService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final visualTheme = controller.visualTheme;
        return MaterialApp(
          title: 'Battery Alarm Monitor',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          theme: AppTheme.buildTheme(
            visualTheme: visualTheme,
            brightness: Brightness.light,
          ),
          darkTheme: AppTheme.buildTheme(
            visualTheme: visualTheme,
            brightness: Brightness.dark,
          ),
          home: DashboardScreen(
            controller: controller,
            onMinimizeToTray: () => trayService.minimizeToTray(),
          ),
        );
      },
    );
  }
}
