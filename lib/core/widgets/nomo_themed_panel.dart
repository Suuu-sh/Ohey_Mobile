import 'package:flutter/material.dart';

enum NomoThemedPanelBorder { all, horizontal }

/// Shared themed surface used when a feature page needs the same panel body
/// treatment with a page-specific accent around it.
class NomoThemedPanel extends StatelessWidget {
  const NomoThemedPanel({
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
    this.border = NomoThemedPanelBorder.all,
    this.glowAlpha = .16,
    this.glowBlur = 28,
    this.glowOffset = const Offset(0, 12),
  });

  final Widget child;
  final Color accentColor;
  final Color backgroundColor;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final double borderRadius;
  final double borderWidth;
  final double borderAlpha;
  final NomoThemedPanelBorder border;
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
          NomoThemedPanelBorder.all => Border.all(
            color: side.color,
            width: side.width,
          ),
          NomoThemedPanelBorder.horizontal => Border.symmetric(
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
