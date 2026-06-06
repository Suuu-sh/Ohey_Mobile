import 'package:flutter/material.dart';
import 'package:ohey/core/theme/app_colors.dart';

class OheyEmptyState extends StatelessWidget {
  const OheyEmptyState({
    super.key,
    required this.visual,
    required this.title,
    this.message,
    this.titleColor,
    this.messageColor,
    this.padding = const EdgeInsets.all(30),
    this.spacing = 16,
    this.action,
    this.hints = const [],
  });

  final Widget visual;
  final String title;
  final String? message;
  final Color? titleColor;
  final Color? messageColor;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final Widget? action;
  final List<String> hints;

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
            if (message?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                message!,
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
            ],
            if (hints.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hint in hints)
                    _OheyEmptyHintChip(
                      label: hint,
                      isWhite: isWhite,
                      foregroundColor: messageColor,
                    ),
                ],
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class _OheyEmptyHintChip extends StatelessWidget {
  const _OheyEmptyHintChip({
    required this.label,
    required this.isWhite,
    required this.foregroundColor,
  });

  final String label;
  final bool isWhite;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWhite
            ? AppColors.white.withValues(alpha: .82)
            : AppColors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isWhite
              ? AppColors.cFFE7EDF3
              : AppColors.white.withValues(alpha: .10),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color:
              foregroundColor ??
              (isWhite
                  ? AppColors.cFF6E7783
                  : AppColors.white.withValues(alpha: .62)),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
