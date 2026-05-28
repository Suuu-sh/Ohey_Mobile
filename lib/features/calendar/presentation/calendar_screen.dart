import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/application/nomo_user_controller.dart';
import '../../../core/data/user_repository.dart';
import '../../../core/models/nomo_drink_invite.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/models/nomo_user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_bottom_sheet.dart';
import '../../../core/widgets/nomo_daily_status_3d_option.dart';
import '../../../core/widgets/nomo_friend_user_block.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_scene_header_backdrop.dart';
import '../../../core/widgets/nomo_themed_panel.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../friends/application/drink_invite_controller.dart';
import '../../friends/data/friend_repository.dart';
import '../../logs/application/drink_log_controller.dart';

const _calendarPrimaryActionColor = Color(0xFF20B9FF);
const _calendarPrimaryActionForegroundColor = Color(0xFF06111D);

String _calendarGroupStorageKey(String userId) =>
    'nomo_custom_friend_filters_v1_$userId';

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
  const CalendarScreen({super.key, this.onAddLogPressed});

  final VoidCallback? onAddLogPressed;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const _calendarIntroSeenKey = 'nomo_calendar_intro_seen';

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selectedDay = _dateOnly(DateTime.now());
  double _monthDragOffset = 0;
  bool _isIntroSeen = true;
  bool _isStatusSaving = false;
  final Map<String, NomoDailyStatus> _statusByDate = {};
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
        _syncCalendarGroupsForUser(ref.read(nomoUserProvider)?.userId);
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
    if (!mounted || status != NomoDailyStatus.unselected) return;
    await _openStatusPicker(showLockedExplanation: true);
  }

  Future<NomoDailyStatus> _loadStatusFor(DateTime day) async {
    final key = _dateKey(day);
    final cached = _statusByDate[key];
    if (cached != null) return cached;
    if (!_loadingStatusKeys.add(key)) return NomoDailyStatus.unselected;
    try {
      final status = await ref
          .read(userRepositoryProvider)
          .fetchDailyStatus(day);
      if (!mounted) return status;
      setState(() => _statusByDate[key] = status);
      return status;
    } catch (_) {
      if (mounted) {
        setState(() => _statusByDate[key] = NomoDailyStatus.unselected);
      }
      return NomoDailyStatus.unselected;
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
    Map<String, NomoDailyStatus> statuses;
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
        _statusByDate[key] = statuses[key] ?? NomoDailyStatus.unselected;
      }
    });
  }

  Future<void> _setStatusForSelectedDay(NomoDailyStatus status) async {
    if (_isStatusSaving) return;
    final day = _selectedDay;
    setState(() => _isStatusSaving = true);
    try {
      await ref
          .read(nomoUserProvider.notifier)
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
    final picked = await showNomoBottomSheet<NomoDailyStatus>(
      context: context,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: .58),
      builder: (_) => _CalendarStatusSheet(
        day: _selectedDay,
        selected:
            _statusByDate[_dateKey(_selectedDay)] ?? NomoDailyStatus.unselected,
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
    final logsAsync = ref.watch(drinkLogControllerProvider);
    final logs = logsAsync.asData?.value ?? const <DrinkLog>[];
    final userLogs = logs.where((log) => !log.isOfficial);
    final monthlyLogs = userLogs.where((log) => log.isInMonth(_month)).toList();
    final todayReservations =
        ref.watch(todayReservationsProvider).asData?.value ??
        const <NomoDrinkInvite>[];
    final selectedLogs = userLogs
        .where((log) => _isSameDate(log.date, _selectedDay))
        .toList(growable: false);
    final selectedFriendsAsync = ref.watch(
      friendsForDateProvider(_dateOnly(_selectedDay)),
    );
    final selectedStatus =
        _statusByDate[_dateKey(_selectedDay)] ?? NomoDailyStatus.unselected;
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
    final user = ref.watch(nomoUserProvider);
    if (_calendarGroupUserId != user?.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncCalendarGroupsForUser(user?.userId);
      });
    }
    final headerBackgroundHeight =
        NomoPageHeader.contentTopInset(context) + 100;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWhite
                ? const [Colors.white, Colors.white, Color(0xFFF7F9FB)]
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
              child: NomoSceneHeaderBackdrop(
                assetPath: 'assets/images/calendar_header_scene.png',
                fadeColor: isWhite
                    ? Colors.white
                    : AppColors.darkBackgroundBottom,
                accentColor: const Color(0xFF20B9FF),
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
                      NomoPageHeader.horizontalPadding,
                      NomoPageHeader.topPadding,
                      NomoPageHeader.horizontalPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const NomoPageHeader(
                          title: 'カレンダー',
                          titleColor: Color(0xFF54D7FF),
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
                                horizontal: NomoPageHeader.horizontalPadding,
                              ),
                              child: _PlayfulMonthGrid(
                                month: _month,
                                selectedDay: _selectedDay,
                                logs: monthlyLogs,
                                statusByDate: _statusByDate,
                                todayReservations: todayReservations,
                                onSelectDay: _selectDay,
                              ),
                            ),
                            if (!_isIntroSeen) ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: NomoPageHeader.horizontalPadding,
                                ),
                                child: _CalendarIntroCard(
                                  isWhite: isWhite,
                                  onDismiss: _dismissIntro,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            const _CalendarGlowDivider(),
                            const SizedBox(height: 7),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _SelectedDayPanel(
                                  day: _selectedDay,
                                  logs: selectedLogs,
                                  friendsAsync: selectedFriendsAsync,
                                  groups: _calendarGroups,
                                  isWhite: isWhite,
                                  status: selectedStatus,
                                  isStatusSaving: _isStatusSaving,
                                  onAddLogPressed: widget.onAddLogPressed,
                                  onChangeStatus: () => _openStatusPicker(
                                    showLockedExplanation:
                                        selectedStatus ==
                                        NomoDailyStatus.unselected,
                                  ),
                                ),
                              ),
                            ),
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
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final messageColor = isWhite
        ? const Color(0xFF657282)
        : Colors.white.withValues(alpha: .66);
    final cardColor = isWhite
        ? Colors.white
        : const Color(0xFF122233).withValues(alpha: .82);
    final borderColor = isWhite
        ? const Color(0xFFDCE4EC)
        : Colors.white.withValues(alpha: .08);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .05 : .18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NomoPopIcon(
            icon: CupertinoIcons.sparkles,
            color: const Color(0xFFFFD166),
            size: 42,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'カレンダーに思い出がたまります',
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
                  '思い出を残すと、その日にアメーバが出るよ。写真つきだとレアカラーになるかも。',
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
                color: const Color(0xFF54D7FF).withValues(alpha: .16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF54D7FF).withValues(alpha: .30),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF54D7FF),
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
              color: Colors.white,
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
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
        ),
        child: Text(
          label,
          style: TextStyle(
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

class _SelectedDayPanel extends StatelessWidget {
  const _SelectedDayPanel({
    required this.day,
    required this.logs,
    required this.friendsAsync,
    required this.groups,
    required this.isWhite,
    required this.status,
    required this.isStatusSaving,
    required this.onAddLogPressed,
    required this.onChangeStatus,
  });

  final DateTime day;
  final List<DrinkLog> logs;
  final AsyncValue<List<NomoFriend>> friendsAsync;
  final List<_CalendarFriendGroup> groups;
  final bool isWhite;
  final NomoDailyStatus status;
  final bool isStatusSaving;
  final VoidCallback? onAddLogPressed;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subColor = isWhite
        ? const Color(0xFF657282)
        : Colors.white.withValues(alpha: .66);
    return NomoThemedPanel(
      width: double.infinity,
      padding: EdgeInsets.zero,
      accentColor: _calendarPrimaryActionColor,
      backgroundColor: Colors.transparent,
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
                    _CalendarDateBadge(day: day, isWhite: isWhite),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '選んだ日のまとめ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: .3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '空き状況と思い出',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: compact ? 15 : 16,
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, compact ? 8 : 12),
                  child: Column(
                    children: [
                      Expanded(
                        flex: compact ? 5 : 6,
                        child: status == NomoDailyStatus.unselected
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
                      SizedBox(height: compact ? 6 : 9),
                      Expanded(
                        flex: compact ? 5 : 5,
                        child: _CalendarMemoryPreview(
                          logs: logs,
                          isWhite: isWhite,
                          compact: compact,
                          onAddLogPressed: onAddLogPressed,
                        ),
                      ),
                    ],
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

class _CalendarDateBadge extends StatelessWidget {
  const _CalendarDateBadge({required this.day, required this.isWhite});

  final DateTime day;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final accent = day.weekday == DateTime.sunday
        ? const Color(0xFFFF6FA6)
        : day.weekday == DateTime.saturday
        ? const Color(0xFF46C8FF)
        : _calendarPrimaryActionColor;
    return Container(
      width: 54,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isWhite ? .22 : .30),
            accent.withValues(alpha: isWhite ? .10 : .16),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: .42)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isWhite ? .10 : .22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.month}/${day.day}',
            style: TextStyle(
              color: isWhite ? const Color(0xFF101820) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _calendarWeekdayLabel(day),
            style: TextStyle(
              color: accent,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarStatusChangeButton extends StatelessWidget {
  const _CalendarStatusChangeButton({
    required this.status,
    required this.isSaving,
    required this.isWhite,
    required this.onTap,
  });

  final NomoDailyStatus status;
  final bool isSaving;
  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = status == NomoDailyStatus.unselected
        ? NomoDailyStatus.canDrinkToday
        : status;
    final accent = _calendarStatusBlockAccent(effectiveStatus);
    final foreground = _calendarStatus3DForegroundColor(effectiveStatus);
    return SizedBox(
      width: 56,
      child: Nomo3DButtonSurface(
        onTap: isSaving ? null : onTap,
        enabled: !isSaving,
        height: 28,
        radius: 14,
        color: _calendarStatus3DSurfaceColor(
          effectiveStatus,
          isWhite: isWhite,
          selected: true,
        ),
        bottomColor: _calendarStatus3DShadowColor(
          effectiveStatus,
          isWhite: isWhite,
          selected: true,
        ),
        borderColor: _calendarStatus3DBorderColor(
          effectiveStatus,
          isWhite: isWhite,
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
          BoxShadow(color: Colors.white.withValues(alpha: .12), blurRadius: 10),
        ],
        child: Center(
          child: Text(
            isSaving
                ? '保存中'
                : status == NomoDailyStatus.unselected
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
            NomoPopIcon(
              icon: CupertinoIcons.lock_fill,
              color: const Color(0xFF94A3B8),
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
                      color: isWhite ? const Color(0xFF101820) : Colors.white,
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
                          ? const Color(0xFF667381)
                          : Colors.white.withValues(alpha: .62),
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
              child: _CalendarInlineActionButton(
                label: '設定',
                onTap: onTap,
                height: compact ? 28 : 30,
                color: _calendarStatusPink,
                isWhite: isWhite,
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
  final AsyncValue<List<NomoFriend>> friendsAsync;
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
                  ? const Color(0xFF667381)
                  : Colors.white.withValues(alpha: .62),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      data: (friends) {
        if (friends.isEmpty) {
          return _CalendarSectionSurface(
            label: 'フレンズの空き状況',
            accent: AppColors.primaryAction,
            isWhite: isWhite,
            compact: compact,
            child: Center(
              child: Text(
                'フレンズを追加すると空き状況を確認できます',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isWhite
                      ? const Color(0xFF667381)
                      : Colors.white.withValues(alpha: .62),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
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
            : const Color(0xFF94A3B8);
        return _CalendarSectionSurface(
          label: 'フレンズの空き状況',
          accent: AppColors.primaryAction,
          isWhite: isWhite,
          compact: compact,
          onTap: openStatusSheet,
          trailing: _CalendarTinyPill(
            label: '$availableCount/${friends.length}',
            color: accent,
            isWhite: isWhite,
          ),
          child: Center(
            child: Row(
              children: [
                NomoPopIcon(
                  icon: CupertinoIcons.person_2_fill,
                  color: accent,
                  size: compact ? 30 : 38,
                  iconSize: compact ? 14 : 18,
                ),
                const SizedBox(width: 10),
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
                              ? const Color(0xFF101820)
                              : Colors.white,
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: compact ? 3 : 4),
                      if (!compact) ...[
                        _CalendarAvailabilityMeter(
                          value: friends.isEmpty
                              ? 0
                              : availableCount / friends.length,
                          color: accent,
                          isWhite: isWhite,
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        availableCount > 0 ? 'タップして誘えそうな人を見る' : '予定あり・未定が多そう',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isWhite
                              ? const Color(0xFF667381)
                              : Colors.white.withValues(alpha: .62),
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
                  child: _CalendarInlineActionButton(
                    label: '見る',
                    onTap: openStatusSheet,
                    height: compact ? 28 : 30,
                    color: _calendarPrimaryActionColor,
                    isWhite: isWhite,
                    fontSize: compact ? 11 : 12,
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
    this.trailing,
    this.onTap,
  });

  final String label;
  final Color accent;
  final bool isWhite;
  final bool compact;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fillColors = isWhite
        ? [Colors.white, const Color(0xFFF7FBFF)]
        : const [Color(0xFF050B13), Color(0xFF07101B)];
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
                : Colors.black.withValues(alpha: .26),
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
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
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

class _CalendarInlineActionButton extends StatelessWidget {
  const _CalendarInlineActionButton({
    required this.label,
    required this.height,
    required this.color,
    required this.isWhite,
    required this.fontSize,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final Color color;
  final bool isWhite;
  final double fontSize;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    final foreground = isWhite
        ? Color.lerp(color, Colors.black, .22)!
        : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: active ? onTap : null,
      child: Opacity(
        opacity: active ? 1 : .62,
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isWhite ? .14 : .20),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: color.withValues(alpha: isWhite ? .30 : .42),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarTinyPill extends StatelessWidget {
  const _CalendarTinyPill({
    required this.label,
    required this.color,
    required this.isWhite,
  });

  final String label;
  final Color color;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isWhite ? .14 : .20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: isWhite ? .30 : .40)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isWhite ? Color.lerp(color, Colors.black, .20)! : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _CalendarAvailabilityMeter extends StatelessWidget {
  const _CalendarAvailabilityMeter({
    required this.value,
    required this.color,
    required this.isWhite,
  });

  final double value;
  final Color color;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 5,
        color: isWhite
            ? const Color(0xFFE8EEF5)
            : Colors.white.withValues(alpha: .10),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: normalized,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, Color.lerp(color, Colors.white, .24)!],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarMemoryPreview extends StatelessWidget {
  const _CalendarMemoryPreview({
    required this.logs,
    required this.isWhite,
    required this.compact,
    required this.onAddLogPressed,
  });

  final List<DrinkLog> logs;
  final bool isWhite;
  final bool compact;
  final VoidCallback? onAddLogPressed;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF54D7FF);
    final visibleLogs = logs.take(compact ? 1 : 2).toList(growable: false);
    final hiddenCount = logs.length - visibleLogs.length;
    return _CalendarSectionSurface(
      label: '思い出',
      accent: accent,
      isWhite: isWhite,
      compact: compact,
      trailing: hiddenCount > 0
          ? _CalendarTinyPill(
              label: '+$hiddenCount',
              color: accent,
              isWhite: isWhite,
            )
          : null,
      child: logs.isEmpty
          ? _CalendarMemoryEmptyState(
              isWhite: isWhite,
              compact: compact,
              onAddLogPressed: onAddLogPressed,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final entry in visibleLogs.asMap().entries) ...[
                  if (entry.key > 0) SizedBox(height: compact ? 5 : 6),
                  _CalendarMemoryPreviewRow(
                    log: entry.value,
                    isWhite: isWhite,
                    compact: compact,
                  ),
                ],
              ],
            ),
    );
  }
}

class _CalendarMemoryEmptyState extends StatelessWidget {
  const _CalendarMemoryEmptyState({
    required this.isWhite,
    required this.compact,
    required this.onAddLogPressed,
  });

  final bool isWhite;
  final bool compact;
  final VoidCallback? onAddLogPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        children: [
          NomoPopIcon(
            icon: CupertinoIcons.sparkles,
            color: const Color(0xFF54D7FF),
            size: compact ? 28 : 36,
            iconSize: compact ? 13 : 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'この日の思い出はまだありません',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite ? const Color(0xFF101820) : Colors.white,
                    fontSize: compact ? 12.5 : 13.5,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: compact ? 2 : 3),
                Text(
                  'あとで写真やメモを残せるよ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWhite
                        ? const Color(0xFF667381)
                        : Colors.white.withValues(alpha: .62),
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
            child: _CalendarInlineActionButton(
              label: '投稿',
              onTap: onAddLogPressed ?? () {},
              height: compact ? 28 : 30,
              color: _calendarPrimaryActionColor,
              isWhite: isWhite,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarMemoryPreviewRow extends StatelessWidget {
  const _CalendarMemoryPreviewRow({
    required this.log,
    required this.isWhite,
    required this.compact,
  });

  final DrinkLog log;
  final bool isWhite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        log.photoAssetPath != null && log.photoAssetPath!.trim().isNotEmpty;
    final accent = hasPhoto ? const Color(0xFF54D7FF) : AppColors.success;
    final content = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 48 : 56),
      padding: EdgeInsets.fromLTRB(4, compact ? 6 : 8, 0, compact ? 6 : 8),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isWhite ? .12 : .18),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: isWhite ? .24 : .32),
              ),
            ),
            child: Center(
              child: NomoGeneratedIcon(
                hasPhoto
                    ? CupertinoIcons.photo_fill_on_rectangle_fill
                    : CupertinoIcons.lock_fill,
                color: accent,
                size: compact ? 17 : 19,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _calendarMemoryTitle(log),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isWhite ? const Color(0xFF344152) : Colors.white,
                fontSize: compact ? 13.5 : 15,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: compact ? 58 : 66,
            child: _CalendarInlineActionButton(
              label: hasPhoto ? '見る' : '記録',
              onTap: hasPhoto
                  ? () => _showCalendarLogPhoto(context, log)
                  : null,
              height: compact ? 32 : 36,
              color: accent,
              isWhite: isWhite,
              fontSize: compact ? 12 : 13,
              enabled: hasPhoto,
            ),
          ),
        ],
      ),
    );
    if (!hasPhoto) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showCalendarLogPhoto(context, log),
      child: content,
    );
  }
}

class _CalendarFriendStatusSummary extends StatelessWidget {
  const _CalendarFriendStatusSummary({
    required this.friends,
    required this.isWhite,
  });

  final List<NomoFriend> friends;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final counts = <NomoDailyStatus, int>{
      for (final status in NomoDailyStatus.values) status: 0,
    };
    for (final friend in friends) {
      final status = nomoDailyStatusFromKey(friend.statusKey);
      counts[status] = (counts[status] ?? 0) + 1;
    }
    final statuses = NomoDailyStatus.values
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

  final NomoDailyStatus status;
  final int count;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final color = _calendarStatusColor(status);
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
          color: isWhite ? const Color(0xFF17212B) : Colors.white,
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
  required List<NomoFriend> friends,
  required List<_CalendarFriendGroup> groups,
  required bool isWhite,
}) {
  return showNomoBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: .58),
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
  final List<NomoFriend> friends;
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

  Future<void> _sendInvite(NomoFriend friend) async {
    if (_sendingFriendId != null) return;
    HapticFeedback.selectionClick();
    setState(() => _sendingFriendId = friend.id);
    try {
      await ref
          .read(drinkInviteControllerProvider)
          .sendInvite(friendId: friend.id, date: widget.day);
      ref.invalidate(todayReservationsProvider);
      ref.invalidate(incomingDrinkInvitesProvider);
      ref.invalidate(outgoingActiveDrinkInvitesProvider(widget.day));
      if (!mounted) return;
      setState(() => _invitedFriendIds.add(friend.id));
      NomoToast.show(
        context,
        '${widget.day.month}/${widget.day.day}で${friend.name}にお誘いを送りました。',
        icon: CupertinoIcons.checkmark_circle_fill,
        placement: NomoToastPlacement.bottom,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _sendingFriendId = null);
      NomoToast.show(
        context,
        '招待を送れなかったよ。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        placement: NomoToastPlacement.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final persistedInvitedFriendIds =
        ref
            .watch(outgoingActiveDrinkInvitesProvider(widget.day))
            .asData
            ?.value
            .map((invite) => invite.toUserId)
            .toSet() ??
        const <String>{};
    final invitedFriendIds = <String>{
      ...persistedInvitedFriendIds,
      ..._invitedFriendIds,
    };
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
    final contentHeight = (media.size.height * .80 - media.padding.bottom - 24)
        .clamp(460.0, 680.0)
        .toDouble();
    return NomoBottomSheetShell(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      radius: 32,
      maxHeightFactor: .82,
      child: SizedBox(
        height: contentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NomoBottomSheetHandle(),
            const SizedBox(height: 14),
            Text(
              'フレンズの空き状況',
              style: TextStyle(
                color: isWhite ? const Color(0xFF101820) : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '予定を決める前に、誰が空いているか一目で見られるよ。',
              style: TextStyle(
                color: isWhite
                    ? const Color(0xFF667381)
                    : Colors.white.withValues(alpha: .62),
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
    final accent = selected ? AppColors.primaryAction : const Color(0xFF94A3B8);
    final surface = selected
        ? accent.withValues(alpha: isWhite ? .32 : .42)
        : isWhite
        ? const Color(0xFFF6F8FA)
        : const Color(0xFF26323C);
    final bottom = selected
        ? Color.lerp(accent, Colors.black, .34)!
        : isWhite
        ? const Color(0xFFD3DBE3)
        : const Color(0xFF151D25);
    final foreground = selected
        ? const Color(0xFFFF86B7)
        : isWhite
        ? const Color(0xFF667381)
        : Colors.white.withValues(alpha: .78);

    return Nomo3DButtonSurface(
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
          ? const Color(0xFFE0E6ED)
          : Colors.white.withValues(alpha: .14),
      outerShadows: [
        BoxShadow(
          color: (selected ? foreground : Colors.black).withValues(
            alpha: selected ? .20 : .12,
          ),
          blurRadius: selected ? 16 : 10,
          offset: const Offset(0, 6),
        ),
      ],
      innerShadows: [
        BoxShadow(
          color: Colors.white.withValues(alpha: selected ? .10 : .06),
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
        : const Color(0xFF94A3B8);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: isWhite
            ? accent.withValues(alpha: .10)
            : Colors.white.withValues(alpha: .06),
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
          NomoPopIcon(
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
                    color: isWhite ? const Color(0xFF101820) : Colors.white,
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
                        ? const Color(0xFF667381)
                        : Colors.white.withValues(alpha: .62),
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
    required this.onInvite,
  });

  final List<NomoFriend> friends;
  final bool isWhite;
  final String? sendingFriendId;
  final Set<String> invitedFriendIds;
  final Future<void> Function(NomoFriend friend) onInvite;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Center(
        child: Text(
          'このグループのフレンズはいません',
          style: TextStyle(
            color: isWhite
                ? const Color(0xFF667381)
                : Colors.white.withValues(alpha: .62),
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
        return _CalendarFriendStatusBlock(
          friend: friend,
          isWhite: isWhite,
          inviteEnabled: sendingFriendId == null,
          inviteSent: invitedFriendIds.contains(friend.id),
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
    required this.inviteSent,
    required this.onInvite,
  });

  final NomoFriend friend;
  final bool isWhite;
  final bool inviteEnabled;
  final bool inviteSent;
  final Future<void> Function() onInvite;

  @override
  Widget build(BuildContext context) {
    final status = nomoDailyStatusFromKey(friend.statusKey);
    return NomoFriendUserBlock(
      friend: friend,
      statusLabel: _calendarStatusLabel(status, day: DateTime.now()),
      statusReason: _calendarStatusCopy(status, day: DateTime.now()),
      statusColor: _calendarFriendBlockStatusColor(status),
      statusEnabled: status.isAvailable,
      fallbackAvatar: _fallbackAvatarForCalendarFriend(friend),
      showInvite: true,
      inviteSent: inviteSent,
      onInvite: inviteEnabled ? onInvite : null,
    );
  }
}

NomoAvatar _fallbackAvatarForCalendarFriend(NomoFriend friend) {
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

Color _calendarFriendBlockStatusColor(NomoDailyStatus status) {
  final color = _calendarStatusColor(status);
  if (status == NomoDailyStatus.unselected) return _calendarStatusGreen;
  return color;
}

bool _calendarFriendIsAvailable(String? statusKey) =>
    nomoDailyStatusFromKey(statusKey).canJoinPlan;

int _calendarFriendStatusRank(String? statusKey) =>
    nomoDailyStatusFromKey(statusKey).availabilityRank;

class _CalendarStatusSheet extends StatelessWidget {
  const _CalendarStatusSheet({
    required this.day,
    required this.selected,
    required this.showLockedExplanation,
  });

  final DateTime day;
  final NomoDailyStatus selected;
  final bool showLockedExplanation;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite ? const Color(0xFF657282) : Colors.white70;
    final options = const [
      NomoDailyStatus.canDrinkToday,
      NomoDailyStatus.nonAlcohol,
      NomoDailyStatus.liverRest,
      NomoDailyStatus.hasPlans,
    ];
    return NomoBottomSheetShell(
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
            NomoDailyStatus3DOption(
              status: status,
              title: _calendarStatusLabel(status, day: day),
              subtitle: _calendarStatusCopy(status, day: day),
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

Future<void> _showCalendarLogPhoto(BuildContext context, DrinkLog log) {
  return showNomoBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (_) => _CalendarLogPhotoSheet(log: log),
  );
}

class _CalendarLogPhotoSheet extends StatelessWidget {
  const _CalendarLogPhotoSheet({required this.log});

  final DrinkLog log;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subColor = isWhite
        ? const Color(0xFF657282)
        : Colors.white.withValues(alpha: .68);
    final title = log.place.trim().isNotEmpty
        ? log.place.trim()
        : log.memo.trim().isNotEmpty
        ? log.memo.trim()
        : '思い出写真';

    return NomoBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: subColor.withValues(alpha: .42),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _CalendarLogPhotoFrame(path: log.photoAssetPath),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${log.date.month}/${log.date.day} の思い出',
            style: TextStyle(
              color: subColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarLogPhotoFrame extends StatelessWidget {
  const _CalendarLogPhotoFrame({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final provider = _calendarImageProviderFor(path);
    if (provider == null) {
      return Container(
        color: Colors.black.withValues(alpha: .20),
        alignment: Alignment.center,
        child: const NomoGeneratedIcon(
          CupertinoIcons.photo,
          color: Colors.white54,
          size: 42,
        ),
      );
    }
    return Image(
      image: provider,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.black.withValues(alpha: .20),
        alignment: Alignment.center,
        child: const NomoGeneratedIcon(
          CupertinoIcons.exclamationmark_triangle,
          color: Colors.white54,
          size: 42,
        ),
      ),
    );
  }
}

ImageProvider? _calendarImageProviderFor(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return NetworkImage(normalized);
  }
  if (normalized.startsWith('/')) {
    final file = File(normalized);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }
  if (normalized.startsWith('assets/')) return AssetImage(normalized);
  return null;
}

class _PlayfulMonthGrid extends StatelessWidget {
  const _PlayfulMonthGrid({
    required this.month,
    required this.selectedDay,
    required this.logs,
    required this.statusByDate,
    required this.todayReservations,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime selectedDay;
  final List<DrinkLog> logs;
  final Map<String, NomoDailyStatus> statusByDate;
  final List<NomoDrinkInvite> todayReservations;
  final ValueChanged<DateTime> onSelectDay;

  static const _rarityColors = {
    DrinkLogRarity.normal: Color(0xFF94A3B8),
    DrinkLogRarity.uncommon: Color(0xFFFF75B5),
    DrinkLogRarity.rare: Color(0xFFC08BFF),
    DrinkLogRarity.superRare: Color(0xFFFFD166),
    DrinkLogRarity.ultraRare: Color(0xFF54D7FF),
    DrinkLogRarity.secret: Color(0xFFB7F51A),
  };

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCells = DateTime(month.year, month.month).weekday % 7;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final previousMonthDays = DateTime(month.year, month.month, 0).day;
    final markers = _markersForLogs(logs);

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
                  final marker = inMonth ? markers[dayNumber] : null;
                  final isToday = inMonth && _isSameDate(DateTime.now(), day);
                  final hasPlan = isToday && todayReservations.isNotEmpty;
                  final dailyStatus =
                      statusByDate[_dateKey(day)] ?? NomoDailyStatus.unselected;
                  return _DayTile(
                    day: displayDay,
                    date: day,
                    inMonth: inMonth,
                    dailyStatus: dailyStatus,
                    marker: marker,
                    isToday: isToday,
                    isSelected: _isSameDate(selectedDay, day),
                    hasPlan: hasPlan,
                    column: index % 7,
                    onTap: () => onSelectDay(day),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Map<int, _Marker> _markersForLogs(List<DrinkLog> logs) {
    final rarities = <int, DrinkLogRarity>{};
    for (final log in logs) {
      final current = rarities[log.date.day];
      if (current == null || _rarityRank(log.rarity) > _rarityRank(current)) {
        rarities[log.date.day] = log.rarity;
      }
    }
    return {
      for (final entry in rarities.entries)
        entry.key: _Marker(_rarityColors[entry.value]!, entry.value),
    };
  }

  int _rarityRank(DrinkLogRarity rarity) => switch (rarity) {
    DrinkLogRarity.normal => 0,
    DrinkLogRarity.uncommon => 1,
    DrinkLogRarity.rare => 2,
    DrinkLogRarity.superRare => 3,
    DrinkLogRarity.ultraRare => 4,
    DrinkLogRarity.secret => 5,
  };
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.date,
    required this.inMonth,
    required this.dailyStatus,
    required this.marker,
    required this.isToday,
    required this.isSelected,
    required this.hasPlan,
    required this.column,
    this.onTap,
  });

  final int day;
  final DateTime date;
  final bool inMonth;
  final NomoDailyStatus dailyStatus;
  final _Marker? marker;
  final bool isToday;
  final bool isSelected;
  final bool hasPlan;
  final int column;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final hasStatus = dailyStatus != NomoDailyStatus.unselected;
    final statusAccent = _calendarStatusTileAccent(dailyStatus);
    final dayColor = hasStatus
        ? _calendarStatusTileForeground(dailyStatus, isWhite: isWhite)
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
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: hasStatus
              ? _calendarStatusTileBackground(
                  dailyStatus,
                  isWhite: isWhite,
                  selected: isSelected,
                )
              : isWhite
              ? (isSelected ? const Color(0xFFEAF8FF) : Colors.white)
              : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: hasPlan
                ? _calendarPrimaryActionColor
                : hasStatus
                ? statusAccent.withValues(alpha: isSelected ? .90 : .52)
                : isSelected
                ? const Color(0xFF54D7FF)
                : _calendarPrimaryActionColor.withValues(
                    alpha: isWhite ? .34 : .24,
                  ),
            width: isSelected || hasPlan ? 2 : 1,
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Align(
                alignment: marker == null
                    ? Alignment.center
                    : Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: marker == null ? 0 : 8),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isToday && !isWhite ? Colors.white : dayColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            if (hasPlan)
              Positioned(
                left: 0,
                right: 0,
                bottom: marker == null ? 7 : 28,
                child: NomoGeneratedIcon(
                  CupertinoIcons.calendar_badge_plus,
                  color: _calendarPrimaryActionColor,
                  size: 22,
                ),
              ),
            if (marker != null)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: NomoGeneratedIcon(
                      CupertinoIcons.person_crop_circle_fill,
                      color: marker!.accent,
                      size: 42,
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

class _Marker {
  const _Marker(this.accent, this.rarity);

  final Color accent;
  final DrinkLogRarity rarity;
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _calendarWeekdayLabel(DateTime day) =>
    const ['月', '火', '水', '木', '金', '土', '日'][day.weekday - 1];

String _calendarMemoryTitle(DrinkLog log) {
  final memo = log.memo.trim();
  if (memo.isNotEmpty) return memo;
  final place = log.place.trim();
  if (place.isNotEmpty) return place;
  final hasPhoto =
      log.photoAssetPath != null && log.photoAssetPath!.trim().isNotEmpty;
  return hasPhoto ? '思い出を残しました' : '記録だけ保存しました';
}

const _calendarStatusPink = Color(0xFFFF5EA8);
const _calendarStatusBlue = Color(0xFF20B9FF);
const _calendarStatusPurple = Color(0xFF8A62FF);
const _calendarStatusGreen = Color(0xFF9AF21A);
const _calendarStatusBlocked = Color(0xFF2B3644);
const _calendarStatusBlockedForeground = Color(0xFF738092);

Color _calendarStatusTileAccent(NomoDailyStatus status) {
  if (status == NomoDailyStatus.hasPlans) {
    return _calendarStatusBlockedForeground;
  }
  return _calendarStatusColor(status);
}

Color _calendarStatusTileBackground(
  NomoDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return isWhite
        ? const Color(0xFFE2E8F0)
        : _calendarStatusBlocked.withValues(alpha: selected ? .92 : .76);
  }
  final color = _calendarStatusColor(status);
  return color.withValues(
    alpha: isWhite ? (selected ? .34 : .22) : (selected ? .52 : .36),
  );
}

Color _calendarStatusTileForeground(
  NomoDailyStatus status, {
  required bool isWhite,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFF111827) : Colors.white;
  }
  return _calendarPrimaryActionForegroundColor;
}

Color _calendarStatusColor(NomoDailyStatus status) => switch (status) {
  NomoDailyStatus.canDrinkToday => _calendarStatusPink,
  NomoDailyStatus.nonAlcohol => _calendarStatusBlue,
  NomoDailyStatus.liverRest => _calendarStatusPurple,
  NomoDailyStatus.hasPlans => _calendarStatusBlockedForeground,
  NomoDailyStatus.unselected => _calendarStatusGreen,
};

Color _calendarStatusBlockAccent(NomoDailyStatus status) => switch (status) {
  NomoDailyStatus.hasPlans => _calendarStatusBlocked,
  _ => _calendarStatusColor(status),
};

Color _calendarStatus3DSurfaceColor(
  NomoDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFFE8EEF5) : const Color(0xFF33404E);
  }
  return _calendarStatusColor(status);
}

Color _calendarStatus3DShadowColor(
  NomoDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFFC2CCD8) : const Color(0xFF16202B);
  }
  return Color.lerp(
    _calendarStatus3DSurfaceColor(status, isWhite: isWhite, selected: selected),
    Colors.black,
    .32,
  )!;
}

Color _calendarStatus3DForegroundColor(NomoDailyStatus status) {
  if (status == NomoDailyStatus.hasPlans) {
    return const Color(0xFF111827);
  }
  return _calendarPrimaryActionForegroundColor;
}

Color _calendarStatus3DBorderColor(
  NomoDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == NomoDailyStatus.hasPlans) {
    return Colors.white.withValues(alpha: selected ? .24 : .18);
  }
  return Colors.white.withValues(alpha: selected ? .30 : .20);
}

String _calendarStatusLabel(NomoDailyStatus status, {required DateTime day}) =>
    status.label;

String _calendarStatusCopy(NomoDailyStatus status, {required DateTime day}) =>
    status.description;
