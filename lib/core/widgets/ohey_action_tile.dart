import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'ohey_3d_button.dart';
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
    final surfaceColor = destructive
        ? Color.lerp(
            isWhite ? const Color(0xFFFFFFFF) : AppColors.darkBackground,
            destructiveColor,
            isWhite ? .18 : .32,
          )!
        : isWhite
        ? Color.lerp(const Color(0xFFF7FAFC), accent, .10)!
        : Color.lerp(AppColors.darkBackground, accent, .18)!;
    final bottomColor = destructive
        ? ohey3DShadowColorFor(
            destructiveColor,
            lightnessScale: isWhite ? .72 : .58,
          )
        : isWhite
        ? const Color(0xFFDCE4EC)
        : const Color(0xFF09131D);
    return Ohey3DButtonSurface(
      onTap: onTap,
      height: 68,
      radius: 22,
      color: surfaceColor,
      bottomColor: bottomColor,
      useGradient: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      borderColor: destructive
          ? destructiveColor.withValues(alpha: .36)
          : isWhite
          ? const Color(0xFFE1E8F1)
          : Colors.white.withValues(alpha: .12),
      outerShadows: [
        BoxShadow(
          color: (destructive ? destructiveColor : accent).withValues(
            alpha: isWhite ? .10 : .18,
          ),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      innerShadows: [
        BoxShadow(
          color: Colors.white.withValues(alpha: isWhite ? .40 : .08),
          blurRadius: 10,
          offset: const Offset(-2, -2),
        ),
      ],
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
    );
  }
}
