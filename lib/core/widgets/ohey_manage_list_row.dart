import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'ohey_pop_icon.dart';

class OheyManageListRow extends StatelessWidget {
  const OheyManageListRow({
    super.key,
    required this.title,
    required this.leading,
    this.subtitle,
    this.actions = const <Widget>[],
    this.onTap,
    this.semanticLabel,
    this.titleColor,
    this.subtitleColor,
    this.surfaceColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.borderRadius = 20,
  });

  final String title;
  final String? subtitle;
  final Widget leading;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? surfaceColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final resolvedTitleColor =
        titleColor ?? (isWhite ? AppColors.cFF101820 : AppColors.white);
    final resolvedSubtitleColor =
        subtitleColor ??
        (isWhite
            ? AppColors.cFF697684
            : AppColors.white.withValues(alpha: .55));
    final resolvedSurfaceColor =
        surfaceColor ??
        (isWhite
            ? AppColors.cFFF7F9FC
            : AppColors.white.withValues(alpha: .06));
    final resolvedBorderColor =
        borderColor ?? (isWhite ? AppColors.cFFE2E8F0 : AppColors.white12);
    final row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedSurfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: resolvedBorderColor),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: subtitle == null || subtitle!.trim().isEmpty
                ? Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: resolvedTitleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: resolvedTitleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: resolvedSubtitleColor,
                          fontSize: 12,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            for (var i = 0; i < actions.length; i++) ...[
              actions[i],
              if (i != actions.length - 1) const SizedBox(width: 6),
            ],
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: row,
      ),
    );
  }
}

class OheyManageListIconButton extends StatelessWidget {
  const OheyManageListIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 41,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: color.withValues(alpha: .30)),
          ),
          child: Center(child: OheyGeneratedIcon(icon, color: color, size: 17)),
        ),
      ),
    );
  }
}

class OheyManageAddTile extends StatelessWidget {
  const OheyManageAddTile({
    super.key,
    required this.label,
    required this.accent,
    required this.onTap,
    this.semanticLabel,
    this.foregroundColor,
    this.surfaceColor,
    this.borderColor,
    this.height = 56,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;
  final String? semanticLabel;
  final Color? foregroundColor;
  final Color? surfaceColor;
  final Color? borderColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final resolvedForegroundColor =
        foregroundColor ?? (isWhite ? AppColors.cFF101820 : AppColors.white);
    final resolvedSurfaceColor =
        surfaceColor ??
        Color.lerp(
          isWhite ? AppColors.white : AppColors.darkBackground,
          accent,
          isWhite ? .20 : .15,
        )!;
    final resolvedBorderColor = borderColor ?? accent.withValues(alpha: .46);
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: resolvedSurfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: resolvedBorderColor),
          ),
          child: Row(
            children: [
              OheyPopIcon(
                icon: CupertinoIcons.plus,
                color: accent,
                size: 36,
                iconSize: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: resolvedForegroundColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OheyGeneratedIcon(
                CupertinoIcons.chevron_right,
                color: accent,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
