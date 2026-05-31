part of 'home_screen.dart';

class _FeedSwipeHint extends StatefulWidget {
  const _FeedSwipeHint({required this.isWhite});

  final bool isWhite;

  @override
  State<_FeedSwipeHint> createState() => _FeedSwipeHintState();
}

class _FeedSwipeHintState extends State<_FeedSwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 40000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 60,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final loop = _controller.value;
                final groupWidth = math.min(constraints.maxWidth, 188.0);
                final travel = math.max(0.0, constraints.maxWidth - groupWidth);
                final motion = _oheySwipeHintMotion(loop, travel);
                final arrowPulse = .5 - .5 * math.cos(loop * math.pi * 4);
                final arrowLift = -7 * arrowPulse;
                final arrowOpacity = (.44 + .56 * (1 - arrowPulse)).clamp(
                  0.0,
                  1.0,
                );

                return Transform.translate(
                  offset: Offset(motion.left, 0),
                  child: SizedBox(
                    width: groupWidth,
                    height: 60,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 45,
                          bottom: 18,
                          child: _OheySpeechBubble(
                            isWhite: widget.isWhite,
                            arrowLift: arrowLift,
                            arrowOpacity: arrowOpacity,
                          ),
                        ),
                        Positioned(
                          left: 4,
                          bottom: 0,
                          child: Transform.rotate(
                            angle: motion.tilt,
                            child: _WalkingOhey(
                              step: motion.step,
                              verticalOffset: motion.verticalOffset,
                              facingRight: motion.facingRight,
                              mood: motion.mood,
                              moodProgress: motion.moodProgress,
                            ),
                          ),
                        ),
                        if (motion.mood == _WalkingOheyMood.sleep)
                          Positioned(
                            left: 38,
                            bottom: 42,
                            child: _OheySleepMarks(
                              progress: motion.moodProgress,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FeedSwipeTutorialOverlay extends StatefulWidget {
  const _FeedSwipeTutorialOverlay({
    required this.isWhite,
    required this.onDismissed,
  });

  final bool isWhite;
  final VoidCallback onDismissed;

  @override
  State<_FeedSwipeTutorialOverlay> createState() =>
      _FeedSwipeTutorialOverlayState();
}

class _FeedSwipeTutorialOverlayState extends State<_FeedSwipeTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelBackground = widget.isWhite
        ? Colors.white.withValues(alpha: .95)
        : const Color(0xFF0D1824).withValues(alpha: .94);
    final titleColor = widget.isWhite ? const Color(0xFF20303D) : Colors.white;
    final subColor = widget.isWhite
        ? const Color(0xFF657282)
        : Colors.white.withValues(alpha: .68);
    final borderColor = widget.isWhite
        ? const Color(0xFFDDE6EE)
        : Colors.white.withValues(alpha: .14);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onDismissed,
      onVerticalDragEnd: (_) => widget.onDismissed(),
      child: ColoredBox(
        color: Colors.black.withValues(alpha: widget.isWhite ? .08 : .18),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: OheyPageHeader.contentTopInset(context) + 18,
              bottom: _feedBottomPageInset + 88,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: panelBackground,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .18),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final lift =
                              -10 *
                              Curves.easeInOut.transform(_controller.value);
                          return Transform.translate(
                            offset: Offset(0, lift),
                            child: child,
                          );
                        },
                        child: const OheyPopIcon(
                          icon: CupertinoIcons.arrow_up,
                          color: Color(0xFF22D7C5),
                          size: 54,
                          iconSize: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '上にスワイプで次のゆるぼへ',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: titleColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.5,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '1枚ずつめくって、参加したいゆるぼに反応しよう。',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.45,
                          letterSpacing: -.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: widget.onDismissed,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF22D7C5),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: const Text('わかった'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OheySwipeHintMotion {
  const _OheySwipeHintMotion({
    required this.left,
    required this.step,
    required this.verticalOffset,
    required this.tilt,
    required this.facingRight,
    required this.mood,
    required this.moodProgress,
  });

  final double left;
  final double step;
  final double verticalOffset;
  final double tilt;
  final bool facingRight;
  final _WalkingOheyMood mood;
  final double moodProgress;
}

enum _WalkingOheyMood { walk, lookAround, hop, sleep }

double _segmentProgress(double value, double start, double end) {
  return ((value - start) / (end - start)).clamp(0.0, 1.0);
}

double _easeInOut(double value) {
  return Curves.easeInOutCubic.transform(value.clamp(0.0, 1.0));
}

_OheySwipeHintMotion _oheySwipeHintMotion(double loop, double travel) {
  if (loop < .24) {
    final p = _segmentProgress(loop, 0, .24);
    final eased = _easeInOut(p);
    final step = math.sin(eased * math.pi * 8);
    return _OheySwipeHintMotion(
      left: travel * (.04 + .58 * eased),
      step: step,
      verticalOffset: -step.abs() * 1.15,
      tilt: math.sin(eased * math.pi * 2) * .025,
      facingRight: true,
      mood: _WalkingOheyMood.walk,
      moodProgress: p,
    );
  }

  if (loop < .36) {
    final p = _segmentProgress(loop, .24, .36);
    return _OheySwipeHintMotion(
      left: travel * .62 + math.sin(p * math.pi * 2) * 3,
      step: math.sin(p * math.pi * 2) * .18,
      verticalOffset: -math.sin(p * math.pi).abs() * .55,
      tilt: math.sin(p * math.pi * 2) * .045,
      facingRight: p < .58,
      mood: _WalkingOheyMood.lookAround,
      moodProgress: p,
    );
  }

  if (loop < .47) {
    final p = _segmentProgress(loop, .36, .47);
    final hop = math.sin(p * math.pi * 2).abs();
    final lean = math.sin(p * math.pi * 4);
    return _OheySwipeHintMotion(
      left: travel * .62 + math.sin(p * math.pi * 2) * 4,
      step: lean * .35,
      verticalOffset: -hop * 12,
      tilt: lean * .08,
      facingRight: true,
      mood: _WalkingOheyMood.hop,
      moodProgress: p,
    );
  }

  if (loop < .65) {
    final p = _segmentProgress(loop, .47, .65);
    final eased = _easeInOut(p);
    final step = math.sin(eased * math.pi * 5);
    return _OheySwipeHintMotion(
      left: travel * (.62 + .25 * eased),
      step: step,
      verticalOffset: -step.abs() * 1.05,
      tilt: math.sin(eased * math.pi * 2) * .02,
      facingRight: true,
      mood: _WalkingOheyMood.walk,
      moodProgress: p,
    );
  }

  if (loop < .90) {
    final p = _segmentProgress(loop, .65, .90);
    final breathe = math.sin(p * math.pi * 6);
    return _OheySwipeHintMotion(
      left: travel * .87,
      step: 0,
      verticalOffset: breathe * .45,
      tilt: -.18 + breathe * .015,
      facingRight: true,
      mood: _WalkingOheyMood.sleep,
      moodProgress: p,
    );
  }

  final p = _segmentProgress(loop, .90, 1);
  final eased = _easeInOut(p);
  final step = math.sin(eased * math.pi * 4);
  return _OheySwipeHintMotion(
    left: travel * (.87 - .83 * eased),
    step: step,
    verticalOffset: -step.abs() * 1.1,
    tilt: math.sin(eased * math.pi * 2) * .025,
    facingRight: false,
    mood: _WalkingOheyMood.walk,
    moodProgress: p,
  );
}

class _OheySleepMarks extends StatelessWidget {
  const _OheySleepMarks({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final opacity = (.35 + .65 * math.sin(progress * math.pi).abs()).clamp(
      0.0,
      1.0,
    );
    return Transform.translate(
      offset: Offset(0, -progress * 5),
      child: Opacity(
        opacity: opacity,
        child: Text(
          'Zzz',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
            shadows: [
              Shadow(
                color: const Color(0xFF162130).withValues(alpha: .55),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OheySpeechBubble extends StatelessWidget {
  const _OheySpeechBubble({
    required this.isWhite,
    required this.arrowLift,
    required this.arrowOpacity,
  });

  final bool isWhite;
  final double arrowLift;
  final double arrowOpacity;

  @override
  Widget build(BuildContext context) {
    final textColor = isWhite ? const Color(0xFF243241) : Colors.white;
    final iconColor = isWhite
        ? const Color(0xFF667381)
        : Colors.white.withValues(alpha: .70);
    final backgroundColor = isWhite
        ? Colors.white.withValues(alpha: .92)
        : Colors.white.withValues(alpha: .08);
    final borderColor = isWhite
        ? const Color(0xFFDCE4EC)
        : Colors.white.withValues(alpha: .14);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 5,
          bottom: -4,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  right: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 9, 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '上にスワイプで次へ',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -.18,
                ),
              ),
              const SizedBox(width: 5),
              Transform.translate(
                offset: Offset(0, arrowLift),
                child: Opacity(
                  opacity: arrowOpacity,
                  child: Icon(
                    CupertinoIcons.arrow_up,
                    color: iconColor,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalkingOhey extends StatelessWidget {
  const _WalkingOhey({
    required this.step,
    required this.verticalOffset,
    required this.facingRight,
    required this.mood,
    required this.moodProgress,
  });

  final double step;
  final double verticalOffset;
  final bool facingRight;
  final _WalkingOheyMood mood;
  final double moodProgress;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: SizedBox(
        width: 48,
        height: 56,
        child: CustomPaint(
          painter: _WalkingOheyPainter(
            step: step,
            facingRight: facingRight,
            mood: mood,
            moodProgress: moodProgress,
          ),
        ),
      ),
    );
  }
}

class _WalkingOheyPainter extends CustomPainter {
  const _WalkingOheyPainter({
    required this.step,
    required this.facingRight,
    required this.mood,
    required this.moodProgress,
  });

  final double step;
  final bool facingRight;
  final _WalkingOheyMood mood;
  final double moodProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 48;
    final sy = size.height / 56;
    canvas.save();
    canvas.scale(sx, sy);

    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: .20);
    canvas.drawOval(const Rect.fromLTWH(9, 50, 30, 5), shadowPaint);

    if (!facingRight) {
      canvas.translate(48, 0);
      canvas.scale(-1, 1);
    }

    final isSleeping = mood == _WalkingOheyMood.sleep;
    final isHopping = mood == _WalkingOheyMood.hop;
    final isLookingAround = mood == _WalkingOheyMood.lookAround;
    if (isSleeping) {
      canvas.translate(2, 6);
      canvas.rotate(-.16);
    }

    final shoePaint = Paint()..color = const Color(0xFFFF4CAF);
    final legStride = isSleeping ? 0.0 : step;
    final backFoot = Offset(20 - legStride * 2.8, isSleeping ? 49.5 : 50.5);
    final frontFoot = Offset(30 + legStride * 3.2, isSleeping ? 49.5 : 50.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: backFoot, width: 6.5, height: 5),
        const Radius.circular(3),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: frontFoot, width: 6.5, height: 5),
        const Radius.circular(3),
      ),
      shoePaint,
    );

    final backArmPaint = Paint()
      ..color = const Color(0xFFD4147C).withValues(alpha: .66)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final frontArmPaint = Paint()
      ..color = const Color(0xFFFF4CAF)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    final armSwing = isSleeping ? 0.0 : step;
    final hopArmLift = isHopping
        ? math.sin(moodProgress * math.pi * 2).abs() * 5
        : 0.0;
    canvas.drawLine(
      const Offset(18, 30),
      Offset(12, 35 + armSwing * 2.7 - hopArmLift),
      backArmPaint,
    );
    canvas.drawLine(
      const Offset(34, 30),
      Offset(40, 35 - armSwing * 2.7 - hopArmLift),
      frontArmPaint,
    );

    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(12, 12),
        const Offset(38, 44),
        const [Color(0xFFFF6FC5), Color(0xFFFF1493)],
      );
    final outlinePaint = Paint()
      ..color = const Color(0xFFFFB7DF).withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final body = Path()
      ..moveTo(24, 12)
      ..cubicTo(34, 11, 41, 20, 40, 31)
      ..cubicTo(39, 42, 30, 47, 19, 45)
      ..cubicTo(10, 43, 8, 34, 10, 25)
      ..cubicTo(12, 17, 16, 13, 24, 12)
      ..close();
    if (isLookingAround) {
      canvas.translate(math.sin(moodProgress * math.pi * 2) * 1.1, 0);
    }
    canvas.drawPath(body.shift(const Offset(0, 1.5)), shadowPaint);
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, outlinePaint);

    final stemPaint = Paint()
      ..color = const Color(0xFF78F018)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(27, 14), const Offset(31, 8), stemPaint);
    final leafPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(28, 2),
        const Offset(42, 11),
        const [Color(0xFFB9FF1E), Color(0xFF62D810)],
      );
    canvas.save();
    canvas.translate(35, 7);
    canvas.rotate(-.34);
    canvas.drawOval(const Rect.fromLTWH(-9, -5, 18, 10), leafPaint);
    canvas.restore();

    final eyePaint = Paint()..color = const Color(0xFF111723);
    final highlightPaint = Paint()..color = Colors.white;
    if (isSleeping) {
      final sleepEyePaint = Paint()
        ..color = const Color(0xFF111723)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        const Offset(21, 30),
        const Offset(26, 30),
        sleepEyePaint,
      );
      canvas.drawLine(
        const Offset(31, 29),
        const Offset(37, 29),
        sleepEyePaint,
      );
    } else {
      final sleepyBlink = isLookingAround && moodProgress > .62;
      canvas.drawOval(
        const Rect.fromLTWH(20.5, 25.5, 5, 9),
        Paint()..color = const Color(0xFF111723).withValues(alpha: .22),
      );
      if (sleepyBlink) {
        final blinkPaint = Paint()
          ..color = const Color(0xFF111723)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(29, 30), const Offset(37, 30), blinkPaint);
      } else {
        canvas.drawOval(const Rect.fromLTWH(29, 23, 8.5, 13), eyePaint);
        canvas.drawOval(const Rect.fromLTWH(31, 24, 3.7, 3.7), highlightPaint);
      }
    }

    final mouthPaint = Paint()
      ..color = const Color(0xFF111723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      const Rect.fromLTWH(34, 34, 6, 5),
      math.pi * .14,
      math.pi * .7,
      false,
      mouthPaint,
    );

    if (isSleeping) {
      _drawSleepingMarks(canvas, moodProgress);
    } else if (isHopping) {
      _drawHopSpark(canvas, moodProgress);
    }

    canvas.restore();
  }

  void _drawSleepingMarks(Canvas canvas, double progress) {
    final zOpacity = (.30 + .70 * math.sin(progress * math.pi).abs()).clamp(
      0.0,
      1.0,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Zz',
        style: TextStyle(
          color: Colors.white.withValues(alpha: zOpacity),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: const Color(0xFF162130).withValues(alpha: .40),
              blurRadius: 5,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(32, 5 - progress * 3));
  }

  void _drawHopSpark(Canvas canvas, double progress) {
    final sparklePaint = Paint()
      ..color = const Color(0xFFB9FF1E).withValues(
        alpha: (.35 + .55 * math.sin(progress * math.pi * 2).abs()).clamp(
          0.0,
          1.0,
        ),
      )
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final y = 12 + math.sin(progress * math.pi * 2).abs() * 3;
    canvas.drawLine(Offset(12, y), Offset(12, y + 6), sparklePaint);
    canvas.drawLine(Offset(9, y + 3), Offset(15, y + 3), sparklePaint);
  }

  @override
  bool shouldRepaint(covariant _WalkingOheyPainter oldDelegate) {
    return oldDelegate.step != step ||
        oldDelegate.facingRight != facingRight ||
        oldDelegate.mood != mood ||
        oldDelegate.moodProgress != moodProgress;
  }
}
