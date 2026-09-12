import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Very light coffee palette in the spirit of genexis.dev paper & ink:
/// near-white cream paper, espresso ink, latte hairlines and a coffee-brown
/// accent. Dark mode is a dark roast with cream text.
///
/// Every value here is reached through `Theme.of(context)` roles in widgets;
/// the only direct `AppColors` reads are the semantic battery states.
abstract class AppColors {
  // --- Light: cream paper ---
  static const Color paper = Color(0xFFFBF8F3);
  static const Color paperRaised = Color(0xFFFFFDFA);
  static const Color paperDeep = Color(0xFFF1EBE1);
  static const Color paperRecess = Color(0xFFE8E0D3);

  // Espresso ink on paper
  static const Color ink = Color(0xFF2B211B);
  static const Color inkSoft = Color(0xFF5E5148);
  static const Color inkMuted = Color(0xFF7E7063);
  static const Color hairline = Color(0x264A3B30);

  // Coffee accent
  static const Color coffee = Color(0xFF6F4E37);
  static const Color coffeeDeep = Color(0xFF4E3626);

  // --- Dark: dark roast ---
  static const Color roast = Color(0xFF1C1714);
  static const Color roastRaised = Color(0xFF262019);
  static const Color roastDeep = Color(0xFF322A23);
  static const Color roastRecess = Color(0xFF3D342C);

  // Cream text on roast
  static const Color cream = Color(0xFFF5EFE6);
  static const Color creamSoft = Color(0xFFCFC3B5);
  static const Color creamMuted = Color(0xFF9A8D7F);
  static const Color hairlineDark = Color(0x26F5EFE6);

  // Latte accent for dark mode
  static const Color latte = Color(0xFFC8A27C);

  // --- Semantic battery states (deep enough to use as text on paper) ---
  static const Color charging = Color(0xFF2E7050);
  static const Color batteryWarning = Color(0xFF8C5E0E);
  static const Color batteryCritical = Color(0xFFB7412F);

  // Same states lifted for dark roast
  static const Color chargingDark = Color(0xFF7FBF9A);
  static const Color batteryWarningDark = Color(0xFFE0A94A);
  static const Color batteryCriticalDark = Color(0xFFE8705C);

  // Alarm ground for the takeover: both clear AA against cream text.
  static const Color alarm = Color(0xFFB7412F);
  static const Color alarmDeep = Color(0xFF8E2F22);
}

/// Motion tokens (Material 3 `Durations` / `Easing`) shared across the app.
abstract class AppMotion {
  /// One half-cycle of the alarm takeover pulse.
  static const Duration pulseDuration = Durations.extralong1;
  static const Curve pulseCurve = Easing.standard;

  /// Banner and surface transitions.
  static const Duration standardDuration = Durations.medium2;
  static const Curve standardCurve = Easing.standard;
}

/// Battery status colors resolved for the current brightness.
class BatteryStatusColors {
  final Color charging;
  final Color warning;
  final Color critical;

  const BatteryStatusColors._({
    required this.charging,
    required this.warning,
    required this.critical,
  });

  static BatteryStatusColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const BatteryStatusColors._(
            charging: AppColors.chargingDark,
            warning: AppColors.batteryWarningDark,
            critical: AppColors.batteryCriticalDark,
          )
        : const BatteryStatusColors._(
            charging: AppColors.charging,
            warning: AppColors.batteryWarning,
            critical: AppColors.batteryCritical,
          );
  }
}

class AppTheme {
  AppTheme._();

  static const double cardRadius = 4.0;
  static const double controlRadius = 3.0;

  static final bool isMacOS = !kIsWeb && Platform.isMacOS;

  /// Text slots the alarm takeover relies on. Sizes come from Material
  /// defaults; only the weights are tuned here so widgets never set them.
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w900,
      height: 1.0,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
    titleMedium: TextStyle(fontWeight: FontWeight.w600),
    labelLarge: TextStyle(fontWeight: FontWeight.w800),
  );

  static ThemeData get lightTheme => buildTheme(brightness: Brightness.light);
  static ThemeData get darkTheme => buildTheme(brightness: Brightness.dark);

  static ThemeData buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.roast : AppColors.paper;
    final surface = isDark ? AppColors.roastRaised : AppColors.paperRaised;
    final surfaceHigh = isDark ? AppColors.roastDeep : AppColors.paperDeep;
    final recess = isDark ? AppColors.roastRecess : AppColors.paperRecess;
    final border = isDark ? AppColors.hairlineDark : AppColors.hairline;
    final accent = isDark ? AppColors.latte : AppColors.coffee;
    final onAccent = isDark ? AppColors.roast : AppColors.cream;
    final textPrimary = isDark ? AppColors.cream : AppColors.ink;
    final textSecondary = isDark ? AppColors.creamSoft : AppColors.inkSoft;
    final charging = isDark ? AppColors.chargingDark : AppColors.charging;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: charging,
      onSecondary: onAccent,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceHigh,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border,
      error: AppColors.alarm,
      errorContainer: AppColors.alarmDeep,
      onError: AppColors.cream,
      onErrorContainer: AppColors.cream,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      fontFamily: 'Literata',
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: border, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: border, width: 1.0),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: recess,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1.0,
        space: 1,
      ),
    );
  }
}
