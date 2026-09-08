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
                      Icons.volume_up_outlined,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alarm Sound & Volume',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: isTesting ? null : onTestAlarm,
                  icon: Icon(
                    isTesting ? Icons.hourglass_top : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(isTesting ? 'Playing (3s)...' : 'Test Alarm'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sound Preset Selector
            DropdownButtonFormField<String>(
              initialValue: selectedSound,
              decoration: const InputDecoration(
                labelText: 'Alarm Sound Preset',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.audio_file, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customSoundPath!.split('/').last,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickCustomAudio(context),
                    child: const Text('Change File'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Volume Slider
            Row(
              children: [
                const Icon(Icons.volume_down, size: 20),
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
                const Icon(Icons.volume_up, size: 20),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(volume * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Snooze Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.snooze, size: 20),
                    const SizedBox(width: 8),
                    const Text('Snooze Duration:'),
                  ],
                ),
                DropdownButton<int>(
                  value: snoozeMinutes,
                  underline: const SizedBox(),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
