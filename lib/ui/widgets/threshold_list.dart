import 'package:flutter/material.dart';
import '../../models/threshold_rule.dart';

class ThresholdList extends StatelessWidget {
  final List<ThresholdRule> rules;
  final Function(int percentage, String label) onAdd;
  final Function(ThresholdRule rule) onUpdate;
  final Function(String id) onDelete;

  const ThresholdList({
    super.key,
    required this.rules,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  void _showAddDialog(BuildContext context) {
    int percentage = 15;
    final labelController = TextEditingController(text: 'Low Alert');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Battery Alarm Threshold'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      hintText: 'e.g. Warning, Critical',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trigger Percentage:'),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
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

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Threshold'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trigger Percentage:'),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
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

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alarm Thresholds',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Threshold'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'App rings loudly when battery drops to or below these percentages while discharging.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (rules.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text('No thresholds set. Click "Add Threshold" above.'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rules.length,
                separatorBuilder: (context, index) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: rule.isEnabled
                          ? (rule.percentage <= 10
                              ? Colors.red.shade100
                              : Colors.orange.shade100)
                          : Colors.grey.shade200,
                      child: Text(
                        '${rule.percentage}%',
                        style: TextStyle(
                          color: rule.isEnabled
                              ? (rule.percentage <= 10
                                  ? Colors.red.shade900
                                  : Colors.orange.shade900)
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      rule.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: rule.isEnabled ? null : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      'Alarm: ${rule.soundType.toUpperCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit threshold',
                          onPressed: () => _showEditDialog(context, rule),
                        ),
                        Switch(
                          value: rule.isEnabled,
                          onChanged: (val) {
                            onUpdate(rule.copyWith(isEnabled: val));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Delete threshold',
                          onPressed: () => onDelete(rule.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
