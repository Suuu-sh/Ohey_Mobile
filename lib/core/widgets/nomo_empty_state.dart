import 'package:flutter/material.dart';

class NomoEmptyState extends StatelessWidget {
  const NomoEmptyState({
    super.key,
    required this.visual,
    required this.title,
    required this.message,
    this.titleColor,
    this.messageColor,
    this.padding = const EdgeInsets.all(30),
    this.spacing = 16,
  });

  final Widget visual;
  final String title;
  final String message;
  final Color? titleColor;
  final Color? messageColor;
  final EdgeInsetsGeometry padding;
  final double spacing;

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
                    (isWhite ? const Color(0xFF27313B) : Colors.white),
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
                        ? const Color(0xFF6E7783)
                        : Colors.white.withValues(alpha: .55)),
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
