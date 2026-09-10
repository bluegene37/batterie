import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/alarm_state.dart';
import '../../models/battery_info.dart';
import '../../theme/app_theme.dart';

class ActiveAlarmBanner extends StatelessWidget {
  final AlarmState alarmState;
  final BatteryInfo batteryInfo;
  final int snoozeMinutes;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;
  final AppVisualTheme visualTheme;

  const ActiveAlarmBanner({
    super.key,
    required this.alarmState,
    required this.batteryInfo,
    required this.snoozeMinutes,
    required this.onSnooze,
    required this.onDismiss,
    this.visualTheme = AppVisualTheme.macGlass,
  });

  @override
  Widget build(BuildContext context) {
    if (alarmState.status == AlarmStatus.idle) {
      return const SizedBox.shrink();
    }

    final isRinging = alarmState.status == AlarmStatus.ringing;
    final isMacGlass = visualTheme == AppVisualTheme.macGlass;
    final bannerColor = isMacGlass
        ? (isRinging ? AppColors.macCritical : AppColors.macWarning)
        : (isRinging ? AppColors.batteryCritical : AppColors.batteryWarning);

    final title = isRinging
        ? 'BATTERY ALARM TRIGGERED!'
        : 'Alarm Snoozed (${snoozeMinutes}m)';
    final message = isRinging
        ? 'Battery dropped to ${batteryInfo.percentage}% (${alarmState.triggeredRule?.label ?? "Critical"}). Connect charger now to stop alarm.'
        : 'Alarm will re-ring in $snoozeMinutes minutes if charger is disconnected.';

    final radius = BorderRadius.circular(isMacGlass ? AppTheme.cardRadius : 4.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: isMacGlass ? 0.35 : 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isMacGlass
                  ? bannerColor.withValues(alpha: 0.82)
                  : bannerColor,
              borderRadius: radius,
              border: Border.all(
                color: isMacGlass
                    ? Colors.white.withValues(alpha: 0.35)
                    : AppColors.hairline,
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isRinging
                          ? (isMacGlass ? CupertinoIcons.exclamationmark_triangle_fill : Icons.warning_amber_rounded)
                          : (isMacGlass ? CupertinoIcons.moon_fill : Icons.snooze_rounded),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isRinging) ...[
                      FilledButton.icon(
                        onPressed: onSnooze,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: bannerColor,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: const Icon(Icons.snooze, size: 14),
                        label: Text(
                          'Snooze (${snoozeMinutes}m)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.2),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Dismiss', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
