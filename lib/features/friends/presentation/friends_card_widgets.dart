part of 'friends_screen.dart';

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.status,
    required this.onFavoriteToggle,
    required this.onInvite,
  });

  final NomoFriend friend;
  final _FriendStatus status;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForFriend(friend);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 98),
      child: NomoThemedPanel(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        accentColor: accent,
        backgroundColor: isWhite ? Colors.white : AppColors.darkBackground,
        gradient: isWhite
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF7FBF4)],
              )
            : null,
        borderRadius: 20,
        borderAlpha: isWhite ? .45 : .18,
        glowAlpha: isWhite ? .04 : .08,
        glowBlur: 24,
        glowOffset: const Offset(0, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 62,
              height: 66,
              child: NomoAvatarView(
                avatar: friend.avatar ?? _fallbackAvatarForFriend(friend),
                size: 62,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          friend.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Semantics(
                        button: true,
                        label: friend.isFavorite ? 'お気に入りを解除' : 'お気に入りに追加',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onFavoriteToggle,
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Center(
                              child: _FavoriteStarIcon(
                                filled: friend.isFavorite,
                                color: friend.isFavorite
                                    ? const Color(0xFFFFC700)
                                    : (isWhite
                                          ? const Color(0xFF8C9CAB)
                                          : _FriendsColors.muted),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _StatusPill(status: status, accent: accent),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _InviteButton(
              status: status,
              accent: accent,
              name: friend.name,
              onInvite: onInvite,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.accent});

  final _FriendStatus status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: status.enabled ? .16 : .10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.enabled ? accent : _FriendsColors.muted,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _FavoriteStarIcon extends StatelessWidget {
  const _FavoriteStarIcon({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 21,
    height: 21,
    child: CustomPaint(
      painter: _FavoriteStarPainter(filled: filled, color: color),
    ),
  );
}

class _FavoriteStarPainter extends CustomPainter {
  const _FavoriteStarPainter({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final star = _starPath(size);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (filled) {
      canvas.drawPath(
        star.shift(Offset(size.width * .045, size.height * .055)),
        Paint()
          ..color = const Color(0xFF06111D).withValues(alpha: .26)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(star, Paint()..color = color);
      canvas.drawPath(
        star,
        stroke..color = Colors.white.withValues(alpha: .38),
      );
      canvas.drawCircle(
        Offset(size.width * .39, size.height * .35),
        size.width * .045,
        Paint()..color = Colors.white.withValues(alpha: .62),
      );
      return;
    }

    canvas.drawPath(star, stroke);
  }

  Path _starPath(Size size) {
    final points = <Offset>[
      Offset(size.width * .50, size.height * .08),
      Offset(size.width * .61, size.height * .36),
      Offset(size.width * .91, size.height * .36),
      Offset(size.width * .67, size.height * .55),
      Offset(size.width * .76, size.height * .85),
      Offset(size.width * .50, size.height * .68),
      Offset(size.width * .24, size.height * .85),
      Offset(size.width * .33, size.height * .55),
      Offset(size.width * .09, size.height * .36),
      Offset(size.width * .39, size.height * .36),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _FavoriteStarPainter oldDelegate) {
    return oldDelegate.filled != filled || oldDelegate.color != color;
  }
}

class _InviteButton extends StatelessWidget {
  const _InviteButton({
    required this.status,
    required this.accent,
    required this.name,
    required this.onInvite,
  });

  final _FriendStatus status;
  final Color accent;
  final String name;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final enabled = status.enabled;
    return SizedBox(
      width: 92,
      child: Nomo3DButton(
        label: '誘う',
        icon: CupertinoIcons.paperplane_fill,
        onTap: enabled ? onInvite : null,
        enabled: enabled,
        height: 36,
        radius: 18,
        color: _FriendsColors.lime,
        foregroundColor: _FriendsColors.limeForeground,
        shadowColor: _FriendsColors.limeShadow,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        fontSize: 12,
      ),
    );
  }
}
