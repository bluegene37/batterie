import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../controllers/battery_alarm_controller.dart';
import '../theme/app_theme.dart';
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
        final visualTheme = controller.visualTheme;
        final isMacGlass = visualTheme == AppVisualTheme.macGlass;
        final isMacOS = AppTheme.isMacOS;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: isMacOS ? 40 : 46,
            titleSpacing: isMacOS ? 78 : 12,
            flexibleSpace: isMacOS
                ? const DragToMoveArea(child: SizedBox.expand())
                : null,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isMacGlass ? 6 : 2),
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
                Expanded(
                  child: Text(
                    'Battery Alarm Monitor',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: isMacGlass ? -0.3 : 0.0,
                      fontFamily: isMacGlass ? '.SF Pro Text' : 'Literata',
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              // Visual Theme Switcher (macOS Glass vs. genexis Paper & Ink)
              Container(
                height: 26,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isMacGlass
                      ? Colors.black.withValues(alpha: 0.08)
                      : AppColors.hairlineFaint,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isMacGlass
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppColors.hairline,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ThemePillButton(
                      label: 'Glass',
                      icon: CupertinoIcons.sparkles,
                      isSelected: isMacGlass,
                      onTap: () => controller.setVisualTheme(AppVisualTheme.macGlass),
                    ),
                    _ThemePillButton(
                      label: 'Paper',
                      icon: CupertinoIcons.book,
                      isSelected: !isMacGlass,
                      onTap: () => controller.setVisualTheme(AppVisualTheme.paperInk),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 16,
                tooltip: 'Minimize to Menu Bar / Tray',
                icon: Icon(
                  isMacGlass ? CupertinoIcons.chevron_down_circle : Icons.arrow_downward_rounded,
                  size: 18,
                ),
                onPressed: onMinimizeToTray,
              ),
              const SizedBox(width: 8),
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
                    visualTheme: visualTheme,
                  ),
                  BatteryGauge(
                    info: controller.batteryInfo,
                    visualTheme: visualTheme,
                  ),
                  const SizedBox(height: 10),
                  ThresholdList(
                    rules: controller.thresholdRules,
                    onAdd: controller.addThreshold,
                    onUpdate: controller.updateThreshold,
                    onDelete: controller.removeThreshold,
                    visualTheme: visualTheme,
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
                    visualTheme: visualTheme,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isMacGlass ? CupertinoIcons.macwindow : Icons.coffee_rounded,
                        size: 13,
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Lives in menu bar • Closing window keeps monitoring active',
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

class _ThemePillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePillButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? (theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.85))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
