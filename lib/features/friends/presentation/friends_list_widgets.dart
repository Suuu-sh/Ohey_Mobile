part of 'friends_screen.dart';

class _FriendsList extends StatelessWidget {
  const _FriendsList({
    required this.friends,
    required this.userAvatar,
    required this.selectedFilter,
    required this.selectedCustomFilter,
    required this.favoriteOverrides,
    required this.onFavoriteToggle,
    required this.onAddFriend,
    required this.onInvite,
  });

  final List<NomoFriend> friends;
  final NomoAvatar userAvatar;
  final _FriendFilterType selectedFilter;
  final _CustomFriendFilter? selectedCustomFilter;
  final Map<String, bool> favoriteOverrides;
  final void Function(NomoFriend friend, bool isFavorite) onFavoriteToggle;
  final VoidCallback onAddFriend;
  final ValueChanged<NomoFriend> onInvite;

  @override
  Widget build(BuildContext context) {
    final decorated = [
      for (var i = 0; i < friends.length; i++)
        _DecoratedFriend(
          friend: _friendWithFavorite(
            friends[i],
            favoriteOverrides[friends[i].id] ?? friends[i].isFavorite,
          ),
          status: _statusForFriend(friends[i], i),
        ),
    ];
    final filtered = decorated.where((item) {
      if (selectedCustomFilter != null) {
        return _matchesCustomFilter(item, selectedCustomFilter!);
      }
      return switch (selectedFilter) {
        _FriendFilterType.all => true,
      };
    }).toList();
    final recommendations = decorated.where(_isRecommendedFriend).toList()
      ..sort(
        (a, b) =>
            _recommendationScoreFor(b).compareTo(_recommendationScoreFor(a)),
      );
    final hasRecommendations = recommendations.isNotEmpty;

    if (filtered.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          const bottomInset = 116.0;
          final contentHeight = constraints.maxHeight - bottomInset;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: bottomInset),
            children: [
              SizedBox(
                height: contentHeight > 0 ? contentHeight : 0,
                child: Center(
                  child: _EmptyFriendsState(
                    avatar: userAvatar,
                    message: friends.isEmpty ? 'フレンズがいません' : 'この条件のフレンズはいません',
                    subtitle: friends.isEmpty
                        ? 'QRコードかIDでフレンズを追加しよう'
                        : selectedCustomFilter == null
                        ? '別の条件を選ぶと見つかるかも'
                        : 'フィルターを長押しすると編集できます',
                    onAddFriend: onAddFriend,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 116),
      itemCount: filtered.length + 1 + (hasRecommendations ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (hasRecommendations && index == 0) {
          return _TodayInviteSection(
            friends: recommendations,
            onInvite: onInvite,
          );
        }
        final friendIndex = index - (hasRecommendations ? 1 : 0);
        if (friendIndex == filtered.length) {
          return _AddFriendsPromoCard(onTap: onAddFriend);
        }
        final item = filtered[friendIndex];
        return _FriendCard(
          friend: item.friend,
          status: item.status,
          onFavoriteToggle: () =>
              onFavoriteToggle(item.friend, !item.friend.isFavorite),
          onInvite: () => onInvite(item.friend),
        );
      },
    );
  }
}

class _TodayInviteSection extends StatelessWidget {
  const _TodayInviteSection({required this.friends, required this.onInvite});

  final List<_DecoratedFriend> friends;
  final ValueChanged<NomoFriend> onInvite;

  @override
  Widget build(BuildContext context) {
    final candidates = friends.take(8).toList();
    final blocked = friends
        .where((item) => !item.status.enabled)
        .take(2)
        .toList();
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF667381)
        : Colors.white.withValues(alpha: .60);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NomoPopIcon(
                icon: CupertinoIcons.sparkles,
                color: _FriendsColors.lime,
                size: 38,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'おすすめ',
                      style: TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '今誘いやすいフレンズを表示しています。',
                      style: TextStyle(
                        color: sub,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (candidates.isEmpty)
            _TodayInviteEmpty(isWhite: isWhite)
          else
            SizedBox(
              height: 178,
              child: Row(
                children: [
                  for (final entry in candidates.take(2).indexed) ...[
                    if (entry.$1 > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _TodayInviteCandidateCard(
                        item: entry.$2,
                        onInvite: () => onInvite(entry.$2.friend),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (blocked.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in blocked)
                  _TodayInviteBlockedChip(item: item, isWhite: isWhite),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayInviteCandidateCard extends StatelessWidget {
  const _TodayInviteCandidateCard({required this.item, required this.onInvite});

  final _DecoratedFriend item;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final friend = item.friend;
    final accent = _accentForFriend(friend);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final reason = _recommendationReasonFor(item);
    return NomoThemedPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
      accentColor: accent,
      backgroundColor: NomoThemedPanel.surfaceColor(isWhite: isWhite),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWhite
            ? const [Color(0xFFFFFFFF), Color(0xFFF7FFE9)]
            : [
                Colors.white.withValues(alpha: .06),
                accent.withValues(alpha: .08),
              ],
      ),
      borderRadius: 24,
      borderAlpha: isWhite ? .24 : .14,
      glowAlpha: isWhite ? .04 : .07,
      glowBlur: 18,
      glowOffset: const Offset(0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _FriendMiniAvatarBubble(
                avatar: friend.avatar ?? _fallbackAvatarForFriend(friend),
                accent: accent,
                size: 42,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _CompactStatusPill(status: item.status, accent: accent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.clock_fill,
                size: 13,
                color: isWhite
                    ? const Color(0xFF667381)
                    : Colors.white.withValues(alpha: .54),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite
                        ? const Color(0xFF667381)
                        : Colors.white.withValues(alpha: .68),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    letterSpacing: -.2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: Nomo3DButton(
              label: '誘う',
              icon: CupertinoIcons.paperplane_fill,
              onTap: onInvite,
              height: 36,
              radius: 18,
              color: _FriendsColors.lime,
              foregroundColor: _FriendsColors.limeForeground,
              shadowColor: _FriendsColors.limeShadow,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatusPill extends StatelessWidget {
  const _CompactStatusPill({required this.status, required this.accent});

  final _FriendStatus status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: status.enabled ? .18 : .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: status.enabled ? accent : _FriendsColors.muted,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: -.15,
        ),
      ),
    );
  }
}

class _FriendMiniAvatarBubble extends StatelessWidget {
  const _FriendMiniAvatarBubble({
    required this.avatar,
    required this.accent,
    this.size = 42,
  });

  final NomoAvatar avatar;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: isWhite ? .22 : .30),
        border: Border.all(
          color: isWhite
              ? Colors.white.withValues(alpha: .86)
              : const Color(0xFF072130),
          width: 3,
        ),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _FriendAvatarBubbleBackground(avatar: avatar),
            Center(
              child: Transform.translate(
                offset: Offset(0, size * .08),
                child: NomoAvatarView(
                  avatar: avatar,
                  size: size * .88,
                  showBody: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayInviteBlockedChip extends StatelessWidget {
  const _TodayInviteBlockedChip({required this.item, required this.isWhite});

  final _DecoratedFriend item;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isWhite
            ? const Color(0xFFF2F4F7)
            : Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${item.friend.name}: ${item.status.reason}',
        style: TextStyle(
          color: isWhite
              ? const Color(0xFF667381)
              : Colors.white.withValues(alpha: .56),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TodayInviteEmpty extends StatelessWidget {
  const _TodayInviteEmpty({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) => Text(
    '今日は誘えそうなフレンズがまだいません。ステータスが更新されるとここに出ます。',
    style: TextStyle(
      color: isWhite
          ? const Color(0xFF667381)
          : Colors.white.withValues(alpha: .58),
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.4,
    ),
  );
}

String _recommendationReasonFor(_DecoratedFriend item) {
  final friend = item.friend;
  if (friend.totalDrinkCount == 0) {
    return 'まだ一緒に行ったことない';
  }
  if (friend.isFavorite && _daysSinceLastDrink(friend) >= 30) {
    return '30日以上行ってない';
  }
  if (friend.statusKey == 'can_drink_today') {
    return '今日飲めそう';
  }
  if (friend.statusKey == 'non_alcohol') {
    return '軽く誘いやすい';
  }
  return '誘いやすい状態';
}

bool _isRecommendedFriend(_DecoratedFriend item) {
  final friend = item.friend;
  return friend.totalDrinkCount == 0 ||
      (friend.isFavorite && _daysSinceLastDrink(friend) >= 30) ||
      friend.statusKey == 'can_drink_today' ||
      friend.statusKey == 'non_alcohol';
}

int _recommendationScoreFor(_DecoratedFriend item) {
  final friend = item.friend;
  var score = 0;
  if (friend.totalDrinkCount == 0) score += 100;
  if (friend.isFavorite && _daysSinceLastDrink(friend) >= 30) score += 80;
  if (friend.statusKey == 'can_drink_today') score += 60;
  if (friend.statusKey == 'non_alcohol') score += 50;
  return score;
}

int _daysSinceLastDrink(NomoFriend friend) {
  final lastDrinkAt = friend.lastDrinkAt;
  if (lastDrinkAt == null) return 1 << 30;
  return DateTime.now().difference(lastDrinkAt).inDays;
}

class _AddFriendsPromoCard extends StatelessWidget {
  const _AddFriendsPromoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 106,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWhite
              ? const [Color(0xFF123D4A), Color(0xFF092334)]
              : const [Color(0xFF0B3240), Color(0xFF071A2B)],
        ),
        border: Border.all(
          color: const Color(0xFF37DFCF).withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1FE4C9).withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Row(
                children: [
                  const _FriendPromoAvatarStack(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'フレンズを追加しよう',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.94),
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'フレンズを増やして、もっと楽しく飲もう',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 76,
                    child: Semantics(
                      button: true,
                      label: 'フレンズを追加',
                      child: Nomo3DButton(
                        label: '追加',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTap();
                        },
                        height: 40,
                        radius: 20,
                        color: _FriendsColors.lime,
                        foregroundColor: const Color(0xFF0B2A22),
                        shadowColor: const Color(0xFF77A600),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendPromoAvatarStack extends StatelessWidget {
  const _FriendPromoAvatarStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 24,
            top: 8,
            child: _PromoAvatarBubble(
              color: const Color(0xFF7C5CFF),
              avatar: const NomoAvatar(
                skin: 0,
                hair: 3,
                shirt: 4,
                eyes: 1,
                mouth: 1,
                accessory: 0,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _PromoAvatarBubble(
              color: const Color(0xFF24D8B0),
              avatar: const NomoAvatar(
                skin: 5,
                hair: 1,
                shirt: 8,
                eyes: 2,
                mouth: 0,
                accessory: 1,
              ),
              isPrimary: true,
            ),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _FriendsColors.lime,
                border: Border.all(color: const Color(0xFF0B3240), width: 3),
              ),
              child: const Center(
                child: NomoGeneratedIcon(
                  CupertinoIcons.plus,
                  color: Color(0xFF0B2A22),
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoAvatarBubble extends StatelessWidget {
  const _PromoAvatarBubble({
    required this.color,
    required this.avatar,
    this.isPrimary = false,
  });

  final Color color;
  final NomoAvatar avatar;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final size = isPrimary ? 50.0 : 44.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: const Color(0xFF072130), width: 4),
      ),
      child: ClipOval(
        child: Container(
          color: color,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, isPrimary ? 5 : 4),
            child: NomoAvatarView(
              avatar: avatar,
              size: isPrimary ? 46 : 40,
              showBody: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _DecoratedFriend {
  const _DecoratedFriend({required this.friend, required this.status});

  final NomoFriend friend;
  final _FriendStatus status;
}

bool _matchesCustomFilter(_DecoratedFriend item, _CustomFriendFilter filter) {
  if (filter.friendIds.isNotEmpty &&
      !filter.friendIds.contains(item.friend.id)) {
    return false;
  }
  if (filter.statusKeys.isNotEmpty &&
      !filter.statusKeys.contains(_normalizedStatusKey(item.friend))) {
    return false;
  }
  if (filter.genderKeys.isNotEmpty &&
      !filter.genderKeys.contains(item.friend.gender.key)) {
    return false;
  }
  if (filter.favoriteOnly && !item.friend.isFavorite) return false;
  if (filter.drinkableOnly && !_isDrinkableStatus(item.status)) return false;
  if (filter.onlineOnly && item.friend.isOnline != true) return false;
  return true;
}

String _normalizedStatusKey(NomoFriend friend) {
  return switch (friend.statusKey) {
    'can_drink_today' => 'can_drink_today',
    'non_alcohol' => 'non_alcohol',
    'liver_rest' => 'liver_rest',
    'has_plans' => 'has_plans',
    _ => 'unset',
  };
}

NomoFriend _friendWithFavorite(NomoFriend friend, bool isFavorite) {
  if (friend.isFavorite == isFavorite) return friend;
  return NomoFriend(
    id: friend.id,
    name: friend.name,
    avatarEmoji: friend.avatarEmoji,
    vibe: friend.vibe,
    characterAssetPath: friend.characterAssetPath,
    kind: friend.kind,
    palette: friend.palette,
    gender: friend.gender,
    avatar: friend.avatar,
    monthlyCount: friend.monthlyCount,
    totalDrinkCount: friend.totalDrinkCount,
    lastDrinkAt: friend.lastDrinkAt,
    statusKey: friend.statusKey,
    isOnline: friend.isOnline,
    isFavorite: isFavorite,
  );
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState({
    required this.avatar,
    required this.message,
    required this.subtitle,
    required this.onAddFriend,
  });

  final NomoAvatar avatar;
  final String message;
  final String subtitle;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return NomoEmptyState(
      visual: _EmptyFriendsVisual(avatar: avatar),
      title: message,
      message: subtitle,
      titleColor: isWhite ? const Color(0xFF1B2633) : Colors.white,
      messageColor: isWhite
          ? const Color(0xFF6D7784)
          : Colors.white.withValues(alpha: .58),
      padding: EdgeInsets.zero,
      spacing: 14,
      action: message == 'フレンズがいません'
          ? _EmptyFriendsActions(onAddFriend: onAddFriend)
          : null,
    );
  }
}

class _EmptyFriendsActions extends StatelessWidget {
  const _EmptyFriendsActions({required this.onAddFriend});

  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 118,
          child: Nomo3DButton(
            label: 'QRで追加',
            icon: CupertinoIcons.qrcode_viewfinder,
            onTap: onAddFriend,
            height: 44,
            radius: 20,
            color: _FriendsColors.lime,
            foregroundColor: _FriendsColors.limeForeground,
            shadowColor: _FriendsColors.limeShadow,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 118,
          child: Nomo3DButton.secondary(
            label: 'IDで追加',
            icon: CupertinoIcons.at,
            onTap: onAddFriend,
            height: 44,
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _EmptyFriendsVisual extends StatelessWidget {
  const _EmptyFriendsVisual({required this.avatar});

  final NomoAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      width: 132,
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _FriendsColors.lime.withValues(alpha: .26),
                  _FriendsColors.lime.withValues(alpha: .04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 86,
            height: 86,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isWhite
                  ? Colors.white
                  : Colors.white.withValues(alpha: .07),
              border: Border.all(
                color: _FriendsColors.lime.withValues(alpha: .45),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: _FriendsColors.lime.withValues(alpha: .18),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: NomoAvatarView(avatar: avatar, size: 76),
          ),
          Positioned(
            right: 22,
            bottom: 18,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _FriendsColors.lime,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isWhite ? Colors.white : _FriendsColors.bg,
                  width: 3,
                ),
              ),
              child: const Center(
                child: NomoGeneratedIcon(
                  CupertinoIcons.plus,
                  color: _FriendsColors.bg,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isDrinkableStatus(_FriendStatus status) {
  return switch (status.label) {
    '今日飲める' || 'ノンアルなら' || '未設定' => true,
    _ => false,
  };
}
