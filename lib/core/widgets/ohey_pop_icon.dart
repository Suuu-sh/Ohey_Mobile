import 'package:flutter/material.dart';
import 'package:ohey/core/theme/app_colors.dart';

/// Ohey's icon slot: a crisp, flat glyph centered in a fixed square so rows
/// and buttons keep their rhythm whatever the icon.
class OheyPopIcon extends StatelessWidget {
  const OheyPopIcon({
    super.key,
    required this.icon,
    this.size = 34,
    this.iconSize,
    this.color = AppColors.brand,
    this.foregroundColor,
    this.showBubble = true,
  });

  final IconData icon;
  final double size;
  final double? iconSize;
  final Color color;
  final Color? foregroundColor;
  final bool showBubble;

  @override
  Widget build(BuildContext context) {
    final glyphSize = iconSize ?? (showBubble ? size * .66 : size);
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Icon(icon, size: glyphSize, color: foregroundColor ?? color),
      ),
    );
  }
}

/// Drop-in for [Icon] that picks up the surrounding [IconTheme].
class OheyGeneratedIcon extends StatelessWidget {
  const OheyGeneratedIcon(this.icon, {super.key, this.color, this.size});

  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) => Icon(
    icon,
    color: color ?? IconTheme.of(context).color ?? AppColors.white,
    size: size ?? IconTheme.of(context).size ?? 24,
  );
}
