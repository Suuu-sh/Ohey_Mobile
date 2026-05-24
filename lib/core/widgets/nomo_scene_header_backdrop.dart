import 'package:flutter/material.dart';

class NomoSceneHeaderBackdrop extends StatelessWidget {
  const NomoSceneHeaderBackdrop({
    super.key,
    required this.assetPath,
    required this.fadeColor,
    required this.accentColor,
    this.shadeColor = const Color(0xFF03101E),
    this.alignment = Alignment.topCenter,
    this.imageTopOffset = 0,
    this.topShadeOpacity = .14,
    this.midShadeOpacity = .06,
    this.fadeStartOpacity = .90,
  });

  final String assetPath;
  final Color fadeColor;
  final Color accentColor;
  final Color shadeColor;
  final Alignment alignment;
  final double imageTopOffset;
  final double topShadeOpacity;
  final double midShadeOpacity;
  final double fadeStartOpacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: imageTopOffset,
            bottom: 0,
            child: ExcludeSemantics(
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: alignment,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.05,
                colors: [
                  accentColor.withValues(alpha: .18),
                  Colors.transparent,
                ],
                stops: const [.06, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  shadeColor.withValues(alpha: topShadeOpacity),
                  shadeColor.withValues(alpha: midShadeOpacity),
                  fadeColor.withValues(alpha: fadeStartOpacity),
                  fadeColor,
                ],
                stops: const [0, .48, .84, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  shadeColor.withValues(alpha: .26),
                  Colors.transparent,
                  shadeColor.withValues(alpha: .16),
                ],
                stops: const [0, .48, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
