import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AudioSettingsCard extends StatelessWidget {
  final String selectedSound;
  final String? customSoundPath;
  final double volume;
  final int snoozeMinutes;
  final bool isTesting;
  final Function(String sound) onSoundChanged;
  final Function(String? path) onCustomPathChanged;
  final Function(double volume) onVolumeChanged;
  final Function(int minutes) onSnoozeChanged;
  final VoidCallback onTestAlarm;

  const AudioSettingsCard({
    super.key,
    required this.selectedSound,
    this.customSoundPath,
    required this.volume,
    required this.snoozeMinutes,
    required this.isTesting,
    required this.onSoundChanged,
    required this.onCustomPathChanged,
    required this.onVolumeChanged,
    required this.onSnoozeChanged,
    required this.onTestAlarm,
  });

  Future<void> _pickCustomAudio(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );
      if (file != null && file.path != null) {
        onCustomPathChanged(file.path);
        onSoundChanged('custom');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file picker: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.volume_up_outlined,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alarm Sound & Volume',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: isTesting ? null : onTestAlarm,
                  icon: Icon(
                    isTesting ? Icons.hourglass_top : Icons.play_arrow_rounded,
                    size: 15,
                  ),
                  label: Text(
                    isTesting ? 'Playing (3s)...' : 'Test Alarm',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Sound Preset Selector
            DropdownButtonFormField<String>(
              initialValue: selectedSound,
              isDense: true,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Alarm Sound Preset',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'siren', child: Text('Urgent Siren (Oscillating)')),
                DropdownMenuItem(value: 'digital', child: Text('Digital Alarm (Rapid Beeps)')),
                DropdownMenuItem(value: 'bell', child: Text('Alert Bell (Sharp Strike)')),
                DropdownMenuItem(value: 'custom', child: Text('Custom Audio File...')),
              ],
              onChanged: (val) {
                if (val == 'custom') {
                  _pickCustomAudio(context);
                } else if (val != null) {
                  onSoundChanged(val);
                }
              },
            ),
            if (selectedSound == 'custom' && customSoundPath != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audio_file, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        customSoundPath!.split('/').last,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      onPressed: () => _pickCustomAudio(context),
                      child: const Text('Change File', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Volume Slider
            Row(
              children: [
                Icon(
                  Icons.volume_down_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: '${(volume * 100).round()}%',
                    onChanged: onVolumeChanged,
                  ),
                ),
                Icon(
                  Icons.volume_up_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(volume * 100).round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Snooze Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.snooze_rounded,
                      size: 17,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Snooze Duration:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: snoozeMinutes,
                    isDense: true,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('2 minutes')),
                      DropdownMenuItem(value: 5, child: Text('5 minutes')),
                      DropdownMenuItem(value: 10, child: Text('10 minutes')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes')),
                    ],
                    onChanged: (val) {
                      if (val != null) onSnoozeChanged(val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
