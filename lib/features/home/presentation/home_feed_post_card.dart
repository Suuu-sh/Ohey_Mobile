part of 'home_screen.dart';

/// A yurubo rendered like an invite card: who and when on top, the plan as
/// the headline, quiet meta lines, attendees, then one primary action.
class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.item,
    required this.isWhite,
    this.onLike,
    this.onShare,
    this.onMore,
    this.onAuthorTap,
  });

  final _FeedItem item;
  final bool isWhite;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final edge = isWhite
        ? AppColors.chunkyBorderLight
        : AppColors.chunkyBorderDark;
    return Semantics(
      label: '${item.userName}のゆるぼ',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: OheyThemedPanel.surfaceColor(isWhite: isWhite),
          borderRadius: BorderRadius.circular(20),
          border: oheyChunkyBorder(edge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _FeedCardAuthorBar(
              item: item,
              isWhite: isWhite,
              onMore: onMore,
              onAuthorTap: onAuthorTap,
            ),
            const SizedBox(height: 12),
            _YuruboCardBody(item: item, isWhite: isWhite),
            const SizedBox(height: 16),
            _FeedCardFooter(
              item: item,
              isWhite: isWhite,
              onLike: onLike,
              onShare: onShare,
            ),
          ],
        ),
      ),
    );
  }
}

class _YuruboCardBody extends StatelessWidget {
  const _YuruboCardBody({required this.item, required this.isWhite});

  final _FeedItem item;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final place = item.place.trim();
    final timeLabel = item.timeLabel.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _yuruboBody(item),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isWhite ? AppColors.cFF3C3C3C : AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.25,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _YuruboMetaLine(
              icon: CupertinoIcons.clock_fill,
              label: timeLabel.isEmpty ? 'いつでも' : timeLabel,
              isWhite: isWhite,
            ),
            _YuruboMetaLine(
              icon: CupertinoIcons.location_solid,
              label: place.isEmpty ? 'どこでも' : place,
              isWhite: isWhite,
            ),
            _YuruboMetaLine(
              icon: item.targetLabel == '全フレンズ'
                  ? CupertinoIcons.person_2_fill
                  : CupertinoIcons.person_3_fill,
              label: item.targetLabel,
              isWhite: isWhite,
            ),
          ],
        ),
      ],
    );
  }
}

class _YuruboMetaLine extends StatelessWidget {
  const _YuruboMetaLine({
    required this.icon,
    required this.label,
    required this.isWhite,
  });

  final IconData icon;
  final String label;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final color = isWhite ? AppColors.cFF777777 : AppColors.cFFAFAFAF;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: isWhite ? AppColors.cFFAFAFAF : color),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedCardAuthorBar extends StatelessWidget {
  const _FeedCardAuthorBar({
    required this.item,
    required this.isWhite,
    this.onMore,
    this.onAuthorTap,
  });

  final _FeedItem item;
  final bool isWhite;
  final VoidCallback? onMore;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final primaryText = isWhite ? AppColors.cFF3C3C3C : AppColors.white;
    final mutedText = isWhite ? AppColors.cFFAFAFAF : AppColors.cFF777777;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: '${item.userName}のプロフィールを開く',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAuthorTap,
              child: Row(
                children: [
                  OheyAvatarView(avatar: item.avatar, size: 34),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      item.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (item.isOfficial) const _OfficialVerifiedBadge(),
                  const SizedBox(width: 6),
                  Text(
                    item.timeAgo,
                    maxLines: 1,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'ゆるぼメニュー',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onMore,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(CupertinoIcons.ellipsis, color: mutedText, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedCardFooter extends StatelessWidget {
  const _FeedCardFooter({
    required this.item,
    required this.isWhite,
    this.onLike,
    this.onShare,
  });

  final _FeedItem item;
  final bool isWhite;
  final VoidCallback? onLike;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final mutedText = isWhite ? AppColors.cFF777777 : AppColors.cFFAFAFAF;
    final isPrimary = !item.liked && !item.ownedByMe;
    final avatars = item.friends
        .map((friend) => friend.avatar)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: avatars.isEmpty
              ? null
              : () => _showFeedCompanionList(context, item),
          child: Row(
            children: [
              if (avatars.isNotEmpty) ...[
                _FeedAttendeeStack(avatars: avatars, isWhite: isWhite),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  _feedReactionSummary(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: item.liked ? '参加申請を取り消す' : 'このゆるぼに参加申請する',
                child: isPrimary
                    ? Ohey3DButton(
                        label: _feedLikeActionLabel(item),
                        icon: CupertinoIcons.hand_raised_fill,
                        onTap: onLike,
                        height: 48,
                        fontSize: 15,
                      )
                    : Ohey3DButton.secondary(
                        label: _feedLikeActionLabel(item),
                        icon: item.ownedByMe
                            ? CupertinoIcons.person_crop_circle_fill
                            : CupertinoIcons.checkmark_alt,
                        foregroundColor: item.ownedByMe
                            ? null
                            : AppColors.brand,
                        onTap: item.ownedByMe ? null : onLike,
                        height: 48,
                        fontSize: 15,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              child: Semantics(
                label: item.isOfficial ? '公式ゆるぼを詳しく見る' : 'ゆるぼを共有',
                child: Ohey3DButton.secondary(
                  label: '',
                  icon: item.isOfficial
                      ? CupertinoIcons.doc_text_fill
                      : CupertinoIcons.share,
                  onTap: onShare,
                  height: 48,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeedAttendeeStack extends StatelessWidget {
  const _FeedAttendeeStack({required this.avatars, required this.isWhite});

  final List<OheyAvatar> avatars;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final visible = avatars.take(3).toList(growable: false);
    const size = 26.0;
    const step = 17.0;
    return SizedBox(
      width: size + (visible.length - 1) * step,
      height: size,
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWhite ? AppColors.white : AppColors.darkBackground,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: OheyAvatarView(avatar: visible[index], size: size),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _feedLikeActionLabel(_FeedItem item) {
  if (item.ownedByMe) return '募集主';
  if (item.liked) {
    return item.myReactionType.isApprovedYuruboReaction ? '参加済み' : '申請中';
  }
  return '参加する';
}

String _feedReactionSummary(_FeedItem item) {
  if (item.isOfficial) {
    return item.likes > 0 ? '${item.likes}人がチェックしました' : 'Oheyからのお知らせです';
  }
  if (item.likes <= 0) {
    return item.ownedByMe ? 'フレンズの申請を待とう' : '参加申請を送ろう';
  }
  return '${item.likes}人が参加確定';
}

class _OfficialVerifiedBadge extends StatelessWidget {
  const _OfficialVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: Semantics(
        label: '公式アカウント',
        child: SizedBox(
          width: 22,
          height: 22,
          child: Stack(
            alignment: Alignment.center,
            children: const [
              Positioned.fill(
                child: CustomPaint(painter: _VerifiedBadgeSeal()),
              ),
              Icon(
                CupertinoIcons.checkmark_alt,
                color: AppColors.white,
                size: 14,
                weight: 900,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedBadgeSeal extends CustomPainter {
  const _VerifiedBadgeSeal();

  static const _pink = AppColors.cFFD9609F;
  static const _pinkLight = AppColors.cFFFF86C8;
  static const _rim = AppColors.cFFFFB8DD;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final seal = _sealPath(size, inset: size.shortestSide * .14);
    final shadow = Paint()
      ..color = _pink.withValues(alpha: .34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(seal.shift(Offset(0, size.height * .10)), shadow);

    final outer = Paint()
      ..color = AppColors.white.withValues(alpha: .95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .10
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(seal, outer);

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_pinkLight, _pink],
      ).createShader(bounds);
    canvas.drawPath(seal, fill);

    final innerRim = Paint()
      ..color = _rim.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .045
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(seal, innerRim);

    canvas.drawCircle(
      Offset(size.width * .36, size.height * .31),
      size.shortestSide * .095,
      Paint()..color = AppColors.white.withValues(alpha: .24),
    );
  }

  Path _sealPath(Size size, {required double inset}) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - inset;
    final path = Path();
    const samples = 48;
    for (var i = 0; i <= samples; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / samples);
      final wave = math.cos(angle * 8);
      final r = radius * (1 + wave * .065);
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _VerifiedBadgeSeal oldDelegate) => false;
}

String _duoStyleBody(_FeedItem item) {
  if (item.isOfficial) {
    return switch (item.prop) {
      _PostProp.spark => 'フレンズとのゆるぼを、もっと楽しく。',
      _PostProp.ticket => 'フレンズと一緒に今月のゆるぼをふり返ろう。',
      _ => item.body,
    };
  }
  return item.body;
}

String _yuruboBody(_FeedItem item) {
  final body = _duoStyleBody(item).trim();
  if (body.isNotEmpty) return body;
  final place = item.place.trim();
  if (place.isNotEmpty) return '$place 行ける人いる？';
  return '今日ゆるく会える人いる？';
}
