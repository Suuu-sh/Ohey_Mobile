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
    titleColor: isWhite ? AppColors.cFF27313B : AppColors.white,
    messageColor: isWhite
        ? AppColors.cFF6E7783
        : AppColors.white.withValues(alpha: .55),
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
  border: Border.all(color: AppColors.white.withValues(alpha: .11), width: 1.2),
  boxShadow: [
    BoxShadow(
      color: AppColors.black.withValues(alpha: .18),
      blurRadius: 26,
      offset: const Offset(0, 14),
    ),
  ],
);

List<_FeedItem> _feedItemsFromYurubos(
  List<Yurubo> yurubos, {
  String? currentUserId,
}) => yurubos
    .map((yurubo) => _FeedItem.fromYurubo(yurubo, currentUserId: currentUserId))
    .toList(growable: false);

class _FeedItem {
  const _FeedItem({
    this.id = '',
    required this.userName,
    required this.timeAgo,
    required this.body,
    this.place = '',
    this.timeLabel = '',
    required this.avatar,
    required this.accent,
    this.linkUrl = '',
    this.targetLabel = '全フレンズ',
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

  factory _FeedItem.fromYurubo(Yurubo yurubo, {String? currentUserId}) {
    final isOwnedByCurrentUser =
        currentUserId?.isNotEmpty == true &&
        yurubo.ownerUserId == currentUserId;
    final body = yurubo.title.trim().isNotEmpty
        ? yurubo.title.trim()
        : yurubo.body.trim();
    return _FeedItem(
      id: yurubo.id,
      userName: yurubo.userName,
      timeAgo: _relativeTime(yurubo.createdAt),
      body: body,
      place: yurubo.placeText,
      timeLabel: yurubo.timeLabel,
      avatar: yurubo.avatar,
      accent: _accentForId(yurubo.id),
      linkUrl: '',
      targetLabel: yurubo.visibilityLabel.isEmpty
          ? '全フレンズ'
          : yurubo.visibilityLabel,
      friends: [
        for (final participant in yurubo.participants)
          _Companion(
            userId: participant.userId,
            name: participant.name,
            handle: participant.handle,
            avatar: participant.avatar,
            accent: _accentForId(participant.userId),
            statusKey: null,
          ),
      ],
      likes: yurubo.reactionCount,
      saved: false,
      liked: yurubo.reactedByMe,
      prop: _PostProp.memory,
      tilt: 0,
      ownerUserId: yurubo.ownerUserId,
      ownedByMe: isOwnedByCurrentUser,
      isOfficial: false,
      sparkles: const <Offset>[],
      displayable: true,
      canReport: !isOwnedByCurrentUser,
      canDelete: isOwnedByCurrentUser,
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final searchable = [
      userName,
      timeAgo,
      body,
      place,
      timeLabel,
    ].join(' ').toLowerCase();
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
  final String timeLabel;
  final OheyAvatar avatar;
  final Color accent;
  final String linkUrl;
  final String targetLabel;
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
    OheyDailyStatus.available => AppColors.cFF9AF21A,
    OheyDailyStatus.maybeAvailable => AppColors.cFF5DEBD3,
    OheyDailyStatus.dependsOnTime => AppColors.cFFFF5EA8,
    OheyDailyStatus.hasPlans => AppColors.cFFB8C1CD,
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
        'memory_like' => AppColors.cFFFF75B5,
        'friend_request_received' => AppColors.cFF58D6FF,
        'friend_request_accepted' => AppColors.cFF9AF21A,
        'invite_received' => AppColors.cFFC08BFF,
        'invite_accepted' => _FeedColors.teal,
        'today_reservation_reminder' => AppColors.cFFFFD166,
        'memory_tagged' => AppColors.cFF58D6FF,
        'system' => AppColors.cFFFFD166,
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
      colors: [AppColors.cFF05080D, AppColors.cFF111821, AppColors.cFF05080D],
      stops: [0, .48, 1],
    ).createShader(rect);
  canvas.drawRect(rect, background);

  const cardWidth = 930.0;
  const cardHorizontalPadding = 56.0;
  const cardTopPadding = 58.0;
  const titleFontSize = 58.0;
  const metaFontSize = 34.0;
  const cardHeight = 520.0;
  const cardLeft = (width - cardWidth) / 2;
  const cardTop = (height - cardHeight) / 2;
  final cardRect = Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight);
  final cardRRect = RRect.fromRectAndRadius(
    cardRect,
    const Radius.circular(32),
  );

  canvas.drawRRect(
    cardRRect.shift(const Offset(0, 18)),
    Paint()
      ..color = AppColors.black.withValues(alpha: .26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
  );
  canvas.drawRRect(cardRRect, Paint()..color = AppColors.white);

  final accentRect = Rect.fromLTWH(cardLeft, cardTop, cardWidth, 12);
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      accentRect,
      topLeft: const Radius.circular(32),
      topRight: const Radius.circular(32),
    ),
    Paint()..color = AppColors.cFFC08BFF,
  );

  final textLeft = cardLeft + cardHorizontalPadding;
  final textWidth = cardWidth - cardHorizontalPadding * 2;
  final title = item.body.trim().isNotEmpty ? item.body.trim() : item.userName;
  _paintShareText(
    canvas,
    title,
    x: textLeft,
    y: cardTop + cardTopPadding,
    maxWidth: textWidth,
    size: titleFontSize,
    weight: FontWeight.w800,
    color: AppColors.cFF111111,
    maxLines: 3,
  );
  _paintShareText(
    canvas,
    item.timeAgo,
    x: textLeft,
    y: cardTop + cardHeight - cardTopPadding - metaFontSize * 1.18,
    maxWidth: textWidth,
    size: metaFontSize,
    weight: FontWeight.w700,
    color: AppColors.cFF8D8D8D,
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
  static const teal = AppColors.cFFC08BFF;
  static const card = AppColors.cFF112332;
  static const sub = AppColors.cFF9AA7B7;
}

Color _accentForId(String id) {
  const colors = [
    AppColors.cFF12C9A4,
    AppColors.cFFC08BFF,
    AppColors.cFF9AF21A,
    AppColors.cFFFF75B5,
    AppColors.cFF58D6FF,
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
