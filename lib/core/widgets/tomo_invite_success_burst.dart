import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';
import 'tomo_pop_icon.dart';

typedef TomoInviteBurstBuilder =
    Widget Function(
      BuildContext context,
      TomoInviteBurstRunner runWithBurst,
      Animation<double> flightAnimation,
    );

typedef TomoInviteBurstRunner =
    Future<void> Function(
      FutureOr<void> Function()? action, {
      FutureOr<void> Function()? afterAnimation,
    });

class TomoInviteSuccessBurst extends StatefulWidget {
  const TomoInviteSuccessBurst({
    super.key,
    required this.builder,
    this.burstIcon = CupertinoIcons.paperplane_fill,
    this.burstColor = AppColors.primaryAction,
    this.confettiColors = _defaultConfettiColors,
  });

  final TomoInviteBurstBuilder builder;
  final IconData burstIcon;
  final Color burstColor;
  final List<Color> confettiColors;

  static const _defaultConfettiColors = [
    Color(0xFFFF5EA8),
    Color(0xFF20B9FF),
    Color(0xFFB8FF00),
    Color(0xFF8A62FF),
    Color(0xFFFFD166),
  ];

  @override
  State<TomoInviteSuccessBurst> createState() => _TomoInviteSuccessBurstState();
}

class _TomoInviteSuccessBurstState extends State<TomoInviteSuccessBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(
    FutureOr<void> Function()? action, {
    FutureOr<void> Function()? afterAnimation,
  }) async {
    if (action == null || _running) return;
    setState(() => _running = true);
    try {
      await action();
      if (!mounted) return;
      await _controller.forward(from: 0);
      if (!mounted) return;
      await afterAnimation?.call();
    } catch (_) {
      // The caller shows the failure UI; don't play a success animation.
    } finally {
      if (mounted) setState(() => _running = false);
    }
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
                painter: _InviteConfettiPainter(
                  progress: _controller.value,
                  colors: widget.confettiColors,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TomoInviteFlyingIcon extends StatelessWidget {
  const TomoInviteFlyingIcon({
    super.key,
    required this.animation,
    this.icon = CupertinoIcons.paperplane_fill,
    required this.color,
    required this.size,
  });

  final Animation<double> animation;
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        final opacity = (1 - animation.value).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(36 * t, -34 * t),
            child: Transform.rotate(angle: -.45 * t, child: child),
          ),
        );
      },
      child: TomoGeneratedIcon(icon, color: color, size: size),
    );
  }
}

class _InviteConfettiPainter extends CustomPainter {
  const _InviteConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);
    final ease = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);

    for (var i = 0; i < 18; i++) {
      final angle = (-math.pi * .88) + (math.pi * 1.76) * (i / 17);
      final distance = 18 + (42 + (i % 4) * 8) * ease;
      final drift = math.sin((progress * math.pi * 2) + i) * 7;
      final offset =
          center +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + drift,
          );
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(angle + progress * math.pi * 1.5);
      final w = 4.0 + (i % 3) * 1.5;
      final h = 7.0 + (i % 2) * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _InviteConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}
