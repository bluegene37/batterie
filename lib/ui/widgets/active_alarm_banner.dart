import 'package:flutter/material.dart';
import '../../models/alarm_state.dart';
import '../../models/battery_info.dart';
import '../../theme/app_theme.dart';

/// Banner shown on the dashboard while an alarm is snoozed.
///
/// While an alarm is ringing the dashboard is replaced by [AlarmTakeover],
/// so the ringing branch here is only reached in isolation.
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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isRinging = alarmState.status == AlarmStatus.ringing;
    final bannerColor = isRinging ? scheme.error : BatteryStatusColors.of(context).warning;
    final onBanner = scheme.onError;

    final title = isRinging
        ? 'BATTERY ALARM TRIGGERED!'
        : 'Alarm Snoozed (${snoozeMinutes}m)';
    final message = isRinging
        ? 'Battery dropped to ${batteryInfo.percentage}% (${alarmState.triggeredRule?.label ?? "Critical"}). Connect charger now to stop alarm.'
        : 'Alarm will re-ring in $snoozeMinutes minutes if charger is disconnected.';

    final radius = BorderRadius.circular(AppTheme.cardRadius);

    return AnimatedContainer(
      duration: AppMotion.standardDuration,
      curve: AppMotion.standardCurve,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: radius,
        border: Border.all(color: scheme.outline, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  isRinging ? Icons.warning_amber_rounded : Icons.snooze_rounded,
                  color: onBanner,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: onBanner,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: onBanner, height: 1.3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isRinging) ...[
                FilledButton.icon(
                  onPressed: onSnooze,
                  style: FilledButton.styleFrom(
                    backgroundColor: onBanner,
                    foregroundColor: bannerColor,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.snooze, size: 14),
                  label: Text('Snooze (${snoozeMinutes}m)'),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: onBanner,
                  side: BorderSide(color: onBanner, width: 1.2),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
