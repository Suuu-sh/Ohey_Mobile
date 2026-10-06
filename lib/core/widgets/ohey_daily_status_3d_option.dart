import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/ohey_user.dart';
import '../theme/app_colors.dart';
import 'ohey_3d_button.dart';
import 'ohey_pop_icon.dart';

// Status reads like a traffic light so it never competes with the brand pink.
const oheyStatusAvailableColor = AppColors.cFF58CC02;
const oheyStatusMaybeColor = AppColors.cFF1CB0F6;
const oheyStatusDependsColor = AppColors.cFFFF9600;
const oheyStatusUnsetColor = AppColors.cFFAFAFAF;
const oheyDailyStatusBlocked = AppColors.cFF2B3A41;
const oheyDailyStatusBlockedForeground = AppColors.cFF1CB0F6;
const oheyDailyStatusActionForeground = AppColors.white;

class OheyDailyStatus3DOption extends StatelessWidget {
  const OheyDailyStatus3DOption({
    super.key,
    required this.status,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
    this.isLoading = false,
    this.showChevron = false,
    this.height = 72,
    this.radius = 28,
  });

  final OheyDailyStatus status;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;
  final bool isLoading;
  final bool showChevron;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final foreground = oheyDailyStatus3DForegroundColor(
      status,
      isWhite: isWhite,
    );
    final canTap = enabled && !isLoading && onTap != null;
    final shouldFade = !enabled && !isLoading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: shouldFade ? .46 : 1,
      child: Ohey3DButtonSurface(
        onTap: canTap ? onTap : null,
        enabled: enabled || isLoading,
        height: height,
        radius: radius,
        color: oheyDailyStatus3DSurfaceColor(
          status,
          isWhite: isWhite,
          selected: selected,
        ),
        bottomColor: oheyDailyStatus3DShadowColor(
          status,
          isWhite: isWhite,
          selected: selected,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            OheyPopIcon(
              icon: oheyDailyStatusIcon(status),
              color: foreground,
              size: 38,
              iconSize: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground.withValues(
                          alpha: status == OheyDailyStatus.hasPlans ? .70 : .72,
                        ),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isLoading)
              CupertinoActivityIndicator(color: foreground)
            else if (selected)
              OheyGeneratedIcon(
                CupertinoIcons.checkmark_circle_fill,
                color: foreground,
                size: 24,
              )
            else if (showChevron)
              OheyGeneratedIcon(
                CupertinoIcons.chevron_right,
                color: foreground.withValues(alpha: .86),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

Color oheyDailyStatusColor(OheyDailyStatus status) => switch (status) {
  OheyDailyStatus.available => oheyStatusAvailableColor,
  OheyDailyStatus.maybeAvailable => oheyStatusMaybeColor,
  OheyDailyStatus.dependsOnTime => oheyStatusDependsColor,
  OheyDailyStatus.hasPlans => oheyDailyStatusBlockedForeground,
  OheyDailyStatus.unselected => oheyStatusUnsetColor,
};

Color oheyDailyStatusBlockAccent(OheyDailyStatus status) => switch (status) {
  OheyDailyStatus.hasPlans => oheyDailyStatusBlocked,
  _ => oheyDailyStatusColor(status),
};

Color oheyDailyStatusTileAccent(OheyDailyStatus status) {
  if (status == OheyDailyStatus.hasPlans) {
    return oheyDailyStatusBlockedForeground;
  }
  return oheyDailyStatusColor(status);
}

Color oheyDailyStatusTileBackground(
  OheyDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return isWhite
        ? AppColors.cFFE5E5E5
        : oheyDailyStatusBlocked.withValues(alpha: selected ? .92 : .76);
  }
  return oheyDailyStatusColor(status).withValues(
    alpha: isWhite ? (selected ? .34 : .22) : (selected ? .52 : .36),
  );
}

Color oheyDailyStatusTileForeground(
  OheyDailyStatus status, {
  required bool isWhite,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return isWhite ? AppColors.cFF131F24 : AppColors.white;
  }
  return oheyDailyStatusActionForeground;
}

Color oheyDailyStatus3DSurfaceColor(
  OheyDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return isWhite ? AppColors.cFFF7F7F7 : AppColors.cFF37464F;
  }
  return oheyDailyStatusColor(status);
}

Color oheyDailyStatus3DShadowColor(
  OheyDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return isWhite ? AppColors.cFFCDCDCD : AppColors.cFF1A272D;
  }
  return ohey3DShadowColorFor(
    oheyDailyStatus3DSurfaceColor(status, isWhite: isWhite, selected: selected),
  );
}

Color oheyDailyStatus3DForegroundColor(
  OheyDailyStatus status, {
  required bool isWhite,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return isWhite ? AppColors.cFF131F24 : AppColors.cFFF7F7F7;
  }
  return oheyDailyStatusActionForeground;
}

IconData oheyDailyStatusIcon(OheyDailyStatus status) => switch (status) {
  OheyDailyStatus.available => CupertinoIcons.sparkles,
  OheyDailyStatus.maybeAvailable => CupertinoIcons.drop_fill,
  OheyDailyStatus.dependsOnTime => CupertinoIcons.clock_fill,
  OheyDailyStatus.hasPlans => CupertinoIcons.calendar_today,
  OheyDailyStatus.unselected => CupertinoIcons.circle,
};
