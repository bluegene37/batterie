import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/threshold_rule.dart';
import '../../theme/app_theme.dart';
import 'glass_surface.dart';

class ThresholdList extends StatelessWidget {
  final List<ThresholdRule> rules;
  final Function(int percentage, String label) onAdd;
  final Function(ThresholdRule rule) onUpdate;
  final Function(String id) onDelete;
  final AppVisualTheme visualTheme;

  const ThresholdList({
    super.key,
    required this.rules,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    this.visualTheme = AppVisualTheme.macGlass,
  });

  void _showAddDialog(BuildContext context) {
    int percentage = 15;
    final labelController = TextEditingController(text: 'Low Alert');
    final isMacGlass = visualTheme == AppVisualTheme.macGlass;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isMacGlass
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  isMacGlass ? AppTheme.cardRadius : 4.0,
                ),
                side: BorderSide(
                  color: isMacGlass
                      ? AppColors.macGlassLightBorder
                      : AppColors.hairline,
                  width: 0.8,
                ),
              ),
              title: const Text(
                'Add Battery Alarm Threshold',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      hintText: 'e.g. Warning, Critical',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trigger Percentage:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(isMacGlass ? 6 : 2),
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: percentage.toDouble(),
                    min: 1,
                    max: 99,
                    divisions: 98,
                    label: '$percentage%',
                    onChanged: (val) {
                      setDialogState(() {
                        percentage = val.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    onAdd(percentage, labelController.text);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Add Threshold'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, ThresholdRule rule) {
    int percentage = rule.percentage;
    final labelController = TextEditingController(text: rule.label);
    final isMacGlass = visualTheme == AppVisualTheme.macGlass;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isMacGlass
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  isMacGlass ? AppTheme.cardRadius : 4.0,
                ),
                side: BorderSide(
                  color: isMacGlass
                      ? AppColors.macGlassLightBorder
                      : AppColors.hairline,
                  width: 0.8,
                ),
              ),
              title: const Text(
                'Edit Threshold',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trigger Percentage:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(isMacGlass ? 6 : 2),
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: percentage.toDouble(),
                    min: 1,
                    max: 99,
                    divisions: 98,
                    label: '$percentage%',
                    onChanged: (val) {
                      setDialogState(() {
                        percentage = val.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    onUpdate(rule.copyWith(
                      percentage: percentage,
                      label: labelController.text,
                    ));
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMacGlass = visualTheme == AppVisualTheme.macGlass;

    return GlassSurface(
      visualTheme: visualTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isMacGlass
                        ? CupertinoIcons.bell
                        : Icons.notifications_active_outlined,
                    color: theme.colorScheme.primary,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Alarm Thresholds',
                    style: isMacGlass
                        ? theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          )
                        : const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Threshold', style: TextStyle(fontSize: 11.5)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'App rings loudly when battery drops to or below these percentages while discharging.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 11,
              letterSpacing: isMacGlass ? -0.1 : 0.0,
            ),
          ),
          const SizedBox(height: 8),
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No thresholds set. Click "Add Threshold" above.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rules.length,
              separatorBuilder: (context, index) => Divider(
                height: 6,
                color: theme.dividerTheme.color,
              ),
              itemBuilder: (context, index) {
                final rule = rules[index];
                final badgeColor = rule.isEnabled
                    ? (rule.percentage <= 10
                        ? (isMacGlass ? AppColors.macCritical : AppColors.batteryCritical)
                        : (isMacGlass ? AppColors.macWarning : AppColors.batteryWarning))
                    : theme.colorScheme.outline;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 26,
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: rule.isEnabled ? 0.14 : 0.06),
                          borderRadius: BorderRadius.circular(isMacGlass ? 8 : 2),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: rule.isEnabled ? 0.35 : 0.15),
                            width: isMacGlass ? 0.8 : 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${rule.percentage}%',
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                                letterSpacing: isMacGlass ? -0.2 : 0.0,
                                color: rule.isEnabled ? null : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Alarm: ${rule.soundType.toUpperCase()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isMacGlass ? CupertinoIcons.pencil : Icons.edit_outlined,
                          size: 15,
                        ),
                        tooltip: 'Edit threshold',
                        visualDensity: VisualDensity.compact,
                        splashRadius: 14,
                        onPressed: () => _showEditDialog(context, rule),
                      ),
                      if (isMacGlass)
                        Transform.scale(
                          scale: 0.72,
                          child: CupertinoSwitch(
                            value: rule.isEnabled,
                            activeTrackColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              onUpdate(rule.copyWith(isEnabled: val));
                            },
                          ),
                        )
                      else
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: rule.isEnabled,
                            onChanged: (val) {
                              onUpdate(rule.copyWith(isEnabled: val));
                            },
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          isMacGlass ? CupertinoIcons.trash : Icons.delete_outline,
                          size: 15,
                        ),
                        tooltip: 'Delete threshold',
                        visualDensity: VisualDensity.compact,
                        splashRadius: 14,
                        onPressed: () => onDelete(rule.id),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
