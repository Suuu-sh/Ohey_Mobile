part of 'home_screen.dart';

double _feedHeaderScrollInset(BuildContext context) {
  return NomoPageHeader.contentTopInset(context);
}

const _feedBottomPageInset = 124.0;

Widget _buildFeedPage({
  required double topPadding,
  required List<_FeedItem> items,
  required bool isWhite,
  required bool isLoading,
  required ValueChanged<_FeedItem> onLikePressed,
  required ValueChanged<_FeedItem> onSharePressed,
  required ValueChanged<_FeedItem> onMorePressed,
}) {
  if (isLoading && items.isEmpty) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: topPadding, bottom: _feedBottomPageInset),
      children: const [
        Padding(
          padding: EdgeInsets.all(36),
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ],
    );
  }

  if (items.isEmpty) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: topPadding, bottom: _feedBottomPageInset),
      children: [_FeedSectionEmptyState(isWhite: isWhite)],
    );
  }

  return PageView.builder(
    scrollDirection: Axis.vertical,
    physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      return _FeedPostPage(
        topPadding: topPadding,
        item: item,
        isWhite: isWhite,
        showSwipeHint: index < items.length - 1,
        onLike: item.isLikeable ? () => onLikePressed(item) : null,
        onShare: item.id.isEmpty ? null : () => onSharePressed(item),
        onMore: item.id.isEmpty ? null : () => onMorePressed(item),
      );
    },
  );
}

class _FeedPostPage extends StatelessWidget {
  const _FeedPostPage({
    required this.topPadding,
    required this.item,
    required this.isWhite,
    required this.showSwipeHint,
    this.onLike,
    this.onShare,
    this.onMore,
  });

  final double topPadding;
  final _FeedItem item;
  final bool isWhite;
  final bool showSwipeHint;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: topPadding,
            bottom: _feedBottomPageInset,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: _FeedPostCard(
              item: item,
              isWhite: isWhite,
              onLike: onLike,
              onShare: onShare,
              onMore: onMore,
            ),
          ),
        ),
        if (showSwipeHint)
          Positioned(
            left: 12,
            right: 12,
            bottom: _feedBottomPageInset + 4,
            child: _FeedSwipeHint(isWhite: isWhite),
          ),
      ],
    );
  }
}

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
                final groupWidth = math.min(constraints.maxWidth, 168.0);
                final travel = math.max(0.0, constraints.maxWidth - groupWidth);
                final motion = _nomoSwipeHintMotion(loop, travel);
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
                          left: 47,
                          bottom: 18,
                          child: _NomoSpeechBubble(
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
                            child: _WalkingNomo(
                              step: motion.step,
                              verticalOffset: motion.verticalOffset,
                              facingRight: motion.facingRight,
                              mood: motion.mood,
                              moodProgress: motion.moodProgress,
                            ),
                          ),
                        ),
                        if (motion.mood == _WalkingNomoMood.sleep)
                          Positioned(
                            left: 38,
                            bottom: 42,
                            child: _NomoSleepMarks(
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

class _NomoSwipeHintMotion {
  const _NomoSwipeHintMotion({
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
  final _WalkingNomoMood mood;
  final double moodProgress;
}

enum _WalkingNomoMood { walk, lookAround, hop, sleep }

double _segmentProgress(double value, double start, double end) {
  return ((value - start) / (end - start)).clamp(0.0, 1.0);
}

double _easeInOut(double value) {
  return Curves.easeInOutCubic.transform(value.clamp(0.0, 1.0));
}

_NomoSwipeHintMotion _nomoSwipeHintMotion(double loop, double travel) {
  if (loop < .24) {
    final p = _segmentProgress(loop, 0, .24);
    final eased = _easeInOut(p);
    final step = math.sin(eased * math.pi * 8);
    return _NomoSwipeHintMotion(
      left: travel * (.04 + .58 * eased),
      step: step,
      verticalOffset: -step.abs() * 1.15,
      tilt: math.sin(eased * math.pi * 2) * .025,
      facingRight: true,
      mood: _WalkingNomoMood.walk,
      moodProgress: p,
    );
  }

  if (loop < .36) {
    final p = _segmentProgress(loop, .24, .36);
    return _NomoSwipeHintMotion(
      left: travel * .62 + math.sin(p * math.pi * 2) * 3,
      step: math.sin(p * math.pi * 2) * .18,
      verticalOffset: -math.sin(p * math.pi).abs() * .55,
      tilt: math.sin(p * math.pi * 2) * .045,
      facingRight: p < .58,
      mood: _WalkingNomoMood.lookAround,
      moodProgress: p,
    );
  }

  if (loop < .47) {
    final p = _segmentProgress(loop, .36, .47);
    final hop = math.sin(p * math.pi * 2).abs();
    final lean = math.sin(p * math.pi * 4);
    return _NomoSwipeHintMotion(
      left: travel * .62 + math.sin(p * math.pi * 2) * 4,
      step: lean * .35,
      verticalOffset: -hop * 12,
      tilt: lean * .08,
      facingRight: true,
      mood: _WalkingNomoMood.hop,
      moodProgress: p,
    );
  }

  if (loop < .65) {
    final p = _segmentProgress(loop, .47, .65);
    final eased = _easeInOut(p);
    final step = math.sin(eased * math.pi * 5);
    return _NomoSwipeHintMotion(
      left: travel * (.62 + .25 * eased),
      step: step,
      verticalOffset: -step.abs() * 1.05,
      tilt: math.sin(eased * math.pi * 2) * .02,
      facingRight: true,
      mood: _WalkingNomoMood.walk,
      moodProgress: p,
    );
  }

  if (loop < .90) {
    final p = _segmentProgress(loop, .65, .90);
    final breathe = math.sin(p * math.pi * 6);
    return _NomoSwipeHintMotion(
      left: travel * .87,
      step: 0,
      verticalOffset: breathe * .45,
      tilt: -.18 + breathe * .015,
      facingRight: true,
      mood: _WalkingNomoMood.sleep,
      moodProgress: p,
    );
  }

  final p = _segmentProgress(loop, .90, 1);
  final eased = _easeInOut(p);
  final step = math.sin(eased * math.pi * 4);
  return _NomoSwipeHintMotion(
    left: travel * (.87 - .83 * eased),
    step: step,
    verticalOffset: -step.abs() * 1.1,
    tilt: math.sin(eased * math.pi * 2) * .025,
    facingRight: false,
    mood: _WalkingNomoMood.walk,
    moodProgress: p,
  );
}

class _NomoSleepMarks extends StatelessWidget {
  const _NomoSleepMarks({required this.progress});

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

class _NomoSpeechBubble extends StatelessWidget {
  const _NomoSpeechBubble({
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
                '上にスワイプ',
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

class _WalkingNomo extends StatelessWidget {
  const _WalkingNomo({
    required this.step,
    required this.verticalOffset,
    required this.facingRight,
    required this.mood,
    required this.moodProgress,
  });

  final double step;
  final double verticalOffset;
  final bool facingRight;
  final _WalkingNomoMood mood;
  final double moodProgress;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: SizedBox(
        width: 48,
        height: 56,
        child: CustomPaint(
          painter: _WalkingNomoPainter(
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

class _WalkingNomoPainter extends CustomPainter {
  const _WalkingNomoPainter({
    required this.step,
    required this.facingRight,
    required this.mood,
    required this.moodProgress,
  });

  final double step;
  final bool facingRight;
  final _WalkingNomoMood mood;
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

    final isSleeping = mood == _WalkingNomoMood.sleep;
    final isHopping = mood == _WalkingNomoMood.hop;
    final isLookingAround = mood == _WalkingNomoMood.lookAround;
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
  bool shouldRepaint(covariant _WalkingNomoPainter oldDelegate) {
    return oldDelegate.step != step ||
        oldDelegate.facingRight != facingRight ||
        oldDelegate.mood != mood ||
        oldDelegate.moodProgress != moodProgress;
  }
}

class _FeedBackground extends ConsumerWidget {
  const _FeedBackground({required this.child});
  final Widget child;

  _FeedBackground copyWith({Widget? child}) =>
      _FeedBackground(child: child ?? this.child);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isWhite
              ? const [Colors.white, Colors.white, Color(0xFFF7F9FB)]
              : AppColors.darkBackgroundGradient,
        ),
      ),
      child: child,
    );
  }
}

class _FeedHeaderOverlay extends StatelessWidget {
  const _FeedHeaderOverlay({
    required this.child,
    required this.isWhite,
    required this.isTransparent,
  });

  final Widget child;
  final bool isWhite;
  final bool isTransparent;

  @override
  Widget build(BuildContext context) {
    final height = NomoPageHeader.sceneBackdropHeight(context);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height,
      child: IgnorePointer(
        ignoring: isTransparent,
        child: AnimatedOpacity(
          opacity: isTransparent ? 0 : 1,
          duration: Duration(milliseconds: isTransparent ? 420 : 620),
          curve: isTransparent ? Curves.easeOutCubic : Curves.easeOutQuart,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                NomoSceneHeaderBackdrop(
                  assetPath: 'assets/images/feed_header_scene.png',
                  fadeColor: isWhite
                      ? Colors.white
                      : AppColors.darkBackgroundBottom,
                  accentColor: _FeedColors.teal,
                  imageTopOffset: -72,
                  topShadeOpacity: .12,
                  fadeStartOpacity: .92,
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      NomoPageHeader.horizontalPadding,
                      NomoPageHeader.topPadding,
                      NomoPageHeader.horizontalPadding,
                      0,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedSectionEmptyState extends StatelessWidget {
  const _FeedSectionEmptyState({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: _FeedEmptyState(
        icon: CupertinoIcons.photo_on_rectangle,
        isWhite: isWhite,
        title: '飲みログはまだありません',
        message: '自分やフレンズの投稿がフィードに大きく表示されます。',
        accent: _FeedColors.teal,
      ),
    );
  }
}

Future<void> _showFeedPostActions(
  BuildContext context,
  WidgetRef ref,
  _FeedItem item,
) async {
  final body = item.body.trim();
  HapticFeedback.selectionClick();
  final action = await showModalBottomSheet<_FeedPostAction>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (context) => _FeedPostActionsSheet(item: item, body: body),
  );
  if (!context.mounted || action == null) return;

  switch (action) {
    case _FeedPostAction.copy:
      await Clipboard.setData(ClipboardData(text: body));
      if (context.mounted) NomoToast.show(context, 'コメントをコピーしました');
    case _FeedPostAction.delete:
      final confirmed = await _confirmDeleteFeedPost(context);
      if (!confirmed || !context.mounted) return;
      try {
        await ref.read(drinkLogControllerProvider.notifier).deleteLog(item.id);
        ref.invalidate(drinkLogControllerProvider);
        if (context.mounted) NomoToast.show(context, '飲みログを削除しました');
      } catch (error) {
        if (context.mounted) {
          NomoToast.show(context, '飲みログを削除できなかったよ。少し時間をおいて試してみてね');
        }
      }
    case _FeedPostAction.report:
      try {
        await ref.read(drinkLogControllerProvider.notifier).reportLog(item.id);
        if (context.mounted) NomoToast.show(context, '飲みログを報告しました');
      } catch (error) {
        if (context.mounted) {
          NomoToast.show(context, '飲みログを報告できなかったよ。少し時間をおいて試してみてね');
        }
      }
  }
}

Future<bool> _confirmDeleteFeedPost(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (context) => const _FeedDeleteConfirmSheet(),
  );
  return result ?? false;
}
