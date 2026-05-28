import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/tomo_friend_mood.dart';
import '../theme/app_colors.dart';
import '../models/tomo_avatar.dart';
import 'tomo_avatar.dart';

class TomoFriendAvatar extends StatefulWidget {
  const TomoFriendAvatar({
    super.key,
    required this.mood,
    this.size = 240,
    this.animate = true,
  });

  final TomoFriendMood mood;
  final double size;
  final bool animate;

  @override
  State<TomoFriendAvatar> createState() => _TomoFriendAvatarState();
}

class _TomoFriendAvatarState extends State<TomoFriendAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TomoFriendAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = widget.animate ? _controller.value : 0.0;
        final float = math.sin(t * math.pi) * 8;
        final rotate = math.sin(t * math.pi * 2) * 0.018;

        return Transform.translate(
          offset: Offset(0, -float),
          child: Transform.rotate(angle: rotate, child: child),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _GlowBubble(size: widget.size, mood: widget.mood),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              child: TomoAvatarView(
                key: ValueKey(widget.mood),
                avatar: TomoAvatar.defaultAvatar,
                size: widget.size * 0.86,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({required this.size, required this.mood});

  final double size;
  final TomoFriendMood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.9,
      height: size * 0.9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _moodColor(mood).withValues(alpha: 0.34),
            AppColors.surface.withValues(alpha: 0.1),
          ],
        ),
      ),
    );
  }

  Color _moodColor(TomoFriendMood mood) => switch (mood) {
    TomoFriendMood.lonely => AppColors.sky,
    TomoFriendMood.calm => AppColors.mint,
    TomoFriendMood.smile => AppColors.blush,
    TomoFriendMood.fun => AppColors.peach,
    TomoFriendMood.spark => AppColors.lavender,
    TomoFriendMood.hype => AppColors.lemon,
    TomoFriendMood.tired => AppColors.blue,
    TomoFriendMood.sleep => AppColors.lilac,
  };
}
