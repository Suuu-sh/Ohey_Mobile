import 'package:flutter/material.dart';
import 'package:ohey/core/theme/app_colors.dart';

class OheyEmptyState extends StatelessWidget {
  const OheyEmptyState({
    super.key,
    required this.visual,
    required this.title,
    required this.message,
    this.titleColor,
    this.messageColor,
    this.padding = const EdgeInsets.all(30),
    this.spacing = 16,
    this.action,
  });

  final Widget visual;
  final String title;
  final String message;
  final Color? titleColor;
  final Color? messageColor;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            SizedBox(height: spacing),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    titleColor ??
                    (isWhite ? AppColors.cFF27313B : AppColors.white),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    messageColor ??
                    (isWhite
                        ? AppColors.cFF6E7783
                        : AppColors.white.withValues(alpha: .55)),
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
