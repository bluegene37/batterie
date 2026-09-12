import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/threshold_rule.dart';
import '../../services/alarm_service.dart';
import '../../theme/app_theme.dart';
import 'paper_surface.dart';

typedef ThresholdAddCallback = void Function(
  int percentage,
  String label,
  String soundType,
  String? customSoundPath,
);

typedef SoundPreviewCallback = void Function(String soundType, String? customPath);

class ThresholdList extends StatelessWidget {
  final List<ThresholdRule> rules;
  final String defaultSound;
  final String? defaultCustomSoundPath;
  final ThresholdAddCallback onAdd;
  final Function(ThresholdRule rule) onUpdate;
  final Function(String id) onDelete;
  final SoundPreviewCallback onPreview;

  const ThresholdList({
    super.key,
    required this.rules,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onPreview,
    this.defaultSound = 'siren',
    this.defaultCustomSoundPath,
  });

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ThresholdEditorDialog(
        title: 'Add Battery Alarm Threshold',
        confirmLabel: 'Add Threshold',
        initialPercentage: 15,
        initialLabel: 'Low Alert',
        initialSound: defaultSound,
        initialCustomPath: defaultCustomSoundPath,
        onPreview: onPreview,
        onConfirm: (percentage, label, sound, customPath) {
          onAdd(percentage, label, sound, customPath);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, ThresholdRule rule) {
    showDialog(
      context: context,
      builder: (ctx) => _ThresholdEditorDialog(
        title: 'Edit Threshold',
        confirmLabel: 'Save',
        initialPercentage: rule.percentage,
        initialLabel: rule.label,
        initialSound: rule.soundType,
        initialCustomPath: rule.customSoundPath,
        onPreview: onPreview,
        onConfirm: (percentage, label, sound, customPath) {
          onUpdate(ThresholdRule(
            id: rule.id,
            percentage: percentage,
            label: label,
            isEnabled: rule.isEnabled,
            soundType: sound,
            customSoundPath: customPath,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = BatteryStatusColors.of(context);

    return PaperSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: theme.colorScheme.primary,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alarm Thresholds',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Threshold'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'App rings loudly when battery drops to or below these percentages while discharging. Each threshold has its own sound.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
                    ? (rule.percentage <= 10 ? status.critical : status.warning)
                    : theme.colorScheme.onSurfaceVariant;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    children: [
                      Container(
                        constraints: const BoxConstraints(minWidth: 38, minHeight: 26),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: rule.isEnabled ? 0.14 : 0.06),
                          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: rule.isEnabled ? 0.35 : 0.15),
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${rule.percentage}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.w700,
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
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: rule.isEnabled ? null : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Alarm: ${AlarmService.describeSound(rule.soundType, rule.customSoundPath)}',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        tooltip: 'Edit threshold',
                        visualDensity: VisualDensity.compact,
                        splashRadius: 14,
                        onPressed: () => _showEditDialog(context, rule),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: MergeSemantics(
                          child: Semantics(
                            label: 'Enable ${rule.label} threshold',
                            child: Switch(
                              value: rule.isEnabled,
                              onChanged: (val) {
                                onUpdate(rule.copyWith(isEnabled: val));
                              },
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 15),
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

/// Shared Add / Edit dialog: label, trigger percentage, and the alarm sound
/// (preset or custom file) with a preview button.
class _ThresholdEditorDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final int initialPercentage;
  final String initialLabel;
  final String initialSound;
  final String? initialCustomPath;
  final SoundPreviewCallback onPreview;
  final void Function(int percentage, String label, String soundType, String? customPath) onConfirm;

  const _ThresholdEditorDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialPercentage,
    required this.initialLabel,
    required this.initialSound,
    required this.initialCustomPath,
    required this.onPreview,
    required this.onConfirm,
  });

  @override
  State<_ThresholdEditorDialog> createState() => _ThresholdEditorDialogState();
}

class _ThresholdEditorDialogState extends State<_ThresholdEditorDialog> {
  late int _percentage;
  late String _sound;
  String? _customPath;
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _percentage = widget.initialPercentage;
    _sound = AlarmService.normalizeSoundType(widget.initialSound);
    _customPath = widget.initialCustomPath;
    _labelController = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _step(int delta) {
    setState(() => _percentage = (_percentage + delta).clamp(1, 99));
  }

  Future<void> _pickCustomAudio() async {
    final previousSound = _sound;
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );
      if (!mounted) return;
      if (file != null && file.path != null) {
        setState(() {
          _sound = 'custom';
          _customPath = file.path;
        });
      } else if (_customPath == null) {
        // Picker cancelled with nothing to fall back on: keep the old preset.
        setState(() => _sound = previousSound);
      } else {
        setState(() => _sound = 'custom');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sound = previousSound);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Could not open file picker: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customPathForSound = _sound == 'custom' ? _customPath : null;

    return AlertDialog(
      title: Text(
        widget.title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. Warning, Critical',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trigger Percentage:', style: theme.textTheme.bodyMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  ),
                  child: Text(
                    '$_percentage%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Stepper buttons give a single-tap alternative to dragging the
            // slider (WCAG 2.5.7) and fine control on a trackpad.
            Row(
              children: [
                IconButton(
                  tooltip: 'Decrease percentage',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: _percentage > 1 ? () => _step(-1) : null,
                ),
                Expanded(
                  child: Slider(
                    value: _percentage.toDouble(),
                    min: 1,
                    max: 99,
                    divisions: 98,
                    label: '$_percentage%',
                    onChanged: (val) => setState(() => _percentage = val.round()),
                  ),
                ),
                IconButton(
                  tooltip: 'Increase percentage',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: _percentage < 99 ? () => _step(1) : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _sound,
              isDense: true,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Alarm Sound',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: [
                for (final entry in AlarmService.presetLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                const DropdownMenuItem(value: 'custom', child: Text('Custom Audio File…')),
              ],
              onChanged: (val) {
                if (val == null) return;
                if (val == 'custom') {
                  _pickCustomAudio();
                } else {
                  setState(() => _sound = val);
                }
              },
            ),
            if (_sound == 'custom' && _customPath != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.audio_file, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AlarmService.describeSound('custom', _customPath),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    onPressed: _pickCustomAudio,
                    child: const Text('Change File'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        OutlinedButton.icon(
          onPressed: () => widget.onPreview(_sound, customPathForSound),
          icon: const Icon(Icons.play_arrow_rounded, size: 15),
          label: const Text('Preview'),
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: () {
                widget.onConfirm(
                  _percentage,
                  _labelController.text,
                  _sound,
                  customPathForSound,
                );
                Navigator.of(context).pop();
              },
              child: Text(widget.confirmLabel),
            ),
          ],
        ),
      ],
    );
  }
}
