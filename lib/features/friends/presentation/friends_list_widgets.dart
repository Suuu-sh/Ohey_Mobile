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

    if (filtered.isEmpty) {
      return _EmptyFriendsState(
        avatar: userAvatar,
        message: friends.isEmpty ? 'フレンズがいません' : 'この条件のフレンズはいません',
        subtitle: friends.isEmpty
            ? '右上の＋からフレンズを追加しよう'
            : selectedCustomFilter == null
            ? '別の条件を選ぶと見つかるかも'
            : 'フィルターを長押しすると編集できます',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 116),
      itemCount: filtered.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == filtered.length) {
          return _AddFriendsPromoCard(onTap: onAddFriend);
        }
        final item = filtered[index];
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
          Positioned(
            left: -34,
            bottom: -54,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _FriendsColors.lime.withValues(alpha: 0.05),
              ),
            ),
          ),
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
                            '友達を増やして、もっと楽しく飲もう',
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
              icon: CupertinoIcons.person_fill,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _PromoAvatarBubble(
              color: const Color(0xFF24D8B0),
              icon: CupertinoIcons.person_2_fill,
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
    required this.icon,
    this.isPrimary = false,
  });

  final Color color;
  final IconData icon;
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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: NomoGeneratedIcon(
          icon,
          color: Colors.white,
          size: isPrimary ? 22 : 19,
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
  });

  final NomoAvatar avatar;
  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: 116),
      child: Transform.translate(
        offset: const Offset(0, -42),
        child: NomoEmptyState(
          visual: _EmptyFriendsVisual(avatar: avatar),
          title: message,
          message: subtitle,
          titleColor: isWhite ? const Color(0xFF1B2633) : Colors.white,
          messageColor: isWhite
              ? const Color(0xFF6D7784)
              : Colors.white.withValues(alpha: .58),
          padding: EdgeInsets.zero,
          spacing: 14,
        ),
      ),
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
            right: 14,
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
