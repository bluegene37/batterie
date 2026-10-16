import 'dart:convert';
// Gene - Oct, 07, 2026: Added dart:io, flutter/foundation, and path_provider for persisting custom sound files inside sandbox
// import 'package:flutter/material.dart' show ThemeMode;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/threshold_rule.dart';
// Gene - Oct 16, 2026: Commented out unnecessary dart:typed_data import as Uint8List is exported by package:flutter/foundation.dart
// import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/threshold_rule.dart';

class SettingsService {
  static const String _keyThresholds = 'threshold_rules';
  static const String _keyVolume = 'alarm_volume';
  static const String _keyDefaultSound = 'alarm_default_sound';
  static const String _keySnoozeMinutes = 'alarm_snooze_minutes';
  static const String _keyRepeatCount = 'alarm_repeat_count';
  static const String _keyCustomSoundPath = 'alarm_custom_sound_path';
  static const String _keyThemeMode = 'app_theme_mode';

  static const List<ThresholdRule> defaultThresholds = [
    ThresholdRule(
      id: 'default-warning',
      percentage: 20,
      label: 'Warning',
      isEnabled: true,
      soundType: 'siren',
    ),
    ThresholdRule(
      id: 'default-critical',
      percentage: 10,
      label: 'Critical Alert',
      isEnabled: true,
      soundType: 'siren',
    ),
  ];

  Future<List<ThresholdRule>> loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyThresholds);
    if (jsonList == null || jsonList.isEmpty) {
      return List.from(defaultThresholds);
    }

    try {
      return jsonList.map((item) {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return ThresholdRule.fromJson(decoded);
      }).toList();
    } catch (_) {
      return List.from(defaultThresholds);
    }
  }

  Future<void> saveThresholds(List<ThresholdRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = rules.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_keyThresholds, jsonList);
  }

  Future<double> loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyVolume) ?? 1.0;
  }

  Future<void> saveVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, volume.clamp(0.0, 1.0));
  }

  Future<String> loadDefaultSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultSound) ?? 'siren';
  }

  Future<void> saveDefaultSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultSound, sound);
  }

  Future<String?> loadCustomSoundPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_keyCustomSoundPath);
    return (path == null || path.isEmpty) ? null : path;
  }

  Future<void> saveCustomSoundPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_keyCustomSoundPath);
    } else {
      await prefs.setString(_keyCustomSoundPath, path);
    }
  }

  // Gene - Oct 16, 2026: Enhanced copyCustomSoundFile to check if already inside custom_sounds, fallback to existing container copies, and added copyCustomSoundBytes. Preserved previous copyCustomSoundFile below.
  // // Gene - Oct, 07, 2026: Copies user-selected audio file into application support directory inside the App Sandbox container so it can be reliably played by AVPlayer across sessions
  // static Future<String> copyCustomSoundFile(String sourcePath) async {
  //   try {
  //     final sourceFile = File(sourcePath);
  //     if (!sourceFile.existsSync()) return sourcePath;
  //     final dir = await getApplicationSupportDirectory();
  //     final soundDir = Directory('${dir.path}/custom_sounds');
  //     if (!soundDir.existsSync()) {
  //       await soundDir.create(recursive: true);
  //     }
  //     final fileName = sourcePath.split(RegExp(r'[\\/]')).last;
  //     final destFile = File('${soundDir.path}/$fileName');
  //     if (sourceFile.path == destFile.path) {
  //       return destFile.path;
  //     }
  //     final bytes = await sourceFile.readAsBytes();
  //     await destFile.writeAsBytes(bytes);
  //     return destFile.path;
  //   } catch (e) {
  //     debugPrint('Could not copy custom sound file to app storage: $e');
  //     return sourcePath;
  //   }
  // }
  static Future<String> copyCustomSoundBytes(String fileName, Uint8List bytes) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final soundDir = Directory('${dir.path}/custom_sounds');
      if (!soundDir.existsSync()) {
        await soundDir.create(recursive: true);
      }
      final cleanName = fileName.split(RegExp(r'[\\/]')).last;
      final destFile = File('${soundDir.path}/$cleanName');
      await destFile.writeAsBytes(bytes);
      return destFile.path;
    } catch (e) {
      debugPrint('Could not save custom sound bytes to app storage: $e');
      return fileName;
    }
  }

  // Gene - Oct 16, 2026: Check if container copy already exists before reading external file to avoid sandbox permission errors. Preserved previous logic below.
  // static Future<String> copyCustomSoundFile(String sourcePath) async {
  //   try {
  //     final dir = await getApplicationSupportDirectory();
  //     final soundDir = Directory('${dir.path}/custom_sounds');
  //     final fileName = sourcePath.split(RegExp(r'[\\/]')).last;
  //     final destFile = File('${soundDir.path}/$fileName');
  //
  //     // If already stored inside container, return directly
  //     if (sourcePath == destFile.path || sourcePath.contains('/custom_sounds/')) {
  //       return destFile.path;
  //     }
  //
  //     final sourceFile = File(sourcePath);
  //     if (!sourceFile.existsSync()) {
  //       // If external file path is no longer accessible but already copied in container, use container copy
  //       if (destFile.existsSync()) {
  //         return destFile.path;
  //       }
  //       return sourcePath;
  //     }
  static Future<String> copyCustomSoundFile(String sourcePath) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final soundDir = Directory('${dir.path}/custom_sounds');
      final fileName = sourcePath.split(RegExp(r'[\\/]')).last;
      final destFile = File('${soundDir.path}/$fileName');

      // If already stored inside container or copy already exists, return directly without touching external storage
      if (sourcePath == destFile.path || sourcePath.contains('/custom_sounds/') || destFile.existsSync()) {
        return destFile.path;
      }

      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        return sourcePath;
      }

      if (!soundDir.existsSync()) {
        await soundDir.create(recursive: true);
      }

      final bytes = await sourceFile.readAsBytes();
      await destFile.writeAsBytes(bytes);
      return destFile.path;
    } catch (e) {
      debugPrint('Could not copy custom sound file to app storage: $e');
      // If reading external file failed due to sandbox permissions, check if a container copy exists
      try {
        final dir = await getApplicationSupportDirectory();
        final fileName = sourcePath.split(RegExp(r'[\\/]')).last;
        final destFile = File('${dir.path}/custom_sounds/$fileName');
        if (destFile.existsSync()) {
          return destFile.path;
        }
      } catch (_) {}
      return sourcePath;
    }
  }

  Future<int> loadSnoozeMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySnoozeMinutes) ?? 5;
  }

  Future<void> saveSnoozeMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySnoozeMinutes, minutes);
  }

  Future<int> loadRepeatCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRepeatCount) ?? 3;
  }

  Future<void> saveRepeatCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRepeatCount, count);
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_keyThemeMode);
    switch (modeStr) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }
}
