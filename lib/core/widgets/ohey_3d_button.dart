import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'ohey_pop_icon.dart';

Color ohey3DShadowColorFor(
  Color color, {
  double lightnessScale = .62,
  double minLightness = .16,
}) {
  final hsl = HSLColor.fromColor(color);
  if (hsl.saturation < .08) {
    return Color.lerp(
      color,
      const Color(0xFF3F5266),
      .58,
    )!.withValues(alpha: color.a);
  }
  return hsl
      .withSaturation((hsl.saturation * 1.08).clamp(.24, 1.0))
      .withLightness((hsl.lightness * lightnessScale).clamp(minLightness, .42))
      .toColor();
}

class Ohey3DButton extends StatelessWidget {
  const Ohey3DButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.customIcon,
    this.height = 58,
    this.radius = 24,
    this.color = AppColors.primaryAction,
    this.foregroundColor = Colors.white,
    this.shadowColor,
    this.disabledColor,
    this.disabledOpacity = 1,
    this.trailing,
    this.isLoading = false,
    this.enabled = true,
    this.forcePressed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.fontSize = 16,
    this.useGradient = true,
  });

  const Ohey3DButton.secondary({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.customIcon,
    this.height = 58,
    this.radius = 24,
    this.color = const Color(0xFF52606B),
    this.foregroundColor = Colors.white,
    this.shadowColor = const Color(0xFF35434D),
    this.disabledColor,
    this.disabledOpacity = 1,
    this.trailing,
    this.isLoading = false,
    this.enabled = true,
    this.forcePressed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.fontSize = 16,
    this.useGradient = false,
  });

  const Ohey3DButton.destructive({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.customIcon,
    this.height = 58,
    this.radius = 24,
    this.color = AppColors.danger,
    this.foregroundColor = Colors.white,
    this.shadowColor = AppColors.dangerShadow,
    this.disabledColor,
    this.disabledOpacity = 1,
    this.trailing,
    this.isLoading = false,
    this.enabled = true,
    this.forcePressed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.fontSize = 16,
    this.useGradient = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? customIcon;
  final double height;
  final double radius;
  final Color color;
  final Color foregroundColor;
  final Color? shadowColor;
  final Color? disabledColor;
  final double disabledOpacity;
  final Widget? trailing;
  final bool isLoading;
  final bool enabled;
  final bool forcePressed;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    return Ohey3DButtonSurface(
      onTap: onTap,
      height: height,
      radius: radius,
      color: color,
      bottomColor: shadowColor,
      disabledColor: disabledColor,
      disabledOpacity: disabledOpacity,
      isLoading: isLoading,
      enabled: enabled,
      forcePressed: forcePressed,
      padding: padding,
      useGradient: useGradient,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            CupertinoActivityIndicator(color: foregroundColor)
          else ...[
            if (customIcon != null || icon != null) ...[
              customIcon ??
                  OheyGeneratedIcon(
                    icon!,
                    color: foregroundColor,
                    size: fontSize + 7,
                  ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -.2,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing!],
          ],
        ],
      ),
    );
  }
}

class Ohey3DButtonSurface extends StatefulWidget {
  const Ohey3DButtonSurface({
    super.key,
    required this.child,
    required this.onTap,
    this.height = 58,
    this.radius = 24,
    this.color = AppColors.primaryAction,
    this.bottomColor,
    this.disabledColor,
    this.disabledOpacity = 1,
    this.isLoading = false,
    this.enabled = true,
    this.forcePressed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.useGradient = true,
    this.borderColor,
    this.borderWidth = 1,
    this.outerShadows,
    this.innerShadows,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final Color color;
  final Color? bottomColor;
  final Color? disabledColor;
  final double disabledOpacity;
  final bool isLoading;
  final bool enabled;
  final bool forcePressed;
  final EdgeInsetsGeometry padding;
  final bool useGradient;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? outerShadows;
  final List<BoxShadow>? innerShadows;
  final AlignmentGeometry alignment;

  @override
  State<Ohey3DButtonSurface> createState() => _Ohey3DButtonSurfaceState();
}

class _Ohey3DButtonSurfaceState extends State<Ohey3DButtonSurface> {
  static const _minimumPressedDuration = Duration(milliseconds: 120);

  bool _isPressed = false;
  DateTime? _pressedAt;
  int _pressToken = 0;

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) {
      return;
    }
    if (value) {
      _pressedAt = DateTime.now();
      _pressToken++;
    }
    setState(() => _isPressed = value);
  }

  void _releasePressed() {
    final pressedAt = _pressedAt;
    if (pressedAt == null) {
      _setPressed(false);
      return;
    }
    final elapsed = DateTime.now().difference(pressedAt);
    final remaining = _minimumPressedDuration - elapsed;
    final token = _pressToken;
    if (remaining <= Duration.zero) {
      _setPressed(false);
      return;
    }
    Future<void>.delayed(remaining, () {
      if (!mounted || token != _pressToken) return;
      _setPressed(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && widget.onTap != null && !widget.isLoading;
    final isUnavailable = !widget.enabled || widget.onTap == null;
    final isPressed = widget.forcePressed || (canTap && _isPressed);
    final base = isUnavailable && widget.disabledColor != null
        ? widget.disabledColor!
        : widget.color;
    final bottom = widget.bottomColor ?? ohey3DShadowColorFor(base);
    final opacity = isUnavailable && widget.disabledColor != null
        ? widget.disabledOpacity
        : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandsWidth = constraints.hasBoundedWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: canTap ? (_) => _setPressed(true) : null,
          onTapUp: canTap ? (_) => _releasePressed() : null,
          onTapCancel: canTap ? _releasePressed : null,
          onTap: canTap ? widget.onTap : null,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: expandsWidth ? double.infinity : null,
              height: widget.height + 7,
              decoration: BoxDecoration(
                color: isPressed ? Colors.transparent : bottom,
                borderRadius: BorderRadius.circular(widget.radius + 1),
                boxShadow:
                    widget.outerShadows ??
                    [
                      BoxShadow(
                        color: base.withValues(alpha: .22),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(0, isPressed ? 6 : 0, 0),
                  width: expandsWidth ? double.infinity : null,
                  height: widget.height,
                  alignment: widget.alignment,
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: widget.useGradient ? null : base,
                    gradient: widget.useGradient
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(base, Colors.white, .22)!,
                              Color.lerp(base, Colors.white, .10)!,
                              base,
                            ],
                            stops: const [0, .55, 1],
                          )
                        : null,
                    boxShadow:
                        widget.innerShadows ??
                        [
                          BoxShadow(
                            color: base.withValues(alpha: .22),
                            blurRadius: 18,
                            spreadRadius: 1,
                            offset: const Offset(0, 0),
                          ),
                        ],
                    borderRadius: BorderRadius.circular(widget.radius),
                    border: Border.all(
                      color:
                          widget.borderColor ??
                          Colors.white.withValues(alpha: .18),
                      width: widget.borderWidth,
                    ),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
