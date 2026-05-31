part of 'home_screen.dart';

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.isWhite = false,
    this.accent = _FeedColors.teal,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isWhite;
  final Color accent;
  final Widget? action;

  @override
  Widget build(BuildContext context) => OheyEmptyState(
    visual: OheyPopIcon(icon: icon, color: accent, size: 58),
    title: title,
    message: message,
    titleColor: isWhite ? const Color(0xFF27313B) : Colors.white,
    messageColor: isWhite
        ? const Color(0xFF6E7783)
        : Colors.white.withValues(alpha: .55),
    action: action,
  );
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({
    required this.avatar,
    required this.size,
    required this.glowColor,
  });

  final OheyAvatar avatar;
  final double size;
  final Color glowColor;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          glowColor.withValues(alpha: .36),
          glowColor.withValues(alpha: .10),
        ],
      ),
    ),
    child: OheyAvatarView(avatar: avatar, size: size * .96),
  );
}

BoxDecoration _feedCardDecoration({required double radius}) => BoxDecoration(
  color: _FeedColors.card.withValues(alpha: .74),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Colors.white.withValues(alpha: .11), width: 1.2),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: .18),
      blurRadius: 26,
      offset: const Offset(0, 14),
    ),
  ],
);

List<_FeedItem> _mockYuruboItems({OheyUser? user, String? currentUserId}) {
  final now = DateTime.now();
  final meName = user?.name.trim().isNotEmpty == true
      ? user!.name.trim()
      : user?.userId.trim().isNotEmpty == true
      ? user!.userId.trim()
      : 'yisshiki391';
  final meAvatar = user?.avatar ?? OheyAvatar.defaultAvatar;

  _FeedItem item({
    required String id,
    required String userName,
    required String body,
    required String place,
    required OheyAvatar avatar,
    required DateTime date,
    required int likes,
    required bool liked,
    required bool ownedByMe,
    String ownerUserId = '',
  }) {
    return _FeedItem(
      id: id,
      userName: userName,
      timeAgo: _relativeTime(date),
      body: body,
      place: place,
      avatar: avatar,
      accent: _accentForId(id),
      photoAssetPath: null,
      captionY: .5,
      linkUrl: '',
      friends: const <_Companion>[],
      likes: likes,
      saved: false,
      liked: liked,
      prop: _PostProp.memory,
      tilt: 0,
      ownerUserId: ownerUserId,
      ownedByMe: ownedByMe,
      isOfficial: false,
      sparkles: const <Offset>[],
      displayable: true,
      canReport: !ownedByMe,
      canDelete: ownedByMe,
    );
  }

  return [
    item(
      id: 'mock-yurubo-1',
      userName: meName,
      body: '今日夜、ご飯いける人いる？',
      place: '渋谷あたり',
      avatar: meAvatar,
      date: now.subtract(const Duration(minutes: 18)),
      likes: 2,
      liked: true,
      ownedByMe: true,
      ownerUserId: currentUserId ?? '',
    ),
    item(
      id: 'mock-yurubo-2',
      userName: 'momo',
      body: '今週どこかでサウナ行きたい',
      place: '都内',
      avatar: const OheyAvatar(
        skin: 1,
        hair: 3,
        shirt: 4,
        eyes: 1,
        mouth: 0,
        accessory: 0,
      ),
      date: now.subtract(const Duration(hours: 1, minutes: 7)),
      likes: 4,
      liked: false,
      ownedByMe: false,
      ownerUserId: 'mock-friend-momo',
    ),
    item(
      id: 'mock-yurubo-3',
      userName: 'ren',
      body: '明日カフェで作業できる人？',
      place: '新宿 / 代々木',
      avatar: const OheyAvatar(
        skin: 3,
        hair: 2,
        shirt: 7,
        eyes: 0,
        mouth: 1,
        accessory: 1,
      ),
      date: now.subtract(const Duration(hours: 3, minutes: 42)),
      likes: 1,
      liked: false,
      ownedByMe: false,
      ownerUserId: 'mock-friend-ren',
    ),
    item(
      id: 'mock-yurubo-4',
      userName: 'hina',
      body: '日曜、ドライブか海行ける人募集',
      place: '湘南方面',
      avatar: const OheyAvatar(
        skin: 4,
        hair: 6,
        shirt: 2,
        eyes: 2,
        mouth: 0,
        accessory: 2,
      ),
      date: now.subtract(const Duration(hours: 7, minutes: 20)),
      likes: 6,
      liked: true,
      ownedByMe: false,
      ownerUserId: 'mock-friend-hina',
    ),
    item(
      id: 'mock-yurubo-5',
      userName: 'sora',
      body: 'このあと軽く飲める人いる？',
      place: '中目黒',
      avatar: const OheyAvatar(
        skin: 0,
        hair: 8,
        shirt: 5,
        eyes: 1,
        mouth: 2,
        accessory: 0,
      ),
      date: now.subtract(const Duration(hours: 9, minutes: 5)),
      likes: 0,
      liked: false,
      ownedByMe: false,
      ownerUserId: 'mock-friend-sora',
    ),
  ];
}

class _FeedItem {
  const _FeedItem({
    this.id = '',
    required this.userName,
    required this.timeAgo,
    required this.body,
    this.place = '',
    required this.avatar,
    required this.accent,
    this.photoAssetPath,
    this.captionY = .5,
    this.linkUrl = '',
    this.friends = const <_Companion>[],
    required this.likes,
    required this.saved,
    required this.liked,
    required this.prop,
    required this.tilt,
    this.ownerUserId = '',
    this.ownedByMe = false,
    this.isOfficial = false,
    required this.sparkles,
    this.displayable = true,
    this.canReport = true,
    this.canDelete = false,
  });

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final searchable = [userName, timeAgo, body, place].join(' ').toLowerCase();
    return searchable.contains(normalized);
  }

  bool get isLikeable => id.isNotEmpty;
  _FeedPostKind get postKind {
    if (isOfficial) return _FeedPostKind.official;
    if (ownedByMe) return _FeedPostKind.mine;
    return _FeedPostKind.friend;
  }

  final String id;
  final String userName;
  final String timeAgo;
  final String body;
  final String place;
  final OheyAvatar avatar;
  final Color accent;
  final String? photoAssetPath;
  final double captionY;
  final String linkUrl;
  final List<_Companion> friends;
  final int likes;
  final bool saved;
  final bool liked;
  final String ownerUserId;
  final _PostProp prop;
  final double tilt;
  final bool ownedByMe;
  final bool isOfficial;
  final List<Offset> sparkles;
  final bool displayable;
  final bool canReport;
  final bool canDelete;
}

enum _PostProp { memory, ticket, spark }

enum _FeedPostKind { mine, friend, official }

class _Companion {
  const _Companion({
    required this.userId,
    required this.name,
    required this.handle,
    required this.avatar,
    required this.accent,
    required this.statusKey,
  });

  final String userId;
  final String name;
  final String handle;
  final OheyAvatar avatar;
  final Color accent;
  final String? statusKey;

  String get handleLabel => handle.trim().isEmpty ? 'Oheyフレンズ' : '@$handle';

  OheyFriend toOheyFriend() => OheyFriend(
    id: userId,
    name: name,
    avatarEmoji: '👤',
    vibe: handle.replaceFirst('@', ''),
    characterAssetPath: '',
    kind: OheyFriendKind.cloud,
    palette: OheyFriendPalette.lavender,
    avatar: avatar,
    statusKey: statusKey,
  );
}

String _companionStatusLabel(String? statusKey) {
  return oheyDailyStatusFromKey(statusKey).label;
}

String _companionStatusMessage(String? statusKey) {
  return oheyDailyStatusFromKey(statusKey).description;
}

IconData _companionStatusIcon(String? statusKey) {
  final status = oheyDailyStatusFromKey(statusKey);
  return switch (status) {
    OheyDailyStatus.available => CupertinoIcons.checkmark_circle_fill,
    OheyDailyStatus.maybeAvailable => CupertinoIcons.drop_fill,
    OheyDailyStatus.dependsOnTime => CupertinoIcons.moon_fill,
    OheyDailyStatus.hasPlans => CupertinoIcons.calendar_today,
    OheyDailyStatus.unselected => CupertinoIcons.circle,
  };
}

Color _companionStatusColor(String? statusKey) {
  final status = oheyDailyStatusFromKey(statusKey);
  return switch (status) {
    OheyDailyStatus.available => const Color(0xFF9AF21A),
    OheyDailyStatus.maybeAvailable => const Color(0xFF5DEBD3),
    OheyDailyStatus.dependsOnTime => const Color(0xFFFF5EA8),
    OheyDailyStatus.hasPlans => const Color(0xFFB8C1CD),
    OheyDailyStatus.unselected => _FeedColors.sub,
  };
}

class _FeedNotification {
  const _FeedNotification({
    required this.kind,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.accent,
    required this.unread,
    this.friendRequestId,
    this.friendRequestStatus,
    this.inviteId,
    this.inviteStatus,
  });

  factory _FeedNotification.fromNotification(OheyNotification notification) {
    return _FeedNotification(
      kind: notification.kind,
      title: notification.displayTitle,
      message: notification.displayMessage,
      timeAgo: _relativeTimeText(notification.createdAt),
      icon: switch (notification.kind) {
        'memory_like' => CupertinoIcons.heart_fill,
        'friend_request_received' => CupertinoIcons.person_badge_plus_fill,
        'friend_request_accepted' => CupertinoIcons.checkmark_seal_fill,
        'invite_received' => CupertinoIcons.calendar_badge_plus,
        'invite_accepted' => CupertinoIcons.checkmark_circle_fill,
        'today_reservation_reminder' => CupertinoIcons.calendar_today,
        'memory_tagged' => CupertinoIcons.person_2_fill,
        'system' => CupertinoIcons.bell_fill,
        _ => CupertinoIcons.bell_fill,
      },
      accent: switch (notification.kind) {
        'memory_like' => const Color(0xFFFF75B5),
        'friend_request_received' => const Color(0xFF58D6FF),
        'friend_request_accepted' => const Color(0xFF9AF21A),
        'invite_received' => const Color(0xFFC08BFF),
        'invite_accepted' => _FeedColors.teal,
        'today_reservation_reminder' => const Color(0xFFFFD166),
        'memory_tagged' => const Color(0xFF58D6FF),
        'system' => const Color(0xFFFFD166),
        _ => _FeedColors.teal,
      },
      unread: notification.isUnread,
      friendRequestId: notification.friendRequestId,
      friendRequestStatus: notification.friendRequestStatus,
      inviteId: notification.inviteId,
      inviteStatus: notification.inviteStatus,
    );
  }

  final String kind;
  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color accent;
  final bool unread;
  final String? friendRequestId;
  final String? friendRequestStatus;
  final String? inviteId;
  final String? inviteStatus;

  bool get canOpen {
    if (kind == 'friend_request_received') {
      return friendRequestId != null && friendRequestId!.isNotEmpty;
    }
    if (kind == 'invite_received') {
      return inviteId != null && inviteId!.isNotEmpty;
    }
    return false;
  }

  bool get requiresAction {
    if (kind == 'friend_request_received') {
      return oheyFriendRequestStatusFromKey(friendRequestStatus).isPending;
    }
    if (kind == 'invite_received') {
      return oheyInviteStatusFromKey(inviteStatus).isPending;
    }
    return false;
  }

  bool get isResolvedAction {
    if (kind == 'friend_request_received') {
      return !oheyFriendRequestStatusFromKey(friendRequestStatus).isPending;
    }
    if (kind == 'invite_received') {
      return !oheyInviteStatusFromKey(inviteStatus).isPending;
    }
    return false;
  }

  String? get actionLabel {
    if (kind == 'friend_request_received') {
      return oheyFriendRequestStatusFromKey(friendRequestStatus).actionLabel;
    }
    if (kind == 'invite_received') {
      return oheyInviteStatusFromKey(inviteStatus).actionLabel;
    }
    return null;
  }
}

String _relativeTimeText(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inHours < 1) return '${diff.inMinutes}分前';
  if (diff.inDays < 1) return '${diff.inHours}時間前';
  if (diff.inDays < 7) return '${diff.inDays}日前';
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '$month/$day';
}

Future<String> _createStoryShareImage(_FeedItem item) async {
  const width = 1080.0;
  const height = 1920.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, width, height);

  final background = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF05080D), Color(0xFF111821), Color(0xFF05080D)],
      stops: [0, .48, 1],
    ).createShader(rect);
  canvas.drawRect(rect, background);

  final photo = await _loadSharePhoto(item.photoAssetPath);
  if (photo != null) {
    final blurredBackdropRect = Rect.fromLTWH(-160, 0, width + 320, height);
    _paintCoverImage(
      canvas,
      image: photo,
      target: blurredBackdropRect,
      opacity: .20,
    );
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF05080D).withValues(alpha: .70),
    );
  }

  const cardWidth = 930.0;
  const cardHorizontalPadding = 42.0;
  const cardTopPadding = 42.0;
  const photoWidth = cardWidth - cardHorizontalPadding * 2;
  const photoHeight = photoWidth * 9 / 16;
  const textTopGap = 38.0;
  const captionFontSize = 54.0;
  const metaFontSize = 34.0;
  const metaGap = 16.0;
  const cardBottomPadding = 44.0;
  const cardHeight =
      cardTopPadding +
      photoHeight +
      textTopGap +
      captionFontSize * 1.20 +
      metaGap +
      metaFontSize * 1.18 +
      cardBottomPadding;
  const cardLeft = (width - cardWidth) / 2;
  const cardTop = (height - cardHeight) / 2;
  final cardRect = Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight);
  final cardRRect = RRect.fromRectAndRadius(cardRect, const Radius.circular(4));

  canvas.drawRRect(
    cardRRect.shift(const Offset(0, 18)),
    Paint()
      ..color = Colors.black.withValues(alpha: .26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
  );
  canvas.drawRRect(cardRRect, Paint()..color = Colors.white);

  final photoRect = Rect.fromLTWH(
    cardLeft + cardHorizontalPadding,
    cardTop + cardTopPadding,
    photoWidth,
    photoHeight,
  );
  final photoRRect = RRect.fromRectAndRadius(
    photoRect,
    const Radius.circular(2),
  );
  if (photo != null) {
    canvas.save();
    canvas.clipRRect(photoRRect);
    _paintCoverImage(canvas, image: photo, target: photoRect);
    canvas.restore();
    photo.dispose();
  } else {
    canvas.drawRRect(
      photoRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF0A8D), Color(0xFF21D6C4)],
        ).createShader(photoRect),
    );
  }

  final title = item.body.trim().isNotEmpty ? item.body.trim() : item.userName;
  final captionTop = photoRect.bottom + textTopGap;
  _paintShareText(
    canvas,
    title,
    x: photoRect.left,
    y: captionTop,
    maxWidth: photoRect.width,
    size: captionFontSize,
    weight: FontWeight.w700,
    color: const Color(0xFF111111),
    maxLines: 1,
  );
  _paintShareText(
    canvas,
    item.timeAgo,
    x: photoRect.left,
    y: captionTop + captionFontSize * 1.20 + metaGap,
    maxWidth: photoRect.width,
    size: metaFontSize,
    weight: FontWeight.w700,
    color: const Color(0xFF8D8D8D),
    maxLines: 1,
  );

  final picture = recorder.endRecording();
  final output = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await output.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('共有画像を作成できませんでした。');
  }
  final path =
      '${Directory.systemTemp.path}/ohey_story_${DateTime.now().microsecondsSinceEpoch}.png';
  await File(path).writeAsBytes(byteData.buffer.asUint8List());
  output.dispose();
  picture.dispose();
  return path;
}

Future<ui.Image?> _loadSharePhoto(String? path) async {
  final normalized = path?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  try {
    late final Uint8List bytes;
    if (normalized.startsWith('/')) {
      final file = File(normalized);
      if (!await file.exists()) return null;
      bytes = await file.readAsBytes();
    } else if (normalized.startsWith('http://') ||
        normalized.startsWith('https://')) {
      final uri = Uri.tryParse(normalized);
      if (uri == null) return null;
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      bytes = await consolidateHttpClientResponseBytes(response);
    } else if (normalized.startsWith('assets/')) {
      final data = await rootBundle.load(normalized);
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } else {
      return null;
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

void _paintCoverImage(
  Canvas canvas, {
  required ui.Image image,
  required Rect target,
  double opacity = 1,
}) {
  final source = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );
  final imageAspect = image.width / image.height;
  final targetAspect = target.width / target.height;
  Rect sourceCrop;
  if (imageAspect > targetAspect) {
    final cropWidth = image.height * targetAspect;
    sourceCrop = Rect.fromLTWH(
      (image.width - cropWidth) / 2,
      0,
      cropWidth,
      image.height.toDouble(),
    );
  } else {
    final cropHeight = image.width / targetAspect;
    sourceCrop = Rect.fromLTWH(
      0,
      (image.height - cropHeight) / 2,
      image.width.toDouble(),
      cropHeight,
    );
  }
  final paint = Paint()..filterQuality = ui.FilterQuality.high;
  if (opacity < 1) {
    paint.colorFilter = ColorFilter.mode(
      Colors.white.withValues(alpha: opacity),
      BlendMode.modulate,
    );
  }
  canvas.drawImageRect(image, sourceCrop.intersect(source), target, paint);
}

void _paintShareText(
  Canvas canvas,
  String text, {
  required double x,
  required double y,
  required double maxWidth,
  required double size,
  required FontWeight weight,
  required Color color,
  int? maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: 1.18,
        letterSpacing: -0.8,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  painter.paint(canvas, Offset(x, y));
}

class _FeedColors {
  const _FeedColors._();
  static const teal = Color(0xFFC08BFF);
  static const card = Color(0xFF112332);
  static const sub = Color(0xFF9AA7B7);
}

Color _accentForId(String id) {
  const colors = [
    Color(0xFF12C9A4),
    Color(0xFFC08BFF),
    Color(0xFF9AF21A),
    Color(0xFFFF75B5),
    Color(0xFF58D6FF),
  ];
  return colors[id.hashCode.abs() % colors.length];
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
  if (diff.inHours < 24) return '${diff.inHours}時間前';
  return '${diff.inDays}日前';
}
