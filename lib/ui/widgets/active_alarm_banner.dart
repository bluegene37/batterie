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

  const ActiveAlarmBanner({
    super.key,
    required this.alarmState,
    required this.batteryInfo,
    required this.snoozeMinutes,
    required this.onSnooze,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (alarmState.status == AlarmStatus.idle) {
      return const SizedBox.shrink();
    }

    final isRinging = alarmState.status == AlarmStatus.ringing;
    final bannerColor = isRinging ? AppColors.batteryCritical : AppColors.batteryWarning;
    final title = isRinging
        ? 'BATTERY ALARM TRIGGERED!'
        : 'Alarm Snoozed (${snoozeMinutes}m)';
    final message = isRinging
        ? 'Battery dropped to ${batteryInfo.percentage}% (${alarmState.triggeredRule?.label ?? "Critical"}). Connect charger now to stop alarm.'
        : 'Alarm will re-ring in $snoozeMinutes minutes if charger is disconnected.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRinging ? Icons.warning_amber_rounded : Icons.snooze_rounded,
                color: Colors.white,
                size: 22,
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
                  label: Text('Snooze (${snoozeMinutes}m)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
    );
  }
}
