import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Brightness, Theme;

import '../theme/app_colors.dart';
import 'ohey_pop_icon.dart';

/// Darker "lip" color drawn under a chunky button face.
Color ohey3DShadowColorFor(
  Color color, {
  double lightnessScale = .80,
  double minLightness = .16,
}) {
  final hsl = HSLColor.fromColor(color);
  if (hsl.saturation < .08) {
    return hsl
        .withLightness((hsl.lightness * .86).clamp(minLightness, .92))
        .toColor()
        .withValues(alpha: color.a);
  }
  return hsl
      .withLightness((hsl.lightness * lightnessScale).clamp(minLightness, .62))
      .toColor();
}

/// Depth of the solid lip under every chunky (Duolingo-style) surface.
const double oheyChunkyLipDepth = 4;

class Ohey3DButton extends StatelessWidget {
  const Ohey3DButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.customIcon,
    this.height = 54,
    this.radius = 16,
    this.color = AppColors.primaryAction,
    this.foregroundColor = AppColors.white,
    this.shadowColor,
    this.disabledColor,
    this.disabledOpacity = 1,
    this.trailing,
    this.isLoading = false,
    this.enabled = true,
    this.forcePressed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.fontSize = 16,
  });

  const Ohey3DButton.secondary({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.customIcon,
    this.height = 54,
    this.radius = 16,
    this.color,
    this.foregroundColor,
    this.shadowColor,
    this.disabledColor,
    this.disabledOpacity = 1,
    this.trailing,
    this.isLoading = false,
    this.enabled = true,
    this.forcePressed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.fontSize = 16,
  });

  const Ohey3DButton.destructive({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.customIcon,
    this.height = 54,
    this.radius = 16,
    this.color = AppColors.danger,
    this.foregroundColor = AppColors.white,
    this.shadowColor = AppColors.dangerShadow,
    this.disabledColor,
    this.disabledOpacity = 1,
    this.trailing,
    this.isLoading = false,
    this.enabled = true,
    this.forcePressed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? customIcon;
  final double height;
  final double radius;

  /// Face color. `null` (the [Ohey3DButton.secondary] default) draws the
  /// neutral outlined button: page-colored face with a grey edge and lip.
  final Color? color;
  final Color? foregroundColor;
  final Color? shadowColor;
  final Color? disabledColor;
  final double disabledOpacity;
  final Widget? trailing;
  final bool isLoading;
  final bool enabled;
  final bool forcePressed;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final isNeutral = color == null;
    final neutralEdge = isWhite
        ? AppColors.chunkyBorderLight
        : AppColors.chunkyBorderDark;
    final foregroundColor =
        this.foregroundColor ??
        (isNeutral && isWhite ? AppColors.ink : AppColors.white);
    return Ohey3DButtonSurface(
      onTap: onTap,
      height: height,
      radius: radius,
      color: color ?? (isWhite ? AppColors.white : AppColors.darkBackground),
      bottomColor: shadowColor ?? (isNeutral ? neutralEdge : null),
      borderColor: isNeutral ? neutralEdge : null,
      disabledColor: disabledColor,
      disabledOpacity: disabledOpacity,
      isLoading: isLoading,
      enabled: enabled,
      forcePressed: forcePressed,
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            _OheyButtonLoadingDots(color: foregroundColor)
          else ...[
            if (customIcon != null || icon != null) ...[
              customIcon ??
                  OheyGeneratedIcon(
                    icon!,
                    color: foregroundColor,
                    size: fontSize + 7,
                  ),
              if (label.isNotEmpty) const SizedBox(width: 10),
            ],
            if (label.isNotEmpty)
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
    this.height = 54,
    this.radius = 16,
    this.color = AppColors.primaryAction,
    this.bottomColor,
    this.disabledColor,
    this.disabledOpacity = 1,
    this.isLoading = false,
    this.enabled = true,
    this.forcePressed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.borderColor,
    this.borderWidth = 2,
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
  final Color? borderColor;
  final double borderWidth;
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
    final lip = widget.bottomColor ?? ohey3DShadowColorFor(base);
    final opacity = isUnavailable && widget.disabledColor != null
        ? widget.disabledOpacity
        : 1.0;
    final borderColor = widget.borderColor;
    final radius = BorderRadius.circular(widget.radius);

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
            child: Stack(
              children: [
                Positioned.fill(
                  top: oheyChunkyLipDepth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: lip, borderRadius: radius),
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    top: isPressed ? oheyChunkyLipDepth : 0,
                    bottom: isPressed ? 0 : oheyChunkyLipDepth,
                  ),
                  child: Container(
                    width: expandsWidth ? double.infinity : null,
                    height: widget.height,
                    alignment: widget.alignment,
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: radius,
                      border: borderColor == null
                          ? null
                          : Border.all(
                              color: borderColor,
                              width: widget.borderWidth,
                            ),
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OheyButtonLoadingDots extends StatefulWidget {
  const _OheyButtonLoadingDots({required this.color});

  final Color color;

  @override
  State<_OheyButtonLoadingDots> createState() => _OheyButtonLoadingDotsState();
}

class _OheyButtonLoadingDotsState extends State<_OheyButtonLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              _LoadingDot(
                color: widget.color,
                progress: (_controller.value + i * .18) % 1,
              ),
              if (i != 2) const SizedBox(width: 5),
            ],
          ],
        );
      },
    );
  }
}

class _LoadingDot extends StatelessWidget {
  const _LoadingDot({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final wave = Curves.easeInOut.transform(
      progress < .5 ? progress * 2 : (1 - progress) * 2,
    );
    return Transform.translate(
      offset: Offset(0, -5 * wave),
      child: Container(
        width: 7 + 2 * wave,
        height: 7 + 2 * wave,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .56 + .38 * wave),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
