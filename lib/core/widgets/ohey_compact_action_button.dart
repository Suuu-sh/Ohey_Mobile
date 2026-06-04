import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';
import 'ohey_3d_button.dart';
import 'ohey_invite_success_burst.dart';

class OheyCompactActionButton extends StatelessWidget {
  const OheyCompactActionButton({
    super.key,
    required this.color,
    required this.foregroundColor,
    this.label,
    this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticButton,
    this.height = 38,
    this.radius,
    this.padding = const EdgeInsets.symmetric(horizontal: 13),
    this.shadowColor,
    this.disabledColor,
    this.disabledOpacity = 1,
    this.enabled = true,
    this.forcePressed = false,
    this.fontSize = 13,
    this.useGradient = true,
    this.borderColor,
    this.outerShadowColor,
    this.outerShadowAlpha = .30,
    this.outerShadowBlur = 20,
    this.outerShadowOffset = const Offset(0, 9),
    this.innerShadowAlpha = .14,
    this.burstOnTap = false,
    this.burstIcon = CupertinoIcons.sparkles,
    this.burstColor,
    this.confettiColors,
    this.onBurstComplete,
  }) : assert(label != null || child != null, 'label or child is required');

  final String? label;
  final Widget? child;
  final FutureOr<void> Function()? onTap;
  final String? semanticLabel;
  final bool? semanticButton;
  final double height;
  final double? radius;
  final Color color;
  final Color foregroundColor;
  final Color? shadowColor;
  final Color? disabledColor;
  final double disabledOpacity;
  final bool enabled;
  final bool forcePressed;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final bool useGradient;
  final Color? borderColor;
  final Color? outerShadowColor;
  final double outerShadowAlpha;
  final double outerShadowBlur;
  final Offset outerShadowOffset;
  final double innerShadowAlpha;
  final bool burstOnTap;
  final IconData burstIcon;
  final Color? burstColor;
  final List<Color>? confettiColors;
  final FutureOr<void> Function()? onBurstComplete;

  VoidCallback? _asVoidCallback(FutureOr<void> Function()? action) {
    if (action == null) return null;
    return () {
      final result = action();
      if (result is Future<void>) unawaited(result);
    };
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? height / 2;
    final effectiveShadowColor =
        shadowColor ??
        Color.lerp(color, AppColors.black, .34) ??
        AppColors.black;
    final content =
        child ??
        Text(
          label!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foregroundColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -.2,
            height: 1,
          ),
        );

    Widget buildSurface(VoidCallback? effectiveTap) => Ohey3DButtonSurface(
      onTap: effectiveTap,
      height: height,
      radius: effectiveRadius,
      color: color,
      bottomColor: effectiveShadowColor,
      disabledColor: disabledColor,
      disabledOpacity: disabledOpacity,
      enabled: enabled,
      forcePressed: forcePressed,
      padding: padding,
      useGradient: useGradient,
      borderColor: borderColor ?? AppColors.white.withValues(alpha: .18),
      outerShadows: [
        BoxShadow(
          color: (outerShadowColor ?? color).withValues(
            alpha: outerShadowAlpha,
          ),
          blurRadius: outerShadowBlur,
          offset: outerShadowOffset,
        ),
      ],
      innerShadows: [
        BoxShadow(
          color: AppColors.white.withValues(alpha: innerShadowAlpha),
          blurRadius: 14,
        ),
      ],
      child: content,
    );

    final Widget button = burstOnTap
        ? OheyInviteSuccessBurst(
            burstIcon: burstIcon,
            burstColor: burstColor ?? color,
            confettiColors:
                confettiColors ??
                [
                  color,
                  AppColors.cFFFF75B5,
                  AppColors.cFFC08BFF,
                  AppColors.cFFFFD166,
                  AppColors.white,
                ],
            builder: (context, runWithBurst, flightAnimation) => buildSurface(
              onTap == null
                  ? null
                  : () => runWithBurst(onTap, afterAnimation: onBurstComplete),
            ),
          )
        : buildSurface(_asVoidCallback(onTap));

    if (semanticLabel == null) return button;
    return Semantics(
      button: semanticButton ?? onTap != null,
      label: semanticLabel,
      child: button,
    );
  }
}
