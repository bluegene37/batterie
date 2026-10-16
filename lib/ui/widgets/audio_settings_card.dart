import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/alarm_service.dart';
// Gene - Oct, 07, 2026: Added settings_service.dart import for copying custom audio into sandbox container
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import 'paper_surface.dart';

// Gene - Oct, 07, 2026: Converted AudioSettingsCard to StatefulWidget to maintain dropdown state sync when canceling file picker and copy custom audio to App Sandbox
// class AudioSettingsCard extends StatelessWidget {
//   final String selectedSound;
//   final String? customSoundPath;
//   final double volume;
//   final int snoozeMinutes;
//   final int repeatCount;
//   final bool isTesting;
//   final Function(String sound) onSoundChanged;
//   final Function(String? path) onCustomPathChanged;
//   final Function(double volume) onVolumeChanged;
//   final Function(int minutes) onSnoozeChanged;
//   final Function(int count) onRepeatCountChanged;
//   final VoidCallback onTestAlarm;
//
//   static const List<int> supportedRepeatCounts = [1, 2, 3, 5, 10, 0];
//
//   const AudioSettingsCard({
//     super.key,
//     required this.selectedSound,
//     this.customSoundPath,
//     required this.volume,
//     required this.snoozeMinutes,
//     required this.repeatCount,
//     required this.isTesting,
//     required this.onSoundChanged,
//     required this.onCustomPathChanged,
//     required this.onVolumeChanged,
//     required this.onSnoozeChanged,
//     required this.onRepeatCountChanged,
//     required this.onTestAlarm,
//   });
//
//   Future<void> _pickCustomAudio(BuildContext context) async {
//     try {
//       final file = await FilePicker.pickFile(
//         type: FileType.custom,
//         allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
//       );
//       if (file != null && file.path != null) {
//         onCustomPathChanged(file.path);
//         onSoundChanged('custom');
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not open file picker: $e')),
//         );
//       }
//     }
//   }
class AudioSettingsCard extends StatefulWidget {
  final String selectedSound;
  final String? customSoundPath;
  final double volume;
  final int snoozeMinutes;
  final int repeatCount;
  final bool isTesting;
  final Function(String sound) onSoundChanged;
  final Function(String? path) onCustomPathChanged;
  final Function(double volume) onVolumeChanged;
  final Function(int minutes) onSnoozeChanged;
  final Function(int count) onRepeatCountChanged;
  final VoidCallback onTestAlarm;

  static const List<int> supportedRepeatCounts = [1, 2, 3, 5, 10, 0];

  const AudioSettingsCard({
    super.key,
    required this.selectedSound,
    this.customSoundPath,
    required this.volume,
    required this.snoozeMinutes,
    required this.repeatCount,
    required this.isTesting,
    required this.onSoundChanged,
    required this.onCustomPathChanged,
    required this.onVolumeChanged,
    required this.onSnoozeChanged,
    required this.onRepeatCountChanged,
    required this.onTestAlarm,
  });

  @override
  State<AudioSettingsCard> createState() => _AudioSettingsCardState();
}

class _AudioSettingsCardState extends State<AudioSettingsCard> {
  int _pickerResetCount = 0;

  // Gene - Oct 16, 2026: Try reading bytes directly from PlatformFile to preserve security-scoped sandbox access, falling back to copyCustomSoundFile. Preserved previous _pickCustomAudio below.
  // Future<void> _pickCustomAudio(BuildContext context) async {
  //   try {
  //     final file = await FilePicker.pickFile(
  //       type: FileType.custom,
  //       allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'aif', 'aiff'],
  //     );
  //     if (file != null && file.path != null) {
  //       final safePath = await SettingsService.copyCustomSoundFile(file.path!);
  //       widget.onCustomPathChanged(safePath);
  //       widget.onSoundChanged('custom');
  //     } else {
  //       setState(() {
  //         _pickerResetCount++;
  //       });
  //     }
  //   } catch (e) {
  //     if (context.mounted) {
  //       setState(() {
  //         _pickerResetCount++;
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Could not open file picker: $e')),
  //       );
  //     }
  //   }
  // }
  Future<void> _pickCustomAudio(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'aif', 'aiff'],
      );
      if (file != null) {
        String safePath;
        try {
          final bytes = await file.readAsBytes();
          safePath = await SettingsService.copyCustomSoundBytes(file.name, bytes);
        } catch (_) {
          if (file.path != null) {
            safePath = await SettingsService.copyCustomSoundFile(file.path!);
          } else {
            safePath = file.name;
          }
        }
        widget.onCustomPathChanged(safePath);
        widget.onSoundChanged('custom');
      } else {
        setState(() {
          _pickerResetCount++;
        });
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _pickerResetCount++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file picker: $e')),
        );
      }
    }
  }

  // Gene - Oct, 07, 2026: Updated build method to access widget fields, add key to DropdownButtonFormField for state sync, and handle custom sound file row
  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //
  //   return PaperSurface(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   Icons.volume_up_outlined,
  //                   color: theme.colorScheme.primary,
  //                   size: 17,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(
  //                   'Alarm Sound & Volume',
  //                   style: theme.textTheme.titleSmall?.copyWith(
  //                     fontWeight: FontWeight.w700,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             FilledButton.icon(
  //               onPressed: isTesting ? null : onTestAlarm,
  //               icon: Icon(
  //                 isTesting ? Icons.hourglass_top : Icons.play_arrow_rounded,
  //                 size: 14,
  //               ),
  //               label: Text(isTesting ? 'Playing (3s)...' : 'Test Alarm'),
  //               style: FilledButton.styleFrom(
  //                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //                 visualDensity: VisualDensity.compact,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 10),
  //         // Sound Preset Selector
  //         DropdownButtonFormField<String>(
  //           initialValue: selectedSound,
  //           isDense: true,
  //           style: theme.textTheme.bodyMedium,
  //           decoration: const InputDecoration(
  //             labelText: 'Default sound (new thresholds & Test Alarm)',
  //             contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //           ),
  //           items: [
  //             for (final entry in AlarmService.presetLabels.entries)
  //               DropdownMenuItem(value: entry.key, child: Text(entry.value)),
  //             const DropdownMenuItem(value: 'custom', child: Text('Custom Audio File…')),
  //           ],
  //           onChanged: (val) {
  //             if (val == 'custom') {
  //               _pickCustomAudio(context);
  //             } else if (val != null) {
  //               onSoundChanged(val);
  //             }
  //           },
  //         ),
  //         if (selectedSound == 'custom' && customSoundPath != null) ...[
  //           const SizedBox(height: 6),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //             decoration: BoxDecoration(
  //               color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
  //               borderRadius: BorderRadius.circular(AppTheme.controlRadius),
  //               border: Border.all(color: theme.colorScheme.outline, width: 1.0),
  //             ),
  //             child: Row(
  //               children: [
  //                 const Icon(Icons.audio_file, size: 15),
  //                 const SizedBox(width: 6),
  //                 Expanded(
  //                   child: Text(
  //                     customSoundPath!.split('/').last,
  //                     style: theme.textTheme.bodySmall,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ),
  //                 TextButton(
  //                   style: TextButton.styleFrom(
  //                     visualDensity: VisualDensity.compact,
  //                     padding: const EdgeInsets.symmetric(horizontal: 6),
  //                   ),
  //                   onPressed: () => _pickCustomAudio(context),
  //                   child: const Text('Change File'),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //         const SizedBox(height: 10),
  //         // Volume Slider
  //         Row(
  //           children: [
  //             Icon(
  //               Icons.volume_down_rounded,
  //               size: 16,
  //               color: theme.colorScheme.onSurfaceVariant,
  //             ),
  //             Expanded(
  //               child: Slider(
  //                 value: volume,
  //                 min: 0.0,
  //                 max: 1.0,
  //                 divisions: 20,
  //                 label: '${(volume * 100).round()}%',
  //                 onChanged: onVolumeChanged,
  //               ),
  //             ),
  //             Icon(
  //               Icons.volume_up_rounded,
  //               size: 16,
  //               color: theme.colorScheme.onSurfaceVariant,
  //             ),
  //             const SizedBox(width: 8),
  //             Container(
  //               width: 38,
  //               alignment: Alignment.centerRight,
  //               child: Text(
  //                 '${(volume * 100).round()}%',
  //                 style: theme.textTheme.labelMedium?.copyWith(
  //                   fontWeight: FontWeight.w700,
  //                   color: theme.colorScheme.primary,
  //                   fontFeatures: const [FontFeature.tabularFigures()],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 4),
  //         // Snooze Duration
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   Icons.snooze_rounded,
  //                   size: 15,
  //                   color: theme.colorScheme.onSurfaceVariant,
  //                 ),
  //                 const SizedBox(width: 6),
  //                 Text(
  //                   'Snooze Duration:',
  //                   style: theme.textTheme.bodySmall?.copyWith(
  //                     color: theme.colorScheme.onSurfaceVariant,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             DropdownButtonHideUnderline(
  //               child: DropdownButton<int>(
  //                 value: snoozeMinutes,
  //                 isDense: true,
  //                 style: theme.textTheme.bodySmall?.copyWith(
  //                   fontWeight: FontWeight.w600,
  //                   color: theme.colorScheme.primary,
  //                 ),
  //                 items: const [
  //                   DropdownMenuItem(value: 2, child: Text('2 minutes')),
  //                   DropdownMenuItem(value: 5, child: Text('5 minutes')),
  //                   DropdownMenuItem(value: 10, child: Text('10 minutes')),
  //                   DropdownMenuItem(value: 15, child: Text('15 minutes')),
  //                 ],
  //                 onChanged: (val) {
  //                   if (val != null) onSnoozeChanged(val);
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 6),
  //         // Repeat Count
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   Icons.repeat_rounded,
  //                   size: 15,
  //                   color: theme.colorScheme.onSurfaceVariant,
  //                 ),
  //                 const SizedBox(width: 6),
  //                 Text(
  //                   'Repeat Alarm:',
  //                   style: theme.textTheme.bodySmall?.copyWith(
  //                     color: theme.colorScheme.onSurfaceVariant,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             DropdownButtonHideUnderline(
  //               child: DropdownButton<int>(
  //                 value: supportedRepeatCounts.contains(repeatCount) ? repeatCount : 3,
  //                 isDense: true,
  //                 style: theme.textTheme.bodySmall?.copyWith(
  //                   fontWeight: FontWeight.w600,
  //                   color: theme.colorScheme.primary,
  //                 ),
  //                 items: const [
  //                   DropdownMenuItem(value: 1, child: Text('1 time')),
  //                   DropdownMenuItem(value: 2, child: Text('2 times')),
  //                   DropdownMenuItem(value: 3, child: Text('3 times')),
  //                   DropdownMenuItem(value: 5, child: Text('5 times')),
  //                   DropdownMenuItem(value: 10, child: Text('10 times')),
  //                   DropdownMenuItem(value: 0, child: Text('Continuous')),
  //                 ],
  //                 onChanged: (val) {
  //                   if (val != null) onRepeatCountChanged(val);
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // Gene - Oct 16, 2026: Enhanced AudioSettingsCard with Neumorphic sunken custom audio well, volume pill, and recessed dropdown containers. Preserved previous build implementation below.
  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //
  //   return PaperSurface(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   Icons.volume_up_outlined,
  //                   color: theme.colorScheme.primary,
  //                   size: 17,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(
  //                   'Alarm Sound & Volume',
  //                   style: theme.textTheme.titleSmall?.copyWith(
  //                     fontWeight: FontWeight.w700,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             FilledButton.icon(
  //               onPressed: widget.isTesting ? null : widget.onTestAlarm,
  //               icon: Icon(
  //                 widget.isTesting ? Icons.hourglass_top : Icons.play_arrow_rounded,
  //                 size: 14,
  //               ),
  //               label: Text(widget.isTesting ? 'Playing (3s)...' : 'Test Alarm'),
  //               style: FilledButton.styleFrom(
  //                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //                 visualDensity: VisualDensity.compact,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 10),
  //         // Sound Preset Selector
  //         DropdownButtonFormField<String>(
  //           key: ValueKey('audio_settings_${widget.selectedSound}_${widget.customSoundPath ?? ""}_$_pickerResetCount'),
  //           initialValue: widget.selectedSound,
  //           isDense: true,
  //           style: theme.textTheme.bodyMedium,
  //           decoration: const InputDecoration(
  //             labelText: 'Default sound (new thresholds & Test Alarm)',
  //             contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //           ),
  //           items: [
  //             for (final entry in AlarmService.presetLabels.entries)
  //               DropdownMenuItem(value: entry.key, child: Text(entry.value)),
  //             const DropdownMenuItem(value: 'custom', child: Text('Custom Audio File…')),
  //           ],
  //           onChanged: (val) {
  //             if (val == 'custom') {
  //               _pickCustomAudio(context);
  //             } else if (val != null) {
  //               widget.onSoundChanged(val);
  //             }
  //           },
  //         ),
  //         if (widget.selectedSound == 'custom') ...[
  //           const SizedBox(height: 6),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //             decoration: BoxDecoration(
  //               color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
  //               borderRadius: BorderRadius.circular(AppTheme.controlRadius),
  //               border: Border.all(color: theme.colorScheme.outline, width: 1.0),
  //             ),
  //             child: Row(
  //               children: [
  //                 const Icon(Icons.audio_file, size: 15),
  //                 const SizedBox(width: 6),
  //                 Expanded(
  //                   child: Text(
  //                     (widget.customSoundPath != null && widget.customSoundPath!.isNotEmpty)
  //                         ? widget.customSoundPath!.split(RegExp(r'[\\/]')).last
  //                         : 'No file selected (will use siren)',
  //                     style: theme.textTheme.bodySmall,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ),
  //                 TextButton(
  //                   style: TextButton.styleFrom(
  //                     visualDensity: VisualDensity.compact,
  //                     padding: const EdgeInsets.symmetric(horizontal: 6),
  //                   ),
  //                   onPressed: () => _pickCustomAudio(context),
  //                   child: Text(widget.customSoundPath != null ? 'Change File' : 'Select File'),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //         const SizedBox(height: 10),
  //         // Volume Slider
  //         Row(
  //           children: [
  //             Icon(
  //               Icons.volume_down_rounded,
  //               size: 16,
  //               color: theme.colorScheme.onSurfaceVariant,
  //             ),
  //             Expanded(
  //               child: Slider(
  //                 value: widget.volume,
  //                 min: 0.0,
  //                 max: 1.0,
  //                 divisions: 20,
  //                 label: '${(widget.volume * 100).round()}%',
  //                 onChanged: widget.onVolumeChanged,
  //               ),
  //             ),
  //             Icon(
  //               Icons.volume_up_rounded,
  //               size: 16,
  //               color: theme.colorScheme.onSurfaceVariant,
  //             ),
  //             const SizedBox(width: 8),
  //             Container(
  //               width: 38,
  //               alignment: Alignment.centerRight,
  //               child: Text(
  //                 '${(widget.volume * 100).round()}%',
  //                 style: theme.textTheme.labelMedium?.copyWith(
  //                   fontWeight: FontWeight.w700,
  //                   color: theme.colorScheme.primary,
  //                   fontFeatures: const [FontFeature.tabularFigures()],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 4),
  //         // Snooze Duration
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   Icons.snooze_rounded,
  //                   size: 15,
  //                   color: theme.colorScheme.onSurfaceVariant,
  //                 ),
  //                 const SizedBox(width: 6),
  //                 Text(
  //                   'Snooze Duration:',
  //                   style: theme.textTheme.bodySmall?.copyWith(
  //                     color: theme.colorScheme.onSurfaceVariant,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             DropdownButtonHideUnderline(
  //               child: DropdownButton<int>(
  //                 value: widget.snoozeMinutes,
  //                 isDense: true,
  //                 style: theme.textTheme.bodySmall?.copyWith(
  //                   fontWeight: FontWeight.w600,
  //                   color: theme.colorScheme.primary,
  //                 ),
  //                 items: const [
  //                   DropdownMenuItem(value: 2, child: Text('2 minutes')),
  //                   DropdownMenuItem(value: 5, child: Text('5 minutes')),
  //                   DropdownMenuItem(value: 10, child: Text('10 minutes')),
  //                   DropdownMenuItem(value: 15, child: Text('15 minutes')),
  //                 ],
  //                 onChanged: (val) {
  //                   if (val != null) widget.onSnoozeChanged(val);
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 6),
  //         // Repeat Count
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   Icons.repeat_rounded,
  //                   size: 15,
  //                   color: theme.colorScheme.onSurfaceVariant,
  //                 ),
  //                 const SizedBox(width: 6),
  //                 Text(
  //                   'Repeat Alarm:',
  //                   style: theme.textTheme.bodySmall?.copyWith(
  //                     color: theme.colorScheme.onSurfaceVariant,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             DropdownButtonHideUnderline(
  //               child: DropdownButton<int>(
  //                 value: AudioSettingsCard.supportedRepeatCounts.contains(widget.repeatCount)
  //                     ? widget.repeatCount
  //                     : 3,
  //                 isDense: true,
  //                 style: theme.textTheme.bodySmall?.copyWith(
  //                   fontWeight: FontWeight.w600,
  //                   color: theme.colorScheme.primary,
  //                 ),
  //                 items: const [
  //                   DropdownMenuItem(value: 1, child: Text('1 time')),
  //                   DropdownMenuItem(value: 2, child: Text('2 times')),
  //                   DropdownMenuItem(value: 3, child: Text('3 times')),
  //                   DropdownMenuItem(value: 5, child: Text('5 times')),
  //                   DropdownMenuItem(value: 10, child: Text('10 times')),
  //                   DropdownMenuItem(value: 0, child: Text('Continuous')),
  //                 ],
  //                 onChanged: (val) {
  //                   if (val != null) widget.onRepeatCountChanged(val);
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PaperSurface(
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
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Alarm Sound & Volume',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: widget.isTesting ? null : widget.onTestAlarm,
                icon: Icon(
                  widget.isTesting ? Icons.hourglass_top : Icons.play_arrow_rounded,
                  size: 14,
                ),
                label: Text(widget.isTesting ? 'Playing (3s)...' : 'Test Alarm'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Sound Preset Selector
          DropdownButtonFormField<String>(
            key: ValueKey('audio_settings_${widget.selectedSound}_${widget.customSoundPath ?? ""}_$_pickerResetCount'),
            initialValue: widget.selectedSound,
            isDense: true,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'Default sound (new thresholds & Test Alarm)',
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            items: [
              for (final entry in AlarmService.presetLabels.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              const DropdownMenuItem(value: 'custom', child: Text('Custom Audio File…')),
            ],
            onChanged: (val) {
              if (val == 'custom') {
                _pickCustomAudio(context);
              } else if (val != null) {
                widget.onSoundChanged(val);
              }
            },
          ),
          if (widget.selectedSound == 'custom') ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                border: Border.all(
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFA3B1C6).withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.audio_file, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (widget.customSoundPath != null && widget.customSoundPath!.isNotEmpty)
                          ? widget.customSoundPath!.split(RegExp(r'[\\/]')).last
                          : 'No file selected (will use siren)',
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
                    child: Text(widget.customSoundPath != null ? 'Change File' : 'Select File'),
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
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: Slider(
                  value: widget.volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: '${(widget.volume * 100).round()}%',
                  onChanged: widget.onVolumeChanged,
                ),
              ),
              Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 42),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  boxShadow: NeumorphicTheme.softShadows(context, distance: 1.5, blur: 3),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${(widget.volume * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Snooze Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.snooze_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Snooze Duration:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  border: Border.all(
                    color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFA3B1C6).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: widget.snoozeMinutes,
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
                      if (val != null) widget.onSnoozeChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Repeat Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Repeat Alarm:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  border: Border.all(
                    color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFA3B1C6).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: AudioSettingsCard.supportedRepeatCounts.contains(widget.repeatCount)
                        ? widget.repeatCount
                        : 3,
                    isDense: true,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 time')),
                      DropdownMenuItem(value: 2, child: Text('2 times')),
                      DropdownMenuItem(value: 3, child: Text('3 times')),
                      DropdownMenuItem(value: 5, child: Text('5 times')),
                      DropdownMenuItem(value: 10, child: Text('10 times')),
                      DropdownMenuItem(value: 0, child: Text('Continuous')),
                    ],
                    onChanged: (val) {
                      if (val != null) widget.onRepeatCountChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
