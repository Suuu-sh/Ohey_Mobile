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
  final Future<void> Function() onInvite;
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
    final avatar = friend.avatar ?? _fallbackAvatarForFriend(friend);
    final statusColor = _friendInviteButtonColor(status);

    final sheetContentHeight = (MediaQuery.sizeOf(context).height * .84)
        .clamp(560.0, 720.0)
        .toDouble();

    return NomoBottomSheetShell(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      radius: 32,
      maxHeightFactor: .90,
      child: SizedBox(
        height: sheetContentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FriendProfileTopBackdrop(
              friend: friend,
              avatar: avatar,
              status: status,
              statusColor: statusColor,
              isWhite: isWhite,
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _FriendProfileCalendar(friend: friend, status: status),
            ),
            const SizedBox(height: 12),
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

class _FriendProfileTopBackdrop extends StatelessWidget {
  const _FriendProfileTopBackdrop({
    required this.friend,
    required this.avatar,
    required this.status,
    required this.statusColor,
    required this.isWhite,
    required this.onClose,
  });

  final NomoFriend friend;
  final NomoAvatar avatar;
  final _FriendStatus status;
  final Color statusColor;
  final bool isWhite;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final usesMascotBackdrop = NomoAvatar.usesMascotBackdrop(avatar.background);
    final backgroundColors =
        NomoAvatar.backgroundGradients[avatar.background %
            NomoAvatar.backgroundGradients.length];
    final nameColor = Colors.white;
    final subColor = Colors.white.withValues(alpha: .70);

    return Container(
      height: 326,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: usesMascotBackdrop
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: backgroundColors,
              ),
        image: DecorationImage(
          image: AssetImage(
            usesMascotBackdrop
                ? 'assets/images/profile_mascot_backdrop_scene.png'
                : 'assets/images/profile_header_scene.png',
          ),
          fit: BoxFit.cover,
          opacity: usesMascotBackdrop ? 1 : .48,
        ),
        boxShadow: [
          BoxShadow(
            color: friend.accentColor.withValues(alpha: .24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkBackgroundBottom.withValues(alpha: .06),
                  AppColors.darkBackgroundBottom.withValues(alpha: .28),
                  AppColors.darkBackgroundBottom.withValues(alpha: .82),
                ],
                stops: const [0, .42, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 2),
                const NomoBottomSheetHandle(),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: onClose,
                    icon: NomoGeneratedIcon(
                      CupertinoIcons.xmark,
                      color: Colors.white.withValues(alpha: .78),
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .72),
                          border: Border.all(color: Colors.white, width: 5),
                        ),
                      ),
                      ClipOval(child: NomoAvatarView(avatar: avatar, size: 74)),
                      const Positioned(
                        right: 0,
                        top: 4,
                        child: NomoPopIcon(
                          icon: CupertinoIcons.sparkles,
                          color: Color(0xFFFFD166),
                          size: 30,
                          iconSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  friend.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: nameColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: .28),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                      color: AppColors.darkBackgroundBottom.withValues(
                        alpha: .62,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .18),
                      ),
                    ),
                    child: Text(
                      friend.vibe.trim().isEmpty
                          ? '@${friend.id}'
                          : '@${friend.vibe}',
                      style: TextStyle(
                        color: subColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: NomoThemedPanel(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    accentColor: statusColor,
                    borderRadius: 22,
                    backgroundColor: AppColors.darkBackgroundBottom.withValues(
                      alpha: .76,
                    ),
                    borderAlpha: isWhite ? .34 : .46,
                    glowAlpha: .10,
                    glowBlur: 20,
                    glowOffset: const Offset(0, 8),
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
                                  color: nameColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                status.reason,
                                style: TextStyle(
                                  color: subColor,
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
                ),
              ],
            ),
          ),
        ],
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
    final month = DateTime(now.year, now.month);
    final accent = _friendInviteButtonColor(status);
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final dailyStatus = nomoDailyStatusFromKey(friend.statusKey);

    return NomoThemedPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      accentColor: accent,
      borderRadius: 24,
      backgroundColor: isWhite ? Colors.white : AppColors.darkBackgroundBottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NomoPopIcon(
                icon: CupertinoIcons.calendar,
                color: accent,
                size: 30,
                iconSize: 16,
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
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _FriendProfileMonthGrid(
              month: month,
              selectedDay: now,
              statusByDate: {_friendProfileDateKey(now): dailyStatus},
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileMonthGrid extends StatelessWidget {
  const _FriendProfileMonthGrid({
    required this.month,
    required this.selectedDay,
    required this.statusByDate,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<String, NomoDailyStatus> statusByDate;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCells = DateTime(month.year, month.month).weekday % 7;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final previousMonthDays = DateTime(month.year, month.month, 0).day;

    return Column(
      children: [
        Row(
          children: const ['日', '月', '火', '水', '木', '金', '土']
              .asMap()
              .entries
              .map(
                (entry) => Expanded(
                  child: Center(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: entry.key == 0
                            ? Color(0xFFFF6FA6)
                            : entry.key == 6
                            ? Color(0xFF46C8FF)
                            : Color(0xFFB7C0CA),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 7),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisSpacing = 6.0;
              const mainAxisSpacing = 5.0;
              final widthBasedExtent =
                  ((constraints.maxWidth - (crossAxisSpacing * 6)) / 7).clamp(
                    42.0,
                    54.0,
                  );
              final heightBasedExtent = rows <= 1
                  ? widthBasedExtent
                  : ((constraints.maxHeight - (mainAxisSpacing * (rows - 1))) /
                            rows)
                        .clamp(34.0, 54.0);
              final tileExtent = widthBasedExtent < heightBasedExtent
                  ? widthBasedExtent
                  : heightBasedExtent;
              final gridHeight =
                  (tileExtent * rows) + (mainAxisSpacing * (rows - 1));
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: gridHeight,
                  child: GridView.builder(
                    itemCount: rows * 7,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: mainAxisSpacing,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisExtent: tileExtent,
                    ),
                    itemBuilder: (context, index) {
                      final dayNumber = index - leadingEmptyCells + 1;
                      final inMonth =
                          dayNumber >= 1 && dayNumber <= daysInMonth;
                      final displayDay = inMonth
                          ? dayNumber
                          : (dayNumber < 1
                                ? previousMonthDays + dayNumber
                                : dayNumber - daysInMonth);
                      final day = DateTime(month.year, month.month, dayNumber);
                      final dailyStatus =
                          statusByDate[_friendProfileDateKey(day)] ??
                          NomoDailyStatus.unselected;
                      return _FriendProfileDayTile(
                        day: displayDay,
                        inMonth: inMonth,
                        dailyStatus: dailyStatus,
                        isToday:
                            inMonth &&
                            _friendProfileIsSameDate(DateTime.now(), day),
                        isSelected: _friendProfileIsSameDate(selectedDay, day),
                        column: index % 7,
                        tileExtent: tileExtent,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FriendProfileDayTile extends StatelessWidget {
  const _FriendProfileDayTile({
    required this.day,
    required this.inMonth,
    required this.dailyStatus,
    required this.isToday,
    required this.isSelected,
    required this.column,
    required this.tileExtent,
  });

  final int day;
  final bool inMonth;
  final NomoDailyStatus dailyStatus;
  final bool isToday;
  final bool isSelected;
  final int column;
  final double tileExtent;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final hasStatus = dailyStatus != NomoDailyStatus.unselected;
    final statusAccent = _friendProfileCalendarStatusTileAccent(dailyStatus);
    final dayColor = hasStatus
        ? _friendProfileCalendarStatusTileForeground(
            dailyStatus,
            isWhite: isWhite,
          )
        : !inMonth
        ? (isWhite
              ? Colors.black.withValues(alpha: .20)
              : Colors.white.withValues(alpha: .20))
        : column == 0
        ? const Color(0xFFFF6FA6)
        : column == 6
        ? const Color(0xFF46C8FF)
        : isWhite
        ? const Color(0xFF101820)
        : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: hasStatus
            ? _friendProfileCalendarStatusTileBackground(
                dailyStatus,
                isWhite: isWhite,
                selected: isSelected,
              )
            : isWhite
            ? (isSelected ? const Color(0xFFEAF8FF) : Colors.white)
            : AppColors.darkBackground,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: hasStatus
              ? statusAccent.withValues(alpha: isSelected ? .90 : .52)
              : isSelected
              ? const Color(0xFF54D7FF)
              : const Color(0xFF20B9FF).withValues(alpha: isWhite ? .34 : .24),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasStatus
                ? statusAccent.withValues(alpha: isWhite ? .16 : .24)
                : Colors.black.withValues(alpha: isWhite ? .05 : .20),
            blurRadius: hasStatus ? 16 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: isToday && !isWhite ? Colors.white : dayColor,
            fontSize: tileExtent >= 42 ? 18 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _friendProfileDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

bool _friendProfileIsSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Color _friendProfileCalendarStatusTileAccent(NomoDailyStatus status) =>
    switch (status) {
      NomoDailyStatus.canDrinkToday => const Color(0xFFFF5EA8),
      NomoDailyStatus.nonAlcohol => const Color(0xFF20B9FF),
      NomoDailyStatus.liverRest => const Color(0xFF8A62FF),
      NomoDailyStatus.hasPlans => const Color(0xFF738092),
      NomoDailyStatus.unselected => const Color(0xFF9AF21A),
    };

Color _friendProfileCalendarStatusTileBackground(
  NomoDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return isWhite
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF2B3644).withValues(alpha: selected ? .92 : .76);
  }
  final color = _friendProfileCalendarStatusTileAccent(status);
  return color.withValues(
    alpha: isWhite ? (selected ? .34 : .22) : (selected ? .52 : .36),
  );
}

Color _friendProfileCalendarStatusTileForeground(
  NomoDailyStatus status, {
  required bool isWhite,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFF111827) : Colors.white;
  }
  return const Color(0xFF06111D);
}
