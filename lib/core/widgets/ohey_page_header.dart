import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ohey_pop_icon.dart';
import 'package:ohey/core/theme/app_colors.dart';

class OheyPageHeader extends StatelessWidget {
  const OheyPageHeader({
    super.key,
    required this.title,
    this.trailing,
    this.titleColor,
    this.titleOffset = Offset.zero,
    this.trailingOffset = Offset.zero,
  });

  static const double height = 52;
  static const double titleSize = 34;
  static const double topPadding = 16;
  static const double horizontalPadding = 22;
  static const double bottomSpacing = 18;
  static const double sceneBackdropBodyHeight = 178;

  static double contentTopInset(BuildContext context) {
    return MediaQuery.paddingOf(context).top +
        topPadding +
        height +
        bottomSpacing;
  }

  static double sceneBackdropHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top + sceneBackdropBodyHeight;
  }

  final String title;
  final Widget? trailing;
  final Color? titleColor;
  final Offset titleOffset;
  final Offset trailingOffset;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final color =
        titleColor ?? (isWhite ? AppColors.cFF27313B : AppColors.white);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Transform.translate(
              offset: titleOffset,
              child: Text(
                title,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                strutStyle: const StrutStyle(
                  fontSize: titleSize,
                  height: 1,
                  forceStrutHeight: true,
                ),
                style: TextStyle(
                  color: color,
                  fontSize: titleSize,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Transform.translate(offset: trailingOffset, child: trailing!),
          ],
        ],
      ),
    );
  }
}

class OheyHeaderIconButton extends StatelessWidget {
  const OheyHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.semanticLabel,
    this.color = AppColors.cFF2DE3D2,
    this.hasDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;
  final Color color;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: CupertinoButton(
        onPressed: onTap,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              OheyPopIcon(
                icon: icon,
                color: color,
                size: 34,
                showBubble: false,
              ),
              if (hasDot)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isWhite ? AppColors.white : AppColors.cFF0C1724,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
