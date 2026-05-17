import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../application/drink_invite_controller.dart';
import '../../logs/application/drink_log_controller.dart';
import '../../profile/presentation/profile_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  _FriendFilterType _selectedFilter = _FriendFilterType.all;

  void _openAddFriend() {
    showMyQrDialog(context, ref.read(nomoUserProvider), ref);
  }

  void _onToggleFavorite(
    BuildContext context,
    NomoFriend friend,
    bool isFavorite,
  ) {
    ref
        .read(friendsControllerProvider)
        .toggleFavorite(friendId: friend.id, isFavorite: isFavorite)
        .catchError((error) {
          if (!context.mounted) return;
          NomoToast.show(context, 'お気に入り設定に失敗しました: $error');
        });
  }

  Future<void> _sendDrinkInvite(NomoFriend friend) async {
    try {
      await ref.read(drinkInviteControllerProvider).sendTodayInvite(friend.id);
      if (!mounted) return;
      NomoToast.show(context, '${friend.name}に飲み招待を送りました。');
    } catch (error) {
      if (!mounted) return;
      NomoToast.show(context, '招待を送れませんでした: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(drinkLogControllerProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final user = ref.watch(nomoUserProvider);
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isWhite
              ? const [Colors.white, Colors.white, Color(0xFFF7F9FB)]
              : const [
                  _FriendsColors.bgTop,
                  _FriendsColors.bg,
                  _FriendsColors.bg,
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NomoPageHeader.horizontalPadding,
            NomoPageHeader.topPadding,
            NomoPageHeader.horizontalPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NomoPageHeader(
                title: 'フレンズ',
                titleColor: _FriendsColors.lime,
                trailing: NomoHeaderIconButton(
                  icon: CupertinoIcons.plus,
                  color: _FriendsColors.lime,
                  onTap: _openAddFriend,
                ),
              ),
              const SizedBox(height: 18),
              _FilterBar(
                selected: _selectedFilter,
                onChanged: (filter) => setState(() => _selectedFilter = filter),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: logsAsync.when(
                  loading: () => const _LoadingState(label: 'ログを読み込み中...'),
                  error: (error, stackTrace) =>
                      _ErrorState(title: 'ログを読み込めませんでした', message: '$error'),
                  data: (logs) => friendsAsync.when(
                    loading: () => const _LoadingState(label: '友達を読み込み中...'),
                    error: (error, stackTrace) =>
                        _ErrorState(title: '友達を読み込めませんでした', message: '$error'),
                    data: (friends) => _FriendsList(
                      logs: logs,
                      friends: friends,
                      userAvatar: user?.avatar ?? NomoAvatar.defaultAvatar,
                      selectedFilter: _selectedFilter,
                      onFavoriteToggle: (friend, isFavorite) =>
                          _onToggleFavorite(context, friend, isFavorite),
                      onInvite: (friend) => _sendDrinkInvite(friend),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FriendFilterType { all, drinkable, favorite }

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _FriendFilterType selected;
  final ValueChanged<_FriendFilterType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (var i = 0; i < _filters.length; i++) ...[
              _FilterChip(
                label: _filters[i].label,
                accent: _filters[i].accent,
                selected: selected == _filters[i].type,
                onTap: () => onChanged(_filters[i].type),
              ),
              if (i != _filters.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

const _filters = [
  _FriendFilter('みんな', _FriendFilterType.all, Color(0xFFB8FF00)),
  _FriendFilter('今日飲める', _FriendFilterType.drinkable, Color(0xFFFF5AA6)),
  _FriendFilter('お気に入り', _FriendFilterType.favorite, Color(0xFFFFA700)),
];

class _FriendFilter {
  const _FriendFilter(this.label, this.type, this.accent);
  final String label;
  final _FriendFilterType type;
  final Color accent;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final topColor = selected
        ? accent
        : isWhite
        ? Colors.white
        : const Color(0xFF243344);
    final bottomColor = selected
        ? Color.lerp(accent, _FriendsColors.bg, .36)!
        : isWhite
        ? const Color(0xFFE7EDF3)
        : const Color(0xFF152536);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 52,
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: bottomColor,
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? accent.withValues(alpha: .30)
                  : Colors.black.withValues(alpha: isWhite ? .08 : .22),
              blurRadius: selected ? 20 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(topColor, Colors.white, selected ? .22 : .06)!,
                topColor,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: .18)
                  : isWhite
                  ? const Color(0xFFDCE4EC)
                  : Colors.white.withValues(alpha: .10),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? _FriendsColors.bg
                      : isWhite
                      ? const Color(0xFF101820)
                      : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList({
    required this.logs,
    required this.friends,
    required this.userAvatar,
    required this.selectedFilter,
    required this.onFavoriteToggle,
    required this.onInvite,
  });

  final List<DrinkLog> logs;
  final List<NomoFriend> friends;
  final NomoAvatar userAvatar;
  final _FriendFilterType selectedFilter;
  final void Function(NomoFriend friend, bool isFavorite) onFavoriteToggle;
  final ValueChanged<NomoFriend> onInvite;

  @override
  Widget build(BuildContext context) {
    final counts = _monthlyFriendCounts(logs, friends);
    final decorated = [
      for (var i = 0; i < friends.length; i++)
        _DecoratedFriend(
          friend: friends[i],
          status: _statusForFriend(friends[i], i),
          count: _displayCount(friends[i], counts),
        ),
    ];
    final filtered = decorated.where((item) {
      return switch (selectedFilter) {
        _FriendFilterType.all => true,
        _FriendFilterType.drinkable => _isDrinkableStatus(item.status),
        _FriendFilterType.favorite => item.friend.isFavorite,
      };
    }).toList()..sort((a, b) => b.count.compareTo(a.count));

    if (filtered.isEmpty) {
      return _EmptyFriendsState(
        avatar: userAvatar,
        message: friends.isEmpty ? 'フレンズがいません' : 'この条件のフレンズはいません',
        subtitle: friends.isEmpty ? '右上の＋からフレンズを追加しよう' : '別の条件を選ぶと見つかるかも',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 116),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _FriendCard(
          friend: item.friend,
          status: item.status,
          count: item.count,
          onFavoriteToggle: () =>
              onFavoriteToggle(item.friend, !item.friend.isFavorite),
          onInvite: () => onInvite(item.friend),
        );
      },
    );
  }
}

class _DecoratedFriend {
  const _DecoratedFriend({
    required this.friend,
    required this.status,
    required this.count,
  });

  final NomoFriend friend;
  final _FriendStatus status;
  final int count;
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
    final ink = isWhite ? const Color(0xFF1B2633) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF6D7784)
        : Colors.white.withValues(alpha: .58);
    return Padding(
      padding: const EdgeInsets.only(bottom: 116),
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -42),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
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
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isDrinkableStatus(_FriendStatus status) {
  return switch (status.label) {
    '今ヒマ' ||
    '終電までなら' ||
    '飲みたい気分' ||
    '今日飲める' ||
    '軽く一杯なら' ||
    'しっかり飲みたい' ||
    'ノンアルなら' ||
    '誘われ待ち' => true,
    _ => false,
  };
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.status,
    required this.count,
    required this.onFavoriteToggle,
    required this.onInvite,
  });

  final NomoFriend friend;
  final _FriendStatus status;
  final int count;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForFriend(friend);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : _FriendsColors.block,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFDCE4EC)
              : Colors.white.withValues(alpha: .075),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .06 : .24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 78,
            child: NomoAvatarView(
              avatar: friend.avatar ?? _fallbackAvatarForFriend(friend),
              size: 72,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        friend.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: friend.isFavorite
                              ? const Color(0xFFFFE39B).withValues(alpha: .22)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          friend.isFavorite
                              ? CupertinoIcons.star_fill
                              : CupertinoIcons.star,
                          size: 20,
                          color: friend.isFavorite
                              ? const Color(0xFFFFC700)
                              : (isWhite
                                    ? const Color(0xFF8C9CAB)
                                    : _FriendsColors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: status.enabled ? accent : _FriendsColors.muted,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (status.enabled)
                            BoxShadow(
                              color: accent.withValues(alpha: .5),
                              blurRadius: 12,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _StatusPill(status: status, accent: accent),
                const SizedBox(height: 6),
                Text(
                  status.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite
                        ? const Color(0xFF687481)
                        : Colors.white.withValues(alpha: .58),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountBadge(count: count, accent: accent),
              const SizedBox(height: 10),
              _InviteButton(
                status: status,
                accent: accent,
                name: friend.name,
                onInvite: onInvite,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.accent});

  final _FriendStatus status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: status.enabled ? .16 : .10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.enabled ? accent : _FriendsColors.muted,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.accent});

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: isWhite ? const Color(0xFFF7F9FB) : _FriendsColors.block,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFDCE4EC)
              : Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count回',
                style: TextStyle(
                  color: isWhite ? const Color(0xFF101820) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '今月の記録',
            style: TextStyle(
              color: isWhite
                  ? const Color(0xFF687481)
                  : Colors.white.withValues(alpha: .55),
              fontWeight: FontWeight.w800,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  const _InviteButton({
    required this.status,
    required this.accent,
    required this.name,
    required this.onInvite,
  });

  final _FriendStatus status;
  final Color accent;
  final String name;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final enabled = status.enabled;
    return SizedBox(
      width: 92,
      child: Nomo3DButton(
        label: '誘う',
        icon: CupertinoIcons.paperplane_fill,
        onTap: enabled
            ? () => _showInviteSheet(
                context: context,
                name: name,
                accent: accent,
                onTodayInvite: onInvite,
              )
            : null,
        enabled: enabled,
        height: 36,
        radius: 18,
        color: const Color(0xFF12C9A4),
        shadowColor: const Color(0xFF079078),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        fontSize: 12,
      ),
    );
  }
}

Future<void> _showInviteSheet({
  required BuildContext context,
  required String name,
  required Color accent,
  required VoidCallback onTodayInvite,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: _FriendsColors.block,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .34),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$nameを誘う',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'どうやって誘う？',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .62),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            _InviteSheetAction(
              icon: Icons.calendar_month_rounded,
              title: '日程を決めて誘う',
              subtitle: '候補日を選んで予定を合わせる',
              accent: accent,
              onTap: () {
                Navigator.of(context).pop();
                NomoToast.show(context, '$nameと日程を決める画面を準備中です。');
              },
            ),
            const SizedBox(height: 10),
            _InviteSheetAction(
              icon: Icons.sports_bar_rounded,
              title: '今日誘う',
              subtitle: '今日飲めるかすぐに聞く',
              accent: _FriendsColors.lime,
              onTap: () {
                Navigator.of(context).pop();
                onTodayInvite();
              },
            ),
          ],
        ),
      );
    },
  );
}

class _InviteSheetAction extends StatelessWidget {
  const _InviteSheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Row(
          children: [
            NomoPopIcon(icon: icon, color: accent, size: 48, iconSize: 25),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .55),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            NomoPopIcon(
              icon: CupertinoIcons.chevron_right,
              color: Colors.white.withValues(alpha: .18),
              foregroundColor: Colors.white.withValues(alpha: .72),
              size: 30,
              iconSize: 17,
              shadow: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(color: Colors.white),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .64),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendStatus {
  const _FriendStatus({
    required this.label,
    required this.message,
    required this.enabled,
  });

  final String label;
  final String message;
  final bool enabled;
}

_FriendStatus _statusForFriend(NomoFriend friend, int index) {
  switch (friend.statusKey) {
    case 'available':
      return const _FriendStatus(
        label: '今ヒマ',
        message: '今日なら行けるよ〜！',
        enabled: true,
      );
    case 'last_train':
      return const _FriendStatus(
        label: '終電までなら',
        message: '軽く飲めるかも！',
        enabled: true,
      );
    case 'want_drink':
      return const _FriendStatus(
        label: '飲みたい気分',
        message: '誰か誘って〜！',
        enabled: true,
      );
    case 'busy':
      return const _FriendStatus(
        label: '休肝日',
        message: '今日はお休み中...',
        enabled: false,
      );
    case 'unset':
      return const _FriendStatus(
        label: '未設定',
        message: 'ステータス未設定',
        enabled: true,
      );
  }

  return switch (index % 5) {
    0 => const _FriendStatus(
      label: '今ヒマ',
      message: '今日なら行けるよ〜！',
      enabled: true,
    ),
    1 => const _FriendStatus(
      label: '終電までなら',
      message: '軽く飲めるかも！',
      enabled: true,
    ),
    2 => const _FriendStatus(
      label: '飲みたい気分',
      message: '誰か誘って〜！',
      enabled: true,
    ),
    3 => const _FriendStatus(
      label: '休肝日',
      message: '今日はお休み中...',
      enabled: false,
    ),
    _ => const _FriendStatus(label: '未設定', message: 'ステータス未設定', enabled: true),
  };
}

Color _accentForFriend(NomoFriend friend) {
  return switch (friend.palette) {
    NomiTomoPalette.peach => const Color(0xFFFFB03B),
    NomiTomoPalette.sky => const Color(0xFF18AFFF),
    NomiTomoPalette.lemon => _FriendsColors.lime,
    NomiTomoPalette.lavender => const Color(0xFFA855F7),
    NomiTomoPalette.mint => const Color(0xFF46E68A),
    NomiTomoPalette.blush => const Color(0xFFFF4B9A),
  };
}

NomoAvatar _fallbackAvatarForFriend(NomoFriend friend) {
  final hash = friend.id.hashCode.abs();
  return NomoAvatar(
    skin: hash % NomoAvatar.skinColors.length,
    hair: (hash ~/ 3) % NomoAvatar.hairStyles.length,
    shirt: (hash ~/ 5) % NomoAvatar.shirtColors.length,
    eyes: (hash ~/ 7) % NomoAvatar.eyeStyles.length,
    mouth: (hash ~/ 11) % NomoAvatar.mouthStyles.length,
    accessory: (hash ~/ 13) % NomoAvatar.accessoryStyles.length,
  );
}

int _displayCount(NomoFriend friend, Map<String, int> counts) {
  final realCount = counts[friend.id] ?? 0;
  if (realCount > 0) return realCount;
  return friend.monthlyCount ?? 0;
}

Map<String, int> _monthlyFriendCounts(
  List<DrinkLog> logs,
  List<NomoFriend> friends,
) {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  final counts = <String, int>{for (final friend in friends) friend.id: 0};
  for (final log in logs.where((log) => log.isInMonth(month))) {
    for (final friend in log.friends) {
      counts.update(friend.id, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  return counts;
}

class _FriendsColors {
  const _FriendsColors._();

  static const bg = Color(0xFF0B1420);
  static const bgTop = Color(0xFF172637);
  static const block = Color(0xFF101B28);
  static const lime = Color(0xFFB8FF00);
  static const muted = Color(0xFF8792A3);
}
