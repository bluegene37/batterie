import 'package:flutter/material.dart';
import '../../models/battery_info.dart';
import '../../theme/app_theme.dart';
import 'glass_surface.dart';

class BatteryGauge extends StatelessWidget {
  final BatteryInfo info;
  final AppVisualTheme visualTheme;

  const BatteryGauge({
    super.key,
    required this.info,
    this.visualTheme = AppVisualTheme.macGlass,
  });

  Color _getStatusColor(bool isMacGlass) {
    if (isMacGlass) {
      if (info.isCharging) return AppColors.macCharging;
      if (info.percentage > 35) return AppColors.macCharging;
      if (info.percentage > 20) return AppColors.macWarning;
      return AppColors.macCritical;
    } else {
      if (info.isCharging) return AppColors.charging;
      if (info.percentage > 35) return AppColors.charging;
      if (info.percentage > 20) return AppColors.batteryWarning;
      return AppColors.batteryCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMacGlass = visualTheme == AppVisualTheme.macGlass;
    final statusColor = _getStatusColor(isMacGlass);
    final fraction = (info.percentage / 100.0).clamp(0.0, 1.0);

    return GlassSurface(
      visualTheme: visualTheme,
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
                        color: statusColor.withValues(alpha: isMacGlass ? 0.15 : 0.12),
                        borderRadius: BorderRadius.circular(isMacGlass ? 10 : 3),
                        border: isMacGlass
                            ? Border.all(color: statusColor.withValues(alpha: 0.25), width: 0.8)
                            : Border.all(color: AppColors.hairline, width: 1.0),
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
                            isMacGlass ? 'Current Battery' : 'CURRENT BATTERY',
                            style: isMacGlass
                                ? theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    letterSpacing: -0.1,
                                    fontWeight: FontWeight.w500,
                                  )
                                : const TextStyle(
                                    fontFamily: 'Archivo Narrow',
                                    fontSize: 10,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkSoft,
                                  ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: isMacGlass ? -0.2 : 0.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isMacGlass ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(isMacGlass ? 12 : 3),
                  border: Border.all(
                    color: statusColor.withValues(alpha: isMacGlass ? 0.35 : 0.25),
                    width: isMacGlass ? 0.8 : 1.0,
                  ),
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
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: isMacGlass ? -0.4 : 0.2,
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
            borderRadius: BorderRadius.circular(isMacGlass ? 5 : 2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: isMacGlass ? 6 : 5,
              backgroundColor: isMacGlass
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                  : theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
