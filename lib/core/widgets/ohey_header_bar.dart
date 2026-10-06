import 'package:flutter/material.dart';
import 'package:ohey/core/theme/app_colors.dart';

/// Flat top bar behind a tab title, matching the page's theme background.
class OheyHeaderBar extends StatelessWidget {
  const OheyHeaderBar({super.key, required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isWhite ? AppColors.white : AppColors.darkBackground,
        ),
      ),
    );
  }
}
