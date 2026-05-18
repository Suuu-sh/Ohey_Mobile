import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'nomo_pop_icon.dart';

class Nomo3DButton extends StatelessWidget {
  const Nomo3DButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 58,
    this.radius = 24,
    this.color = const Color(0xFF12C9A4),
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

class Nomo3DButtonSurface extends StatelessWidget {
  const Nomo3DButtonSurface({
    super.key,
    required this.child,
    required this.onTap,
    this.height = 58,
    this.radius = 24,
    this.color = const Color(0xFF12C9A4),
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
  Widget build(BuildContext context) {
    final canTap = enabled && onTap != null && !isLoading;
    final isUnavailable = !enabled || onTap == null;
    final base = isUnavailable && disabledColor != null
        ? disabledColor!
        : color;
    final bottom = bottomColor ?? Color.lerp(base, Colors.black, .28)!;
    final opacity = isUnavailable && disabledColor != null
        ? disabledOpacity
        : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandsWidth = constraints.hasBoundedWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canTap ? onTap : null,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: expandsWidth ? double.infinity : null,
              height: height + 7,
              decoration: BoxDecoration(
                color: bottom,
                borderRadius: BorderRadius.circular(radius + 1),
                boxShadow:
                    outerShadows ??
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
                  duration: const Duration(milliseconds: 140),
                  width: expandsWidth ? double.infinity : null,
                  height: height,
                  alignment: alignment,
                  padding: padding,
                  decoration: BoxDecoration(
                    color: useGradient ? null : base,
                    gradient: useGradient
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
                        innerShadows ??
                        [
                          BoxShadow(
                            color: base.withValues(alpha: .22),
                            blurRadius: 18,
                            spreadRadius: 1,
                            offset: const Offset(0, 0),
                          ),
                        ],
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: borderColor ?? Colors.white.withValues(alpha: .18),
                      width: borderWidth,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
