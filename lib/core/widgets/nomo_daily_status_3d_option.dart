import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/nomo_user.dart';
import 'nomo_3d_button.dart';
import 'nomo_pop_icon.dart';

const nomoDailyStatusPink = Color(0xFFFF5EA8);
const nomoDailyStatusBlue = Color(0xFF20B9FF);
const nomoDailyStatusPurple = Color(0xFF8A62FF);
const nomoDailyStatusGreen = Color(0xFF9AF21A);
const nomoDailyStatusBlocked = Color(0xFF2B3644);
const nomoDailyStatusBlockedForeground = Color(0xFF738092);
const nomoDailyStatusActionForeground = Color(0xFF06111D);

class NomoDailyStatus3DOption extends StatelessWidget {
  const NomoDailyStatus3DOption({
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

  final NomoDailyStatus status;
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
    final accent = nomoDailyStatusBlockAccent(status);
    final foreground = nomoDailyStatus3DForegroundColor(
      status,
      isWhite: isWhite,
    );
    final canTap = enabled && !isLoading && onTap != null;
    final shouldFade = !enabled && !isLoading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: shouldFade ? .46 : 1,
      child: Nomo3DButtonSurface(
        onTap: canTap ? onTap : null,
        enabled: enabled || isLoading,
        height: height,
        radius: radius,
        color: nomoDailyStatus3DSurfaceColor(
          status,
          isWhite: isWhite,
          selected: selected,
        ),
        bottomColor: nomoDailyStatus3DShadowColor(
          status,
          isWhite: isWhite,
          selected: selected,
        ),
        borderColor: nomoDailyStatus3DBorderColor(status, selected: selected),
        borderWidth: 1.2,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        useGradient: true,
        outerShadows: nomoDailyStatus3DOuterShadows(
          status,
          accent: accent,
          selected: selected,
        ),
        innerShadows: nomoDailyStatus3DInnerShadows(status, selected: selected),
        child: Row(
          children: [
            NomoPopIcon(
              icon: nomoDailyStatusIcon(status),
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
                        alpha: status == NomoDailyStatus.hasPlans ? .70 : .72,
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
              NomoGeneratedIcon(
                CupertinoIcons.checkmark_circle_fill,
                color: foreground,
                size: 24,
              )
            else if (showChevron)
              NomoGeneratedIcon(
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

Color nomoDailyStatusColor(NomoDailyStatus status) => switch (status) {
  NomoDailyStatus.available => nomoDailyStatusPink,
  NomoDailyStatus.maybeAvailable => nomoDailyStatusBlue,
  NomoDailyStatus.dependsOnTime => nomoDailyStatusPurple,
  NomoDailyStatus.hasPlans => nomoDailyStatusBlockedForeground,
  NomoDailyStatus.unselected => nomoDailyStatusGreen,
};

Color nomoDailyStatusBlockAccent(NomoDailyStatus status) => switch (status) {
  NomoDailyStatus.hasPlans => nomoDailyStatusBlocked,
  _ => nomoDailyStatusColor(status),
};

Color nomoDailyStatus3DSurfaceColor(
  NomoDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFFE8EEF5) : const Color(0xFF33404E);
  }
  return nomoDailyStatusColor(status);
}

Color nomoDailyStatus3DShadowColor(
  NomoDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFFC2CCD8) : const Color(0xFF16202B);
  }
  return Color.lerp(
    nomoDailyStatus3DSurfaceColor(status, isWhite: isWhite, selected: selected),
    Colors.black,
    .32,
  )!;
}

Color nomoDailyStatus3DForegroundColor(
  NomoDailyStatus status, {
  required bool isWhite,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFF111827) : const Color(0xFFE8EEF5);
  }
  return nomoDailyStatusActionForeground;
}

Color nomoDailyStatus3DBorderColor(
  NomoDailyStatus status, {
  required bool selected,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return Colors.white.withValues(alpha: selected ? .24 : .18);
  }
  return Colors.white.withValues(alpha: selected ? .30 : .20);
}

List<BoxShadow> nomoDailyStatus3DOuterShadows(
  NomoDailyStatus status, {
  required Color accent,
  required bool selected,
}) {
  if (status == NomoDailyStatus.hasPlans) {
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

List<BoxShadow> nomoDailyStatus3DInnerShadows(
  NomoDailyStatus status, {
  required bool selected,
}) {
  if (status == NomoDailyStatus.hasPlans) {
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

IconData nomoDailyStatusIcon(NomoDailyStatus status) => switch (status) {
  NomoDailyStatus.available => CupertinoIcons.sparkles,
  NomoDailyStatus.maybeAvailable => CupertinoIcons.drop_fill,
  NomoDailyStatus.dependsOnTime => CupertinoIcons.clock_fill,
  NomoDailyStatus.hasPlans => CupertinoIcons.calendar_today,
  NomoDailyStatus.unselected => CupertinoIcons.circle,
};
