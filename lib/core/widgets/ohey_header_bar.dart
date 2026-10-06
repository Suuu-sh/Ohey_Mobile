import 'package:flutter/material.dart';
import 'package:ohey/core/theme/app_colors.dart';

/// Flat top bar behind a tab title: the page color plus a 2pt divider, the
/// way Duolingo separates its header from scrolling content.
class OheyHeaderBar extends StatelessWidget {
  const OheyHeaderBar({super.key, required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isWhite ? AppColors.white : AppColors.darkBackground,
          border: Border(
            bottom: BorderSide(
              color: isWhite
                  ? AppColors.chunkyBorderLight
                  : AppColors.chunkyBorderDark,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
