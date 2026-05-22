import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
      backgroundColor: AppColors.darkBackground,
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

  static const _assetPath = 'assets/images/backend_busy_nomo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: 230,
      height: 210,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
