import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A paper plate: raised surface, hairline border, soft graphite shadow.
class PaperSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? surfaceColor;
  final Color? borderColor;

  const PaperSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
    this.margin,
    this.surfaceColor,
    this.borderColor,
  });

  // Gene - Oct 16, 2026: Enhanced PaperSurface with soft Neumorphic dual-shadow extrusion and subtle rim lighting. Preserved previous flat paper plate implementation below.
  // @override
  // Widget build(BuildContext context) {
  //   final scheme = Theme.of(context).colorScheme;
  //   final isDark = scheme.brightness == Brightness.dark;
  //
  //   return Container(
  //     margin: margin,
  //     decoration: BoxDecoration(
  //       color: surfaceColor ?? scheme.surface,
  //       borderRadius: BorderRadius.circular(AppTheme.cardRadius),
  //       border: Border.all(color: borderColor ?? scheme.outline, width: 1.0),
  //       boxShadow: isDark
  //           ? [
  //               BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.3),
  //                 blurRadius: 12,
  //                 offset: const Offset(0, 3),
  //               ),
  //             ]
  //           : [
  //               BoxShadow(
  //                 color: AppColors.ink.withValues(alpha: 0.06),
  //                 blurRadius: 2,
  //                 offset: const Offset(0, 1),
  //               ),
  //               BoxShadow(
  //                 color: AppColors.ink.withValues(alpha: 0.18),
  //                 blurRadius: 24,
  //                 spreadRadius: -10,
  //                 offset: const Offset(0, 10),
  //               ),
  //             ],
  //     ),
  //     padding: padding,
  //     child: child,
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surfaceColor ?? scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.65)),
          width: 0.9,
        ),
        boxShadow: NeumorphicTheme.raisedShadows(
          context,
          distance: isDark ? 5.0 : 6.0,
          blur: isDark ? 10.0 : 12.0,
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}
