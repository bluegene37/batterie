import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/threshold_rule.dart';

class SettingsService {
  static const String _keyThresholds = 'threshold_rules';
  static const String _keyVolume = 'alarm_volume';
  static const String _keyDefaultSound = 'alarm_default_sound';
  static const String _keySnoozeMinutes = 'alarm_snooze_minutes';

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

  Future<int> loadSnoozeMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySnoozeMinutes) ?? 5;
  }

  Future<void> saveSnoozeMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySnoozeMinutes, minutes);
  }
}
