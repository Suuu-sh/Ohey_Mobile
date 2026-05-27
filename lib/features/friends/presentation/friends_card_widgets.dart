part of 'friends_screen.dart';

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.status,
    required this.onFavoriteToggle,
    required this.onInvite,
    required this.onProfile,
  });

  final NomoFriend friend;
  final _FriendStatus status;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onInvite;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => NomoFriendUserBlock(
    friend: friend,
    statusLabel: status.label,
    statusReason: status.reason,
    statusColor: _friendInviteButtonColor(status),
    statusEnabled: status.enabled,
    fallbackAvatar: _fallbackAvatarForFriend(friend),
    showFavorite: true,
    showInvite: true,
    onFavoriteToggle: onFavoriteToggle,
    onInvite: onInvite,
    onTap: onProfile,
  );
}

Future<void> _showFriendProfileSheet(
  BuildContext context, {
  required NomoFriend friend,
  required _FriendStatus status,
}) {
  return showNomoBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (_) => _FriendProfileSheet(friend: friend, status: status),
  );
}

class _FriendProfileSheet extends StatelessWidget {
  const _FriendProfileSheet({required this.friend, required this.status});

  final NomoFriend friend;
  final _FriendStatus status;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF667381)
        : Colors.white.withValues(alpha: .62);
    final avatar = friend.avatar ?? _fallbackAvatarForFriend(friend);
    final statusColor = _friendInviteButtonColor(status);

    return NomoBottomSheetShell(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      radius: 32,
      maxHeightFactor: .88,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NomoBottomSheetHandle(),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: NomoGeneratedIcon(
                  CupertinoIcons.xmark,
                  color: sub,
                  size: 30,
                ),
              ),
            ),
            _FriendProfileHero(friend: friend, avatar: avatar),
            const SizedBox(height: 14),
            Text(
              friend.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
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
                  friend.vibe.trim().isEmpty
                      ? '@${friend.id}'
                      : '@${friend.vibe}',
                  style: TextStyle(
                    color: sub,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            NomoThemedPanel(
              padding: const EdgeInsets.all(14),
              accentColor: statusColor,
              borderRadius: 22,
              backgroundColor: isWhite
                  ? Colors.white
                  : AppColors.darkBackgroundBottom,
              child: Row(
                children: [
                  NomoPopIcon(
                    icon: CupertinoIcons.cloud_fill,
                    color: statusColor,
                    size: 38,
                    iconSize: 21,
                    showBubble: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.label,
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.reason,
                          style: TextStyle(
                            color: sub,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FriendProfileCalendar(friend: friend, status: status),
            const SizedBox(height: 14),
            Nomo3DButton.secondary(
              label: '閉じる',
              onTap: () => Navigator.of(context).pop(),
              height: 48,
              radius: 22,
              color: const Color(0xFF252044),
              foregroundColor: const Color(0xFFC08BFF),
              shadowColor: const Color(0xFF15142C),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendProfileHero extends StatelessWidget {
  const _FriendProfileHero({required this.friend, required this.avatar});

  final NomoFriend friend;
  final NomoAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final backgroundColors =
        NomoAvatar.backgroundGradients[avatar.background %
            NomoAvatar.backgroundGradients.length];
    return Container(
      height: 156,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundColors,
        ),
        image: DecorationImage(
          image: const AssetImage('assets/images/profile_header_scene.png'),
          fit: BoxFit.cover,
          opacity: .18,
        ),
        boxShadow: [
          BoxShadow(
            color: friend.accentColor.withValues(alpha: .20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .72),
                border: Border.all(color: Colors.white, width: 5),
              ),
            ),
            ClipOval(child: NomoAvatarView(avatar: avatar, size: 100)),
            const Positioned(
              right: 4,
              top: 8,
              child: NomoPopIcon(
                icon: CupertinoIcons.sparkles,
                color: Color(0xFFFFD166),
                size: 32,
                iconSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendProfileCalendar extends StatelessWidget {
  const _FriendProfileCalendar({required this.friend, required this.status});

  final NomoFriend friend;
  final _FriendStatus status;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leading = DateTime(now.year, now.month).weekday % 7;
    final rows = ((leading + daysInMonth) / 7).ceil();
    final accent = _friendInviteButtonColor(status);
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF667381)
        : Colors.white.withValues(alpha: .62);

    return NomoThemedPanel(
      padding: const EdgeInsets.all(14),
      accentColor: accent,
      borderRadius: 24,
      backgroundColor: isWhite ? Colors.white : AppColors.darkBackgroundBottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NomoPopIcon(
                icon: CupertinoIcons.calendar,
                color: accent,
                size: 34,
                iconSize: 18,
                showBubble: false,
              ),
              const SizedBox(width: 9),
              Text(
                '${now.year}/${now.month.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '今日の予定',
                style: TextStyle(
                  color: sub,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const ['日', '月', '火', '水', '木', '金', '土']
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Color(0xFF8B96A3),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              mainAxisExtent: 34,
            ),
            itemBuilder: (context, index) {
              final day = index - leading + 1;
              final inMonth = day >= 1 && day <= daysInMonth;
              final isToday = inMonth && day == now.day;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: isToday
                      ? accent.withValues(alpha: isWhite ? .22 : .30)
                      : isWhite
                      ? const Color(0xFFF5F8FB)
                      : Colors.white.withValues(alpha: .045),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isToday
                        ? accent.withValues(alpha: .80)
                        : Colors.white.withValues(alpha: isWhite ? .0 : .08),
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    inMonth ? '$day' : '',
                    style: TextStyle(
                      color: isToday ? accent : sub,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
