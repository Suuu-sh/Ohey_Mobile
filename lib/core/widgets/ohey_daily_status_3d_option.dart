import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/ohey_user.dart';
import '../theme/app_colors.dart';
import 'ohey_3d_button.dart';
import 'ohey_pop_icon.dart';

const oheyDailyStatusPink = AppColors.cFFFF5EA8;
const oheyDailyStatusBlue = AppColors.cFF20B9FF;
const oheyDailyStatusPurple = AppColors.cFF8A62FF;
const oheyDailyStatusGreen = AppColors.cFF9AF21A;
const oheyDailyStatusBlocked = AppColors.cFF2B3644;
const oheyDailyStatusBlockedForeground = AppColors.cFF738092;
const oheyDailyStatusActionForeground = AppColors.cFF06111D;

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
    final accent = oheyDailyStatusBlockAccent(status);
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
        borderColor: oheyDailyStatus3DBorderColor(status, selected: selected),
        borderWidth: 1.2,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        useGradient: true,
        outerShadows: oheyDailyStatus3DOuterShadows(
          status,
          accent: accent,
          selected: selected,
        ),
        innerShadows: oheyDailyStatus3DInnerShadows(status, selected: selected),
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
  OheyDailyStatus.available => oheyDailyStatusPink,
  OheyDailyStatus.maybeAvailable => oheyDailyStatusBlue,
  OheyDailyStatus.dependsOnTime => oheyDailyStatusPurple,
  OheyDailyStatus.hasPlans => oheyDailyStatusBlockedForeground,
  OheyDailyStatus.unselected => oheyDailyStatusGreen,
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
        ? AppColors.cFFE2E8F0
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
    return isWhite ? AppColors.cFF111827 : AppColors.white;
  }
  return oheyDailyStatusActionForeground;
}

Color oheyDailyStatus3DSurfaceColor(
  OheyDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return isWhite ? AppColors.cFFE8EEF5 : AppColors.cFF33404E;
  }
  return oheyDailyStatusColor(status);
}

Color oheyDailyStatus3DShadowColor(
  OheyDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return isWhite ? AppColors.cFFC2CCD8 : AppColors.cFF16202B;
  }
  return Color.lerp(
    oheyDailyStatus3DSurfaceColor(status, isWhite: isWhite, selected: selected),
    AppColors.black,
    .32,
  )!;
}

Color oheyDailyStatus3DForegroundColor(
  OheyDailyStatus status, {
  required bool isWhite,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return isWhite ? AppColors.cFF111827 : AppColors.cFFE8EEF5;
  }
  return oheyDailyStatusActionForeground;
}

Color oheyDailyStatus3DBorderColor(
  OheyDailyStatus status, {
  required bool selected,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return AppColors.white.withValues(alpha: selected ? .24 : .18);
  }
  return AppColors.white.withValues(alpha: selected ? .30 : .20);
}

List<BoxShadow> oheyDailyStatus3DOuterShadows(
  OheyDailyStatus status, {
  required Color accent,
  required bool selected,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return [
      BoxShadow(
        color: AppColors.black.withValues(alpha: selected ? .34 : .28),
        blurRadius: selected ? 28 : 22,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: AppColors.white.withValues(alpha: selected ? .08 : .05),
        blurRadius: 10,
        offset: const Offset(0, -2),
      ),
    ];
  }
  return [
    BoxShadow(
      color: accent.withValues(alpha: selected ? .34 : .18),
      blurRadius: selected ? 28 : 18,
      offset: const Offset(0, 10),
    ),
  ];
}

List<BoxShadow> oheyDailyStatus3DInnerShadows(
  OheyDailyStatus status, {
  required bool selected,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return [
      BoxShadow(
        color: AppColors.white.withValues(alpha: selected ? .20 : .15),
        blurRadius: selected ? 18 : 14,
        offset: const Offset(0, -1),
      ),
    ];
  }
  return [
    BoxShadow(
      color: AppColors.white.withValues(alpha: selected ? .16 : .10),
      blurRadius: selected ? 18 : 12,
    ),
  ];
}

IconData oheyDailyStatusIcon(OheyDailyStatus status) => switch (status) {
  OheyDailyStatus.available => CupertinoIcons.sparkles,
  OheyDailyStatus.maybeAvailable => CupertinoIcons.drop_fill,
  OheyDailyStatus.dependsOnTime => CupertinoIcons.clock_fill,
  OheyDailyStatus.hasPlans => CupertinoIcons.calendar_today,
  OheyDailyStatus.unselected => CupertinoIcons.circle,
};
