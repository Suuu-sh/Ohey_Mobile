part of 'home_screen.dart';

class _FeedCompanionListSheet extends StatelessWidget {
  const _FeedCompanionListSheet({required this.friends});

  final List<_Companion> friends;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? AppColors.cFF101820 : AppColors.white;
    final subtitleColor = isWhite
        ? AppColors.cFF697684
        : AppColors.white.withValues(alpha: .58);
    final listHeight = (friends.length * 78.0).clamp(
      78.0,
      MediaQuery.sizeOf(context).height * .44,
    );
    return OheyBottomSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OheyPopIcon(
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
              const SizedBox.shrink(),
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
    final titleColor = isWhite ? AppColors.cFF101820 : AppColors.white;
    final subtitleColor = isWhite
        ? AppColors.cFF697684
        : AppColors.white.withValues(alpha: .56);
    final statusColor = _companionStatusColor(friend.statusKey);
    final tileColor = isWhite
        ? AppColors.cFFF7FAFC
        : Color.lerp(AppColors.darkBackground, friend.accent, .20)!;
    final tileBorderColor = isWhite
        ? AppColors.cFFE1E8F1
        : Color.lerp(
            friend.accent,
            AppColors.white,
            .18,
          )!.withValues(alpha: .26);
    final statusBackgroundColor = isWhite
        ? statusColor.withValues(alpha: .13)
        : Color.lerp(AppColors.darkBackground, statusColor, .34)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tileBorderColor),
        ),
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
                color: statusBackgroundColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _companionStatusLabel(friend.statusKey),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OheyPopIcon(
              icon: CupertinoIcons.chevron_forward,
              color: subtitleColor,
              size: 28,
              iconSize: 15,
              shadow: false,
            ),
          ],
        ),
      ),
    );
  }
}

final _feedCompanionRelationshipProvider = FutureProvider.autoDispose
    .family<OheyFriendRelationshipStatus, String>((ref, userId) {
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
            ? AppColors.cFFF7FAFC
            : AppColors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isWhite
              ? AppColors.cFFE1E8F1
              : AppColors.white.withValues(alpha: .08),
        ),
      ),
      child: Row(
        children: [
          OheyPopIcon(
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
            ? AppColors.cFFF7FAFC
            : AppColors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isWhite
              ? AppColors.cFFE1E8F1
              : AppColors.white.withValues(alpha: .08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const OheyPopIcon(
                icon: CupertinoIcons.lock_fill,
                color: AppColors.cFFC08BFF,
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
          Ohey3DButton(
            label: buttonLabel,
            icon: CupertinoIcons.person_badge_plus_fill,
            onTap: enabled ? onTap : null,
            isLoading: isLoading,
            enabled: enabled,
            height: 46,
            radius: 20,
            color: AppColors.cFFC08BFF,
            foregroundColor: AppColors.white,
            shadowColor: AppColors.cFF7F51C9,
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
  final OheyFriendRelationshipStatus? initialRelationship;

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
      OheyToast.show(
        context,
        '${widget.friend.name}にフレンド申請を送りました',
        icon: CupertinoIcons.paperplane_fill,
        placement: OheyToastPlacement.bottom,
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
    final friend = widget.friend;
    final statusColor = _companionStatusColor(friend.statusKey);
    final media = MediaQuery.of(context);
    final sheetContentHeight = media.size.height - media.padding.bottom;
    final relationshipAsync = widget.initialRelationship == null
        ? (friend.userId.trim().isEmpty
              ? const AsyncValue<OheyFriendRelationshipStatus>.data(
                  OheyFriendRelationshipStatus(
                    alreadyFriend: false,
                    requestState: OheyFriendRequestState.none,
                  ),
                )
              : ref.watch(_feedCompanionRelationshipProvider(friend.userId)))
        : AsyncValue<OheyFriendRelationshipStatus>.data(
            widget.initialRelationship!,
          );

    return OheyBottomSheetShell(
      padding: EdgeInsets.zero,
      radius: 0,
      maxHeightFactor: 1,
      followKeyboard: false,
      child: SizedBox(
        height: sheetContentHeight,
        child: ColoredBox(
          color: AppColors.darkBackgroundBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FeedCompanionTopBackdrop(friend: friend),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: relationshipAsync.when(
                    loading: () =>
                        const Center(child: CupertinoActivityIndicator()),
                    error: (_, _) => _FeedCompanionRequestCard(
                      isWhite: false,
                      subtitleColor: AppColors.white.withValues(alpha: .58),
                      message: 'プロフィール情報を確認できませんでした。',
                      buttonLabel: '閉じる',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    data: (relationship) {
                      if (!relationship.alreadyFriend) {
                        return Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: double.infinity,
                            child: _FeedCompanionRequestCard(
                              isWhite: false,
                              subtitleColor: AppColors.white.withValues(
                                alpha: .58,
                              ),
                              message: _requestError ?? 'フレンズになるとカレンダーを見られます。',
                              buttonLabel: switch (relationship.requestState) {
                                OheyFriendRequestState.outgoing => '申請済み',
                                OheyFriendRequestState.incoming => '申請を確認する',
                                OheyFriendRequestState.none => 'フレンド申請する',
                              },
                              isLoading: _isSendingRequest,
                              enabled:
                                  relationship.requestState ==
                                  OheyFriendRequestState.none,
                              onTap:
                                  relationship.requestState ==
                                      OheyFriendRequestState.none
                                  ? _sendRequest
                                  : () => Navigator.of(context).pop(),
                            ),
                          ),
                        );
                      }
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: double.infinity,
                          height: 92,
                          child: _FeedCompanionStatusCard(
                            friend: friend,
                            isWhite: false,
                            titleColor: AppColors.white,
                            subtitleColor: AppColors.white.withValues(
                              alpha: .58,
                            ),
                            statusColor: statusColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Ohey3DButton.secondary(
                  label: '閉じる',
                  onTap: () => Navigator.of(context).pop(),
                  height: 48,
                  radius: 22,
                  color: AppColors.cFF252044,
                  foregroundColor: AppColors.cFFC08BFF,
                  shadowColor: AppColors.cFF15142C,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedCompanionTopBackdrop extends StatelessWidget {
  const _FeedCompanionTopBackdrop({required this.friend});

  final _Companion friend;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final headerHeight = topPadding + 318;
    return SizedBox(
      height: headerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _FeedCompanionHeaderBackdrop(avatar: friend.avatar),
          Padding(
            padding: EdgeInsets.fromLTRB(
              OheyPageHeader.horizontalPadding,
              topPadding + 4,
              OheyPageHeader.horizontalPadding,
              6,
            ),
            child: Column(
              children: [
                const Spacer(),
                _FeedCompanionHero(friend: friend),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCompanionHeaderBackdrop extends StatelessWidget {
  const _FeedCompanionHeaderBackdrop({required this.avatar});

  final OheyAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final imageBackdropAsset = OheyAvatar.imageBackdropAsset(avatar.background);
    if (imageBackdropAsset != null) {
      return ExcludeSemantics(
        child: Image.asset(
          imageBackdropAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      );
    }

    final backgroundColors =
        OheyAvatar.backgroundGradients[avatar.background %
            OheyAvatar.backgroundGradients.length];
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: backgroundColors,
            ),
          ),
        ),
        Opacity(
          opacity: avatar.background == OheyAvatar.dreamRoomBackground
              ? .18
              : .10,
          child: ExcludeSemantics(
            child: Image.asset(
              'assets/images/profile_header_scene.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.white.withValues(alpha: .18),
                AppColors.white.withValues(alpha: .36),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedCompanionHero extends StatelessWidget {
  const _FeedCompanionHero({required this.friend});

  final _Companion friend;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 190,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: OheyAvatarView(avatar: friend.avatar, size: 156),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 9),
            color: AppColors.darkBackgroundBottom,
            child: Center(
              child: Text(
                '${friend.name} ・ ${friend.handleLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: .72),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
