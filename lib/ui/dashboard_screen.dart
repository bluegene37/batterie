import 'package:flutter/material.dart';
import '../controllers/battery_alarm_controller.dart';
import 'widgets/active_alarm_banner.dart';
import 'widgets/audio_settings_card.dart';
import 'widgets/battery_gauge.dart';
import 'widgets/threshold_list.dart';

class DashboardScreen extends StatelessWidget {
  final BatteryAlarmController controller;
  final VoidCallback onMinimizeToTray;

  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onMinimizeToTray,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icons/app_logo.png',
                    width: 30,
                    height: 30,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.battery_charging_full,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Battery Alarm Monitor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Minimize to Menu Bar / Tray',
                icon: const Icon(Icons.arrow_downward_rounded),
                onPressed: onMinimizeToTray,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ActiveAlarmBanner(
                    alarmState: controller.alarmState,
                    batteryInfo: controller.batteryInfo,
                    snoozeMinutes: controller.snoozeMinutes,
                    onSnooze: () => controller.snooze(),
                    onDismiss: () => controller.dismiss(),
                  ),
                  BatteryGauge(info: controller.batteryInfo),
                  const SizedBox(height: 16),
                  ThresholdList(
                    rules: controller.thresholdRules,
                    onAdd: controller.addThreshold,
                    onUpdate: controller.updateThreshold,
                    onDelete: controller.removeThreshold,
                  ),
                  const SizedBox(height: 16),
                  AudioSettingsCard(
                    selectedSound: controller.defaultSound,
                    customSoundPath: controller.customSoundPath,
                    volume: controller.volume,
                    snoozeMinutes: controller.snoozeMinutes,
                    isTesting: controller.isTesting,
                    onSoundChanged: controller.setDefaultSound,
                    onCustomPathChanged: controller.setCustomSoundPath,
                    onVolumeChanged: controller.setVolume,
                    onSnoozeChanged: controller.setSnoozeMinutes,
                    onTestAlarm: controller.testAlarm,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Running in background • Closing this window keeps monitoring active in tray',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
