import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';

typedef OheyInviteBurstBuilder =
    Widget Function(
      BuildContext context,
      OheyInviteBurstRunner runWithBurst,
      Animation<double> flightAnimation,
    );

typedef OheyInviteBurstRunner =
    Future<void> Function(
      FutureOr<void> Function()? action, {
      FutureOr<void> Function()? afterAnimation,
    });

class OheyInviteSuccessBurst extends StatefulWidget {
  const OheyInviteSuccessBurst({
    super.key,
    required this.builder,
    this.burstIcon = CupertinoIcons.paperplane_fill,
    this.burstColor = AppColors.primaryAction,
    this.confettiColors = _defaultConfettiColors,
  });

  final OheyInviteBurstBuilder builder;
  final IconData burstIcon;
  final Color burstColor;
  final List<Color> confettiColors;

  static const _defaultConfettiColors = [
    AppColors.cFFFF5EA8,
    AppColors.cFF20B9FF,
    AppColors.cFFB8FF00,
    AppColors.cFF8A62FF,
    AppColors.cFFFFD166,
  ];

  @override
  State<OheyInviteSuccessBurst> createState() => _OheyInviteSuccessBurstState();
}

class _OheyInviteSuccessBurstState extends State<OheyInviteSuccessBurst>
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
