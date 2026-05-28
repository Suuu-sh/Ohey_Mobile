part of 'friends_screen.dart';

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.status,
    required this.onFavoriteToggle,
    required this.isInvited,
    required this.onInvite,
    required this.onInviteAnimationComplete,
    required this.onProfile,
  });

  final NomoFriend friend;
  final _FriendStatus status;
  final VoidCallback onFavoriteToggle;
  final bool isInvited;
  final Future<void> Function() onInvite;
  final VoidCallback onInviteAnimationComplete;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => NomoFriendUserBlock(
    friend: friend,
    statusLabel: status.label,
    statusReason: status.reason,
    statusColor: _friendInviteButtonColor(status),
    statusEnabled: status.enabled,
    inviteSent: isInvited,
    fallbackAvatar: _fallbackAvatarForFriend(friend),
    showFavorite: true,
    showInvite: true,
    onFavoriteToggle: onFavoriteToggle,
    onInvite: onInvite,
    onInviteAnimationComplete: onInviteAnimationComplete,
    onTap: onProfile,
  );
}

Future<void> showNomoFriendProfileSheet(
  BuildContext context, {
  required NomoFriend friend,
}) {
  return _showFriendProfileSheet(
    context,
    friend: friend,
    status: _statusForFriend(friend, 0),
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

class _FriendProfileSheet extends StatefulWidget {
  const _FriendProfileSheet({required this.friend, required this.status});

  final NomoFriend friend;
  final _FriendStatus status;

  @override
  State<_FriendProfileSheet> createState() => _FriendProfileSheetState();
}

class _FriendProfileSheetState extends State<_FriendProfileSheet> {
  late _FriendStatus _selectedStatus = widget.status;

  void _handleSelectedStatusChanged(NomoDailyStatus status) {
    final nextStatus = _friendStatusForDailyStatus(status);
    if (_selectedStatus.label == nextStatus.label &&
        _selectedStatus.reason == nextStatus.reason &&
        _selectedStatus.enabled == nextStatus.enabled &&
        _selectedStatus.buttonColor == nextStatus.buttonColor) {
      return;
    }
    setState(() => _selectedStatus = nextStatus);
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final avatar =
        widget.friend.avatar ?? _fallbackAvatarForFriend(widget.friend);
    final statusColor = _friendInviteButtonColor(_selectedStatus);

    final sheetContentHeight = (MediaQuery.sizeOf(context).height * .84)
        .clamp(560.0, 720.0)
        .toDouble();

    return NomoBottomSheetShell(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      radius: 32,
      maxHeightFactor: .90,
      child: SizedBox(
        height: sheetContentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FriendProfileTopBackdrop(
              friend: widget.friend,
              avatar: avatar,
              status: _selectedStatus,
              statusColor: statusColor,
              isWhite: isWhite,
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _FriendProfileCalendar(
                  friend: widget.friend,
                  status: widget.status,
                  onSelectedStatusChanged: _handleSelectedStatusChanged,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Nomo3DButton.secondary(
                label: '閉じる',
                onTap: () => Navigator.of(context).pop(),
                height: 48,
                radius: 22,
                color: const Color(0xFF252044),
                foregroundColor: const Color(0xFFC08BFF),
                shadowColor: const Color(0xFF15142C),
              ),
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
      height: 338,
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
          Positioned(
            top: 14,
            right: 10,
            child: IconButton(
              onPressed: onClose,
              icon: NomoGeneratedIcon(
                CupertinoIcons.xmark,
                color: Colors.white.withValues(alpha: .78),
                size: 30,
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
                const SizedBox(height: 8),
                Center(child: _FriendProfileAvatarFigure(avatar: avatar)),
                const SizedBox(height: 5),
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
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: NomoThemedPanel(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    accentColor: statusColor,
                    borderRadius: 22,
                    backgroundColor: Color.lerp(
                      AppColors.darkBackgroundBottom,
                      statusColor,
                      isWhite ? .24 : .34,
                    )!.withValues(alpha: .90),
                    borderAlpha: isWhite ? .42 : .56,
                    glowAlpha: .16,
                    glowBlur: 22,
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

class _FriendProfileAvatarFigure extends StatelessWidget {
  const _FriendProfileAvatarFigure({required this.avatar});

  final NomoAvatar avatar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      height: 142,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 8,
            child: Container(
              width: 98,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppColors.darkBackgroundBottom.withValues(alpha: .18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -2),
            child: NomoAvatarView(avatar: avatar, size: 146),
          ),
          const Positioned(
            right: 16,
            top: 16,
            child: NomoPopIcon(
              icon: CupertinoIcons.sparkles,
              color: Color(0xFFFFD166),
              size: 32,
              iconSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileCalendar extends ConsumerStatefulWidget {
  const _FriendProfileCalendar({
    required this.friend,
    required this.status,
    required this.onSelectedStatusChanged,
  });

  final NomoFriend friend;
  final _FriendStatus status;
  final ValueChanged<NomoDailyStatus> onSelectedStatusChanged;

  @override
  ConsumerState<_FriendProfileCalendar> createState() =>
      _FriendProfileCalendarState();
}

class _FriendProfileCalendarState
    extends ConsumerState<_FriendProfileCalendar> {
  late DateTime _month;
  late DateTime _selectedDay;
  final Map<String, NomoDailyStatus> _statusByDate = {};
  final Set<String> _loadingStatusKeys = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = _friendProfileDateOnly(now);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStatusesForMonth(_month);
    });
  }

  void _moveMonth(int offset) {
    final nextMonth = DateTime(_month.year, _month.month + offset);
    final today = _friendProfileDateOnly(DateTime.now());
    setState(() {
      _month = nextMonth;
      _selectedDay = _friendProfileIsSameMonth(nextMonth, today)
          ? today
          : DateTime(nextMonth.year, nextMonth.month);
    });
    _loadStatusesForMonth(_month);
  }

  Future<void> _loadStatusesForMonth(DateTime month) async {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCells = DateTime(month.year, month.month).weekday % 7;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final targets = <DateTime>[];
    for (var index = 0; index < rows * 7; index++) {
      final dayNumber = index - leadingEmptyCells + 1;
      final date = DateTime(month.year, month.month, dayNumber);
      final key = _friendProfileDateKey(date);
      if (_statusByDate.containsKey(key) || !_loadingStatusKeys.add(key)) {
        continue;
      }
      targets.add(date);
    }
    if (targets.isEmpty) return;

    final entries = await Future.wait(
      targets.map((date) async {
        try {
          final friends = await ref.read(friendsForDateProvider(date).future);
          final friend = friends
              .where((candidate) => candidate.id == widget.friend.id)
              .firstOrNull;
          return MapEntry(
            _friendProfileDateKey(date),
            nomoDailyStatusFromKey(friend?.statusKey),
          );
        } catch (_) {
          return MapEntry(
            _friendProfileDateKey(date),
            NomoDailyStatus.unselected,
          );
        }
      }),
    );
    for (final date in targets) {
      _loadingStatusKeys.remove(_friendProfileDateKey(date));
    }
    if (!mounted) return;
    setState(() {
      for (final entry in entries) {
        _statusByDate[entry.key] = entry.value;
      }
    });
    final selectedStatus = _statusByDate[_friendProfileDateKey(_selectedDay)];
    if (selectedStatus != null) {
      widget.onSelectedStatusChanged(selectedStatus);
    }
  }

  void _handleMonthSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 220) return;
    _moveMonth(velocity > 0 ? -1 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;

    return GestureDetector(
      onHorizontalDragEnd: _handleMonthSwipe,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FriendProfileMonthHeader(
            month: _month,
            ink: ink,
            onMove: _moveMonth,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _FriendProfileMonthGrid(
              month: _month,
              selectedDay: _selectedDay,
              statusByDate: _statusByDate,
              onSelectDay: (day) {
                HapticFeedback.selectionClick();
                setState(() => _selectedDay = day);
                widget.onSelectedStatusChanged(
                  _statusByDate[_friendProfileDateKey(day)] ??
                      NomoDailyStatus.unselected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileMonthHeader extends StatelessWidget {
  const _FriendProfileMonthHeader({
    required this.month,
    required this.ink,
    required this.onMove,
  });

  final DateTime month;
  final Color ink;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FriendProfileMonthArrowButton(label: '<', onTap: () => onMove(-1)),
        Expanded(
          child: Text(
            '${month.year}/${month.month.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -.4,
            ),
          ),
        ),
        _FriendProfileMonthArrowButton(label: '>', onTap: () => onMove(1)),
      ],
    );
  }
}

class _FriendProfileMonthArrowButton extends StatelessWidget {
  const _FriendProfileMonthArrowButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            height: .95,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FriendProfileMonthGrid extends StatelessWidget {
  const _FriendProfileMonthGrid({
    required this.month,
    required this.selectedDay,
    required this.statusByDate,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<String, NomoDailyStatus> statusByDate;
  final ValueChanged<DateTime> onSelectDay;

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
                        onTap: inMonth ? () => onSelectDay(day) : null,
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
    this.onTap,
  });

  final int day;
  final bool inMonth;
  final NomoDailyStatus dailyStatus;
  final bool isToday;
  final bool isSelected;
  final int column;
  final double tileExtent;
  final VoidCallback? onTap;

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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
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
                : const Color(
                    0xFF20B9FF,
                  ).withValues(alpha: isWhite ? .34 : .24),
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
      ),
    );
  }
}

String _friendProfileDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime _friendProfileDateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

bool _friendProfileIsSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

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
