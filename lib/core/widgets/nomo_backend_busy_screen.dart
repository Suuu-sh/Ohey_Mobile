import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'nomo_pop_icon.dart';

class NomoBackendBusyScreen extends StatefulWidget {
  const NomoBackendBusyScreen({super.key});

  @override
  State<NomoBackendBusyScreen> createState() => _NomoBackendBusyScreenState();
}

class _NomoBackendBusyScreenState extends State<NomoBackendBusyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF071622),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
          child: Column(
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final bob = math.sin(_controller.value * math.pi * 2) * 8;
                  return Transform.translate(
                    offset: Offset(0, bob),
                    child: child,
                  );
                },
                child: const _BusyMascotIllustration(),
              ),
              const SizedBox(height: 34),
              const Text(
                'ただいま混雑中',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'サーバーを起こしています。\n10秒ほどお待ちください。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .66),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              _LoadingDots(controller: _controller),
              const Spacer(flex: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NomoGeneratedIcon(
                      CupertinoIcons.clock_fill,
                      color: Color(0xFF12C9A4),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'もうすぐ開きます',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) ...[
              _Dot(phase: (controller.value + i * .18) % 1),
              if (i != 2) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    final wave = (math.sin(phase * math.pi * 2) + 1) / 2;
    return Container(
      width: 12 + wave * 5,
      height: 12 + wave * 5,
      decoration: BoxDecoration(
        color: Color.lerp(
          const Color(0xFF12C9A4),
          const Color(0xFF9AF21A),
          wave,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF12C9A4).withValues(alpha: .20 + wave * .25),
            blurRadius: 14 + wave * 12,
          ),
        ],
      ),
    );
  }
}

class _BusyMascotIllustration extends StatelessWidget {
  const _BusyMascotIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 210,
      child: CustomPaint(painter: _BusyMascotPainter()),
    );
  }
}

class _BusyMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shadow = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: .20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .50, h * .88),
        width: w * .64,
        height: h * .12,
      ),
      shadow,
    );

    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * .50, h * .48),
        width: w * .76,
        height: h * .58,
      ),
      Radius.circular(w * .17),
    );
    canvas.drawRRect(
      bubbleRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24E0C4), Color(0xFFB188FF)],
        ).createShader(bubbleRect.outerRect),
    );
    canvas.drawRRect(
      bubbleRect.deflate(5),
      Paint()..color = const Color(0xFF0B2331),
    );

    final face = Paint()..color = const Color(0xFFFFC98B);
    final blush = Paint()
      ..color = const Color(0xFFFF75B5).withValues(alpha: .38);
    final ink = Paint()..color = const Color(0xFF2D1E28);
    final white = Paint()..color = Colors.white;
    final mint = Paint()..color = const Color(0xFF12C9A4);
    final lime = Paint()..color = const Color(0xFF9AF21A);

    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * .50, h * .49),
        width: w * .34,
        height: h * .32,
      ),
      Radius.circular(w * .075),
    );
    canvas.drawRRect(head, face);

    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(w * (.36 + i * .07), h * (.34 + (i.isEven ? 0 : -.012))),
        w * .045,
        ink,
      );
    }

    canvas.drawCircle(Offset(w * .42, h * .49), w * .043, white);
    canvas.drawCircle(Offset(w * .58, h * .49), w * .043, white);
    canvas.drawCircle(Offset(w * .42, h * .49), w * .023, ink);
    canvas.drawCircle(Offset(w * .58, h * .49), w * .023, ink);
    canvas.drawCircle(Offset(w * .43, h * .47), w * .008, white);
    canvas.drawCircle(Offset(w * .59, h * .47), w * .008, white);
    canvas.drawCircle(Offset(w * .37, h * .58), w * .025, blush);
    canvas.drawCircle(Offset(w * .63, h * .58), w * .025, blush);

    final smile = Path()
      ..moveTo(w * .43, h * .60)
      ..quadraticBezierTo(w * .50, h * .67, w * .58, h * .60);
    canvas.drawPath(
      smile,
      Paint()
        ..color = ink.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * .50, h * .72),
        width: w * .30,
        height: h * .20,
      ),
      Radius.circular(w * .09),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFFF75B5));

    // Beer mug / server cup.
    final mug = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * .72, h * .66),
        width: w * .16,
        height: h * .18,
      ),
      Radius.circular(w * .035),
    );
    canvas.drawRRect(mug, Paint()..color = const Color(0xFFFFD166));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .76, h * .61, w * .07, h * .08),
        Radius.circular(w * .03),
      ),
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(w * (.66 + i * .05), h * .56), w * .035, white);
    }

    // Sparkles.
    void sparkle(Offset center, double radius, Paint paint) {
      final path = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..quadraticBezierTo(
          center.dx + radius * .25,
          center.dy - radius * .25,
          center.dx + radius,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx + radius * .25,
          center.dy + radius * .25,
          center.dx,
          center.dy + radius,
        )
        ..quadraticBezierTo(
          center.dx - radius * .25,
          center.dy + radius * .25,
          center.dx - radius,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx - radius * .25,
          center.dy - radius * .25,
          center.dx,
          center.dy - radius,
        )
        ..close();
      canvas.drawPath(path, paint);
    }

    sparkle(Offset(w * .24, h * .28), w * .045, lime);
    sparkle(Offset(w * .80, h * .31), w * .035, mint);
    sparkle(Offset(w * .25, h * .70), w * .030, mint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
