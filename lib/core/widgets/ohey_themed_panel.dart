import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum OheyThemedPanelBorder { all, horizontal }

/// Shared themed surface used when a feature page needs the same panel body
/// treatment with a page-specific accent around it.
class OheyThemedPanel extends StatelessWidget {
  const OheyThemedPanel({
    super.key,
    required this.child,
    required this.accentColor,
    required this.backgroundColor,
    this.width,
    this.padding,
    this.gradient,
    this.borderRadius = 24,
    this.borderWidth = 1,
    this.borderAlpha = .28,
    this.border = OheyThemedPanelBorder.all,
    this.glowAlpha = .16,
    this.glowBlur = 28,
    this.glowOffset = const Offset(0, 12),
  });

  static Color surfaceColor({required bool isWhite}) =>
      isWhite ? Colors.white : AppColors.darkBackground;

  final Widget child;
  final Color accentColor;
  final Color backgroundColor;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final double borderRadius;
  final double borderWidth;
  final double borderAlpha;
  final OheyThemedPanelBorder border;
  final double glowAlpha;
  final double glowBlur;
  final Offset glowOffset;

  Color get borderColor => accentColor.withValues(alpha: borderAlpha);

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: borderColor, width: borderWidth);
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: switch (border) {
          OheyThemedPanelBorder.all => Border.all(
            color: side.color,
            width: side.width,
          ),
          OheyThemedPanelBorder.horizontal => Border.symmetric(
            horizontal: side,
          ),
        },
        boxShadow: glowAlpha <= 0
            ? null
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: glowAlpha),
                  blurRadius: glowBlur,
                  offset: glowOffset,
                ),
              ],
      ),
      child: child,
    );
  }
}
