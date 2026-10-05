import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum OheyThemedPanelBorder { all, horizontal }

/// Shared themed surface used when a feature page needs the same panel body
/// treatment with a page-specific accent around it.
///
/// Panels follow the chunky card style: a flat fill, a solid hairline, and a
/// thicker bottom edge that reads as the card's lip.
class OheyThemedPanel extends StatelessWidget {
  const OheyThemedPanel({
    super.key,
    required this.child,
    required this.accentColor,
    required this.backgroundColor,
    this.width,
    this.padding,
    this.gradient,
    this.borderRadius = 20,
    this.borderWidth = 2,
    this.borderAlpha = .28,
    this.border = OheyThemedPanelBorder.all,
  });

  static Color surfaceColor({required bool isWhite}) =>
      isWhite ? AppColors.white : AppColors.darkBackground;

  /// Extra thickness of the bottom edge on fully bordered panels.
  static const double lipDepth = 2;

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

  Color get borderColor => accentColor.withValues(alpha: borderAlpha);

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: borderColor, width: borderWidth);
    final hasBorder = borderWidth > 0 && borderAlpha > 0;
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: !hasBorder
            ? null
            : switch (border) {
                OheyThemedPanelBorder.all => Border(
                  top: side,
                  left: side,
                  right: side,
                  bottom: side.copyWith(width: borderWidth + lipDepth),
                ),
                OheyThemedPanelBorder.horizontal => Border.symmetric(
                  horizontal: side,
                ),
              },
      ),
      child: child,
    );
  }
}
