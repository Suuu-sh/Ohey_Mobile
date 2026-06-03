part of 'home_screen.dart';

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.item,
    required this.isWhite,
    this.compactYurubo = false,
    this.onLike,
    this.onShare,
    this.onMore,
    this.onAuthorTap,
  });

  final _FeedItem item;
  final bool isWhite;
  final bool compactYurubo;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = OheyThemedPanel.surfaceColor(isWhite: isWhite);
    return Semantics(
      label: '${item.userName}のゆるぼ',
      child: OheyThemedPanel(
        accentColor: _FeedColors.teal,
        backgroundColor: surfaceColor,
        borderRadius: 0,
        border: OheyThemedPanelBorder.horizontal,
        borderWidth: 0,
        borderAlpha: 0,
        glowAlpha: 0,
        glowBlur: 24,
        glowOffset: const Offset(0, 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _FeedCardAuthorBar(
                  item: item,
                  isWhite: isWhite,
                  compactYurubo: compactYurubo,
                  onMore: onMore,
                  onAuthorTap: onAuthorTap,
                ),
                if (compactYurubo)
                  _YuruboCardBody(item: item, isWhite: isWhite)
                else
                  _FeedMemoryBody(item: item, isWhite: isWhite, onLike: onLike),
                _FeedCardFooter(
                  item: item,
                  isWhite: isWhite,
                  compactYurubo: compactYurubo,
                  onLike: onLike,
                  onShare: onShare,
                ),
              ],
            ),
            if (compactYurubo) const _YuruboBlockGlowUnderline(),
          ],
        ),
      ),
    );
  }
}

class _YuruboBlockGlowUnderline extends StatelessWidget {
  const _YuruboBlockGlowUnderline();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            color: AppColors.cFFC08BFF.withValues(alpha: .82),
            boxShadow: [
              BoxShadow(
                color: AppColors.cFFC08BFF.withValues(alpha: .58),
                blurRadius: 9,
                spreadRadius: .4,
              ),
            ],
          ),
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
    final primaryText = isWhite ? AppColors.cFF17202B : AppColors.white;
    final body = _yuruboBody(item);
    final place = item.place.trim();
    final timeLabel = item.timeLabel.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final chipWidth = (constraints.maxWidth - 12) / 3;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: chipWidth),
                    child: _YuruboMetaChip(
                      icon: item.targetLabel == '全フレンズ'
                          ? CupertinoIcons.person_2_fill
                          : CupertinoIcons.person_3_fill,
                      label: item.targetLabel,
                      color: _feedPrimaryActionColor,
                      isWhite: isWhite,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: chipWidth),
                    child: _YuruboMetaChip(
                      icon: CupertinoIcons.location_fill,
                      label: place.isEmpty ? 'どこでも' : place,
                      color: _FeedColors.teal,
                      isWhite: isWhite,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: chipWidth),
                    child: _YuruboMetaChip(
                      icon: CupertinoIcons.clock_fill,
                      label: timeLabel.isEmpty ? 'いつでも' : timeLabel,
                      color: _FeedColors.teal,
                      isWhite: isWhite,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.18,
              letterSpacing: -.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _YuruboMetaChip extends StatelessWidget {
  const _YuruboMetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isWhite,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final foreground = isWhite
        ? Color.lerp(color, AppColors.black, .20)!
        : AppColors.white;
    return Container(
      constraints: const BoxConstraints(minWidth: 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isWhite ? .13 : .22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: isWhite ? .32 : .42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
                height: 1,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedMemoryBody extends StatelessWidget {
  const _FeedMemoryBody({
    required this.item,
    required this.isWhite,
    this.onLike,
  });

  final _FeedItem item;
  final bool isWhite;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    final primaryText = isWhite ? AppColors.cFF17202B : AppColors.white;
    final secondaryText = isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .66);
    final body = _duoStyleBody(item).trim();
    final title = body.isNotEmpty
        ? body
        : (item.place.trim().isNotEmpty ? item.place.trim() : '思い出を記録しました');
    final metadata = [
      item.timeAgo,
      if (item.place.trim().isNotEmpty) item.place.trim(),
    ].join(' ・ ');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onLike,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.accent.withValues(alpha: isWhite ? .12 : .20),
              isWhite
                  ? AppColors.cFFF8FAFD
                  : AppColors.cFF0A1521.withValues(alpha: .78),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: item.accent.withValues(alpha: isWhite ? .24 : .30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OheyPopIcon(
                  icon: CupertinoIcons.text_bubble_fill,
                  color: item.accent,
                  size: 34,
                  iconSize: 18,
                  shadow: false,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    metadata,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: secondaryText,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.18,
                letterSpacing: -.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCardAuthorBar extends StatelessWidget {
  const _FeedCardAuthorBar({
    required this.item,
    required this.isWhite,
    this.compactYurubo = false,
    this.onMore,
    this.onAuthorTap,
  });

  final _FeedItem item;
  final bool isWhite;
  final bool compactYurubo;
  final VoidCallback? onMore;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final primaryText = isWhite ? AppColors.cFF17202B : AppColors.white;
    final secondaryText = isWhite
        ? AppColors.cFF778393
        : AppColors.white.withValues(alpha: .62);
    const menuAccent = AppColors.cFFC08BFF;
    final iconColor = isWhite
        ? Color.lerp(menuAccent, AppColors.black, .18)!
        : Color.lerp(menuAccent, AppColors.white, .18)!;
    final place = item.place.trim();
    final metadataLabel = compactYurubo
        ? (place.isEmpty ? 'ゆるぼ' : place)
        : item.isOfficial
        ? (place.isEmpty ? 'Ohey公式からのお知らせ' : 'Ohey公式 ・ $place')
        : place.isEmpty
        ? 'ゆるぼ'
        : place;
    final kind = item.postKind;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                    _AvatarBubble(
                      avatar: item.avatar,
                      size: 40,
                      glowColor: item.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  item.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: primaryText,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w900,
                                        height: 1.05,
                                        letterSpacing: -.25,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              _FeedPostKindBadge(kind: kind, isWhite: isWhite),
                              if (item.isOfficial)
                                const _OfficialVerifiedBadge(),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            metadataLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: secondaryText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                          ),
                        ],
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
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  CupertinoIcons.ellipsis,
                  color: iconColor,
                  size: 27,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCardFooter extends StatelessWidget {
  const _FeedCardFooter({
    required this.item,
    required this.isWhite,
    this.compactYurubo = false,
    this.onLike,
    this.onShare,
  });

  final _FeedItem item;
  final bool isWhite;
  final bool compactYurubo;
  final VoidCallback? onLike;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final primaryText = isWhite ? AppColors.cFF17202B : AppColors.white;
    final secondaryText = isWhite
        ? AppColors.cFF778393
        : AppColors.white.withValues(alpha: .62);
    const feedActionPurple = AppColors.cFFC08BFF;
    final likeAccent = item.liked
        ? Color.lerp(AppColors.danger, feedActionPurple, .58)!
        : feedActionPurple;
    final shareAccent = Color.lerp(AppColors.info, feedActionPurple, .58)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OheyPostActionPill(
                semanticLabel: item.liked ? '参加申請を取り消す' : 'このゆるぼに参加申請する',
                icon: item.liked
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                label: compactYurubo
                    ? _yuruboInterestedActionLabel(item)
                    : _feedLikeActionLabel(item),
                color: likeAccent,
                isWhite: isWhite,
                burstOnTap: !item.liked,
                burstIcon: CupertinoIcons.heart_fill,
                burstColor: likeAccent,
                animateIconOnBurst: true,
                onTap: onLike,
              ),
              const SizedBox(width: 8),
              OheyPostActionPill(
                semanticLabel: compactYurubo
                    ? 'このゆるぼを共有'
                    : item.isOfficial
                    ? '公式ゆるぼを詳しく見る'
                    : item.ownedByMe
                    ? 'ゆるぼを共有'
                    : 'ゆるぼを共有',
                customIcon: item.isOfficial
                    ? null
                    : OheyPostShareIcon(
                        color: oheyPostActionForeground(shareAccent),
                        size: 19,
                      ),
                icon: item.isOfficial ? CupertinoIcons.doc_text_fill : null,
                label: compactYurubo ? '共有' : _feedShareActionLabel(item),
                color: shareAccent,
                isWhite: isWhite,
                onTap: onShare,
              ),
              const Spacer(),
              if (item.friends.isNotEmpty) ...[
                const SizedBox(width: 8),
                OheyPostCompanionPill(
                  avatars: item.friends
                      .map((friend) => friend.avatar)
                      .toList(growable: false),
                  isWhite: isWhite,
                  onTap: () => _showFeedCompanionList(context, item),
                ),
              ],
            ],
          ),
          if (!compactYurubo) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _feedReactionSummary(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: item.likes > 0 ? primaryText : secondaryText,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  item.timeAgo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: secondaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ],
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
  return '参加申請';
}

String _feedShareActionLabel(_FeedItem item) {
  if (item.isOfficial) return '詳しく';
  return '共有';
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

class _FeedPostKindBadge extends StatelessWidget {
  const _FeedPostKindBadge({required this.kind, required this.isWhite});

  final _FeedPostKind kind;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      _FeedPostKind.mine => '自分',
      _FeedPostKind.friend => 'フレンズ',
      _FeedPostKind.official => '公式',
    };
    final color = switch (kind) {
      _FeedPostKind.mine => AppColors.primaryAction,
      _FeedPostKind.friend => AppColors.invite,
      _FeedPostKind.official => AppColors.info,
    };
    final textColor = isWhite
        ? Color.lerp(color, AppColors.black, .22)!
        : AppColors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isWhite ? .14 : .22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: isWhite ? .34 : .42)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: -.1,
        ),
      ),
    );
  }
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

  static const _pink = AppColors.cFFFF5EA8;
  static const _pinkLight = AppColors.cFFFF83C0;
  static const _rim = AppColors.cFFFFC1DC;

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

String _yuruboInterestedActionLabel(_FeedItem item) {
  if (item.ownedByMe) return '募集主';
  if (item.liked) {
    return item.myReactionType.isApprovedYuruboReaction ? '参加済み' : '申請中';
  }
  return '参加申請';
}
