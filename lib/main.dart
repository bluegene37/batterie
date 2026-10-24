import 'package:flutter/material.dart';
import 'controllers/battery_alarm_controller.dart';
import 'services/battery_service.dart';
import 'services/tray_window_service.dart';
import 'theme/app_theme.dart';
import 'ui/dashboard_screen.dart';
// Gene - Oct 24, 2026: Added UpdateStatus import for tray update state wiring.
import 'models/update_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final batteryService = BatteryService();
  final controller = BatteryAlarmController(batteryService: batteryService);
  final trayService = TrayWindowService();

  await controller.init();

  // Gene - Oct 24, 2026: Hooked onCheckForUpdates and onInstallUpdate into tray service. Preserved previous trayService.init below.
  // await trayService.init(
  //   onShow: () {},
  //   onTest: () => controller.testAlarm(),
  //   onToggleTheme: () => controller.toggleThemeMode(),
  //   onQuit: () {
  //     controller.dispose();
  //     batteryService.dispose();
  //   },
  // );
  await trayService.init(
    onShow: () {},
    onTest: () => controller.testAlarm(),
    onToggleTheme: () => controller.toggleThemeMode(),
    onCheckForUpdates: () => controller.checkForUpdates(manual: true),
    onInstallUpdate: () => controller.installUpdate(),
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

  // Gene - Oct 24, 2026: Forwarded update flags to updateTray on controller state change. Preserved previous listener below.
  // controller.addListener(() {
  //   trayService.updateTray(
  //     controller.batteryInfo,
  //     controller.alarmState.isRinging,
  //   );
  // });
  controller.addListener(() {
    trayService.updateTray(
      controller.batteryInfo,
      controller.alarmState.isRinging,
      hasUpdate: controller.hasUpdateAvailable,
      updateVersion: controller.updateInfo?.version,
      isCheckingUpdates: controller.updateStatus == UpdateStatus.checking,
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
