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
    onToggleTheme: () => controller.toggleThemeMode(),
    onQuit: () {
      controller.dispose();
      batteryService.dispose();
    },
  );

  // Hook controller to tray & window: ringing takes the window over
  // (always on top, every Space, menu bar + Dock flags); ending it restores
  // a normal window.
  controller.onAlarmTriggered = () async {
    await trayService.enterAlarmMode(controller.batteryInfo);
    await trayService.updateTray(controller.batteryInfo, true);
  };
  controller.onAlarmEnded = () async {
    await trayService.exitAlarmMode();
    await trayService.updateTray(controller.batteryInfo, false);
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
        return MaterialApp(
          title: 'Battery Alarm Monitor',
          debugShowCheckedModeBanner: false,
          themeMode: controller.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: DashboardScreen(
            controller: controller,
            trayService: trayService,
            onMinimizeToTray: () => trayService.minimizeToTray(),
          ),
        );
      },
    );
  }
}
