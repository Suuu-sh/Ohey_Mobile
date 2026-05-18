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
    this.disabledOpacity = .62,
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
    final active = enabled && onTap != null && !isLoading;
    final base = active ? color : disabledColor ?? const Color(0xFF52606F);
    final bottom = shadowColor ?? Color.lerp(base, Colors.black, .28)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandsWidth = constraints.hasBoundedWidth;

        return GestureDetector(
          onTap: active ? onTap : null,
          child: Opacity(
            opacity: active ? 1 : disabledOpacity,
            child: Container(
              width: expandsWidth ? double.infinity : null,
              height: height + 7,
              decoration: BoxDecoration(
                color: bottom,
                borderRadius: BorderRadius.circular(radius + 1),
                boxShadow: [
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
                    boxShadow: [
                      BoxShadow(
                        color: base.withValues(alpha: .22),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .18),
                    ),
                  ),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
