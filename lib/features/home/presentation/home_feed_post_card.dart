part of 'home_screen.dart';

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
    final photoPath = item.photoAssetPath;
    final hasPhoto = _isDisplayablePostPhoto(photoPath);
    final caption = _feedCardCaption(item);
    final surfaceColor = OheyThemedPanel.surfaceColor(isWhite: isWhite);
    return Semantics(
      label: '${item.userName}の思い出',
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
            _FeedPhotoLikeSurface(
              item: item,
              hasPhoto: hasPhoto,
              photoPath: photoPath,
              caption: caption,
              onLike: onLike,
            ),
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

class _FeedPhotoLikeSurface extends StatefulWidget {
  const _FeedPhotoLikeSurface({
    required this.item,
    required this.hasPhoto,
    required this.photoPath,
    required this.caption,
    this.onLike,
  });

  final _FeedItem item;
  final bool hasPhoto;
  final String? photoPath;
  final String caption;
  final VoidCallback? onLike;

  @override
  State<_FeedPhotoLikeSurface> createState() => _FeedPhotoLikeSurfaceState();
}

class _FeedPhotoLikeSurfaceState extends State<_FeedPhotoLikeSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (widget.onLike == null) return;
    final wasLiked = widget.item.liked;
    widget.onLike!();
    if (wasLiked) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: widget.onLike == null ? null : _handleDoubleTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.hasPhoto
                  ? _PostPhoto(path: widget.photoPath!)
                  : _FeedPhotoPlaceholder(accent: widget.item.accent),
              _FeedPhotoCaptionOverlay(
                caption: widget.caption,
                captionY: widget.item.captionY,
              ),
              _FeedPhotoDoubleTapLikeBurst(
                animation: _controller,
                color: Color.lerp(
                  AppColors.danger,
                  const Color(0xFFC08BFF),
                  .42,
                )!,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedPhotoDoubleTapLikeBurst extends StatelessWidget {
  const _FeedPhotoDoubleTapLikeBurst({
    required this.animation,
    required this.color,
  });

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final raw = animation.value.clamp(0.0, 1.0);
          if (raw <= 0 || raw >= 1) return const SizedBox.shrink();

          final scaleIn = Curves.easeOutBack.transform((raw / .34).clamp(0, 1));
          final fadeOut = raw < .58 ? 1.0 : ((1 - raw) / .42).clamp(0.0, 1.0);
          final scale = .58 + scaleIn * .62 + raw * .16;

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _FeedPhotoLikeParticlePainter(
                  progress: raw,
                  color: color,
                ),
              ),
              Center(
                child: Opacity(
                  opacity: fadeOut,
                  child: Transform.rotate(
                    angle: math.sin(raw * math.pi * 2) * .08 * (1 - raw),
                    child: Transform.scale(scale: scale, child: child),
                  ),
                ),
              ),
            ],
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .42),
                blurRadius: 34,
                spreadRadius: 8,
              ),
            ],
          ),
          child: OheyPopIcon(
            icon: CupertinoIcons.heart_fill,
            color: color,
            size: 96,
            iconSize: 78,
            showBubble: false,
          ),
        ),
      ),
    );
  }
}

class _FeedPhotoLikeParticlePainter extends CustomPainter {
  const _FeedPhotoLikeParticlePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);
    final ease = Curves.easeOutCubic.transform(progress);
    final fade = progress < .68 ? 1.0 : ((1 - progress) / .32).clamp(0.0, 1.0);

    for (var i = 0; i < 14; i++) {
      final angle = -math.pi + (math.pi * 2 * (i / 14));
      final distance = 40 + (34 + (i % 4) * 9) * ease;
      final drift = math.sin(progress * math.pi * 2 + i) * 9;
      final point =
          center +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + drift,
          );
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Color.lerp(
          color,
          i.isEven ? Colors.white : const Color(0xFFFF75B5),
          i.isEven ? .56 : .30,
        )!.withValues(alpha: .86 * fade);
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + progress * math.pi);
      _drawParticleHeart(canvas, paint, 5.2 + (i % 3) * 1.6);
      canvas.restore();
    }
  }

  void _drawParticleHeart(Canvas canvas, Paint paint, double size) {
    final path = Path()
      ..moveTo(0, size * .42)
      ..cubicTo(
        -size * .82,
        -size * .18,
        -size * .46,
        -size * .78,
        0,
        -size * .28,
      )
      ..cubicTo(size * .46, -size * .78, size * .82, -size * .18, 0, size * .42)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FeedPhotoLikeParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _FeedPhotoCaptionOverlay extends StatelessWidget {
  const _FeedPhotoCaptionOverlay({
    required this.caption,
    required this.captionY,
  });

  final String caption;
  final double captionY;

  @override
  Widget build(BuildContext context) {
    final body = caption.trim();
    if (body.isEmpty) return const SizedBox.shrink();

    const bandHeight = 52.0;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxTop = (constraints.maxHeight - bandHeight).clamp(
            0.0,
            double.infinity,
          );
          final top = maxTop * captionY.clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: top,
                height: bandHeight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  color: Colors.black.withValues(alpha: .46),
                  alignment: Alignment.center,
                  child: Text(
                    body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -.65,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
    final primaryText = isWhite ? const Color(0xFF17202B) : Colors.white;
    final secondaryText = isWhite
        ? const Color(0xFF778393)
        : Colors.white.withValues(alpha: .62);
    const menuAccent = Color(0xFFC08BFF);
    final iconColor = isWhite
        ? Color.lerp(menuAccent, Colors.black, .18)!
        : Color.lerp(menuAccent, Colors.white, .18)!;
    final place = item.place.trim();
    final metadataLabel = item.isOfficial
        ? (place.isEmpty ? 'Ohey公式からのお知らせ' : 'Ohey公式 ・ $place')
        : place.isEmpty
        ? '思い出'
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
            label: '投稿メニュー',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onMore,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: OheyPopIcon(
                  icon: CupertinoIcons.ellipsis,
                  color: iconColor,
                  size: 27,
                  showBubble: false,
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
    this.onLike,
    this.onShare,
  });

  final _FeedItem item;
  final bool isWhite;
  final VoidCallback? onLike;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final primaryText = isWhite ? const Color(0xFF17202B) : Colors.white;
    final secondaryText = isWhite
        ? const Color(0xFF778393)
        : Colors.white.withValues(alpha: .62);
    const feedActionPurple = Color(0xFFC08BFF);
    final likeAccent = item.liked
        ? Color.lerp(AppColors.danger, feedActionPurple, .58)!
        : feedActionPurple;
    final shareAccent = item.isOfficial
        ? Color.lerp(AppColors.info, feedActionPurple, .58)!
        : item.ownedByMe
        ? Color.lerp(AppColors.invite, feedActionPurple, .66)!
        : feedActionPurple;

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
                semanticLabel: item.liked ? 'いいねを取り消す' : 'いいねで反応',
                icon: item.liked
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                label: _feedLikeActionLabel(item),
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
                semanticLabel: item.isOfficial
                    ? '公式投稿を詳しく見る'
                    : item.ownedByMe
                    ? '思い出を共有'
                    : '投稿を共有',
                customIcon: item.isOfficial
                    ? null
                    : OheyPostShareIcon(
                        color: oheyPostActionForeground(shareAccent),
                        size: 19,
                      ),
                icon: item.isOfficial ? CupertinoIcons.doc_text_fill : null,
                label: _feedShareActionLabel(item),
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
                  onTap: () => _showFeedCompanionList(context, item.friends),
                ),
              ],
            ],
          ),
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
      ),
    );
  }
}

class _FeedPhotoPlaceholder extends StatelessWidget {
  const _FeedPhotoPlaceholder({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF101B28), accent, .34)!,
            const Color(0xFF090D16),
            Color.lerp(const Color(0xFF2A1538), accent, .22)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -52,
            top: 80,
            child: _FeedPlaceholderOrb(
              color: accent.withValues(alpha: .28),
              size: 170,
            ),
          ),
          Positioned(
            right: -46,
            bottom: 110,
            child: _FeedPlaceholderOrb(
              color: const Color(0xFFFF7AB8).withValues(alpha: .20),
              size: 190,
            ),
          ),
          Center(
            child: Icon(
              CupertinoIcons.photo_fill_on_rectangle_fill,
              color: Colors.white.withValues(alpha: .18),
              size: 74,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedPlaceholderOrb extends StatelessWidget {
  const _FeedPlaceholderOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: 42, spreadRadius: 16)],
    ),
  );
}

String _feedCardCaption(_FeedItem item) {
  return _duoStyleBody(item).trim();
}

String _feedLikeActionLabel(_FeedItem item) {
  return item.liked ? 'いいね済み' : 'いいね';
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
    return item.ownedByMe ? '友達のリアクションを待とう' : 'いいねで気持ちを送ろう';
  }
  return '${item.likes}件のいいね';
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
        ? Color.lerp(color, Colors.black, .22)!
        : Colors.white;

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
                color: Colors.white,
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

  static const _pink = Color(0xFFFF5EA8);
  static const _pinkLight = Color(0xFFFF83C0);
  static const _rim = Color(0xFFFFC1DC);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final seal = _sealPath(size, inset: size.shortestSide * .14);
    final shadow = Paint()
      ..color = _pink.withValues(alpha: .34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(seal.shift(Offset(0, size.height * .10)), shadow);

    final outer = Paint()
      ..color = Colors.white.withValues(alpha: .95)
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
      Paint()..color = Colors.white.withValues(alpha: .24),
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

bool _isDisplayablePostPhoto(String? path) {
  final normalized = path?.trim();
  if (normalized == null || normalized.isEmpty) return false;
  if (normalized.startsWith('ohey_memory_template_')) return false;
  if (normalized.startsWith('/')) return File(normalized).existsSync();
  if (normalized.startsWith('http://') ||
      normalized.startsWith('https://') ||
      normalized.startsWith('assets/')) {
    return true;
  }
  return false;
}

String _duoStyleBody(_FeedItem item) {
  if (item.isOfficial) {
    return switch (item.prop) {
      _PostProp.spark => 'フレンズとの思い出を、もっと楽しく。',
      _PostProp.ticket => 'フレンズと一緒に今月の思い出をふり返ろう。',
      _ => item.body,
    };
  }
  return item.body;
}

class _PostPhoto extends StatelessWidget {
  const _PostPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final provider = _imageProviderFor(path);
    if (provider == null) return const SizedBox.shrink();

    return Image(
      image: provider,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }

  ImageProvider? _imageProviderFor(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }
    if (normalized.startsWith('/')) {
      final file = File(normalized);
      if (!file.existsSync()) return null;
      return FileImage(file);
    }
    if (normalized.startsWith('assets/')) return AssetImage(normalized);
    return null;
  }
}
