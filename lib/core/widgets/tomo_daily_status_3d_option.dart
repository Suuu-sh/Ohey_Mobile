import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/tomo_user.dart';
import 'tomo_3d_button.dart';
import 'tomo_pop_icon.dart';

const tomoDailyStatusPink = Color(0xFFFF5EA8);
const tomoDailyStatusBlue = Color(0xFF20B9FF);
const tomoDailyStatusPurple = Color(0xFF8A62FF);
const tomoDailyStatusGreen = Color(0xFF9AF21A);
const tomoDailyStatusBlocked = Color(0xFF2B3644);
const tomoDailyStatusBlockedForeground = Color(0xFF738092);
const tomoDailyStatusActionForeground = Color(0xFF06111D);

class TomoDailyStatus3DOption extends StatelessWidget {
  const TomoDailyStatus3DOption({
    super.key,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
    this.isLoading = false,
    this.showChevron = false,
    this.height = 84,
    this.radius = 28,
  });

  final TomoDailyStatus status;
  final String title;
  final String subtitle;
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
    final accent = tomoDailyStatusBlockAccent(status);
    final foreground = tomoDailyStatus3DForegroundColor(
      status,
      isWhite: isWhite,
    );
    final canTap = enabled && !isLoading && onTap != null;
    final shouldFade = !enabled && !isLoading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: shouldFade ? .46 : 1,
      child: Tomo3DButtonSurface(
        onTap: canTap ? onTap : null,
        enabled: enabled || isLoading,
        height: height,
        radius: radius,
        color: tomoDailyStatus3DSurfaceColor(
          status,
          isWhite: isWhite,
          selected: selected,
        ),
        bottomColor: tomoDailyStatus3DShadowColor(
          status,
          isWhite: isWhite,
          selected: selected,
        ),
        borderColor: tomoDailyStatus3DBorderColor(status, selected: selected),
        borderWidth: 1.2,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        useGradient: true,
        outerShadows: tomoDailyStatus3DOuterShadows(
          status,
          accent: accent,
          selected: selected,
        ),
        innerShadows: tomoDailyStatus3DInnerShadows(status, selected: selected),
        child: Row(
          children: [
            TomoPopIcon(
              icon: tomoDailyStatusIcon(status),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground.withValues(
                        alpha: status == TomoDailyStatus.hasPlans ? .70 : .72,
                      ),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              CupertinoActivityIndicator(color: foreground)
            else if (selected)
              TomoGeneratedIcon(
                CupertinoIcons.checkmark_circle_fill,
                color: foreground,
                size: 24,
              )
            else if (showChevron)
              TomoGeneratedIcon(
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

Color tomoDailyStatusColor(TomoDailyStatus status) => switch (status) {
  TomoDailyStatus.available => tomoDailyStatusPink,
  TomoDailyStatus.maybeAvailable => tomoDailyStatusBlue,
  TomoDailyStatus.dependsOnTime => tomoDailyStatusPurple,
  TomoDailyStatus.hasPlans => tomoDailyStatusBlockedForeground,
  TomoDailyStatus.unselected => tomoDailyStatusGreen,
};

Color tomoDailyStatusBlockAccent(TomoDailyStatus status) => switch (status) {
  TomoDailyStatus.hasPlans => tomoDailyStatusBlocked,
  _ => tomoDailyStatusColor(status),
};

Color tomoDailyStatus3DSurfaceColor(
  TomoDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == TomoDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFFE8EEF5) : const Color(0xFF33404E);
  }
  return tomoDailyStatusColor(status);
}

Color tomoDailyStatus3DShadowColor(
  TomoDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == TomoDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFFC2CCD8) : const Color(0xFF16202B);
  }
  return Color.lerp(
    tomoDailyStatus3DSurfaceColor(status, isWhite: isWhite, selected: selected),
    Colors.black,
    .32,
  )!;
}

Color tomoDailyStatus3DForegroundColor(
  TomoDailyStatus status, {
  required bool isWhite,
}) {
  if (status == TomoDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFF111827) : const Color(0xFFE8EEF5);
  }
  return tomoDailyStatusActionForeground;
}

Color tomoDailyStatus3DBorderColor(
  TomoDailyStatus status, {
  required bool selected,
}) {
  if (status == TomoDailyStatus.hasPlans) {
    return Colors.white.withValues(alpha: selected ? .24 : .18);
  }
  return Colors.white.withValues(alpha: selected ? .30 : .20);
}

List<BoxShadow> tomoDailyStatus3DOuterShadows(
  TomoDailyStatus status, {
  required Color accent,
  required bool selected,
}) {
  if (status == TomoDailyStatus.hasPlans) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: selected ? .34 : .28),
        blurRadius: selected ? 28 : 22,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: selected ? .08 : .05),
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

List<BoxShadow> tomoDailyStatus3DInnerShadows(
  TomoDailyStatus status, {
  required bool selected,
}) {
  if (status == TomoDailyStatus.hasPlans) {
    return [
      BoxShadow(
        color: Colors.white.withValues(alpha: selected ? .20 : .15),
        blurRadius: selected ? 18 : 14,
        offset: const Offset(0, -1),
      ),
    ];
  }
  return [
    BoxShadow(
      color: Colors.white.withValues(alpha: selected ? .16 : .10),
      blurRadius: selected ? 18 : 12,
    ),
  ];
}

IconData tomoDailyStatusIcon(TomoDailyStatus status) => switch (status) {
  TomoDailyStatus.available => CupertinoIcons.sparkles,
  TomoDailyStatus.maybeAvailable => CupertinoIcons.drop_fill,
  TomoDailyStatus.dependsOnTime => CupertinoIcons.clock_fill,
  TomoDailyStatus.hasPlans => CupertinoIcons.calendar_today,
  TomoDailyStatus.unselected => CupertinoIcons.circle,
};
