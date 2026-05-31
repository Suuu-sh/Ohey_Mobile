import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/ohey_avatar.dart';
import 'ohey_3d_button.dart';
import 'ohey_avatar.dart';
import 'ohey_invite_success_burst.dart';
import 'ohey_pop_icon.dart';

class OheyPostActionPill extends StatelessWidget {
  const OheyPostActionPill({
    super.key,
    required this.semanticLabel,
    required this.label,
    required this.color,
    required this.isWhite,
    this.icon,
    this.customIcon,
    this.burstOnTap = false,
    this.burstIcon = CupertinoIcons.sparkles,
    this.burstColor,
    this.animateIconOnBurst = false,
    this.glowUnderline = false,
    this.onTap,
  });

  final String semanticLabel;
  final String label;
  final IconData? icon;
  final Widget? customIcon;
  final Color color;
  final bool isWhite;
  final bool burstOnTap;
  final IconData burstIcon;
  final Color? burstColor;
  final bool animateIconOnBurst;
  final bool glowUnderline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = oheyPostActionForeground(color);
    final shadowColor = Color.lerp(color, Colors.black, .34)!;
    Widget buildIcon(Animation<double>? iconAnimation) {
      if (customIcon != null) return customIcon!;
      final resolvedIcon = icon ?? CupertinoIcons.circle;
      if (animateIconOnBurst) {
        return _OheyPostLikeBurstIcon(
          animation: iconAnimation ?? const AlwaysStoppedAnimation<double>(0),
          icon: resolvedIcon,
          color: textColor,
          particleColor: burstColor ?? color,
        );
      }
      return OheyPopIcon(
        icon: resolvedIcon,
        color: textColor,
        size: 19,
        iconSize: 16,
        showBubble: false,
      );
    }

    Widget buildButton(
      VoidCallback? effectiveTap, {
      Animation<double>? iconAnimation,
    }) => Ohey3DButtonSurface(
      onTap: effectiveTap,
      height: 38,
      radius: 19,
      color: color,
      bottomColor: shadowColor,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      borderColor: Colors.white.withValues(alpha: .18),
      outerShadows: [
        BoxShadow(
          color: color.withValues(alpha: isWhite ? .18 : .30),
          blurRadius: 20,
          offset: const Offset(0, 9),
        ),
      ],
      innerShadows: [
        BoxShadow(color: Colors.white.withValues(alpha: .14), blurRadius: 14),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildIcon(iconAnimation),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          if (glowUnderline)
            Positioned(
              left: 8,
              right: 8,
              bottom: -7,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFC08BFF),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC08BFF).withValues(alpha: .90),
                      blurRadius: 12,
                      spreadRadius: 1.5,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF75D6).withValues(alpha: .42),
                      blurRadius: 22,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    final child = animateIconOnBurst
        ? _OheyPostInlineIconBurstHost(
            particleColor: burstColor ?? color,
            builder: (context, runWithBurst, iconAnimation) {
              final effectiveTap = onTap == null
                  ? null
                  : burstOnTap
                  ? () => runWithBurst(onTap)
                  : onTap;
              return buildButton(effectiveTap, iconAnimation: iconAnimation);
            },
          )
        : burstOnTap
        ? OheyInviteSuccessBurst(
            burstIcon: burstIcon,
            burstColor: burstColor ?? color,
            confettiColors: [
              color,
              const Color(0xFFFF75B5),
              const Color(0xFFC08BFF),
              const Color(0xFFFFD166),
              Colors.white,
            ],
            builder: (context, runWithBurst, flightAnimation) =>
                buildButton(onTap == null ? null : () => runWithBurst(onTap)),
          )
        : buildButton(onTap);

    return Semantics(button: true, label: semanticLabel, child: child);
  }
}

typedef _OheyPostInlineIconBurstBuilder =
    Widget Function(
      BuildContext context,
      void Function(VoidCallback? action) runWithBurst,
      Animation<double> iconAnimation,
    );

class _OheyPostInlineIconBurstHost extends StatefulWidget {
  const _OheyPostInlineIconBurstHost({
    required this.builder,
    required this.particleColor,
  });

  final _OheyPostInlineIconBurstBuilder builder;
  final Color particleColor;

  @override
  State<_OheyPostInlineIconBurstHost> createState() =>
      _OheyPostInlineIconBurstHostState();
}

class _OheyPostInlineIconBurstHostState
    extends State<_OheyPostInlineIconBurstHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run(VoidCallback? action) {
    if (action == null || _running) return;
    setState(() => _running = true);
    action();
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _running = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.builder(context, _run, _controller),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => CustomPaint(
                painter: _OheyPostFlyingHeartBurstPainter(
                  progress: _controller.value,
                  color: widget.particleColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OheyPostLikeBurstIcon extends StatelessWidget {
  const _OheyPostLikeBurstIcon({
    required this.animation,
    required this.icon,
    required this.color,
    required this.particleColor,
  });

  final Animation<double> animation;
  final IconData icon;
  final Color color;
  final Color particleColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final raw = animation.value.clamp(0.0, 1.0);
        final active = raw > 0 && raw < 1;
        final pop = !active
            ? 0.0
            : raw < .32
            ? Curves.easeOutBack.transform(raw / .32)
            : (1 - Curves.easeOutCubic.transform((raw - .32) / .68)).clamp(
                0.0,
                1.0,
              );
        final bounce = active && raw > .26 && raw < .58
            ? math.sin(((raw - .26) / .32) * math.pi) * .07
            : 0.0;
        final scale = 1 + (.23 * pop) - bounce;
        final angle = active
            ? math.sin(raw * math.pi * 2.4) * .12 * (1 - raw)
            : 0.0;

        return SizedBox(
          width: 19,
          height: 19,
          child: ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(19),
                  painter: _OheyPostLikeIconBurstPainter(
                    progress: raw,
                    color: particleColor,
                  ),
                ),
                Transform.rotate(
                  angle: angle,
                  child: Transform.scale(scale: scale, child: child),
                ),
              ],
            ),
          ),
        );
      },
      child: OheyPopIcon(
        icon: icon,
        color: color,
        size: 19,
        iconSize: 16,
        showBubble: false,
      ),
    );
  }
}

class _OheyPostLikeIconBurstPainter extends CustomPainter {
  const _OheyPostLikeIconBurstPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= .96) return;

    final t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final fade = progress < .68
        ? 1.0
        : ((.96 - progress) / .28).clamp(0.0, 1.0);
    final shortest = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15 * (1 - t)
      ..color = Color.lerp(
        color,
        Colors.white,
        .44,
      )!.withValues(alpha: .42 * fade);
    canvas.drawCircle(center, shortest * (.16 + .28 * t), ringPaint);

    for (var i = 0; i < 8; i++) {
      final angle = (-math.pi / 2) + (math.pi * 2 * i / 8);
      final distance = shortest * (.10 + .36 * t);
      final twinkle = math.sin((progress * math.pi * 2.6) + i) * shortest * .03;
      final offset =
          center +
          Offset(
            math.cos(angle) * (distance + twinkle),
            math.sin(angle) * (distance + twinkle),
          );
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Color.lerp(
          color,
          i.isEven ? Colors.white : const Color(0xFFFF75B5),
          i.isEven ? .62 : .46,
        )!.withValues(alpha: .86 * fade);

      canvas.drawCircle(offset, (1.35 - .42 * t).clamp(.7, 1.35), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OheyPostLikeIconBurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _OheyPostFlyingHeartBurstPainter extends CustomPainter {
  const _OheyPostFlyingHeartBurstPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  static const _particles = [
    _OheyPostFlyingHeartParticle(
      angle: -2.70,
      distance: 48,
      size: 6.4,
      delay: .00,
    ),
    _OheyPostFlyingHeartParticle(
      angle: -2.25,
      distance: 66,
      size: 8.6,
      delay: .02,
    ),
    _OheyPostFlyingHeartParticle(
      angle: -1.82,
      distance: 58,
      size: 6.8,
      delay: .06,
    ),
    _OheyPostFlyingHeartParticle(
      angle: -1.36,
      distance: 74,
      size: 10.4,
      delay: .00,
    ),
    _OheyPostFlyingHeartParticle(
      angle: -0.94,
      distance: 68,
      size: 7.6,
      delay: .04,
    ),
    _OheyPostFlyingHeartParticle(
      angle: -0.42,
      distance: 60,
      size: 6.8,
      delay: .09,
    ),
    _OheyPostFlyingHeartParticle(
      angle: 0.20,
      distance: 48,
      size: 5.8,
      delay: .12,
    ),
    _OheyPostFlyingHeartParticle(
      angle: 0.78,
      distance: 42,
      size: 6.4,
      delay: .15,
    ),
    _OheyPostFlyingHeartParticle(
      angle: 2.62,
      distance: 34,
      size: 5.6,
      delay: .08,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final origin = Offset(22, size.height * .42);
    final flashProgress = (progress / .24).clamp(0.0, 1.0);
    final flashFade = (1 - Curves.easeOutCubic.transform(flashProgress)).clamp(
      0.0,
      1.0,
    );
    if (flashFade > 0) {
      final flashPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * flashFade
        ..color = Color.lerp(
          color,
          Colors.white,
          .72,
        )!.withValues(alpha: .56 * flashFade);
      canvas.drawCircle(origin, 6 + 17 * flashProgress, flashPaint);
    }

    for (var i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      final local = ((progress - particle.delay) / (1 - particle.delay)).clamp(
        0.0,
        1.0,
      );
      if (local <= 0 || local >= 1) continue;

      final ease = Curves.easeOutBack.transform(local.clamp(0.0, .88) / .88);
      final drift = math.sin((local * math.pi * 2.2) + i) * 7;
      final floatUp = math.sin(local * math.pi) * -15;
      final offset =
          origin +
          Offset(
            math.cos(particle.angle) * particle.distance * ease,
            math.sin(particle.angle) * particle.distance * ease +
                drift +
                floatUp,
          );
      final fade = local < .72 ? 1.0 : ((1 - local) / .28).clamp(0.0, 1.0);
      final scale = .58 + math.sin(local * math.pi).clamp(0.0, 1.0) * .62;
      final rotation =
          particle.angle * .20 + math.sin((local + i) * math.pi * 2) * .36;
      final particleColor = Color.lerp(
        color,
        i.isEven ? Colors.white : const Color(0xFFFF75B5),
        i.isEven ? .34 : .22,
      )!.withValues(alpha: .94 * fade);

      _drawFlyingHeart(
        canvas,
        center: offset,
        size: particle.size * scale,
        rotation: rotation,
        color: particleColor,
      );
    }

    for (var i = 0; i < 8; i++) {
      final local = ((progress - i * .035) / .82).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final angle = -math.pi + (math.pi * 1.6 * (i / 7));
      final distance = 18 + 44 * Curves.easeOutCubic.transform(local);
      final point =
          origin +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      final fade = (1 - local).clamp(0.0, 1.0);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: .72 * fade);
      canvas.drawCircle(point, (2.2 - local).clamp(.7, 2.2), paint);
    }
  }

  void _drawFlyingHeart(
    Canvas canvas, {
    required Offset center,
    required double size,
    required double rotation,
    required Color color,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, size * .10)
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .46);

    final path = Path()
      ..moveTo(0, size * .38)
      ..cubicTo(
        -size * .78,
        -size * .24,
        -size * .50,
        -size * .82,
        -size * .10,
        -size * .56,
      )
      ..cubicTo(
        size * .04,
        -size * .46,
        size * .08,
        -size * .30,
        0,
        -size * .17,
      )
      ..cubicTo(
        size * .08,
        -size * .30,
        size * .04,
        -size * .46,
        size * .10,
        -size * .56,
      )
      ..cubicTo(size * .50, -size * .82, size * .78, -size * .24, 0, size * .38)
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(-size * .20, -size * .30),
      Offset(-size * .05, -size * .40),
      highlightPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OheyPostFlyingHeartBurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _OheyPostFlyingHeartParticle {
  const _OheyPostFlyingHeartParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });

  final double angle;
  final double distance;
  final double size;
  final double delay;
}

Color oheyPostActionForeground(Color color) {
  final brightness = ThemeData.estimateBrightnessForColor(color);
  return brightness == Brightness.dark ? Colors.white : const Color(0xFF06111D);
}

class OheyPostShareIcon extends StatelessWidget {
  const OheyPostShareIcon({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: OheyPostShareIconPainter(color)),
  );
}

class OheyPostShareIconPainter extends CustomPainter {
  const OheyPostShareIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * .105;

    final tray = Path()
      ..moveTo(w * .22, h * .62)
      ..lineTo(w * .22, h * .76)
      ..quadraticBezierTo(w * .22, h * .86, w * .32, h * .86)
      ..lineTo(w * .68, h * .86)
      ..quadraticBezierTo(w * .78, h * .86, w * .78, h * .76)
      ..lineTo(w * .78, h * .62);
    canvas.drawPath(tray, stroke);

    canvas.drawLine(Offset(w * .50, h * .66), Offset(w * .50, h * .16), stroke);
    canvas.drawLine(Offset(w * .34, h * .31), Offset(w * .50, h * .16), stroke);
    canvas.drawLine(Offset(w * .66, h * .31), Offset(w * .50, h * .16), stroke);
  }

  @override
  bool shouldRepaint(covariant OheyPostShareIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class OheyPostCompanionPill extends StatelessWidget {
  const OheyPostCompanionPill({
    super.key,
    required this.avatars,
    required this.isWhite,
    this.onTap,
    this.label = 'With',
    this.semanticLabel = '一緒に遊んだフレンズを表示',
    this.color = const Color(0xFFC08BFF),
  });

  final List<OheyAvatar> avatars;
  final bool isWhite;
  final VoidCallback? onTap;
  final String label;
  final String semanticLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = oheyPostActionForeground(color);

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Ohey3DButtonSurface(
        onTap: onTap,
        height: 38,
        radius: 19,
        color: color,
        bottomColor: Color.lerp(color, Colors.black, .34),
        padding: const EdgeInsets.fromLTRB(13, 0, 8, 0),
        borderColor: Colors.white.withValues(alpha: .18),
        outerShadows: [
          BoxShadow(
            color: color.withValues(alpha: isWhite ? .18 : .30),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
        innerShadows: [
          BoxShadow(color: Colors.white.withValues(alpha: .14), blurRadius: 14),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 182),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(width: 7),
              _OheyPostCompanionAvatarStack(avatars: avatars),
            ],
          ),
        ),
      ),
    );
  }
}

class _OheyPostCompanionAvatarStack extends StatelessWidget {
  const _OheyPostCompanionAvatarStack({required this.avatars});

  final List<OheyAvatar> avatars;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    final visible = avatars.take(3).toList(growable: false);
    return SizedBox(
      width: 28.0 + (visible.length - 1) * 18.0,
      height: 28,
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * 18.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF112332),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: OheyAvatarView(avatar: visible[index], size: 28),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
