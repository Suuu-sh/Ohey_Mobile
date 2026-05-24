import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'nomo_pop_icon.dart';

class NomoActionTile extends StatelessWidget {
  const NomoActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.destructive = false,
    this.destructiveColor = const Color(0xFFFF5F8F),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool destructive;
  final Color destructiveColor;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = destructive
        ? destructiveColor
        : isWhite
        ? const Color(0xFF101820)
        : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .55);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isWhite ? const Color(0xFFF7FAFC) : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: destructive
                ? destructiveColor.withValues(alpha: .32)
                : isWhite
                ? const Color(0xFFE1E8F1)
                : Colors.white.withValues(alpha: .10),
          ),
        ),
        child: Row(
          children: [
            NomoPopIcon(icon: icon, color: accent, size: 44, iconSize: 23),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
            NomoPopIcon(
              icon: CupertinoIcons.chevron_forward,
              color: subtitleColor,
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
