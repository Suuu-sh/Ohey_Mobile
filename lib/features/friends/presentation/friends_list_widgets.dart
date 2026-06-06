part of 'friends_screen.dart';

class _FriendsRefreshIndicator extends StatelessWidget {
  const _FriendsRefreshIndicator({
    required this.state,
    required this.pulledExtent,
    required this.triggerDistance,
    required this.showDone,
  });

  final RefreshIndicatorMode state;
  final double pulledExtent;
  final double triggerDistance;
  final bool showDone;

  @override
  Widget build(BuildContext context) {
    final label = showDone
        ? '更新しました'
        : switch (state) {
            RefreshIndicatorMode.inactive || RefreshIndicatorMode.drag => '',
            RefreshIndicatorMode.armed ||
            RefreshIndicatorMode.refresh => '更新中...',
            RefreshIndicatorMode.done => '',
          };

    return SizedBox(
      height: pulledExtent,
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        minHeight: 0,
        maxHeight: 60,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: label.isEmpty ? 0 : 1,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: AppColors.cFF101C2B.withValues(alpha: .82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _FriendsColors.lime.withValues(alpha: .24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _FriendsColors.lime.withValues(alpha: .18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList({
    required this.friends,
    required this.userAvatar,
    required this.selectedFilter,
    required this.selectedCustomFilter,
    required this.favoriteOverrides,
    required this.invitedFriendIds,
    required this.onRefresh,
    required this.showRefreshDone,
    required this.isSendingGroupInvite,
    required this.onFavoriteToggle,
    required this.onAddFriend,
    required this.onInvite,
    required this.onGroupInvite,
    required this.onInviteAnimationComplete,
    required this.onProfile,
  });

  final List<OheyFriend> friends;
  final OheyAvatar userAvatar;
  final _FriendFilterType selectedFilter;
  final _CustomFriendFilter? selectedCustomFilter;
  final Map<String, bool> favoriteOverrides;
  final Set<String> invitedFriendIds;
  final Future<void> Function() onRefresh;
  final bool showRefreshDone;
  final bool isSendingGroupInvite;
  final void Function(OheyFriend friend, bool isFavorite) onFavoriteToggle;
  final VoidCallback onAddFriend;
  final Future<void> Function(OheyFriend friend) onInvite;
  final Future<void> Function(List<OheyFriend> friends) onGroupInvite;
  final void Function(OheyFriend friend) onInviteAnimationComplete;
  final void Function(OheyFriend friend, _FriendStatus status) onProfile;

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
          originalIndex: i,
        ),
    ]..sort(_compareFriendsForList);
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
    final isGroupView = selectedCustomFilter != null;
    final hasRecommendations = !isGroupView && recommendations.isNotEmpty;
    final hasGroupSchedule = isGroupView && filtered.isNotEmpty;
    final groupInviteTargets = filtered
        .where(
          (item) =>
              item.status.enabled && !invitedFriendIds.contains(item.friend.id),
        )
        .map((item) => item.friend)
        .toList(growable: false);
    final listEntries = _friendListEntriesFromFriends(filtered);

    Widget withRefresh(Widget child) => CustomScrollView(
      clipBehavior: Clip.hardEdge,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: 56,
          refreshIndicatorExtent: 56,
          onRefresh: onRefresh,
          builder:
              (
                context,
                refreshState,
                pulledExtent,
                refreshTriggerPullDistance,
                refreshIndicatorExtent,
              ) => _FriendsRefreshIndicator(
                state: refreshState,
                pulledExtent: pulledExtent,
                triggerDistance: refreshTriggerPullDistance,
                showDone: showRefreshDone,
              ),
        ),
        child,
      ],
    );

    if (filtered.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          const bottomInset = 168.0;
          final contentHeight = constraints.maxHeight - bottomInset;
          return withRefresh(
            SliverPadding(
              padding: const EdgeInsets.only(bottom: bottomInset),
              sliver: SliverList.list(
                children: [
                  SizedBox(
                    height: contentHeight > 0 ? contentHeight : 0,
                    child: Center(
                      child: _EmptyFriendsState(
                        avatar: userAvatar,
                        message: friends.isEmpty
                            ? 'フレンズがいません'
                            : 'この条件のフレンズはいません',
                        subtitle: friends.isEmpty
                            ? 'QRコードかIDでフレンズを追加しよう'
                            : selectedCustomFilter == null
                            ? '別の条件を選ぶと見つかるかも'
                            : '長押しでグループ編集',
                        onAddFriend: onAddFriend,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return withRefresh(
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 168),
        sliver: SliverList.separated(
          itemCount:
              listEntries.length +
              1 +
              (hasRecommendations ? 1 : 0) +
              (hasGroupSchedule ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            if (hasRecommendations && index == 0) {
              return _TodayInviteSection(
                friends: recommendations,
                invitedFriendIds: invitedFriendIds,
                onInvite: onInvite,
                onInviteAnimationComplete: onInviteAnimationComplete,
              );
            }
            if (hasGroupSchedule && index == 0) {
              return _GroupScheduleSection(
                groupName: selectedCustomFilter!.name,
                friends: filtered,
                inviteTargets: groupInviteTargets,
                isSendingInvite: isSendingGroupInvite,
                onInviteGroup: () => onGroupInvite(groupInviteTargets),
              );
            }
            final friendIndex =
                index -
                (hasRecommendations ? 1 : 0) -
                (hasGroupSchedule ? 1 : 0);
            if (friendIndex == listEntries.length) {
              return _AddFriendsPromoCard(onTap: onAddFriend);
            }
            final entry = listEntries[friendIndex];
            return switch (entry) {
              _FriendBlockEntry(:final item) => _FriendCard(
                friend: item.friend,
                status: item.status,
                onFavoriteToggle: () =>
                    onFavoriteToggle(item.friend, !item.friend.isFavorite),
                isInvited: invitedFriendIds.contains(item.friend.id),
                onInvite: () => onInvite(item.friend),
                onInviteAnimationComplete: () =>
                    onInviteAnimationComplete(item.friend),
                onProfile: () => onProfile(item.friend, item.status),
              ),
              _FriendAdBlockEntry(:final index) => _FriendNativeAdBlock(
                index: index,
              ),
            };
          },
        ),
      ),
    );
  }
}

const _friendsAdNativeFactoryId = 'ohey_yurubo_native_ad';
const _friendsFirstAdAfter = 2;
const _friendsAdFrequency = 3;

String get _friendsNativeAdUnitId => OheyAdsConfig.nativeAdUnitId;

List<_FriendListEntry> _friendListEntriesFromFriends(
  List<_DecoratedFriend> friends,
) {
  if (friends.length < _friendsFirstAdAfter) {
    return [for (final item in friends) _FriendBlockEntry(item)];
  }
  final entries = <_FriendListEntry>[];
  var adIndex = 0;
  for (var index = 0; index < friends.length; index++) {
    entries.add(_FriendBlockEntry(friends[index]));
    final position = index + 1;
    final shouldInsertAd =
        position == _friendsFirstAdAfter ||
        (position > _friendsFirstAdAfter &&
            (position - _friendsFirstAdAfter) % _friendsAdFrequency == 0);
    if (shouldInsertAd) entries.add(_FriendAdBlockEntry(adIndex++));
  }
  return entries;
}

sealed class _FriendListEntry {
  const _FriendListEntry();
}

class _FriendBlockEntry extends _FriendListEntry {
  const _FriendBlockEntry(this.item);

  final _DecoratedFriend item;
}

class _FriendAdBlockEntry extends _FriendListEntry {
  const _FriendAdBlockEntry(this.index);

  final int index;
}

class _FriendNativeAdBlock extends StatefulWidget {
  const _FriendNativeAdBlock({required this.index});

  final int index;

  @override
  State<_FriendNativeAdBlock> createState() => _FriendNativeAdBlockState();
}

class _FriendNativeAdBlockState extends State<_FriendNativeAdBlock> {
  NativeAd? _ad;
  bool _isLoaded = false;
  bool _didFail = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adUnitId = _friendsNativeAdUnitId;
    if (adUnitId.isEmpty) {
      _didFail = true;
      return;
    }
    final canRequestAds = await OheyAdsConsentService.prepareToRequestAds();
    if (!mounted) return;
    if (!canRequestAds) {
      setState(() => _didFail = true);
      return;
    }
    final ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: _friendsAdNativeFactoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as NativeAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _didFail = true);
        },
      ),
    );
    ad.load().catchError((_) {
      if (!mounted) return;
      setState(() => _didFail = true);
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_didFail) return const SizedBox.shrink();
    if (!_isLoaded || _ad == null) return const _FriendAdPlaceholderBlock();
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      label: '広告',
      child: OheyThemedPanel(
        padding: EdgeInsets.zero,
        accentColor: _FriendsColors.lime,
        backgroundColor: isWhite
            ? AppColors.white
            : AppColors.darkBackgroundBottom,
        borderRadius: 20,
        borderAlpha: isWhite ? .28 : .36,
        glowAlpha: isWhite ? .08 : .14,
        glowBlur: 22,
        glowOffset: Offset.zero,
        child: SizedBox(
          height: 156,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: AdWidget(ad: _ad!),
          ),
        ),
      ),
    );
  }
}

class _FriendAdPlaceholderBlock extends StatelessWidget {
  const _FriendAdPlaceholderBlock();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return OheyThemedPanel(
      padding: const EdgeInsets.all(14),
      accentColor: _FriendsColors.lime,
      backgroundColor: isWhite
          ? AppColors.white
          : AppColors.darkBackgroundBottom,
      borderRadius: 20,
      borderAlpha: isWhite ? .28 : .36,
      glowAlpha: isWhite ? .08 : .14,
      glowBlur: 22,
      glowOffset: Offset.zero,
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _FriendsColors.lime.withValues(alpha: .16),
            ),
            child: const Center(
              child: Text(
                'PR',
                style: TextStyle(
                  color: _FriendsColors.lime,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(
                      alpha: isWhite ? .22 : .10,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: .68,
                  child: Container(
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(
                        alpha: isWhite ? .16 : .07,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
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

class _TodayInviteSection extends StatelessWidget {
  const _TodayInviteSection({
    required this.friends,
    required this.invitedFriendIds,
    required this.onInvite,
    required this.onInviteAnimationComplete,
  });

  final List<_DecoratedFriend> friends;
  final Set<String> invitedFriendIds;
  final Future<void> Function(OheyFriend friend) onInvite;
  final void Function(OheyFriend friend) onInviteAnimationComplete;

  @override
  Widget build(BuildContext context) {
    final candidates = friends.take(8).toList();
    final blocked = friends
        .where((item) => !item.status.enabled)
        .take(2)
        .toList();
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FriendsSectionHeader(
            icon: CupertinoIcons.sparkles,
            iconColor: _FriendsColors.lime,
            title: 'おすすめ',
            subtitle: 'あなたにおすすめのフレンズを表示しています。',
          ),
          const SizedBox(height: 14),
          if (candidates.isEmpty)
            _TodayInviteEmpty(isWhite: isWhite)
          else
            SizedBox(
              height: 142,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 520),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                transitionBuilder: (child, animation) =>
                    _SlimeSplitTransition(animation: animation, child: child),
                child: _TodayInviteCardsStrip(
                  key: ValueKey(
                    '${candidates.length}-${candidates.map((item) => item.friend.id).join(',')}',
                  ),
                  candidates: candidates,
                  invitedFriendIds: invitedFriendIds,
                  onInvite: onInvite,
                  onInviteAnimationComplete: onInviteAnimationComplete,
                ),
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
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            height: 1.5,
            color: isWhite
                ? AppColors.cFFE1E7DE
                : AppColors.white.withValues(alpha: .14),
          ),
        ],
      ),
    );
  }
}

class _TodayInviteCardsStrip extends StatelessWidget {
  const _TodayInviteCardsStrip({
    super.key,
    required this.candidates,
    required this.invitedFriendIds,
    required this.onInvite,
    required this.onInviteAnimationComplete,
  });

  final List<_DecoratedFriend> candidates;
  final Set<String> invitedFriendIds;
  final Future<void> Function(OheyFriend friend) onInvite;
  final void Function(OheyFriend friend) onInviteAnimationComplete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingle = candidates.length == 1;
        final cardWidth = isSingle
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: candidates.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) => TweenAnimationBuilder<double>(
            key: ValueKey(candidates[index].friend.id),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 420 + index * 70),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              final squeeze = 1 - value;
              return Transform.scale(
                scaleX: 1 + squeeze * (isSingle ? .10 : .18),
                scaleY: 1 - squeeze * .08,
                alignment: Alignment.center,
                child: Opacity(opacity: value.clamp(0, 1), child: child),
              );
            },
            child: SizedBox(
              width: cardWidth,
              child: _TodayInviteCandidateCard(
                item: candidates[index],
                isInvited: invitedFriendIds.contains(
                  candidates[index].friend.id,
                ),
                onInvite: () => onInvite(candidates[index].friend),
                onInviteAnimationComplete: () =>
                    onInviteAnimationComplete(candidates[index].friend),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FriendsSectionHeader extends StatelessWidget {
  const _FriendsSectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .60);

    return SizedBox(
      height: 47,
      child: Row(
        children: [
          OheyPopIcon(icon: icon, color: iconColor, size: 38, iconSize: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class _SlimeSplitTransition extends StatelessWidget {
  const _SlimeSplitTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = Curves.easeOutBack.transform(animation.value.clamp(0, 1));
        final squash = 1 - value;
        return Transform.scale(
          scaleX: 1 + squash * .16,
          scaleY: 1 - squash * .10,
          alignment: Alignment.centerLeft,
          child: Opacity(opacity: animation.value.clamp(0, 1), child: child),
        );
      },
    );
  }
}

class _GroupScheduleSection extends StatelessWidget {
  const _GroupScheduleSection({
    required this.groupName,
    required this.friends,
    required this.inviteTargets,
    required this.isSendingInvite,
    required this.onInviteGroup,
  });

  final String groupName;
  final List<_DecoratedFriend> friends;
  final List<OheyFriend> inviteTargets;
  final bool isSendingInvite;
  final Future<void> Function() onInviteGroup;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final suggestions = _groupScheduleSuggestions(friends);
    final isGroupInvited = inviteTargets.isEmpty;
    final canInviteGroup = !isGroupInvited && !isSendingInvite;
    final inviteButtonColor = isGroupInvited
        ? _FriendsColors.invitedButton
        : _FriendsColors.lime;
    final inviteButtonForeground = isGroupInvited
        ? _FriendsColors.invitedButtonForeground
        : AppColors.cFF101820;
    final inviteButtonShadow = isGroupInvited
        ? _FriendsColors.invitedButtonShadow
        : Color.lerp(_FriendsColors.lime, AppColors.black, .34);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FriendsSectionHeader(
            icon: CupertinoIcons.calendar_badge_plus,
            iconColor: AppColors.cFF5DEBD3,
            title: '$groupNameで集まる日',
            subtitle: 'グループからまとめて誘えるよ。',
            trailing: SizedBox(
              width: 104,
              child: Ohey3DButton(
                label: isSendingInvite
                    ? '送信中'
                    : isGroupInvited
                    ? '招待済み'
                    : '全員招待',
                onTap: canInviteGroup ? onInviteGroup : null,
                enabled: canInviteGroup,
                height: 38,
                radius: 19,
                color: inviteButtonColor,
                foregroundColor: inviteButtonForeground,
                shadowColor: inviteButtonShadow,
                disabledColor: _FriendsColors.invitedButton,
                disabledOpacity: 1,
                forcePressed: isGroupInvited,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 142,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInBack,
              transitionBuilder: (child, animation) =>
                  _SlimeSplitTransition(animation: animation, child: child),
              child: _GroupScheduleCardsStrip(
                key: ValueKey(
                  suggestions
                      .map(
                        (suggestion) =>
                            '${suggestion.title}-${suggestion.badge}',
                      )
                      .join(','),
                ),
                suggestions: suggestions,
                isWhite: isWhite,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            height: 1.5,
            color: isWhite
                ? AppColors.cFFE1E7DE
                : AppColors.white.withValues(alpha: .14),
          ),
        ],
      ),
    );
  }
}

class _GroupScheduleCardsStrip extends StatelessWidget {
  const _GroupScheduleCardsStrip({
    super.key,
    required this.suggestions,
    required this.isWhite,
  });

  final List<_GroupScheduleSuggestion> suggestions;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) => TweenAnimationBuilder<double>(
            key: ValueKey(
              '${suggestions[index].title}-${suggestions[index].badge}',
            ),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 420 + index * 70),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              final squeeze = 1 - value;
              return Transform.scale(
                scaleX: 1 + squeeze * .18,
                scaleY: 1 - squeeze * .08,
                alignment: Alignment.center,
                child: Opacity(opacity: value.clamp(0, 1), child: child),
              );
            },
            child: SizedBox(
              width: cardWidth,
              child: _GroupScheduleSuggestionCard(
                suggestion: suggestions[index],
                isWhite: isWhite,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroupScheduleSuggestionCard extends StatelessWidget {
  const _GroupScheduleSuggestionCard({
    required this.suggestion,
    required this.isWhite,
  });

  final _GroupScheduleSuggestion suggestion;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .62);
    return OheyThemedPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
      accentColor: suggestion.accent,
      backgroundColor: OheyThemedPanel.surfaceColor(isWhite: isWhite),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWhite
            ? const [AppColors.cFFFFFFFF, AppColors.cFFF7FFE9]
            : [
                AppColors.white.withValues(alpha: .06),
                suggestion.accent.withValues(alpha: .08),
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
            children: [
              OheyPopIcon(
                icon: CupertinoIcons.calendar_badge_plus,
                color: suggestion.accent,
                size: 40,
                iconSize: 20,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: suggestion.accent.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  suggestion.badge,
                  style: TextStyle(
                    color: suggestion.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            suggestion.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -.25,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            suggestion.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sub,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayInviteCandidateCard extends StatelessWidget {
  const _TodayInviteCandidateCard({
    required this.item,
    required this.isInvited,
    required this.onInvite,
    required this.onInviteAnimationComplete,
  });

  final _DecoratedFriend item;
  final bool isInvited;
  final Future<void> Function() onInvite;
  final VoidCallback onInviteAnimationComplete;

  @override
  Widget build(BuildContext context) {
    final friend = item.friend;
    final frameAccent = _friendBlockFrameColor(item.status);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final isInviteEnabled = item.status.enabled && !isInvited;
    final buttonColor = isInvited
        ? _FriendsColors.invitedButton
        : _friendInviteButtonColor(item.status);
    final buttonForeground = isInvited
        ? _FriendsColors.invitedButtonForeground
        : _friendInviteButtonForegroundColor(item.status);
    final ink = item.status.enabled
        ? (isWhite ? AppColors.cFF101820 : AppColors.white)
        : (isWhite ? AppColors.cFF667381 : _FriendsColors.muted);
    return OheyThemedPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
      accentColor: frameAccent,
      backgroundColor: _friendBlockSurfaceColor(isWhite: isWhite),
      borderRadius: 24,
      borderAlpha: _friendBlockBorderAlpha(
        isWhite: isWhite,
        status: item.status,
      ),
      glowAlpha: _friendInviteCardGlowAlpha(
        isWhite: isWhite,
        status: item.status,
      ),
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
                accent: frameAccent,
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
                    _CompactStatusPill(status: item.status),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OheyInviteSuccessBurst(
              builder: (context, runWithBurst, flightAnimation) => Ohey3DButton(
                label: isInvited ? '招待済み' : '招待する',
                icon: null,
                customIcon: null,
                onTap: isInviteEnabled
                    ? () => runWithBurst(
                        onInvite,
                        afterAnimation: onInviteAnimationComplete,
                      )
                    : null,
                enabled: isInviteEnabled,
                forcePressed: isInvited,
                height: 40,
                radius: 20,
                color: buttonColor,
                foregroundColor: buttonForeground,
                shadowColor: isInvited
                    ? _FriendsColors.invitedButtonShadow
                    : _friendInviteButtonShadowColor(item.status),
                disabledColor: isInvited
                    ? _FriendsColors.invitedButton
                    : _FriendsColors.disabledButton,
                disabledOpacity: 1,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatusPill extends StatelessWidget {
  const _CompactStatusPill({required this.status});

  final _FriendStatus status;

  @override
  Widget build(BuildContext context) {
    final accent = _friendStatusPillColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: status.enabled ? .20 : .38),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: status.enabled
              ? accent
              : _friendInviteButtonForegroundColor(status),
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: -.15,
        ),
      ),
    );
  }
}

class _FriendAvatarBubbleBackground extends StatelessWidget {
  const _FriendAvatarBubbleBackground({required this.avatar});

  final OheyAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final colors =
        OheyAvatar.backgroundGradients[avatar.background %
            OheyAvatar.backgroundGradients.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
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

  final OheyAvatar avatar;
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
              ? AppColors.white.withValues(alpha: .86)
              : AppColors.cFF072130,
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
                child: OheyAvatarView(
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
            ? AppColors.cFFF2F4F7
            : AppColors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${item.friend.name}: ${item.status.reason}',
        style: TextStyle(
          color: isWhite
              ? AppColors.cFF667381
              : AppColors.white.withValues(alpha: .56),
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
    '今日はまだ誘えそうなフレンズがいないみたい。',
    style: TextStyle(
      color: isWhite
          ? AppColors.cFF667381
          : AppColors.white.withValues(alpha: .58),
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.4,
    ),
  );
}

class _GroupScheduleSuggestion {
  const _GroupScheduleSuggestion({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color accent;
}

List<_GroupScheduleSuggestion> _groupScheduleSuggestions(
  List<_DecoratedFriend> friends,
) {
  final stats = _groupAvailabilityStats(friends);
  final now = DateTime.now();

  final tiers = <_GroupScheduleTier>[
    if (stats.isAllOk)
      const _GroupScheduleTier(
        dayOffset: 0,
        title: '全員OK',
        subtitle: '全員いけそう。まずこの日を押さえよ。',
        accent: AppColors.cFFFF5EA8,
      ),
    if (stats.isAlmostOk)
      const _GroupScheduleTier(
        dayOffset: 1,
        title: 'ほぼOK',
        subtitle: '1人だけまだ決めてない。確認したらまとまりそう。',
        accent: AppColors.cFF20B9FF,
      ),
    if (stats.isMaybeOk)
      const _GroupScheduleTier(
        dayOffset: 2,
        title: '確認すればいけそう',
        subtitle: '予定ある人が少なめ。候補として聞いてみよ。',
        accent: AppColors.cFF8A62FF,
      ),
  ];

  if (tiers.isEmpty && stats.hasNoPlannedMembers) {
    return [
      for (var i = 0; i < 2; i++)
        _GroupScheduleSuggestion(
          title: _groupScheduleDayLabel(now.add(Duration(days: i))),
          subtitle: i == 0 ? '予定を入れてもらってね。' : '予定を入れてもらってね。',
          badge: '${stats.okCount}/${stats.total}人OK',
          accent: AppColors.cFFB8FF00,
        ),
    ];
  }

  final visibleTiers = tiers.isEmpty
      ? const [
          _GroupScheduleTier(
            dayOffset: 1,
            title: '確認してみよ',
            subtitle: 'まだ揃いきってないから、まず予定を聞いてみよ。',
            accent: AppColors.cFF94A3B8,
          ),
        ]
      : tiers;

  return [
    for (final tier in visibleTiers)
      _GroupScheduleSuggestion(
        title: _groupScheduleDayLabel(now.add(Duration(days: tier.dayOffset))),
        subtitle: tier.subtitle,
        badge: tier.title == '全員OK'
            ? '全員OK'
            : '${stats.okCount}/${stats.total}人OK',
        accent: tier.accent,
      ),
  ];
}

class _GroupScheduleTier {
  const _GroupScheduleTier({
    required this.dayOffset,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final int dayOffset;
  final String title;
  final String subtitle;
  final Color accent;
}

class _GroupAvailabilityStats {
  const _GroupAvailabilityStats({
    required this.total,
    required this.okCount,
    required this.maybeCount,
    required this.blockedCount,
    required this.undecidedCount,
    required this.plannedCount,
    required this.weightedScore,
  });

  final int total;
  final int okCount;
  final int maybeCount;
  final int blockedCount;
  final int undecidedCount;
  final int plannedCount;
  final double weightedScore;

  double get averageWeight => total == 0 ? 0 : weightedScore / total;

  bool get isAllOk => total > 0 && blockedCount == 0 && averageWeight >= .8;

  bool get hasNoPlannedMembers => total > 0 && plannedCount == 0;

  bool get isAlmostOk => total >= 3 && averageWeight >= .75;

  bool get isMaybeOk => total > 0 && averageWeight >= .5;
}

_GroupAvailabilityStats _groupAvailabilityStats(
  List<_DecoratedFriend> friends,
) {
  var okCount = 0;
  var maybeCount = 0;
  var blockedCount = 0;
  var undecidedCount = 0;
  var plannedCount = 0;
  var weightedScore = 0.0;
  for (final item in friends) {
    final status = oheyDailyStatusFromKey(item.friend.statusKey);
    final weight = status.availabilityWeight;
    weightedScore += weight;
    if (weight >= .8) okCount += 1;
    if (weight > 0) {
      maybeCount += 1;
    } else {
      blockedCount += 1;
    }
    if (status.isUndecided) {
      undecidedCount += 1;
    }
    if (status == OheyDailyStatus.hasPlans) {
      plannedCount += 1;
    }
  }
  return _GroupAvailabilityStats(
    total: friends.length,
    okCount: okCount,
    maybeCount: maybeCount,
    blockedCount: blockedCount,
    undecidedCount: undecidedCount,
    plannedCount: plannedCount,
    weightedScore: weightedScore,
  );
}

String _groupScheduleDayLabel(DateTime day) {
  final now = DateTime.now();
  if (_isSameLocalDay(day, now)) return '今日';
  if (_isSameLocalDay(day, now.add(const Duration(days: 1)))) return '明日';
  const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
  return '${day.month}/${day.day}（${weekdays[day.weekday - 1]}）';
}

bool _isSameLocalDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isRecommendedFriend(_DecoratedFriend item) {
  final friend = item.friend;
  final status = oheyDailyStatusFromKey(friend.statusKey);
  if (status.blocksRecommendations) return false;

  return friend.totalMemoryCount == 0 ||
      (friend.isFavorite && _daysSinceLastMemory(friend) >= 30) ||
      status.recommendationBonus > 0;
}

int _recommendationScoreFor(_DecoratedFriend item) {
  final friend = item.friend;
  final status = oheyDailyStatusFromKey(friend.statusKey);
  var score = 0;
  if (friend.totalMemoryCount == 0) score += 100;
  if (friend.isFavorite && _daysSinceLastMemory(friend) >= 30) score += 80;
  score += status.recommendationBonus;
  return score;
}

int _daysSinceLastMemory(OheyFriend friend) {
  final lastMemoryAt = friend.lastMemoryAt;
  if (lastMemoryAt == null) return 1 << 30;
  return DateTime.now().difference(lastMemoryAt).inDays;
}

class _AddFriendsPromoCard extends StatelessWidget {
  const _AddFriendsPromoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    const accent = AppColors.cFF37DFCF;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 98),
      child: OheyThemedPanel(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        accentColor: accent,
        backgroundColor: isWhite
            ? AppColors.white
            : AppColors.darkBackgroundBottom,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWhite
              ? const [AppColors.cFF123D4A, AppColors.cFF092334]
              : const [AppColors.cFF0B3240, AppColors.cFF071A2B],
        ),
        borderRadius: 20,
        borderAlpha: .42,
        glowAlpha: .18,
        glowBlur: 24,
        glowOffset: Offset.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _FriendPromoAvatarStack(),
            const SizedBox(width: 12),
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
                        color: AppColors.white.withValues(alpha: 0.94),
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
                      'フレンズを増やして、もっと気軽に誘おう',
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.68),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 76,
              child: Semantics(
                button: true,
                label: 'フレンズを追加',
                child: Ohey3DButton(
                  label: '追加',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap();
                  },
                  height: 40,
                  radius: 20,
                  color: _FriendsColors.lime,
                  foregroundColor: AppColors.cFF0B2A22,
                  shadowColor: AppColors.cFF77A600,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
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
              color: AppColors.cFF7C5CFF,
              avatar: const OheyAvatar(
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
              color: AppColors.cFF24D8B0,
              avatar: const OheyAvatar(
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
                border: Border.all(color: AppColors.cFF0B3240, width: 3),
              ),
              child: const Center(
                child: OheyGeneratedIcon(
                  CupertinoIcons.plus,
                  color: AppColors.cFF0B2A22,
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
  final OheyAvatar avatar;
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
        border: Border.all(color: AppColors.cFF072130, width: 4),
      ),
      child: ClipOval(
        child: Container(
          color: color,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, isPrimary ? 5 : 4),
            child: OheyAvatarView(
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
  const _DecoratedFriend({
    required this.friend,
    required this.status,
    required this.originalIndex,
  });

  final OheyFriend friend;
  final _FriendStatus status;
  final int originalIndex;
}

int _compareFriendsForList(_DecoratedFriend a, _DecoratedFriend b) {
  if (a.friend.isFavorite != b.friend.isFavorite) {
    return a.friend.isFavorite ? -1 : 1;
  }

  final statusRankCompare = oheyDailyStatusFromKey(a.friend.statusKey)
      .availabilityRank
      .compareTo(oheyDailyStatusFromKey(b.friend.statusKey).availabilityRank);
  if (statusRankCompare != 0) return statusRankCompare;

  return a.originalIndex.compareTo(b.originalIndex);
}

bool _matchesCustomFilter(_DecoratedFriend item, _CustomFriendFilter filter) {
  return filter.friendIds.contains(item.friend.id);
}

OheyFriend _friendWithFavorite(OheyFriend friend, bool isFavorite) {
  if (friend.isFavorite == isFavorite) return friend;
  return OheyFriend(
    id: friend.id,
    name: friend.name,
    avatarEmoji: friend.avatarEmoji,
    vibe: friend.vibe,
    characterAssetPath: friend.characterAssetPath,
    kind: friend.kind,
    palette: friend.palette,
    avatar: friend.avatar,
    monthlyCount: friend.monthlyCount,
    totalMemoryCount: friend.totalMemoryCount,
    lastMemoryAt: friend.lastMemoryAt,
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

  final OheyAvatar avatar;
  final String message;
  final String subtitle;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return OheyEmptyState(
      visual: _EmptyFriendsVisual(avatar: avatar),
      title: message == 'フレンズがいません' ? 'ここにフレンズを呼ぼう' : message,
      message: message == 'フレンズがいません'
          ? '「誰か誘いたいな」の相手が、ここに並びます。まずはQRかIDでひとり追加してみよう。'
          : subtitle,
      titleColor: isWhite ? AppColors.cFF1B2633 : AppColors.white,
      messageColor: isWhite
          ? AppColors.cFF6D7784
          : AppColors.white.withValues(alpha: .58),
      padding: EdgeInsets.zero,
      spacing: 14,
      hints: message == 'フレンズがいません'
          ? const ['ゆるぼに誘える', '空き状況が見える']
          : const ['フィルターを変えてみよう', 'グループは長押しで編集'],
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
    return SizedBox(
      width: 190,
      child: Ohey3DButton(
        label: 'QR・IDで探す',
        icon: CupertinoIcons.qrcode_viewfinder,
        onTap: onAddFriend,
        height: 44,
        radius: 20,
        color: _FriendsColors.lime,
        foregroundColor: _FriendsColors.limeForeground,
        shadowColor: _FriendsColors.limeShadow,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        fontSize: 13,
      ),
    );
  }
}

class _EmptyFriendsVisual extends StatelessWidget {
  const _EmptyFriendsVisual({required this.avatar});

  final OheyAvatar avatar;

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
                  AppColors.transparent,
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
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: .07),
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
            child: OheyAvatarView(avatar: avatar, size: 76),
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
                  color: isWhite ? AppColors.white : _FriendsColors.bg,
                  width: 3,
                ),
              ),
              child: const Center(
                child: OheyGeneratedIcon(
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
