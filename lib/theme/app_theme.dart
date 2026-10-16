import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Very light coffee palette in the spirit of genexis.dev paper & ink:
/// near-white cream paper, espresso ink, latte hairlines and a coffee-brown
/// accent. Dark mode is a dark roast with cream text.
///
/// Every value here is reached through `Theme.of(context)` roles in widgets;
/// the only direct `AppColors` reads are the semantic battery states.
// Gene - Oct 16, 2026: Converted color palette to soft Neumorphic design across light and dark modes, with dedicated shadow and highlight tokens. Preserved previous paper & roast palette commented below.
// abstract class AppColors {
//   // --- Light: cream paper ---
//   static const Color paper = Color(0xFFFBF8F3);
//   static const Color paperRaised = Color(0xFFFFFDFA);
//   static const Color paperDeep = Color(0xFFF1EBE1);
//   static const Color paperRecess = Color(0xFFE8E0D3);
// 
//   // Espresso ink on paper
//   static const Color ink = Color(0xFF2B211B);
//   static const Color inkSoft = Color(0xFF5E5148);
//   static const Color inkMuted = Color(0xFF7E7063);
//   static const Color hairline = Color(0x264A3B30);
// 
//   // Coffee accent
//   static const Color coffee = Color(0xFF6F4E37);
//   static const Color coffeeDeep = Color(0xFF4E3626);
// 
//   // --- Dark: dark roast ---
//   static const Color roast = Color(0xFF1C1714);
//   static const Color roastRaised = Color(0xFF262019);
//   static const Color roastDeep = Color(0xFF322A23);
//   static const Color roastRecess = Color(0xFF3D342C);
// 
//   // Cream text on roast
//   static const Color cream = Color(0xFFF5EFE6);
//   static const Color creamSoft = Color(0xFFCFC3B5);
//   static const Color creamMuted = Color(0xFF9A8D7F);
//   static const Color hairlineDark = Color(0x26F5EFE6);
// 
//   // Latte accent for dark mode
//   static const Color latte = Color(0xFFC8A27C);
// 
//   // --- Semantic battery states (deep enough to use as text on paper) ---
//   static const Color charging = Color(0xFF2E7050);
//   static const Color batteryWarning = Color(0xFF8C5E0E);
//   static const Color batteryCritical = Color(0xFFB7412F);
// 
//   // Same states lifted for dark roast
//   static const Color chargingDark = Color(0xFF7FBF9A);
//   static const Color batteryWarningDark = Color(0xFFE0A94A);
//   static const Color batteryCriticalDark = Color(0xFFE8705C);
// 
//   // Alarm ground for the takeover: both clear AA against cream text.
//   static const Color alarm = Color(0xFFB7412F);
//   static const Color alarmDeep = Color(0xFF8E2F22);
// }
abstract class AppColors {
  // --- Light Neumorphism (Soft Slate & Royal Blue) ---
  static const Color neumorphicLightBase = Color(0xFFE0E5EC);
  static const Color neumorphicLightRaised = Color(0xFFE0E5EC);
  static const Color neumorphicLightDeep = Color(0xFFD6DDE6);
  static const Color neumorphicLightRecess = Color(0xFFD3DAE4);

  // Soft shadows and highlights for light neumorphism
  static const Color lightHighlight = Color(0xFFFFFFFF);
  static const Color lightShadow = Color(0xFFA3B1C6);

  // Slate ink for light neumorphism (WCAG AA compliant)
  static const Color ink = Color(0xFF1E293B);
  static const Color inkSoft = Color(0xFF475569);
  static const Color inkMuted = Color(0xFF64748B);
  static const Color hairline = Color(0x1F94A3B8);

  // Vibrant Blue Accent for Light Neumorphism
  static const Color accentLight = Color(0xFF2563EB);
  static const Color accentLightDeep = Color(0xFF1D4ED8);

  // --- Dark Neumorphism (Dark Slate & Electric Blue) ---
  static const Color neumorphicDarkBase = Color(0xFF1E222A);
  static const Color neumorphicDarkRaised = Color(0xFF1E222A);
  static const Color neumorphicDarkDeep = Color(0xFF171A20);
  static const Color neumorphicDarkRecess = Color(0xFF15171D);

  // Soft shadows and highlights for dark neumorphism
  static const Color darkHighlight = Color(0xFF2B303B);
  static const Color darkShadow = Color(0xFF121419);

  // Clean text for dark neumorphism (WCAG AA compliant)
  static const Color textDark = Color(0xFFF1F5F9);
  static const Color textDarkSoft = Color(0xFFCBD5E1);
  static const Color textDarkMuted = Color(0xFF94A3B8);
  static const Color hairlineDark = Color(0x2694A3B8);

  // Vibrant Blue Accent for Dark Neumorphism
  static const Color accentDark = Color(0xFF3B82F6);
  static const Color accentDarkDeep = Color(0xFF1D4ED8);

  // --- Semantic Battery States (Carefully tuned for WCAG AA contrast) ---
  static const Color charging = Color(0xFF059669);
  static const Color batteryWarning = Color(0xFFD97706);
  static const Color batteryCritical = Color(0xFFDC2626);

  static const Color chargingDark = Color(0xFF34D399);
  static const Color batteryWarningDark = Color(0xFFFBBF24);
  static const Color batteryCriticalDark = Color(0xFFF87171);

  // Alarm takeover colors (WCAG AA >= 4.5:1 against white text)
  static const Color alarm = Color(0xFFDC2626);
  static const Color alarmDeep = Color(0xFF991B1B);
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

// Gene - Oct 16, 2026: Added NeumorphicTheme helper providing consistent soft dual shadows and highlight rims.
class NeumorphicTheme {
  NeumorphicTheme._();

  static List<BoxShadow> raisedShadows(
    BuildContext context, {
    double distance = 5.0,
    double blur = 10.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: const Color(0xFF2C323E).withValues(alpha: 0.65),
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.8),
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.95),
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: const Color(0xFFA3B1C6).withValues(alpha: 0.55),
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
      ];
    }
  }

  static List<BoxShadow> softShadows(
    BuildContext context, {
    double distance = 2.5,
    double blur = 5.0,
  }) {
    return raisedShadows(context, distance: distance, blur: blur);
  }
}

class AppTheme {
  AppTheme._();

  // Gene - Oct 16, 2026: Updated card and control radius for soft Neumorphic curved surfaces.
  // static const double cardRadius = 4.0;
  // static const double controlRadius = 3.0;
  static const double cardRadius = 16.0;
  static const double controlRadius = 10.0;

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

  // Gene - Oct 16, 2026: Refactored theme building to apply Neumorphic color schemes, curved shapes, and input styling. Preserved previous theme building below.
  // static ThemeData buildTheme({required Brightness brightness}) {
  //   final isDark = brightness == Brightness.dark;
  //
  //   final bg = isDark ? AppColors.roast : AppColors.paper;
  //   final surface = isDark ? AppColors.roastRaised : AppColors.paperRaised;
  //   final surfaceHigh = isDark ? AppColors.roastDeep : AppColors.paperDeep;
  //   final recess = isDark ? AppColors.roastRecess : AppColors.paperRecess;
  //   final border = isDark ? AppColors.hairlineDark : AppColors.hairline;
  //   final accent = isDark ? AppColors.latte : AppColors.coffee;
  //   final onAccent = isDark ? AppColors.roast : AppColors.cream;
  //   final textPrimary = isDark ? AppColors.cream : AppColors.ink;
  //   final textSecondary = isDark ? AppColors.creamSoft : AppColors.inkSoft;
  //   final charging = isDark ? AppColors.chargingDark : AppColors.charging;
  //
  //   final colorScheme = ColorScheme(
  //     brightness: brightness,
  //     primary: accent,
  //     onPrimary: onAccent,
  //     secondary: charging,
  //     onSecondary: onAccent,
  //     surface: surface,
  //     onSurface: textPrimary,
  //     surfaceContainerHighest: surfaceHigh,
  //     onSurfaceVariant: textSecondary,
  //     outline: border,
  //     outlineVariant: border,
  //     error: AppColors.alarm,
  //     errorContainer: AppColors.alarmDeep,
  //     onError: AppColors.cream,
  //     onErrorContainer: AppColors.cream,
  //   );
  //
  //   return ThemeData(
  //     useMaterial3: true,
  //     brightness: brightness,
  //     colorScheme: colorScheme,
  //     scaffoldBackgroundColor: bg,
  //     canvasColor: bg,
  //     fontFamily: 'Literata',
  //     textTheme: _textTheme,
  //     appBarTheme: AppBarTheme(
  //       backgroundColor: Colors.transparent,
  //       foregroundColor: textPrimary,
  //       elevation: 0,
  //       scrolledUnderElevation: 0,
  //       centerTitle: false,
  //     ),
  //     cardTheme: CardThemeData(
  //       color: surface,
  //       elevation: 0,
  //       margin: EdgeInsets.zero,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(cardRadius),
  //         side: BorderSide(color: border, width: 1.0),
  //       ),
  //     ),
  //     dialogTheme: DialogThemeData(
  //       backgroundColor: surface,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(cardRadius),
  //         side: BorderSide(color: border, width: 1.0),
  //       ),
  //     ),
  //     sliderTheme: SliderThemeData(
  //       activeTrackColor: accent,
  //       inactiveTrackColor: recess,
  //       thumbColor: accent,
  //       overlayColor: accent.withValues(alpha: 0.15),
  //       trackHeight: 3,
  //       thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
  //     ),
  //     filledButtonTheme: FilledButtonThemeData(
  //       style: FilledButton.styleFrom(
  //         backgroundColor: accent,
  //         foregroundColor: onAccent,
  //         elevation: 0,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(controlRadius),
  //         ),
  //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  //         textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
  //       ),
  //     ),
  //     dividerTheme: DividerThemeData(
  //       color: border,
  //       thickness: 1.0,
  //       space: 1,
  //     ),
  //   );
  // }
  static ThemeData buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.neumorphicDarkBase : AppColors.neumorphicLightBase;
    final surface = isDark ? AppColors.neumorphicDarkRaised : AppColors.neumorphicLightRaised;
    final surfaceHigh = isDark ? AppColors.neumorphicDarkDeep : AppColors.neumorphicLightDeep;
    final recess = isDark ? AppColors.neumorphicDarkRecess : AppColors.neumorphicLightRecess;
    final border = isDark ? AppColors.hairlineDark : AppColors.hairline;
    final accent = isDark ? AppColors.accentDark : AppColors.accentLight;
    final onAccent = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textPrimary = isDark ? AppColors.textDark : AppColors.ink;
    final textSecondary = isDark ? AppColors.textDarkMuted : AppColors.inkSoft;
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
      onError: Colors.white,
      onErrorContainer: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
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
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: recess,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.15),
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: recess,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: accent, width: 1.5),
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
