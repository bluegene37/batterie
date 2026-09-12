import 'package:flutter/material.dart';
import '../../models/alarm_state.dart';
import '../../models/battery_info.dart';
import '../../theme/app_theme.dart';

/// Full-window alarm screen shown while a threshold is ringing.
///
/// It replaces the dashboard entirely so the window reads as an alarm, not a
/// settings panel: pulsing ground, the live percentage, the rule that fired,
/// and two large actions. There are deliberately no keyboard shortcuts here,
/// so a stray keystroke can never silence the alarm.
///
/// Colors come from the theme's error roles (`error` / `errorContainer` /
/// `onError`), which both themes tune to keep AA contrast at either end of
/// the pulse. The pulse is a looping controller (repeat + reverse needs
/// playback control) and stops entirely under reduced motion.
class AlarmTakeover extends StatefulWidget {
  final AlarmState alarmState;
  final BatteryInfo batteryInfo;
  final int snoozeMinutes;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;

  const AlarmTakeover({
    super.key,
    required this.alarmState,
    required this.batteryInfo,
    required this.snoozeMinutes,
    required this.onSnooze,
    required this.onDismiss,
  });

  @override
  State<AlarmTakeover> createState() => _AlarmTakeoverState();
}

class _AlarmTakeoverState extends State<AlarmTakeover>
    with SingleTickerProviderStateMixin {
  static const double _actionHeight = 46;

  late final AnimationController _pulse;
  late final Animation<double> _pulseCurve;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: AppMotion.pulseDuration,
    );
    _pulseCurve = CurvedAnimation(parent: _pulse, curve: AppMotion.pulseCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _pulse.stop();
      _pulse.value = 1.0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final ruleLabel = widget.alarmState.triggeredRule?.label ?? 'Critical';
    final rulePercentage = widget.alarmState.triggeredRule?.percentage ?? 0;
    final radius = BorderRadius.circular(AppTheme.cardRadius);
    final actionShape = RoundedRectangleBorder(borderRadius: radius);

    return AnimatedBuilder(
      animation: _pulseCurve,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(scheme.errorContainer, scheme.error, _pulseCurve.value),
          ),
          child: child,
        );
      },
      // Everything below is static: built once, repainted over the pulse.
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: scheme.onError,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    'BATTERY ALARM TRIGGERED!',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(color: scheme.onError),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${widget.batteryInfo.percentage}%',
                  style: text.displayLarge?.copyWith(color: scheme.onError),
                ),
                const SizedBox(height: 6),
                Text(
                  ruleLabel,
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(color: scheme.onError),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.onError.withValues(alpha: 0.16),
                    borderRadius: radius,
                    border: Border.all(
                      color: scheme.onError.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.power_rounded,
                          color: scheme.onError,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Plug in the charger to stop the alarm.',
                          style: text.bodyMedium?.copyWith(color: scheme.onError),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    minHeight: _actionHeight,
                  ),
                  child: FilledButton.icon(
                    onPressed: widget.onSnooze,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.onError,
                      foregroundColor: scheme.errorContainer,
                      shape: actionShape,
                    ),
                    icon: const Icon(Icons.snooze, size: 18),
                    label: Text('Snooze (${widget.snoozeMinutes}m)'),
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    minHeight: _actionHeight,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: widget.onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onError,
                      side: BorderSide(color: scheme.onError, width: 1.4),
                      shape: actionShape,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dismiss stays quiet until the battery recovers above $rulePercentage%.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: scheme.onError),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
