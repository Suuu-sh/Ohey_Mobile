import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'nomo_pop_icon.dart';

class Nomo3DButton extends StatelessWidget {
  const Nomo3DButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
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
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.fontSize = 16,
    this.useGradient = true,
  });

  const Nomo3DButton.secondary({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
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
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.fontSize = 16,
    this.useGradient = false,
  });

  const Nomo3DButton.destructive({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
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
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.fontSize = 16,
    this.useGradient = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
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
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    return Nomo3DButtonSurface(
      onTap: onTap,
      height: height,
      radius: radius,
      color: color,
      bottomColor: shadowColor,
      disabledColor: disabledColor,
      disabledOpacity: disabledOpacity,
      isLoading: isLoading,
      enabled: enabled,
      padding: padding,
      useGradient: useGradient,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            CupertinoActivityIndicator(color: foregroundColor)
          else ...[
            if (icon != null) ...[
              NomoGeneratedIcon(
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

class Nomo3DButtonSurface extends StatefulWidget {
  const Nomo3DButtonSurface({
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
  final EdgeInsetsGeometry padding;
  final bool useGradient;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? outerShadows;
  final List<BoxShadow>? innerShadows;
  final AlignmentGeometry alignment;

  @override
  State<Nomo3DButtonSurface> createState() => _Nomo3DButtonSurfaceState();
}

class _Nomo3DButtonSurfaceState extends State<Nomo3DButtonSurface> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) {
      return;
    }
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && widget.onTap != null && !widget.isLoading;
    final isUnavailable = !widget.enabled || widget.onTap == null;
    final isPressed = canTap && _isPressed;
    final base = isUnavailable && widget.disabledColor != null
        ? widget.disabledColor!
        : widget.color;
    final bottom = widget.bottomColor ?? Color.lerp(base, Colors.black, .28)!;
    final opacity = isUnavailable && widget.disabledColor != null
        ? widget.disabledOpacity
        : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandsWidth = constraints.hasBoundedWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: canTap ? (_) => _setPressed(true) : null,
          onTapUp: canTap ? (_) => _setPressed(false) : null,
          onTapCancel: canTap ? () => _setPressed(false) : null,
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
