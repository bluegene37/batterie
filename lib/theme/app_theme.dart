import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Available visual themes for the application.
enum AppVisualTheme {
  macGlass, // macOS Translucent Frosted Glass
  paperInk, // genexis.dev Cotton Paper & Ink
}

/// Paper & Ink palette from genexis.dev, along with native macOS Glass colors.
class AppColors {
  AppColors._();

  // --- genexis.dev Paper & Ink Palette ---
  // Paper (light surfaces)
  static const Color paper = Color(0xFFF2EDE3);
  static const Color paperRaised = Color(0xFFFAF7F0);
  static const Color paperDeep = Color(0xFFE7E0D0);
  static const Color paperRecess = Color(0xFFDED6C4);

  // Ink (text on paper)
  static const Color ink = Color(0xFF16161A);
  static const Color crease = Color(0xFF2B2B2E);
  static const Color inkSoft = Color(0xFF5A564E);
  static const Color graphite = Color(0xFF66625A);

  // Hairlines
  static const Color hairline = Color(0x2E2B2B2E);
  static const Color hairlineFaint = Color(0x172B2B2E);

  // Lead (the red accent)
  static const Color lead = Color(0xFFB4402C);
  static const Color leadDeep = Color(0xFF8E3122);
  static const Color leadWash = Color(0x1AB4402C);

  // Dark Paper / Ink surfaces
  static const Color inkBg = Color(0xFF16161A);
  static const Color inkRaised = Color(0xFF212125);
  static const Color inkDeep = Color(0xFF2B2B2E);
  static const Color inkRecess = Color(0xFF35353A);

  // Paper text in dark mode
  static const Color paperText = Color(0xFFF2EDE3);
  static const Color paperSoft = Color(0xFFB9B3A6);
  static const Color paperMuted = Color(0xFF8A857A);
  static const Color hairlineDark = Color(0x26F2EDE3);
  static const Color leadLight = Color(0xFFD4674F);

  // --- macOS Native Glass Palette ---
  static const Color macAccent = Color(0xFF007AFF);
  static const Color macAccentDark = Color(0xFF0A84FF);

  static const Color macGlassLightBg = Color(0x12FFFFFF);
  static const Color macGlassDarkBg = Color(0x16000000);

  static const Color macGlassLightSurface = Color(0x66FFFFFF);
  static const Color macGlassDarkSurface = Color(0x45222226);

  static const Color macGlassLightBorder = Color(0x4DFFFFFF);
  static const Color macGlassDarkBorder = Color(0x2AFFFFFF);

  static const Color macGlassLightHighlight = Color(0x80FFFFFF);
  static const Color macGlassDarkHighlight = Color(0x35FFFFFF);

  static const Color macTextPrimaryLight = Color(0xFF1D1D1F);
  static const Color macTextSecondaryLight = Color(0xFF6E6E73);
  static const Color macTextPrimaryDark = Color(0xFFF5F5F7);
  static const Color macTextSecondaryDark = Color(0xFF98989D);

  static const Color macCharging = Color(0xFF34C759);
  static const Color macWarning = Color(0xFFFF9F0A);
  static const Color macCritical = Color(0xFFFF453A);

  // Semantic (paper battery states)
  static const Color charging = Color(0xFF4F8A63);
  static const Color batteryWarning = Color(0xFFB8862B);
  static const Color batteryCritical = lead;
}

class AppTheme {
  AppTheme._();

  static const double cardRadius = 13.0;
  static const double controlRadius = 8.0;

  /// True where the native window is frosted glass (macOS vibrancy).
  static final bool isMacOS = !kIsWeb && Platform.isMacOS;

  static ThemeData get lightTheme => buildTheme(
        visualTheme: AppVisualTheme.macGlass,
        brightness: Brightness.light,
      );

  static ThemeData get darkTheme => buildTheme(
        visualTheme: AppVisualTheme.macGlass,
        brightness: Brightness.dark,
      );

  /// Builds ThemeData for the chosen visual theme and brightness.
  static ThemeData buildTheme({
    required AppVisualTheme visualTheme,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    if (visualTheme == AppVisualTheme.macGlass) {
      return _buildMacGlassTheme(isDark);
    } else {
      return _buildPaperInkTheme(isDark);
    }
  }

  // --- macOS Glass Theme Builder ---
  static ThemeData _buildMacGlassTheme(bool isDark) {
    final bg = isMacOS
        ? Colors.transparent
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFEBEBF0));

    final surface = isDark ? AppColors.macGlassDarkSurface : AppColors.macGlassLightSurface;
    final primary = isDark ? AppColors.macAccentDark : AppColors.macAccent;
    final onSurface = isDark ? AppColors.macTextPrimaryDark : AppColors.macTextPrimaryLight;
    final onSurfaceVariant = isDark ? AppColors.macTextSecondaryDark : AppColors.macTextSecondaryLight;
    final border = isDark ? AppColors.macGlassDarkBorder : AppColors.macGlassLightBorder;

    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: AppColors.macCharging,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: isDark ? const Color(0x35333338) : const Color(0x40E5E5EA),
      onSurfaceVariant: onSurfaceVariant,
      outline: border,
      outlineVariant: border,
      error: AppColors.macCritical,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      fontFamily: '.SF Pro Text',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
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
          side: BorderSide(color: border, width: 0.8),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: isDark ? const Color(0x35FFFFFF) : const Color(0x28000000),
        thumbColor: Colors.white,
        overlayColor: primary.withValues(alpha: 0.12),
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5, elevation: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 0.6,
        space: 1,
      ),
    );
  }

  // --- genexis.dev Paper & Ink Theme Builder ---
  static ThemeData _buildPaperInkTheme(bool isDark) {
    final bg = isDark ? AppColors.inkBg : AppColors.paper;
    final surface = isDark ? AppColors.inkRaised : AppColors.paperRaised;
    final surfaceHigh = isDark ? AppColors.inkDeep : AppColors.paperDeep;
    final recess = isDark ? AppColors.inkRecess : AppColors.paperRecess;
    final border = isDark ? AppColors.hairlineDark : AppColors.hairline;
    final accent = isDark ? AppColors.leadLight : AppColors.lead;
    final onAccent = isDark ? AppColors.inkBg : AppColors.paperRaised;
    final textPrimary = isDark ? AppColors.paperText : AppColors.ink;
    final textSecondary = isDark ? AppColors.paperSoft : AppColors.inkSoft;

    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: accent,
      onPrimary: onAccent,
      secondary: AppColors.charging,
      onSecondary: onAccent,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceHigh,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border,
      error: AppColors.batteryCritical,
      onError: onAccent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isMacOS ? bg.withValues(alpha: isDark ? 0.75 : 0.85) : bg,
      canvasColor: bg,
      fontFamily: 'Literata',
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
          borderRadius: BorderRadius.circular(4.0),
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
            borderRadius: BorderRadius.circular(3.0),
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
