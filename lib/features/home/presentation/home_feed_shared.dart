part of 'home_screen.dart';

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.isWhite = false,
    this.accent = _FeedColors.teal,
    this.action,
    this.hints = const [],
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isWhite;
  final Color accent;
  final Widget? action;
  final List<String> hints;

  @override
  Widget build(BuildContext context) => OheyEmptyState(
    visual: OheyPopIcon(icon: icon, color: accent, size: 58),
    title: title,
    message: message,
    titleColor: isWhite ? AppColors.cFF27313B : AppColors.white,
    messageColor: isWhite
        ? AppColors.cFF6E7783
        : AppColors.white.withValues(alpha: .55),
    hints: hints,
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
    this.startsAt,
    required this.avatar,
    required this.accent,
    this.linkUrl = '',
    this.targetLabel = '全フレンズ',
    this.friends = const <_Companion>[],
    this.myReactionType = '',
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
      startsAt: yurubo.startsAt,
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
            statusKey: participant.isPending
                ? oheyPendingYuruboCompanionKey
                : null,
          ),
      ],
      likes: yurubo.reactionCount,
      myReactionType: yurubo.myReactionType,
      saved: false,
      liked: isOwnedByCurrentUser || yurubo.reactedByMe,
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
  final DateTime? startsAt;
  final OheyAvatar avatar;
  final Color accent;
  final String linkUrl;
  final String targetLabel;
  final List<_Companion> friends;
  final String myReactionType;
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
  if (statusKey.isPendingYuruboCompanion) return '承認待ち';
  return oheyDailyStatusFromKey(statusKey).label;
}

String _companionStatusMessage(String? statusKey) {
  return oheyDailyStatusFromKey(statusKey).description;
}

IconData _companionStatusIcon(String? statusKey) {
  return oheyDailyStatusIcon(oheyDailyStatusFromKey(statusKey));
}

Color _companionStatusColor(String? statusKey) {
  if (statusKey.isPendingYuruboCompanion) {
    return AppColors.cFFFFD84D;
  }
  final status = oheyDailyStatusFromKey(statusKey);
  if (status == OheyDailyStatus.unselected) return _FeedColors.sub;
  return oheyDailyStatusColor(status);
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
    this.yurubo,
    this.yuruboParticipant,
  });

  factory _FeedNotification.fromNotification(OheyNotification notification) {
    return _FeedNotification(
      kind: notification.kind,
      title: notification.displayTitle,
      message: notification.displayMessage,
      timeAgo: _relativeTimeText(notification.createdAt),
      icon: switch (notification.kind) {
        OheyNotificationKindKeys.memoryLike => CupertinoIcons.heart_fill,
        OheyNotificationKindKeys.friendRequestReceived =>
          CupertinoIcons.person_badge_plus_fill,
        OheyNotificationKindKeys.friendRequestAccepted =>
          CupertinoIcons.checkmark_seal_fill,
        OheyNotificationKindKeys.inviteReceived =>
          CupertinoIcons.calendar_badge_plus,
        OheyNotificationKindKeys.inviteAccepted =>
          CupertinoIcons.checkmark_circle_fill,
        OheyNotificationKindKeys.todayReservationReminder =>
          CupertinoIcons.calendar_today,
        OheyNotificationKindKeys.memoryTagged => CupertinoIcons.person_2_fill,
        OheyNotificationKindKeys.system => CupertinoIcons.bell_fill,
        _ => CupertinoIcons.bell_fill,
      },
      accent: switch (notification.kind) {
        OheyNotificationKindKeys.memoryLike => AppColors.cFFFF75B5,
        OheyNotificationKindKeys.friendRequestReceived => AppColors.cFF58D6FF,
        OheyNotificationKindKeys.friendRequestAccepted => AppColors.cFF9AF21A,
        OheyNotificationKindKeys.inviteReceived => AppColors.cFFC08BFF,
        OheyNotificationKindKeys.inviteAccepted => _FeedColors.teal,
        OheyNotificationKindKeys.todayReservationReminder =>
          AppColors.cFFFFD166,
        OheyNotificationKindKeys.memoryTagged => AppColors.cFF58D6FF,
        OheyNotificationKindKeys.system => AppColors.cFFFFD166,
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
  final Yurubo? yurubo;
  final YuruboParticipant? yuruboParticipant;

  bool get canOpen {
    if (kind == OheyNotificationKindKeys.friendRequestReceived) {
      return friendRequestId != null && friendRequestId!.isNotEmpty;
    }
    if (kind == OheyNotificationKindKeys.inviteReceived) {
      return inviteId != null && inviteId!.isNotEmpty;
    }
    if (kind == 'yurubo_participation_requested') {
      return yurubo != null && yuruboParticipant != null;
    }
    return false;
  }

  bool get requiresAction {
    if (kind == OheyNotificationKindKeys.friendRequestReceived) {
      return oheyFriendRequestStatusFromKey(friendRequestStatus).isPending;
    }
    if (kind == OheyNotificationKindKeys.inviteReceived) {
      return oheyInviteStatusFromKey(inviteStatus).isPending;
    }
    if (kind == 'yurubo_participation_requested') return true;
    return false;
  }

  bool get isResolvedAction {
    if (kind == OheyNotificationKindKeys.friendRequestReceived) {
      return !oheyFriendRequestStatusFromKey(friendRequestStatus).isPending;
    }
    if (kind == OheyNotificationKindKeys.inviteReceived) {
      return !oheyInviteStatusFromKey(inviteStatus).isPending;
    }
    if (kind == 'yurubo_participation_requested') return false;
    return false;
  }

  String? get actionLabel {
    if (kind == OheyNotificationKindKeys.friendRequestReceived) {
      return oheyFriendRequestStatusFromKey(friendRequestStatus).actionLabel;
    }
    if (kind == OheyNotificationKindKeys.inviteReceived) {
      return oheyInviteStatusFromKey(inviteStatus).actionLabel;
    }
    if (kind == 'yurubo_participation_requested') return '承認する';
    return null;
  }
}

String _relativeTimeText(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return '1分未満前';
  if (diff.inHours < 1) return '${diff.inMinutes}分前';
  if (diff.inDays < 1) return '${diff.inHours}時間前';
  if (diff.inDays < 7) return '${diff.inDays}日前';
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '$month/$day';
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
  if (diff.inMinutes < 1) return '1分未満前';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
  if (diff.inHours < 24) return '${diff.inHours}時間前';
  return '${diff.inDays}日前';
}
