part of 'home_screen.dart';

class _FeedCompanionListSheet extends StatelessWidget {
  const _FeedCompanionListSheet({required this.friends});

  final List<_Companion> friends;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .58);
    final listHeight = (friends.length * 78.0).clamp(
      78.0,
      MediaQuery.sizeOf(context).height * .44,
    );
    return NomoBottomSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NomoBottomSheetHandle(),
          const SizedBox(height: 18),
          Row(
            children: [
              NomoPopIcon(
                icon: CupertinoIcons.person_2_fill,
                color: _FeedColors.teal,
                size: 46,
                iconSize: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '一緒に遊んだフレンズ',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'タップしてプロフィールを見る',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: NomoPopIcon(
                  icon: CupertinoIcons.xmark,
                  color: subtitleColor,
                  size: 34,
                  iconSize: 18,
                  shadow: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: listHeight,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: friends.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _FeedCompanionTile(
                friend: friends[index],
                onTap: () => Navigator.of(context).pop(friends[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCompanionTile extends StatelessWidget {
  const _FeedCompanionTile({required this.friend, required this.onTap});

  final _Companion friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .56);
    return Nomo3DButtonSurface(
      onTap: onTap,
      height: 68,
      radius: 22,
      color: isWhite ? const Color(0xFFF7FAFC) : AppColors.darkBackground,
      bottomColor: isWhite ? const Color(0xFFDCE4EC) : const Color(0xFF09131D),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      borderColor: isWhite
          ? const Color(0xFFE1E8F1)
          : Colors.white.withValues(alpha: .12),
      outerShadows: [
        BoxShadow(
          color: friend.accent.withValues(alpha: isWhite ? .10 : .18),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      innerShadows: [
        BoxShadow(
          color: Colors.white.withValues(alpha: isWhite ? .40 : .08),
          blurRadius: 10,
          offset: const Offset(-2, -2),
        ),
      ],
      child: Row(
        children: [
          _AvatarBubble(
            avatar: friend.avatar,
            size: 44,
            glowColor: friend.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  friend.handleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _companionStatusColor(
                friend.statusKey,
              ).withValues(alpha: isWhite ? .13 : .11),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _companionStatusLabel(friend.statusKey),
              style: TextStyle(
                color: _companionStatusColor(friend.statusKey),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          NomoPopIcon(
            icon: CupertinoIcons.chevron_forward,
            color: subtitleColor,
            size: 28,
            iconSize: 15,
            shadow: false,
          ),
        ],
      ),
    );
  }
}

final _feedCompanionRelationshipProvider = FutureProvider.autoDispose
    .family<NomoFriendRelationshipStatus, String>((ref, userId) {
      return ref.read(friendRepositoryProvider).relationshipStatus(userId);
    });

class _FeedCompanionStatusCard extends StatelessWidget {
  const _FeedCompanionStatusCard({
    required this.friend,
    required this.isWhite,
    required this.titleColor,
    required this.subtitleColor,
    required this.statusColor,
  });

  final _Companion friend;
  final bool isWhite;
  final Color titleColor;
  final Color subtitleColor;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWhite
            ? const Color(0xFFF7FAFC)
            : Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFE1E8F1)
              : Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Row(
        children: [
          NomoPopIcon(
            icon: _companionStatusIcon(friend.statusKey),
            color: statusColor,
            size: 40,
            iconSize: 22,
            showBubble: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _companionStatusLabel(friend.statusKey),
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _companionStatusMessage(friend.statusKey),
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCompanionRequestCard extends StatelessWidget {
  const _FeedCompanionRequestCard({
    required this.isWhite,
    required this.subtitleColor,
    required this.message,
    required this.buttonLabel,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  });

  final bool isWhite;
  final Color subtitleColor;
  final String message;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWhite
            ? const Color(0xFFF7FAFC)
            : Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFE1E8F1)
              : Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NomoPopIcon(
                icon: CupertinoIcons.lock_fill,
                color: Color(0xFFC08BFF),
                size: 40,
                iconSize: 20,
                showBubble: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Nomo3DButton(
            label: buttonLabel,
            icon: CupertinoIcons.person_badge_plus_fill,
            onTap: enabled ? onTap : null,
            isLoading: isLoading,
            enabled: enabled,
            height: 46,
            radius: 20,
            color: const Color(0xFFC08BFF),
            foregroundColor: Colors.white,
            shadowColor: const Color(0xFF7F51C9),
          ),
        ],
      ),
    );
  }
}

class _FeedCompanionProfileSheet extends ConsumerStatefulWidget {
  const _FeedCompanionProfileSheet({
    required this.friend,
    this.initialRelationship,
  });

  final _Companion friend;
  final NomoFriendRelationshipStatus? initialRelationship;

  @override
  ConsumerState<_FeedCompanionProfileSheet> createState() =>
      _FeedCompanionProfileSheetState();
}

class _FeedCompanionProfileSheetState
    extends ConsumerState<_FeedCompanionProfileSheet> {
  bool _isSendingRequest = false;
  String? _requestError;

  Future<void> _sendRequest() async {
    if (_isSendingRequest || widget.friend.userId.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isSendingRequest = true;
      _requestError = null;
    });
    try {
      await ref
          .read(friendRepositoryProvider)
          .sendFriendRequest(widget.friend.userId);
      ref.invalidate(friendsProvider);
      if (!mounted) return;
      NomoToast.show(
        context,
        '${widget.friend.name}にフレンド申請を送りました',
        icon: CupertinoIcons.paperplane_fill,
        placement: NomoToastPlacement.bottom,
      );
      setState(() => _isSendingRequest = false);
      ref.invalidate(_feedCompanionRelationshipProvider(widget.friend.userId));
    } catch (_) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _isSendingRequest = false;
        _requestError = '申請を送れませんでした。あとでもう一度試してね。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .58);
    final friend = widget.friend;
    final statusColor = _companionStatusColor(friend.statusKey);
    final relationshipAsync = widget.initialRelationship == null
        ? (friend.userId.trim().isEmpty
              ? const AsyncValue<NomoFriendRelationshipStatus>.data(
                  NomoFriendRelationshipStatus(
                    alreadyFriend: false,
                    requestState: NomoFriendRequestState.none,
                  ),
                )
              : ref.watch(_feedCompanionRelationshipProvider(friend.userId)))
        : AsyncValue<NomoFriendRelationshipStatus>.data(
            widget.initialRelationship!,
          );
    return NomoBottomSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NomoBottomSheetHandle(),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: NomoPopIcon(
                icon: CupertinoIcons.xmark,
                color: subtitleColor,
                size: 34,
                iconSize: 18,
                shadow: false,
              ),
            ),
          ),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 142,
                  height: 142,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [friend.accent, _FeedColors.teal],
                    ),
                  ),
                ),
                Container(
                  width: 130,
                  height: 130,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isWhite ? Colors.white : const Color(0xFFF4F2EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                  ),
                  child: ClipOval(
                    child: NomoAvatarView(avatar: friend.avatar, size: 112),
                  ),
                ),
                const Positioned(
                  right: 12,
                  top: 14,
                  child: NomoPopIcon(
                    icon: CupertinoIcons.sparkles,
                    color: Color(0xFFFFD166),
                    size: 32,
                    iconSize: 19,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            friend.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isWhite
                    ? const Color(0xFFF2F6F8)
                    : Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isWhite
                      ? const Color(0xFFE1E8F1)
                      : Colors.white.withValues(alpha: .10),
                ),
              ),
              child: Text(
                friend.handleLabel,
                style: TextStyle(
                  color: subtitleColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          relationshipAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (_, _) => _FeedCompanionRequestCard(
              isWhite: isWhite,
              subtitleColor: subtitleColor,
              message: 'プロフィール情報を確認できませんでした。',
              buttonLabel: '閉じる',
              onTap: () => Navigator.of(context).pop(),
            ),
            data: (relationship) {
              if (!relationship.alreadyFriend) {
                return _FeedCompanionRequestCard(
                  isWhite: isWhite,
                  subtitleColor: subtitleColor,
                  message: _requestError ?? 'フレンズになるとカレンダーを見られます。',
                  buttonLabel: switch (relationship.requestState) {
                    NomoFriendRequestState.outgoing => '申請済み',
                    NomoFriendRequestState.incoming => '申請を確認する',
                    NomoFriendRequestState.none => 'フレンド申請する',
                  },
                  isLoading: _isSendingRequest,
                  enabled:
                      relationship.requestState == NomoFriendRequestState.none,
                  onTap:
                      relationship.requestState == NomoFriendRequestState.none
                      ? _sendRequest
                      : () => Navigator.of(context).pop(),
                );
              }
              return _FeedCompanionStatusCard(
                friend: friend,
                isWhite: isWhite,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                statusColor: statusColor,
              );
            },
          ),
          const SizedBox(height: 16),
          _FeedModalTextButton(
            label: '閉じる',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
