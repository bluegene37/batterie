import 'package:flutter/material.dart';
import '../../models/alarm_state.dart';
import '../../models/battery_info.dart';

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
    final backgroundColor = isRinging ? Colors.red.shade700 : Colors.amber.shade800;
    final title = isRinging
        ? 'BATTERY ALARM TRIGGERED!'
        : 'Alarm Snoozed (${snoozeMinutes}m)';
    final message = isRinging
        ? 'Battery dropped to ${batteryInfo.percentage}% (${alarmState.triggeredRule?.label ?? "Critical"}). Connect your charger now to stop the alarm.'
        : 'Alarm will re-ring in $snoozeMinutes minutes if the charger is not connected.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isRinging ? Icons.warning_amber_rounded : Icons.snooze,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isRinging)
            ElevatedButton.icon(
              onPressed: onSnooze,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
              icon: const Icon(Icons.snooze, size: 18),
              label: Text('Snooze (${snoozeMinutes}m)'),
            ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onDismiss,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}
