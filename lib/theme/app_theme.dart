import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Paper & Ink palette, taken from genexis.dev.
///
/// Light mode is warm paper with ink text and a single red ("lead") accent.
/// Dark mode inverts it: ink surfaces with paper text.
class AppColors {
  AppColors._();

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

  // Hairlines (crease at low alpha, as on the site)
  static const Color hairline = Color(0x2E2B2B2E);
  static const Color hairlineFaint = Color(0x172B2B2E);

  // Lead: the one accent
  static const Color lead = Color(0xFFB4402C);
  static const Color leadDeep = Color(0xFF8E3122);
  static const Color leadWash = Color(0x1AB4402C);

  // Ink surfaces (dark mode)
  static const Color inkBg = Color(0xFF16161A);
  static const Color inkRaised = Color(0xFF212125);
  static const Color inkDeep = Color(0xFF2B2B2E);
  static const Color inkRecess = Color(0xFF35353A);

  // Paper text (dark mode)
  static const Color paperText = Color(0xFFF2EDE3);
  static const Color paperSoft = Color(0xFFB9B3A6);
  static const Color paperMuted = Color(0xFF8A857A);
  static const Color hairlineDark = Color(0x26F2EDE3);
  static const Color leadLight = Color(0xFFD4674F);

  // Semantic (battery states), tuned to sit on paper
  static const Color charging = Color(0xFF4F8A63);
  static const Color batteryWarning = Color(0xFFB8862B);
  static const Color batteryCritical = lead;
}

/// One set of roles the theme is built from; light and dark each supply one.
class _Palette {
  const _Palette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.recess,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.bgGlassAlpha,
    required this.surfaceGlassAlpha,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color recess;
  final Color border;
  final Color accent;
  final Color onAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// How much of the window background is paint vs. frosted glass.
  final double bgGlassAlpha;
  final double surfaceGlassAlpha;
}

class AppTheme {
  AppTheme._();

  static const double cardRadius = 14.0;
  static const double controlRadius = 10.0;

  /// True where the native window is frosted glass (macOS vibrancy).
  /// Backgrounds are painted translucent so the glass shows through;
  /// everywhere else the same palette is painted opaque.
  static final bool glass = !kIsWeb && Platform.isMacOS;

  static const _Palette _light = _Palette(
    brightness: Brightness.light,
    bg: AppColors.paper,
    surface: AppColors.paperRaised,
    surfaceHigh: AppColors.paperDeep,
    recess: AppColors.paperRecess,
    border: AppColors.hairline,
    accent: AppColors.lead,
    onAccent: AppColors.paperRaised,
    textPrimary: AppColors.ink,
    textSecondary: AppColors.inkSoft,
    textMuted: AppColors.graphite,
    bgGlassAlpha: 0.42,
    surfaceGlassAlpha: 0.50,
  );

  static const _Palette _dark = _Palette(
    brightness: Brightness.dark,
    bg: AppColors.inkBg,
    surface: AppColors.inkRaised,
    surfaceHigh: AppColors.inkDeep,
    recess: AppColors.inkRecess,
    border: AppColors.hairlineDark,
    accent: AppColors.leadLight,
    onAccent: AppColors.inkBg,
    textPrimary: AppColors.paperText,
    textSecondary: AppColors.paperSoft,
    textMuted: AppColors.paperMuted,
    bgGlassAlpha: 0.28,
    surfaceGlassAlpha: 0.32,
  );

  static ThemeData get lightTheme => _build(_light);
  static ThemeData get darkTheme => _build(_dark);

  static Color _tint(Color color, double alpha) =>
      glass ? color.withValues(alpha: alpha) : color;

  static ThemeData _build(_Palette p) {
    final bg = _tint(p.bg, p.bgGlassAlpha);
    final surface = _tint(p.surface, p.surfaceGlassAlpha);

    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: AppColors.charging,
      onSecondary: p.onAccent,
      surface: p.surface,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.surfaceHigh,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.border,
      error: AppColors.batteryCritical,
      onError: p.onAccent,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p.textPrimary,
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
          side: BorderSide(color: p.border, width: 1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        inactiveTrackColor: p.recess,
        thumbColor: p.accent,
        overlayColor: p.accent.withValues(alpha: 0.15),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.onAccent;
          }
          return p.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.accent;
          }
          return p.recess;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceHigh.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.accent, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 0.8,
        space: 1,
      ),
    );
  }
}
