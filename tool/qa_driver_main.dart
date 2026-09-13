import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:batterie/controllers/battery_alarm_controller.dart';
import 'package:batterie/main.dart' as app;
import 'package:batterie/services/battery_service.dart';
import 'package:batterie/services/tray_window_service.dart';

void main() async {
  BatteryAlarmController? controller;

  enableFlutterDriverExtension(handler: (message) async {
    if (message == 'light') {
      await controller?.setThemeMode(ThemeMode.light);
      return 'ok';
    } else if (message == 'dark') {
      await controller?.setThemeMode(ThemeMode.dark);
      return 'ok';
    }
    return 'unknown';
  });

  final batteryService = BatteryService();
  controller = BatteryAlarmController(batteryService: batteryService);
  final trayService = TrayWindowService();

  await controller.init();

  await trayService.init(
    onShow: () {},
    onTest: () => controller?.testAlarm(),
    onToggleTheme: () => controller?.toggleThemeMode(),
    onQuit: () {
      controller?.dispose();
      batteryService.dispose();
    },
  );

  runApp(app.BatteryAlarmApp(
    controller: controller,
    trayService: trayService,
  ));
}
