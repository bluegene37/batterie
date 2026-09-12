import 'package:flutter/material.dart';
import '../../models/battery_info.dart';
import '../../theme/app_theme.dart';
import 'paper_surface.dart';

class BatteryGauge extends StatelessWidget {
  final BatteryInfo info;

  const BatteryGauge({super.key, required this.info});

  Color _statusColor(BatteryStatusColors colors) {
    if (info.isCharging) return colors.charging;
    if (info.percentage > 35) return colors.charging;
    if (info.percentage > 20) return colors.warning;
    return colors.critical;
  }

  String? get _timeRemainingText {
    final tr = info.timeRemaining;
    if (tr == null || tr.isEmpty || tr == '0:00') return null;
    final lower = tr.toLowerCase();
    if (lower.contains('remaining') ||
        lower.contains('left') ||
        lower.contains('until') ||
        lower.contains('full')) {
      return tr;
    }
    return info.isDischarging ? '$tr remaining' : '$tr until full';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(BatteryStatusColors.of(context));
    final fraction = (info.percentage / 100.0).clamp(0.0, 1.0);
    final remainingText = _timeRemainingText;

    return PaperSurface(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                        border: Border.all(color: theme.colorScheme.outline, width: 1.0),
                      ),
                      child: Icon(
                        info.isCharging
                            ? Icons.battery_charging_full_rounded
                            : (info.percentage <= 20
                                ? Icons.battery_alert_rounded
                                : Icons.battery_std_rounded),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT BATTERY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontFamily: 'Archivo Narrow',
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.isDischarging
                                ? 'Discharging'
                                : (info.isCharging ? 'Charging' : 'On AC Power'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (remainingText != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              remainingText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (info.isCharging) ...[
                      Icon(Icons.bolt_rounded, color: statusColor, size: 15),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      '${info.percentage}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
