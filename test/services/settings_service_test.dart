import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batterie/models/threshold_rule.dart';
import 'package:batterie/services/settings_service.dart';

void main() {
  group('SettingsService unit tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Provides sensible defaults when storage is empty', () async {
      final service = SettingsService();
      final thresholds = await service.loadThresholds();
      expect(thresholds.length, equals(2));
      expect(thresholds[0].percentage, equals(20));
      expect(thresholds[1].percentage, equals(10));

      final volume = await service.loadVolume();
      expect(volume, equals(1.0));

      final sound = await service.loadDefaultSound();
      expect(sound, equals('siren'));

      final snoozeMinutes = await service.loadSnoozeMinutes();
      expect(snoozeMinutes, equals(5));

      final themeMode = await service.loadThemeMode();
      expect(themeMode, equals(ThemeMode.light));
    });

    test('Saves and restores customized threshold rules', () async {
      final service = SettingsService();
      final customRules = [
        const ThresholdRule(
          id: 'custom-1',
          percentage: 25,
          label: 'Custom Alert',
          isEnabled: true,
          soundType: 'bell',
        ),
      ];

      await service.saveThresholds(customRules);
      final loaded = await service.loadThresholds();

      expect(loaded.length, equals(1));
      expect(loaded[0].id, equals('custom-1'));
      expect(loaded[0].percentage, equals(25));
      expect(loaded[0].label, equals('Custom Alert'));
      expect(loaded[0].soundType, equals('bell'));
    });

    test('Saves and restores volume and sound preferences', () async {
      final service = SettingsService();

      await service.saveVolume(0.85);
      expect(await service.loadVolume(), equals(0.85));

      await service.saveDefaultSound('digital');
      expect(await service.loadDefaultSound(), equals('digital'));

      await service.saveSnoozeMinutes(10);
      expect(await service.loadSnoozeMinutes(), equals(10));
    });

    test('Saves and restores the custom default sound path', () async {
      final service = SettingsService();
      expect(await service.loadCustomSoundPath(), isNull);

      await service.saveCustomSoundPath('/Users/me/alarm.mp3');
      expect(await service.loadCustomSoundPath(), equals('/Users/me/alarm.mp3'));

      await service.saveCustomSoundPath(null);
      expect(await service.loadCustomSoundPath(), isNull);
    });

    test('Saves and restores theme mode preferences', () async {
      final service = SettingsService();
      expect(await service.loadThemeMode(), equals(ThemeMode.light));

      await service.saveThemeMode(ThemeMode.dark);
      expect(await service.loadThemeMode(), equals(ThemeMode.dark));

      await service.saveThemeMode(ThemeMode.light);
      expect(await service.loadThemeMode(), equals(ThemeMode.light));

      await service.saveThemeMode(ThemeMode.system);
      expect(await service.loadThemeMode(), equals(ThemeMode.system));
    });
  });
}
