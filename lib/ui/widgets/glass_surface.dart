import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A card/surface widget that adapts seamlessly between:
/// 1. macOS Frosted Glass (BackdropFilter blur, specular border, translucent surface)
/// 2. genexis.dev Paper & Ink (clean paper plate, hairline border, graphite shadow)
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final AppVisualTheme visualTheme;
  final Color? surfaceColor;
  final Color? borderColor;

  const GlassSurface({
    super.key,
    required this.child,
    required this.visualTheme,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
    this.margin,
    this.borderRadius,
    this.surfaceColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (visualTheme == AppVisualTheme.macGlass) {
      final radius = BorderRadius.circular(borderRadius ?? AppTheme.cardRadius);
      final bg = surfaceColor ??
          (isDark ? AppColors.macGlassDarkSurface : AppColors.macGlassLightSurface);
      final border = borderColor ??
          (isDark ? AppColors.macGlassDarkBorder : AppColors.macGlassLightBorder);

      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                color: bg,
                border: Border.all(color: border, width: 0.8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    // genexis.dev Paper & Ink mode
    final radius = BorderRadius.circular(borderRadius ?? 4.0);
    final bg = surfaceColor ?? (isDark ? AppColors.inkRaised : AppColors.paperRaised);
    final border = borderColor ?? (isDark ? AppColors.hairlineDark : AppColors.hairline);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: 1.0),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x122B2B2E),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
                BoxShadow(
                  color: Color(0x4D2B2B2E),
                  blurRadius: 24,
                  spreadRadius: -10,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      padding: padding,
      child: child,
    );
  }
}
