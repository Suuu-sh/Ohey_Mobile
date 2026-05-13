import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_user.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_character.dart';
import '../../logs/application/drink_log_controller.dart';
import 'add_nomi_tomo_screen.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(drinkLogControllerProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final user = ref.watch(nomoUserProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 112),
            sliver: SliverList.list(
              children: [
                _Header(
                  onAdd: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const AddNomiTomoScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                logsAsync.when(
                  loading: () =>
                      const Center(child: CupertinoActivityIndicator()),
                  error: (error, stackTrace) => Text('ログを読み込めませんでした: $error'),
                  data: (logs) => friendsAsync.when(
                    loading: () =>
                        const Center(child: CupertinoActivityIndicator()),
                    error: (error, stackTrace) => Text('友達を読み込めませんでした: $error'),
                    data: (friends) => _FriendsBody(
                      logs: logs,
                      friends: _friendsWithUser(user, friends),
                      user: user,
                      onAdd: () => Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (_) => const AddNomiTomoScreen(),
                        ),
                      ),
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

List<NomoFriend> _friendsWithUser(NomoUser? user, List<NomoFriend> friends) {
  if (user == null) return friends;
  final me = NomoFriend(
    id: 'me',
    name: user.name,
    avatarEmoji: '✨',
    vibe: 'My Nomo',
    characterAssetPath: user.characterPose.assetPath,
    kind: NomiTomoKind.cloud,
    palette: NomiTomoPalette.peach,
  );
  return [me, ...friends];
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 44),
        Expanded(
          child: Text(
            '友達',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(
            CupertinoIcons.person_badge_plus,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _FriendsBody extends StatefulWidget {
  const _FriendsBody({
    required this.logs,
    required this.friends,
    required this.user,
    required this.onAdd,
  });

  final List<DrinkLog> logs;
  final List<NomoFriend> friends;
  final NomoUser? user;
  final VoidCallback onAdd;

  @override
  State<_FriendsBody> createState() => _FriendsBodyState();
}

class _FriendsBodyState extends State<_FriendsBody> {
  final Map<String, _Availability> _availability = {};

  _Availability _availabilityFor(NomoFriend friend) {
    return _availability[friend.id] ?? _Availability.unselected;
  }

  void _setAvailability(NomoFriend friend, _Availability availability) {
    setState(() => _availability[friend.id] = availability);
  }

  @override
  Widget build(BuildContext context) {
    final counts = _monthlyFriendCounts(widget.logs, widget.friends);
    final sorted = [...widget.friends]
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    final me = sorted.where((friend) => friend.id == 'me').firstOrNull;
    final friendsOnly = sorted.where((friend) => friend.id != 'me').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 106,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == 0) return _AddFriendStory(onTap: widget.onAdd);
              final friend = friendsOnly[index - 1];
              final availability = _availabilityFor(friend);
              return _FriendStory(
                friend: friend,
                pose: _poseForFriend(friend),
                availability: availability,
                onTap: availability == _Availability.wantDrink
                    ? () => _showInviteSheet(
                        context,
                        friend,
                        _poseForFriend(friend),
                        availability,
                      )
                    : null,
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemCount: friendsOnly.length + 1,
          ),
        ),
        if (me != null) ...[
          const SizedBox(height: 18),
          _MyStatusCard(
            availability: _availabilityFor(me),
            onChanged: (availability) => _setAvailability(me, availability),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          '友達リスト',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        ...friendsOnly.map((friend) {
          final count = counts[friend.id] ?? 0;
          final availability = _availabilityFor(friend);
          return _FriendInviteRow(
            friend: friend,
            pose: _poseForFriend(friend),
            count: count,
            availability: availability,
            onInvite: () => _showInviteSheet(
              context,
              friend,
              _poseForFriend(friend),
              availability,
            ),
          );
        }),
      ],
    );
  }

  NomoCharacterPose _poseForFriend(NomoFriend friend) {
    if (friend.id == 'me') {
      return widget.user?.characterPose ?? NomoCharacterPose.iconSmile;
    }
    return NomoCharacterPose.iconSmile;
  }

  void _showInviteSheet(
    BuildContext context,
    NomoFriend friend,
    NomoCharacterPose pose,
    _Availability availability,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: .62),
      builder: (context) =>
          _InviteDialog(friend: friend, pose: pose, availability: availability),
    );
  }
}

class _AddFriendStory extends StatelessWidget {
  const _AddFriendStory({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line, width: 2),
              ),
              child: const Icon(CupertinoIcons.plus, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              '追加',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendStory extends StatelessWidget {
  const _FriendStory({
    required this.friend,
    required this.pose,
    required this.availability,
    required this.onTap,
  });

  final NomoFriend friend;
  final NomoCharacterPose pose;
  final _Availability availability;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 86,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        friend.ringColor,
                        availability.color,
                        friend.accentColor,
                        friend.ringColor,
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: NomoCharacter(pose: pose),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: availability.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              friend.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyStatusCard extends StatelessWidget {
  const _MyStatusCard({required this.availability, required this.onChanged});

  final _Availability availability;
  final ValueChanged<_Availability> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日のステータス',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _AvailabilitySwitch(value: availability, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _FriendInviteRow extends StatelessWidget {
  const _FriendInviteRow({
    required this.friend,
    required this.pose,
    required this.count,
    required this.availability,
    required this.onInvite,
  });

  final NomoFriend friend;
  final NomoCharacterPose pose;
  final int count;
  final _Availability availability;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: friend.accentColor,
              shape: BoxShape.circle,
            ),
            child: NomoCharacter(pose: pose),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        friend.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '$count回',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.mutedInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _ReadOnlyAvailabilityPill(availability: availability),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: availability == _Availability.wantDrink
                ? onInvite
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              disabledBackgroundColor: AppColors.softGray,
              disabledForegroundColor: AppColors.mutedInk,
              foregroundColor: Colors.white,
              minimumSize: const Size(44, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: const Icon(
              Icons.sports_bar_rounded,
              semanticLabel: '誘う',
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyAvailabilityPill extends StatelessWidget {
  const _ReadOnlyAvailabilityPill({required this.availability});

  final _Availability availability;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '友達の今日のステータス: ${availability.label}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: availability.background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: availability.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                availability.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: availability.textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteDialog extends StatelessWidget {
  const _InviteDialog({
    required this.friend,
    required this.pose,
    required this.availability,
  });

  final NomoFriend friend;
  final NomoCharacterPose pose;
  final _Availability availability;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 34),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .18),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        friend.ringColor,
                        availability.color,
                        friend.accentColor,
                        friend.ringColor,
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: NomoCharacter(pose: pose),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: availability.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              friend.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _AvailabilityPill(availability: availability),
            const SizedBox(height: 22),
            Text(
              availability == _Availability.wantDrink
                  ? '${friend.name}を誘いますか？'
                  : availability == _Availability.busy
                  ? '${friend.name}は今は空いてないみたい'
                  : '${friend.name}のステータスは未選択です',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            if (availability == _Availability.wantDrink) ...[
              _DialogButton(
                label: '今すぐ誘う',
                icon: CupertinoIcons.paperplane_fill,
                primary: true,
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${friend.name}に誘うメッセージを準備しました（ダミー）。'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '閉じる',
                  style: TextStyle(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Availability { unselected, wantDrink, busy }

extension _AvailabilityX on _Availability {
  String get label => switch (this) {
    _Availability.unselected => '未選択',
    _Availability.wantDrink => '飲みたい',
    _Availability.busy => '空いてない',
  };

  Color get color => switch (this) {
    _Availability.unselected => const Color(0xFFD9DCE7),
    _Availability.wantDrink => const Color(0xFF52C46A),
    _Availability.busy => const Color(0xFFE53935),
  };

  Color get background => switch (this) {
    _Availability.unselected => AppColors.softGray,
    _Availability.wantDrink => const Color(0xFFEFF8E8),
    _Availability.busy => const Color(0xFFFFE3E0),
  };

  Color get textColor => switch (this) {
    _Availability.unselected => AppColors.mutedInk,
    _Availability.wantDrink => const Color(0xFF2E8744),
    _Availability.busy => const Color(0xFFD73A31),
  };
}

class _AvailabilitySwitch extends StatelessWidget {
  const _AvailabilitySwitch({required this.value, required this.onChanged});

  final _Availability value;
  final ValueChanged<_Availability> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          for (final option in _Availability.values)
            Expanded(
              child: _AvailabilitySwitchOption(
                option: option,
                selected: value == option,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvailabilitySwitchOption extends StatelessWidget {
  const _AvailabilitySwitchOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Availability option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? option.color : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          option.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.mutedInk,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.availability});

  final _Availability availability;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: availability.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: availability.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            availability.label,
            style: TextStyle(
              color: availability == _Availability.wantDrink
                  ? const Color(0xFF2E8744)
                  : AppColors.mutedInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? AppColors.navy : AppColors.softGray,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: primary ? Colors.white : AppColors.navy,
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
