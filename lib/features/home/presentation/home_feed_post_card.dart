part of 'home_screen.dart';

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.item,
    required this.isWhite,
    this.onLike,
    this.onShare,
    this.onMore,
  });

  final _FeedItem item;
  final bool isWhite;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final photoPath = item.photoAssetPath;
    final hasPhoto = _isDisplayablePostPhoto(photoPath);
    final caption = _feedCardCaption(item);
    final surfaceColor = isWhite ? Colors.white : AppColors.darkBackground;
    final borderColor = isWhite
        ? const Color(0xFFE3EAF3)
        : Colors.white.withValues(alpha: .08);

    return Semantics(
      label: '${item.userName}の飲みログ',
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border.symmetric(
            horizontal: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _FeedCardAuthorBar(item: item, isWhite: isWhite, onMore: onMore),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: borderColor, width: .8),
                ),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      hasPhoto
                          ? _PostPhoto(path: photoPath!)
                          : _FeedPhotoPlaceholder(accent: item.accent),
                      _FeedPhotoCaptionOverlay(caption: caption),
                    ],
                  ),
                ),
              ),
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

class _FeedPhotoCaptionOverlay extends StatelessWidget {
  const _FeedPhotoCaptionOverlay({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final body = caption.trim();
    if (body.isEmpty) return const SizedBox.shrink();

    const bandHeight = 52.0;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.maxHeight > bandHeight
              ? (constraints.maxHeight - bandHeight) / 2
              : 0.0;

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
  });

  final _FeedItem item;
  final bool isWhite;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final primaryText = isWhite ? const Color(0xFF17202B) : Colors.white;
    final secondaryText = isWhite
        ? const Color(0xFF778393)
        : Colors.white.withValues(alpha: .62);
    final iconColor = isWhite
        ? const Color(0xFF1E2733)
        : Colors.white.withValues(alpha: .92);
    final place = item.place.trim();
    final metadataLabel = place.isEmpty
        ? item.timeAgo
        : '${item.timeAgo} ・ $place';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarBubble(avatar: item.avatar, size: 40, glowColor: item.accent),
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: primaryText,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: -.25,
                        ),
                      ),
                    ),
                    if (item.isOfficial) const _OfficialVerifiedBadge(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  metadataLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: secondaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
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
                child: NomoPopIcon(
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FeedOverlayAction(
                          semanticLabel: item.liked ? 'いいねを取り消す' : 'いいね',
                          icon: item.liked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: item.liked
                              ? const Color(0xFFFF5EA8)
                              : primaryText,
                          onTap: onLike,
                        ),
                        const SizedBox(width: 18),
                        _FeedOverlayAction(
                          semanticLabel: '共有',
                          customIcon: _VectorShareIcon(
                            color: primaryText,
                            size: 27,
                          ),
                          onTap: onShare,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.likes}件のいいね',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (item.friends.isNotEmpty) ...[
                const SizedBox(width: 10),
                _FeedCompanionInlineButton(
                  friends: item.friends,
                  isWhite: isWhite,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedOverlayAction extends StatelessWidget {
  const _FeedOverlayAction({
    required this.semanticLabel,
    this.icon,
    this.customIcon,
    this.color = Colors.white,
    this.onTap,
  });

  final String semanticLabel;
  final IconData? icon;
  final Widget? customIcon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              customIcon ??
                  NomoPopIcon(
                    icon: icon ?? CupertinoIcons.circle,
                    color: color,
                    size: 29,
                    showBubble: false,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedCompanionInlineButton extends StatelessWidget {
  const _FeedCompanionInlineButton({
    required this.friends,
    required this.isWhite,
  });

  final List<_Companion> friends;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final textColor = isWhite ? const Color(0xFF344152) : Colors.white;
    final borderColor = isWhite
        ? const Color(0xFFE0E7EF)
        : Colors.white.withValues(alpha: .13);
    final backgroundColor = isWhite
        ? const Color(0xFFF4F7FA)
        : Colors.white.withValues(alpha: .07);
    final label = friends.length == 1
        ? '${friends.first.name}と一緒'
        : '${friends.first.name}ほか${friends.length - 1}人と一緒';

    return Semantics(
      button: true,
      label: '一緒に飲んだフレンズを表示',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showFeedCompanionList(context, friends),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 182),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FriendAvatarStack(friends: friends),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
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

class _VectorShareIcon extends StatelessWidget {
  const _VectorShareIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _VectorShareIconPainter(color)),
  );
}

class _VectorShareIconPainter extends CustomPainter {
  const _VectorShareIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * .105;

    final tray = Path()
      ..moveTo(w * .22, h * .62)
      ..lineTo(w * .22, h * .76)
      ..quadraticBezierTo(w * .22, h * .86, w * .32, h * .86)
      ..lineTo(w * .68, h * .86)
      ..quadraticBezierTo(w * .78, h * .86, w * .78, h * .76)
      ..lineTo(w * .78, h * .62);
    canvas.drawPath(tray, stroke);

    canvas.drawLine(Offset(w * .50, h * .66), Offset(w * .50, h * .16), stroke);
    canvas.drawLine(Offset(w * .34, h * .31), Offset(w * .50, h * .16), stroke);
    canvas.drawLine(Offset(w * .66, h * .31), Offset(w * .50, h * .16), stroke);
  }

  @override
  bool shouldRepaint(covariant _VectorShareIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

bool _isDisplayablePostPhoto(String? path) {
  final normalized = path?.trim();
  if (normalized == null || normalized.isEmpty) return false;
  if (normalized.startsWith('nomo_memory_template_')) return false;
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
      _PostProp.spark => 'Nomoで飲みともとの思い出をもっと楽しく残せるようになったよ！',
      _PostProp.ticket => 'フレンズと一緒に今月の飲みログをふり返ろう。',
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

class _FriendAvatarStack extends StatelessWidget {
  const _FriendAvatarStack({required this.friends});

  final List<_Companion> friends;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const SizedBox.shrink();
    final visible = friends.take(3).toList();
    return SizedBox(
      width: 28.0 + (visible.length - 1) * 18.0,
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _FeedColors.card,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: NomoAvatarView(avatar: visible[i].avatar, size: 28),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
