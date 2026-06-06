import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'ohey_pop_icon.dart';

class OheyActionTile extends StatelessWidget {
  const OheyActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.destructive = false,
    this.destructiveColor = AppColors.cFFFF5F8F,
    this.showShadow = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool destructive;
  final Color destructiveColor;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = destructive
        ? destructiveColor
        : isWhite
        ? AppColors.cFF101820
        : AppColors.white;
    final subtitleColor = isWhite
        ? AppColors.cFF697684
        : AppColors.white.withValues(alpha: .55);
    final surfaceColor = isWhite
        ? Color.lerp(AppColors.cFFF7FAFC, accent, .10)!
        : AppColors.darkBackground;
    return CupertinoButton(
      onPressed: onTap,
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWhite
                ? AppColors.cFFE1E8F1
                : AppColors.white.withValues(alpha: .12),
          ),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: (destructive ? destructiveColor : accent).withValues(
                      alpha: isWhite ? .08 : .14,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            OheyPopIcon(icon: icon, color: accent, size: 44, iconSize: 23),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            OheyPopIcon(
              icon: CupertinoIcons.chevron_forward,
              color: destructive ? destructiveColor : subtitleColor,
              size: 30,
              iconSize: 16,
              shadow: false,
            ),
          ],
        ),
      ),
    );
  }
}
