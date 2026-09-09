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
            toolbarHeight: 46,
            titleSpacing: 12,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/icons/app_logo.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.battery_charging_full_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Battery Alarm Monitor',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                tooltip: 'Minimize to Menu Bar / Tray',
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                onPressed: onMinimizeToTray,
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                  const SizedBox(height: 10),
                  ThresholdList(
                    rules: controller.thresholdRules,
                    onAdd: controller.addThreshold,
                    onUpdate: controller.updateThreshold,
                    onDelete: controller.removeThreshold,
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.coffee_rounded,
                        size: 13,
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Lives in top bar • Closing window keeps monitoring active',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
