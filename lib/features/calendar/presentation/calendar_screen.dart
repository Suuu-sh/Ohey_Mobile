import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/application/ohey_user_controller.dart';
import '../../../core/data/user_repository.dart';
import '../../../core/models/ohey_invite.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/models/ohey_friend.dart';
import '../../../core/models/ohey_user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ohey_theme_mode.dart';
import '../../../core/widgets/ohey_3d_button.dart';
import '../../../core/widgets/ohey_bottom_sheet.dart';
import '../../../core/widgets/ohey_daily_status_3d_option.dart';
import '../../../core/widgets/ohey_friend_user_block.dart';
import '../../../core/widgets/ohey_page_header.dart';
import '../../../core/widgets/ohey_pop_icon.dart';
import '../../../core/widgets/ohey_scene_header_backdrop.dart';
import '../../../core/widgets/ohey_themed_panel.dart';
import '../../../core/widgets/ohey_toast.dart';
import '../../friends/application/invite_controller.dart';
import '../../friends/data/friend_repository.dart';
import '../../memories/application/memory_controller.dart';

const _calendarPrimaryActionColor = AppColors.cFF20B9FF;
const _calendarPrimaryActionForegroundColor = AppColors.cFF06111D;
const _calendarPrimaryActionShadowColor = AppColors.cFF0B78B7;

String _calendarGroupStorageKey(String userId) =>
    'ohey_custom_friend_filters_v1_$userId';

class _CalendarFriendGroup {
  const _CalendarFriendGroup({
    required this.id,
    required this.name,
    required this.friendIds,
  });

  final String id;
  final String name;
  final List<String> friendIds;

  static _CalendarFriendGroup? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = (value['id'] as String?)?.trim();
    final name = (value['name'] as String?)?.trim();
    final rawFriendIds = value['friendIds'] ?? value['friend_ids'];
    if (id == null || id.isEmpty || name == null || name.isEmpty) return null;
    final friendIds = rawFriendIds is List
        ? [
            for (final friendId in rawFriendIds)
              if (friendId is String && friendId.trim().isNotEmpty)
                friendId.trim(),
          ]
        : const <String>[];
    if (friendIds.isEmpty) return null;
    return _CalendarFriendGroup(id: id, name: name, friendIds: friendIds);
  }
}

List<_CalendarFriendGroup> _decodeCalendarFriendGroups(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final groups = <_CalendarFriendGroup>[];
    for (final item in decoded) {
      final group = _CalendarFriendGroup.fromJson(item);
      if (group != null) groups.add(group);
    }
    return groups;
  } catch (_) {
    return const [];
  }
}

_CalendarFriendGroup? _findCalendarFriendGroup(
  String? id,
  List<_CalendarFriendGroup> groups,
) {
  if (id == null) return null;
  for (final group in groups) {
    if (group.id == id) return group;
  }
  return null;
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const _calendarIntroSeenKey = 'ohey_calendar_intro_seen';

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selectedDay = _dateOnly(DateTime.now());
  double _monthDragOffset = 0;
  bool _isIntroSeen = true;
  bool _isStatusSaving = false;
  final Map<String, OheyDailyStatus> _statusByDate = {};
  final Set<String> _loadingStatusKeys = {};
  String? _calendarGroupUserId;
  List<_CalendarFriendGroup> _calendarGroups = const [];

  @override
  void initState() {
    super.initState();
    _loadIntroSeen();
    _loadStatusesForMonth(_month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncCalendarGroupsForUser(ref.read(oheyUserProvider)?.userId);
      }
    });
  }

  void _syncCalendarGroupsForUser(String? userId) {
    if (_calendarGroupUserId == userId) return;
    _calendarGroupUserId = userId;
    if (mounted) {
      setState(() => _calendarGroups = const []);
    }
    if (userId != null && userId.trim().isNotEmpty) {
      _loadCalendarGroups(userId);
    }
  }

  Future<void> _loadCalendarGroups(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedGroups = _decodeCalendarFriendGroups(
      prefs.getString(_calendarGroupStorageKey(userId)),
    );
    var groups = cachedGroups;
    try {
      final rows = await ref.read(friendRepositoryProvider).fetchFriendGroups();
      groups = rows
          .map(_CalendarFriendGroup.fromJson)
          .whereType<_CalendarFriendGroup>()
          .toList(growable: false);
      await prefs.setString(
        _calendarGroupStorageKey(userId),
        jsonEncode([
          for (final group in groups)
            {'id': group.id, 'name': group.name, 'friendIds': group.friendIds},
        ]),
      );
    } catch (_) {
      // Fall back to the local cache while backend group sync rolls out.
      groups = cachedGroups;
    }
    if (!mounted || _calendarGroupUserId != userId) return;
    setState(() => _calendarGroups = groups);
  }

  Future<void> _loadIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isIntroSeen = prefs.getBool(_calendarIntroSeenKey) ?? false;
    });
  }

  Future<void> _dismissIntro() async {
    if (_isIntroSeen) return;
    setState(() => _isIntroSeen = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_calendarIntroSeenKey, true);
  }

  void _moveMonth(int offset) {
    final nextSelectedDay = DateTime(_month.year, _month.month + offset, 1);
    setState(() {
      _month = DateTime(nextSelectedDay.year, nextSelectedDay.month);
      _selectedDay = nextSelectedDay;
    });
    _loadStatusesForMonth(_month);
  }

  Future<void> _selectDay(DateTime day) async {
    setState(() => _selectedDay = day);
    final status = await _loadStatusFor(day);
    if (!mounted || status != OheyDailyStatus.unselected) return;
    await _openStatusPicker(showLockedExplanation: true);
  }

  Future<OheyDailyStatus> _loadStatusFor(DateTime day) async {
    final key = _dateKey(day);
    final cached = _statusByDate[key];
    if (cached != null) return cached;
    if (!_loadingStatusKeys.add(key)) return OheyDailyStatus.unselected;
    try {
      final status = await ref
          .read(userRepositoryProvider)
          .fetchDailyStatus(day);
      if (!mounted) return status;
      setState(() => _statusByDate[key] = status);
      return status;
    } catch (_) {
      if (mounted) {
        setState(() => _statusByDate[key] = OheyDailyStatus.unselected);
      }
      return OheyDailyStatus.unselected;
    } finally {
      _loadingStatusKeys.remove(key);
    }
  }

  Future<void> _loadStatusesForMonth(DateTime month) async {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCells = DateTime(month.year, month.month).weekday % 7;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final targets = <DateTime>[];
    for (var index = 0; index < rows * 7; index++) {
      final dayNumber = index - leadingEmptyCells + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        continue;
      }
      final date = DateTime(month.year, month.month, dayNumber);
      final key = _dateKey(date);
      if (_statusByDate.containsKey(key) || !_loadingStatusKeys.add(key)) {
        continue;
      }
      targets.add(date);
    }
    if (targets.isEmpty) return;

    final repository = ref.read(userRepositoryProvider);
    Map<String, OheyDailyStatus> statuses;
    try {
      statuses = await repository.fetchDailyStatusesForMonth(month);
    } catch (_) {
      statuses = const {};
    }
    for (final date in targets) {
      _loadingStatusKeys.remove(_dateKey(date));
    }
    if (!mounted) return;
    setState(() {
      for (final date in targets) {
        final key = _dateKey(date);
        _statusByDate[key] = statuses[key] ?? OheyDailyStatus.unselected;
      }
    });
  }

  Future<void> _setStatusForSelectedDay(OheyDailyStatus status) async {
    if (_isStatusSaving) return;
    final day = _selectedDay;
    setState(() => _isStatusSaving = true);
    try {
      await ref
          .read(oheyUserProvider.notifier)
          .updateDailyStatus(status, date: day);
      if (!mounted) return;
      setState(() {
        _statusByDate[_dateKey(day)] = status;
        _isStatusSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isStatusSaving = false);
    }
  }

  Future<void> _openStatusPicker({bool showLockedExplanation = false}) async {
    final picked = await showOheyBottomSheet<OheyDailyStatus>(
      context: context,
      useSafeArea: true,
      barrierColor: AppColors.black.withValues(alpha: .58),
      builder: (_) => _CalendarStatusSheet(
        day: _selectedDay,
        selected:
            _statusByDate[_dateKey(_selectedDay)] ?? OheyDailyStatus.unselected,
        showLockedExplanation: showLockedExplanation,
      ),
    );
    if (picked == null) return;
    await _setStatusForSelectedDay(picked);
  }

  void _handleMonthDragStart(DragStartDetails details) {
    _monthDragOffset = 0;
  }

  void _handleMonthDragUpdate(DragUpdateDetails details) {
    _monthDragOffset += details.delta.dx;
  }

  void _handleMonthDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final distance = _monthDragOffset.abs();
    if (distance < 80 && velocity.abs() < 300) {
      _monthDragOffset = 0;
      return;
    }

    final isRightSwipe = velocity > 0 || _monthDragOffset > 0;
    if (isRightSwipe) {
      _moveMonth(-1);
    } else {
      _moveMonth(1);
    }
    _monthDragOffset = 0;
  }

  @override
  Widget build(BuildContext context) {
    final todayReservations =
        ref.watch(todayReservationsProvider).asData?.value ??
        const <OheyInvite>[];
    final selectedFriendsAsync = ref.watch(
      friendsForDateProvider(_dateOnly(_selectedDay)),
    );
    final selectedStatus =
        _statusByDate[_dateKey(_selectedDay)] ?? OheyDailyStatus.unselected;
    final isWhite = ref.watch(oheyThemeModeProvider).isWhite;
    final user = ref.watch(oheyUserProvider);
    if (_calendarGroupUserId != user?.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncCalendarGroupsForUser(user?.userId);
      });
    }
    final headerBackgroundHeight =
        OheyPageHeader.contentTopInset(context) + 100;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWhite
                ? const [AppColors.white, AppColors.white, AppColors.cFFF7F9FB]
                : AppColors.darkBackgroundGradient,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: headerBackgroundHeight,
              child: OheySceneHeaderBackdrop(
                assetPath: 'assets/images/calendar_header_scene.png',
                fadeColor: isWhite
                    ? AppColors.white
                    : AppColors.darkBackgroundBottom,
                accentColor: AppColors.cFF20B9FF,
                alignment: const Alignment(0.72, -1),
                imageTopOffset: -86,
                topShadeOpacity: .12,
                fadeStartOpacity: .88,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      OheyPageHeader.horizontalPadding,
                      OheyPageHeader.topPadding,
                      OheyPageHeader.horizontalPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const OheyPageHeader(
                          title: 'カレンダー',
                          titleColor: AppColors.cFF54D7FF,
                        ),
                        const SizedBox(height: 18),
                        _MonthHeader(month: _month, onMove: _moveMonth),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragStart: _handleMonthDragStart,
                      onHorizontalDragUpdate: _handleMonthDragUpdate,
                      onHorizontalDragEnd: _handleMonthDragEnd,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 116),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: OheyPageHeader.horizontalPadding,
                              ),
                              child: _PlayfulMonthGrid(
                                month: _month,
                                selectedDay: _selectedDay,
                                statusByDate: _statusByDate,
                                todayReservations: todayReservations,
                                onSelectDay: _selectDay,
                              ),
                            ),
                            if (!_isIntroSeen) ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: OheyPageHeader.horizontalPadding,
                                ),
                                child: _CalendarIntroCard(
                                  isWhite: isWhite,
                                  onDismiss: _dismissIntro,
                                ),
                              ),
                            ],
                            if (_isIntroSeen) ...[
                              const SizedBox(height: 8),
                              const _CalendarGlowDivider(),
                              const SizedBox(height: 7),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _SelectedDayPanel(
                                    day: _selectedDay,
                                    friendsAsync: selectedFriendsAsync,
                                    groups: _calendarGroups,
                                    isWhite: isWhite,
                                    status: selectedStatus,
                                    isStatusSaving: _isStatusSaving,
                                    onChangeStatus: () => _openStatusPicker(
                                      showLockedExplanation:
                                          selectedStatus ==
                                          OheyDailyStatus.unselected,
                                    ),
                                  ),
                                ),
                              ),
                            ] else
                              const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarGlowDivider extends StatelessWidget {
  const _CalendarGlowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _calendarPrimaryActionColor.withValues(alpha: .72),
        boxShadow: [
          BoxShadow(
            color: _calendarPrimaryActionColor.withValues(alpha: .62),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _CalendarIntroCard extends StatelessWidget {
  const _CalendarIntroCard({required this.isWhite, required this.onDismiss});

  final bool isWhite;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final titleColor = isWhite ? AppColors.cFF101820 : AppColors.white;
    final messageColor = isWhite
        ? AppColors.cFF657282
        : AppColors.white.withValues(alpha: .66);
    final cardColor = isWhite
        ? AppColors.white
        : AppColors.cFF122233.withValues(alpha: .82);
    final borderColor = isWhite
        ? AppColors.cFFDCE4EC
        : AppColors.white.withValues(alpha: .08);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isWhite ? .05 : .18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OheyPopIcon(
            icon: CupertinoIcons.sparkles,
            color: AppColors.cFFFFD166,
            size: 42,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '友達の予定が見やすくなります',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '空き状況を入れると、誘いやすい日がひと目で分かります。',
                  style: TextStyle(
                    color: messageColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CupertinoButton(
            minimumSize: const Size(34, 34),
            padding: EdgeInsets.zero,
            onPressed: onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cFF54D7FF.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.cFF54D7FF.withValues(alpha: .30),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.cFF54D7FF,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onMove});

  final DateTime month;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ArrowButton(label: '<', onTap: () => onMove(-1)),
        Expanded(
          child: Text(
            '${month.year}/${month.month.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
        ),
        _ArrowButton(label: '>', onTap: () => onMove(1)),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.white.withValues(alpha: .10)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 24,
            height: .95,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SelectedDayPanel extends StatelessWidget {
  const _SelectedDayPanel({
    required this.day,
    required this.friendsAsync,
    required this.groups,
    required this.isWhite,
    required this.status,
    required this.isStatusSaving,
    required this.onChangeStatus,
  });

  final DateTime day;
  final AsyncValue<List<OheyFriend>> friendsAsync;
  final List<_CalendarFriendGroup> groups;
  final bool isWhite;
  final OheyDailyStatus status;
  final bool isStatusSaving;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final titleColor = isWhite ? AppColors.cFF101820 : AppColors.white;
    return OheyThemedPanel(
      width: double.infinity,
      padding: EdgeInsets.zero,
      accentColor: _calendarPrimaryActionColor,
      backgroundColor: AppColors.transparent,
      borderRadius: 0,
      borderWidth: 0,
      borderAlpha: 0,
      glowAlpha: 0,
      glowBlur: 28,
      glowOffset: const Offset(0, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = _useCompactCalendarDetailLayout(
            constraints.maxHeight,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, compact ? 10 : 12, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _calendarSelectedDayTitle(day),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: compact ? 18 : 20,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CalendarStatusChangeButton(
                      status: status,
                      isSaving: isStatusSaving,
                      isWhite: isWhite,
                      onTap: onChangeStatus,
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 6 : 10),
              Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, compact ? 8 : 12),
                child: SizedBox(
                  height: compact ? 96 : 112,
                  child: status == OheyDailyStatus.unselected
                      ? _CalendarFriendStatusLocked(
                          isWhite: isWhite,
                          compact: compact,
                          onTap: onChangeStatus,
                        )
                      : _CalendarFriendStatusList(
                          day: day,
                          friendsAsync: friendsAsync,
                          groups: groups,
                          isWhite: isWhite,
                          compact: compact,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

bool _useCompactCalendarDetailLayout(double availableHeight) {
  // カレンダー行数で下ブロックの表現が変わらないよう、常に小さい範囲向けの
  // 省スペースレイアウトに統一する。
  return true;
}

String _calendarSelectedDayTitle(DateTime day) =>
    '${day.month}/${day.day}(${_calendarWeekdayLabel(day)}) の空き状況とゆるぼ';

class _CalendarStatusChangeButton extends StatelessWidget {
  const _CalendarStatusChangeButton({
    required this.status,
    required this.isSaving,
    required this.isWhite,
    required this.onTap,
  });

  final OheyDailyStatus status;
  final bool isSaving;
  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = status == OheyDailyStatus.unselected
        ? OheyDailyStatus.available
        : status;
    final accent = oheyDailyStatusBlockAccent(effectiveStatus);
    final foreground = oheyDailyStatus3DForegroundColor(
      effectiveStatus,
      isWhite: isWhite,
    );
    return SizedBox(
      width: 56,
      child: Ohey3DButtonSurface(
        onTap: isSaving ? null : onTap,
        enabled: !isSaving,
        height: 28,
        radius: 14,
        color: oheyDailyStatus3DSurfaceColor(
          effectiveStatus,
          isWhite: isWhite,
          selected: true,
        ),
        bottomColor: oheyDailyStatus3DShadowColor(
          effectiveStatus,
          isWhite: isWhite,
          selected: true,
        ),
        borderColor: oheyDailyStatus3DBorderColor(
          effectiveStatus,
          selected: true,
        ),
        borderWidth: 1.1,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        outerShadows: [
          BoxShadow(
            color: accent.withValues(alpha: .24),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
        innerShadows: [
          BoxShadow(
            color: AppColors.white.withValues(alpha: .12),
            blurRadius: 10,
          ),
        ],
        child: Center(
          child: Text(
            isSaving
                ? '保存中'
                : status == OheyDailyStatus.unselected
                ? '設定'
                : '変更',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarFriendStatusLocked extends StatelessWidget {
  const _CalendarFriendStatusLocked({
    required this.isWhite,
    required this.compact,
    required this.onTap,
  });

  final bool isWhite;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CalendarSectionSurface(
      label: 'フレンズの空き状況',
      accent: AppColors.primaryAction,
      isWhite: isWhite,
      compact: compact,
      onTap: onTap,
      child: Center(
        child: Row(
          children: [
            OheyPopIcon(
              icon: CupertinoIcons.lock_fill,
              color: AppColors.cFF94A3B8,
              size: compact ? 30 : 38,
              iconSize: compact ? 13 : 17,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '自分の予定を設定すると見られるよ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isWhite ? AppColors.cFF101820 : AppColors.white,
                      fontSize: compact ? 12.5 : 13.5,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 3),
                  Text(
                    '先にこの日の空き状況を設定してね',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isWhite
                          ? AppColors.cFF667381
                          : AppColors.white.withValues(alpha: .62),
                      fontSize: compact ? 10.5 : 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: compact ? 56 : 62,
              child: Ohey3DButton(
                label: '設定',
                onTap: onTap,
                height: compact ? 28 : 30,
                radius: compact ? 14 : 15,
                color: oheyDailyStatusPink,
                foregroundColor: _calendarPrimaryActionForegroundColor,
                shadowColor: Color.lerp(
                  oheyDailyStatusPink,
                  AppColors.black,
                  .32,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarFriendStatusList extends StatelessWidget {
  const _CalendarFriendStatusList({
    required this.day,
    required this.friendsAsync,
    required this.groups,
    required this.isWhite,
    required this.compact,
  });

  final DateTime day;
  final AsyncValue<List<OheyFriend>> friendsAsync;
  final List<_CalendarFriendGroup> groups;
  final bool isWhite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return friendsAsync.when(
      loading: () => _CalendarSectionSurface(
        label: 'フレンズの空き状況',
        accent: AppColors.primaryAction,
        isWhite: isWhite,
        compact: compact,
        child: const Center(child: CupertinoActivityIndicator(radius: 8)),
      ),
      error: (_, _) => _CalendarSectionSurface(
        label: 'フレンズの空き状況',
        accent: AppColors.primaryAction,
        isWhite: isWhite,
        compact: compact,
        child: Center(
          child: Text(
            'フレンズの空き状況を読み込めませんでした',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWhite
                  ? AppColors.cFF667381
                  : AppColors.white.withValues(alpha: .62),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      data: (friends) {
        if (friends.isEmpty) {
          return const SizedBox.shrink();
        }

        final sorted = [...friends]
          ..sort((a, b) {
            final statusCompare = _calendarFriendStatusRank(
              a.statusKey,
            ).compareTo(_calendarFriendStatusRank(b.statusKey));
            if (statusCompare != 0) return statusCompare;
            return a.name.compareTo(b.name);
          });
        final availableCount = friends
            .where((friend) => _calendarFriendIsAvailable(friend.statusKey))
            .length;
        void openStatusSheet() {
          _showCalendarFriendStatusSheet(
            context,
            day: day,
            friends: sorted,
            groups: groups,
            isWhite: isWhite,
          );
        }

        final accent = availableCount > 0
            ? _calendarPrimaryActionColor
            : AppColors.cFF94A3B8;
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 98),
          child: OheyThemedPanel(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            accentColor: accent,
            backgroundColor: isWhite
                ? AppColors.white
                : AppColors.darkBackgroundBottom,
            borderRadius: 20,
            borderAlpha: .42,
            glowAlpha: .18,
            glowBlur: 24,
            glowOffset: Offset.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OheyPopIcon(
                  icon: CupertinoIcons.person_2_fill,
                  color: accent,
                  size: compact ? 44 : 52,
                  iconSize: compact ? 22 : 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$availableCount/${friends.length}人が空いてそう',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isWhite
                              ? AppColors.cFF101820
                              : AppColors.white,
                          fontSize: compact ? 17 : 19,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        availableCount > 0 ? '誘えそうな人を見る' : '予定あり・未定が多そう',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isWhite
                              ? AppColors.cFF667381
                              : AppColors.white.withValues(alpha: .62),
                          fontSize: compact ? 11.5 : 13,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 76,
                  child: Ohey3DButton(
                    label: '見る',
                    onTap: openStatusSheet,
                    height: 40,
                    radius: 20,
                    color: _calendarPrimaryActionColor,
                    foregroundColor: _calendarPrimaryActionForegroundColor,
                    shadowColor: _calendarPrimaryActionShadowColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CalendarSectionSurface extends StatelessWidget {
  const _CalendarSectionSurface({
    required this.label,
    required this.accent,
    required this.isWhite,
    required this.compact,
    required this.child,
    this.onTap,
  });

  final String label;
  final Color accent;
  final bool isWhite;
  final bool compact;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fillColors = isWhite
        ? [AppColors.white, AppColors.cFFF7FBFF]
        : const [AppColors.darkBackground, AppColors.darkBackground];
    final content = Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.fromLTRB(12, compact ? 5 : 9, 12, compact ? 5 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: fillColors,
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: accent.withValues(alpha: isWhite ? .24 : .22),
        ),
        boxShadow: [
          BoxShadow(
            color: isWhite
                ? accent.withValues(alpha: .06)
                : AppColors.black.withValues(alpha: .26),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact) ...[
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .34),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Expanded(child: child),
        ],
      ),
    );
    final handler = onTap;
    if (handler == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: handler,
      child: content,
    );
  }
}

class _CalendarFriendStatusSummary extends StatelessWidget {
  const _CalendarFriendStatusSummary({
    required this.friends,
    required this.isWhite,
  });

  final List<OheyFriend> friends;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final counts = <OheyDailyStatus, int>{
      for (final status in OheyDailyStatus.values) status: 0,
    };
    for (final friend in friends) {
      final status = oheyDailyStatusFromKey(friend.statusKey);
      counts[status] = (counts[status] ?? 0) + 1;
    }
    final statuses = OheyDailyStatus.values
        .where((status) => (counts[status] ?? 0) > 0)
        .toList(growable: false);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final status in statuses)
          _CalendarFriendStatusCountChip(
            status: status,
            count: counts[status] ?? 0,
            isWhite: isWhite,
          ),
      ],
    );
  }
}

class _CalendarFriendStatusCountChip extends StatelessWidget {
  const _CalendarFriendStatusCountChip({
    required this.status,
    required this.count,
    required this.isWhite,
  });

  final OheyDailyStatus status;
  final int count;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final color = oheyDailyStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isWhite ? .16 : .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .36)),
      ),
      child: Text(
        '${status.label} $count',
        style: TextStyle(
          color: isWhite ? AppColors.cFF17212B : AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Future<void> _showCalendarFriendStatusSheet(
  BuildContext context, {
  required DateTime day,
  required List<OheyFriend> friends,
  required List<_CalendarFriendGroup> groups,
  required bool isWhite,
}) {
  return showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => _CalendarFriendStatusSheet(
      day: day,
      friends: friends,
      groups: groups,
      isWhite: isWhite,
    ),
  );
}

class _CalendarFriendStatusSheet extends ConsumerStatefulWidget {
  const _CalendarFriendStatusSheet({
    required this.day,
    required this.friends,
    required this.groups,
    required this.isWhite,
  });

  final DateTime day;
  final List<OheyFriend> friends;
  final List<_CalendarFriendGroup> groups;
  final bool isWhite;

  @override
  ConsumerState<_CalendarFriendStatusSheet> createState() =>
      _CalendarFriendStatusSheetState();
}

class _CalendarFriendStatusSheetState
    extends ConsumerState<_CalendarFriendStatusSheet> {
  String? _selectedGroupId;
  String? _sendingFriendId;
  final Set<String> _invitedFriendIds = <String>{};

  Future<void> _sendInvite(OheyFriend friend) async {
    if (_sendingFriendId != null) return;
    if (_isPastCalendarDate(widget.day)) {
      HapticFeedback.mediumImpact();
      OheyToast.show(
        context,
        '過去の日には誘えません',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        placement: OheyToastPlacement.bottom,
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _sendingFriendId = friend.id);
    try {
      await ref
          .read(inviteControllerProvider)
          .sendInvite(friendId: friend.id, date: widget.day);
      ref.invalidate(todayReservationsProvider);
      ref.invalidate(incomingInvitesProvider);
      ref.invalidate(outgoingActiveInvitesProvider(widget.day));
      if (!mounted) return;
      setState(() => _invitedFriendIds.add(friend.id));
      OheyToast.show(
        context,
        '${widget.day.month}/${widget.day.day}で${friend.name}にお誘いを送りました。',
        icon: CupertinoIcons.checkmark_circle_fill,
        placement: OheyToastPlacement.bottom,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _sendingFriendId = null);
      OheyToast.show(
        context,
        '誘えなかったよ。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        placement: OheyToastPlacement.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final persistedInvitedFriendIds =
        ref
            .watch(outgoingActiveInvitesProvider(widget.day))
            .asData
            ?.value
            .map((invite) => invite.inviteeUserId)
            .toSet() ??
        const <String>{};
    final invitedFriendIds = <String>{
      ...persistedInvitedFriendIds,
      ..._invitedFriendIds,
    };
    final inviteAvailable = !_isPastCalendarDate(widget.day);
    final selectedGroup = _findCalendarFriendGroup(
      _selectedGroupId,
      widget.groups,
    );
    final friends = selectedGroup == null
        ? widget.friends
        : widget.friends
              .where((friend) => selectedGroup.friendIds.contains(friend.id))
              .toList(growable: false);
    final isWhite = widget.isWhite;
    final availableCount = friends
        .where((friend) => _calendarFriendIsAvailable(friend.statusKey))
        .length;
    final media = MediaQuery.of(context);
    // Keep the fixed inner height comfortably below the sheet's max height.
    // The shell adds its own handle/padding, so using nearly the same factor as
    // maxHeightFactor can overflow by a few pixels on Dynamic Island devices.
    final contentHeight = (media.size.height * .74 - media.padding.bottom - 28)
        .clamp(420.0, 620.0)
        .toDouble();
    return OheyBottomSheetShell(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      radius: 32,
      maxHeightFactor: .82,
      child: SizedBox(
        height: contentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'フレンズの空き状況',
              style: TextStyle(
                color: isWhite ? AppColors.cFF101820 : AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '予定を決める前に、誰が空いているか一目で見られるよ。',
              style: TextStyle(
                color: isWhite
                    ? AppColors.cFF667381
                    : AppColors.white.withValues(alpha: .62),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            _CalendarFriendStatusModalOverview(
              availableCount: availableCount,
              totalCount: friends.length,
              isWhite: isWhite,
            ),
            if (widget.groups.isNotEmpty) ...[
              const SizedBox(height: 10),
              _CalendarFriendGroupSelector(
                groups: widget.groups,
                selectedGroupId: _selectedGroupId,
                isWhite: isWhite,
                onChanged: (groupId) => setState(() {
                  _selectedGroupId = groupId;
                }),
              ),
            ],
            const SizedBox(height: 8),
            _CalendarFriendStatusSummary(friends: friends, isWhite: isWhite),
            const SizedBox(height: 12),
            Expanded(
              child: _CalendarFriendStatusBlockList(
                friends: friends,
                isWhite: isWhite,
                sendingFriendId: _sendingFriendId,
                invitedFriendIds: invitedFriendIds,
                inviteAvailable: inviteAvailable,
                onInvite: _sendInvite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarFriendGroupSelector extends StatelessWidget {
  const _CalendarFriendGroupSelector({
    required this.groups,
    required this.selectedGroupId,
    required this.isWhite,
    required this.onChanged,
  });

  final List<_CalendarFriendGroup> groups;
  final String? selectedGroupId;
  final bool isWhite;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: groups.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final group = index == 0 ? null : groups[index - 1];
          final selected = group?.id == selectedGroupId;
          return _CalendarFriendGroupChip(
            label: group?.name ?? 'みんな',
            selected: index == 0 ? selectedGroupId == null : selected,
            isWhite: isWhite,
            onTap: () => onChanged(group?.id),
          );
        },
      ),
    );
  }
}

class _CalendarFriendGroupChip extends StatelessWidget {
  const _CalendarFriendGroupChip({
    required this.label,
    required this.selected,
    required this.isWhite,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppColors.primaryAction : AppColors.cFF94A3B8;
    final surface = selected
        ? accent.withValues(alpha: isWhite ? .32 : .42)
        : isWhite
        ? AppColors.cFFF6F8FA
        : AppColors.cFF26323C;
    final bottom = selected
        ? Color.lerp(accent, AppColors.black, .34)!
        : isWhite
        ? AppColors.cFFD3DBE3
        : AppColors.cFF151D25;
    final foreground = selected
        ? AppColors.cFFFF86B7
        : isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .78);

    return Ohey3DButtonSurface(
      onTap: onTap,
      height: 29,
      radius: 999,
      color: surface,
      bottomColor: bottom,
      useGradient: true,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderColor: selected
          ? foreground.withValues(alpha: .48)
          : isWhite
          ? AppColors.cFFE0E6ED
          : AppColors.white.withValues(alpha: .14),
      outerShadows: [
        BoxShadow(
          color: (selected ? foreground : AppColors.black).withValues(
            alpha: selected ? .20 : .12,
          ),
          blurRadius: selected ? 16 : 10,
          offset: const Offset(0, 6),
        ),
      ],
      innerShadows: [
        BoxShadow(
          color: AppColors.white.withValues(alpha: selected ? .10 : .06),
          blurRadius: 8,
          offset: const Offset(-2, -2),
        ),
      ],
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _CalendarFriendStatusModalOverview extends StatelessWidget {
  const _CalendarFriendStatusModalOverview({
    required this.availableCount,
    required this.totalCount,
    required this.isWhite,
  });

  final int availableCount;
  final int totalCount;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final accent = availableCount > 0
        ? _calendarPrimaryActionColor
        : AppColors.cFF94A3B8;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: isWhite
            ? accent.withValues(alpha: .10)
            : AppColors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: .28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isWhite ? .08 : .14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          OheyPopIcon(
            icon: CupertinoIcons.person_2_fill,
            color: accent,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$availableCount/$totalCount人が空いてそう',
                  style: TextStyle(
                    color: isWhite ? AppColors.cFF101820 : AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  availableCount > 0 ? '誘えそうなフレンズを上に並べています' : '今日は予定あり・未定が多そう',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite
                        ? AppColors.cFF667381
                        : AppColors.white.withValues(alpha: .62),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
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

class _CalendarFriendStatusBlockList extends StatelessWidget {
  const _CalendarFriendStatusBlockList({
    required this.friends,
    required this.isWhite,
    required this.sendingFriendId,
    required this.invitedFriendIds,
    required this.inviteAvailable,
    required this.onInvite,
  });

  final List<OheyFriend> friends;
  final bool isWhite;
  final String? sendingFriendId;
  final Set<String> invitedFriendIds;
  final bool inviteAvailable;
  final Future<void> Function(OheyFriend friend) onInvite;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Center(
        child: Text(
          'このグループのフレンズはいません',
          style: TextStyle(
            color: isWhite
                ? AppColors.cFF667381
                : AppColors.white.withValues(alpha: .62),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: friends.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final friend = friends[index];
        final inviteSent = invitedFriendIds.contains(friend.id);
        return _CalendarFriendStatusBlock(
          friend: friend,
          isWhite: isWhite,
          inviteEnabled: inviteAvailable && !inviteSent,
          inviteAvailable: inviteAvailable,
          inviteSent: inviteSent,
          invitePressed: sendingFriendId == friend.id,
          onInvite: () => onInvite(friend),
        );
      },
    );
  }
}

class _CalendarFriendStatusBlock extends StatelessWidget {
  const _CalendarFriendStatusBlock({
    required this.friend,
    required this.isWhite,
    required this.inviteEnabled,
    required this.inviteAvailable,
    required this.inviteSent,
    required this.invitePressed,
    required this.onInvite,
  });

  final OheyFriend friend;
  final bool isWhite;
  final bool inviteEnabled;
  final bool inviteAvailable;
  final bool inviteSent;
  final bool invitePressed;
  final Future<void> Function() onInvite;

  @override
  Widget build(BuildContext context) {
    final status = oheyDailyStatusFromKey(friend.statusKey);
    return OheyFriendUserBlock(
      friend: friend,
      statusLabel: status.label,
      statusReason: status.description,
      statusColor: _calendarFriendBlockStatusColor(status),
      statusEnabled: status.isAvailable,
      fallbackAvatar: _fallbackAvatarForCalendarFriend(friend),
      showInvite: true,
      inviteAvailable: inviteAvailable,
      inviteSent: inviteSent,
      invitePressed: invitePressed,
      onInvite: inviteEnabled ? onInvite : null,
    );
  }
}

OheyAvatar _fallbackAvatarForCalendarFriend(OheyFriend friend) {
  final hash = friend.id.hashCode.abs();
  return OheyAvatar(
    skin: hash % OheyAvatar.skinColors.length,
    hair: (hash ~/ 3) % OheyAvatar.hairStyles.length,
    shirt: (hash ~/ 5) % OheyAvatar.shirtColors.length,
    eyes: (hash ~/ 7) % OheyAvatar.eyeStyles.length,
    mouth: (hash ~/ 11) % OheyAvatar.mouthStyles.length,
    accessory: (hash ~/ 13) % OheyAvatar.accessoryStyles.length,
  );
}

Color _calendarFriendBlockStatusColor(OheyDailyStatus status) {
  final color = oheyDailyStatusColor(status);
  if (status == OheyDailyStatus.unselected) return oheyDailyStatusGreen;
  return color;
}

bool _calendarFriendIsAvailable(String? statusKey) =>
    oheyDailyStatusFromKey(statusKey).canJoinPlan;

bool _isPastCalendarDate(DateTime day) =>
    _dateOnly(day).isBefore(_dateOnly(DateTime.now()));

int _calendarFriendStatusRank(String? statusKey) =>
    oheyDailyStatusFromKey(statusKey).availabilityRank;

class _CalendarStatusSheet extends StatelessWidget {
  const _CalendarStatusSheet({
    required this.day,
    required this.selected,
    required this.showLockedExplanation,
  });

  final DateTime day;
  final OheyDailyStatus selected;
  final bool showLockedExplanation;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite ? AppColors.cFF657282 : AppColors.white70;
    final options = const [
      OheyDailyStatus.available,
      OheyDailyStatus.maybeAvailable,
      OheyDailyStatus.dependsOnTime,
      OheyDailyStatus.hasPlans,
    ];
    return OheyBottomSheetShell(
      title: 'この日の気分',
      showHandle: true,
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            showLockedExplanation
                ? '先に自分の予定を設定すると見られるよ。'
                : '${day.month}/${day.day} の予定決めに使えるよ。',
            style: TextStyle(color: sub, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          for (final status in options) ...[
            OheyDailyStatus3DOption(
              status: status,
              title: status.label,
              subtitle: status.description,
              selected: status == selected,
              onTap: () => Navigator.of(context).pop(status),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PlayfulMonthGrid extends StatelessWidget {
  const _PlayfulMonthGrid({
    required this.month,
    required this.selectedDay,
    required this.statusByDate,
    required this.todayReservations,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<String, OheyDailyStatus> statusByDate;
  final List<OheyInvite> todayReservations;
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
                            ? AppColors.cFFFF6FA6
                            : entry.key == 6
                            ? AppColors.cFF46C8FF
                            : AppColors.cFFB7C0CA,
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
        LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisSpacing = 6.0;
            const mainAxisSpacing = 5.0;
            final tileExtent =
                ((constraints.maxWidth - (crossAxisSpacing * 6)) / 7).clamp(
                  42.0,
                  54.0,
                );
            final gridHeight =
                (tileExtent * rows) + (mainAxisSpacing * (rows - 1));
            return SizedBox(
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
                  final inMonth = dayNumber >= 1 && dayNumber <= daysInMonth;
                  final displayDay = inMonth
                      ? dayNumber
                      : (dayNumber < 1
                            ? previousMonthDays + dayNumber
                            : dayNumber - daysInMonth);
                  final day = DateTime(month.year, month.month, dayNumber);
                  final isToday = inMonth && _isSameDate(DateTime.now(), day);
                  final hasPlan = isToday && todayReservations.isNotEmpty;
                  final dailyStatus = inMonth
                      ? statusByDate[_dateKey(day)] ??
                            OheyDailyStatus.unselected
                      : OheyDailyStatus.unselected;
                  return _DayTile(
                    day: displayDay,
                    date: day,
                    inMonth: inMonth,
                    dailyStatus: dailyStatus,
                    isToday: isToday,
                    isSelected: inMonth && _isSameDate(selectedDay, day),
                    hasPlan: hasPlan,
                    column: index % 7,
                    onTap: inMonth ? () => onSelectDay(day) : null,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.date,
    required this.inMonth,
    required this.dailyStatus,
    required this.isToday,
    required this.isSelected,
    required this.hasPlan,
    required this.column,
    this.onTap,
  });

  final int day;
  final DateTime date;
  final bool inMonth;
  final OheyDailyStatus dailyStatus;
  final bool isToday;
  final bool isSelected;
  final bool hasPlan;
  final int column;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final hasStatus = inMonth && dailyStatus != OheyDailyStatus.unselected;
    final statusAccent = oheyDailyStatusTileAccent(dailyStatus);
    final dayColor = hasStatus
        ? oheyDailyStatusTileForeground(dailyStatus, isWhite: isWhite)
        : !inMonth
        ? (isWhite
              ? AppColors.black.withValues(alpha: .20)
              : AppColors.white.withValues(alpha: .20))
        : column == 0
        ? AppColors.cFFFF6FA6
        : column == 6
        ? AppColors.cFF46C8FF
        : isWhite
        ? AppColors.cFF101820
        : AppColors.white;

    return GestureDetector(
      onTap: inMonth ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: !inMonth
              ? AppColors.transparent
              : hasStatus
              ? oheyDailyStatusTileBackground(
                  dailyStatus,
                  isWhite: isWhite,
                  selected: isSelected,
                )
              : isWhite
              ? (isSelected ? AppColors.cFFEAF8FF : AppColors.white)
              : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: !inMonth
                ? AppColors.transparent
                : hasPlan
                ? _calendarPrimaryActionColor
                : hasStatus
                ? statusAccent.withValues(alpha: isSelected ? .90 : .52)
                : isSelected
                ? AppColors.cFF54D7FF
                : _calendarPrimaryActionColor.withValues(
                    alpha: isWhite ? .34 : .24,
                  ),
            width: isSelected || hasPlan ? 2 : 1,
          ),
          boxShadow: !inMonth
              ? null
              : [
                  BoxShadow(
                    color: hasStatus
                        ? statusAccent.withValues(alpha: isWhite ? .16 : .24)
                        : AppColors.black.withValues(
                            alpha: isWhite ? .05 : .20,
                          ),
                    blurRadius: hasStatus ? 16 : 12,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isToday && !isWhite ? AppColors.white : dayColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (hasPlan)
              Positioned(
                left: 0,
                right: 0,
                bottom: 7,
                child: OheyGeneratedIcon(
                  CupertinoIcons.calendar_badge_plus,
                  color: _calendarPrimaryActionColor,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _calendarWeekdayLabel(DateTime day) =>
    const ['月', '火', '水', '木', '金', '土', '日'][day.weekday - 1];
