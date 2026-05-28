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
    useSafeArea: false,
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
    final avatar =
        widget.friend.avatar ?? _fallbackAvatarForFriend(widget.friend);
    final statusColor = _friendInviteButtonColor(_selectedStatus);
    final media = MediaQuery.of(context);
    final sheetContentHeight = media.size.height - media.padding.bottom;
    const bodyBackground = AppColors.darkBackgroundBottom;

    return NomoBottomSheetShell(
      padding: EdgeInsets.zero,
      radius: 0,
      maxHeightFactor: 1,
      followKeyboard: false,
      child: SizedBox(
        height: sheetContentHeight,
        child: ColoredBox(
          color: bodyBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FriendProfileTopBackdrop(
                friend: widget.friend,
                avatar: avatar,
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FriendProfileStatusPanel(
                        status: _selectedStatus,
                        statusColor: statusColor,
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _FriendProfileCalendar(
                          friend: widget.friend,
                          status: widget.status,
                          onSelectedStatusChanged: _handleSelectedStatusChanged,
                        ),
                      ),
                    ],
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendProfileTopBackdrop extends StatelessWidget {
  const _FriendProfileTopBackdrop({
    required this.friend,
    required this.avatar,
    required this.onClose,
  });

  final NomoFriend friend;
  final NomoAvatar avatar;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.paddingOf(context).top + 318;
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final headerColor = isWhite ? const Color(0xFF101820) : Colors.white;
    return SizedBox(
      height: headerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _FriendProfileHeaderBackdrop(avatar: avatar),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NomoPageHeader.horizontalPadding,
                4,
                NomoPageHeader.horizontalPadding,
                6,
              ),
              child: Column(
                children: [
                  NomoPageHeader(
                    title: 'プロフィール',
                    titleColor: headerColor,
                    trailing: _FriendProfileCloseButton(
                      isWhite: isWhite,
                      onTap: onClose,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _FriendProfileHero(friend: friend, avatar: avatar),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileHeaderBackdrop extends StatelessWidget {
  const _FriendProfileHeaderBackdrop({required this.avatar});

  final NomoAvatar avatar;

  @override
  Widget build(BuildContext context) {
    if (NomoAvatar.usesMascotBackdrop(avatar.background)) {
      return ExcludeSemantics(
        child: Image.asset(
          'assets/images/profile_mascot_backdrop_scene.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      );
    }

    final backgroundColors =
        NomoAvatar.backgroundGradients[avatar.background %
            NomoAvatar.backgroundGradients.length];
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
          opacity: avatar.background == NomoAvatar.dreamRoomBackground
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
                Colors.white.withValues(alpha: .18),
                Colors.white.withValues(alpha: .36),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendProfileCloseButton extends StatelessWidget {
  const _FriendProfileCloseButton({required this.isWhite, required this.onTap});

  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '閉じる',
      child: CupertinoButton(
        onPressed: onTap,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: NomoGeneratedIcon(
              CupertinoIcons.xmark,
              color: isWhite ? const Color(0xFF101820) : Colors.white,
              size: 38,
            ),
          ),
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
    final handle = friend.vibe.trim().isEmpty ? friend.id : '@${friend.vibe}';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 132,
            child: Center(child: NomoAvatarView(avatar: avatar, size: 146)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 9),
            color: AppColors.darkBackgroundBottom,
            child: Center(
              child: Text(
                '${friend.name} ・ $handle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .72),
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

class _FriendProfileStatusPanel extends StatelessWidget {
  const _FriendProfileStatusPanel({
    required this.status,
    required this.statusColor,
  });

  final _FriendStatus status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return NomoThemedPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      accentColor: statusColor,
      borderRadius: 22,
      backgroundColor: Color.lerp(
        AppColors.darkBackgroundBottom,
        statusColor,
        .34,
      )!.withValues(alpha: .90),
      borderAlpha: .56,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.reason,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .70),
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
