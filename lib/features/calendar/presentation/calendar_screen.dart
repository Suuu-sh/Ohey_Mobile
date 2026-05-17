import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../logs/application/drink_log_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  double _monthDragOffset = 0;

  void _moveMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _selectedDay = DateTime(_month.year, _month.month);
    });
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
    final monthlyLogs = logs.where((log) => log.isInMonth(_month)).toList();
    final selectedLogs = monthlyLogs
        .where((log) => log.isSameDay(_selectedDay))
        .toList();
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isWhite
              ? const [Colors.white, Colors.white, Color(0xFFF7F9FB)]
              : const [Color(0xFF172637), Color(0xFF101B28), Color(0xFF0B1420)],
        ),
      ),
      child: SafeArea(
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
                  const NomoPageHeader(title: 'カレンダー'),
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
                  padding: const EdgeInsets.fromLTRB(
                    NomoPageHeader.horizontalPadding,
                    14,
                    NomoPageHeader.horizontalPadding,
                    148,
                  ),
                  child: Column(
                    children: [
                      _PlayfulMonthGrid(
                        month: _month,
                        logs: monthlyLogs,
                        selectedDay: _selectedDay,
                        onDaySelected: (day) =>
                            setState(() => _selectedDay = day),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _SelectedDayPosts(
                          day: _selectedDay,
                          logs: selectedLogs,
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
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onMove});

  final DateTime month;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Row(
      children: [
        _ArrowButton(label: '<', onTap: () => onMove(-1)),
        Expanded(
          child: Text(
            '${month.year}/${month.month.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isWhite ? const Color(0xFF101820) : Colors.white,
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
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isWhite
              ? const Color(0xFFF3F6F8)
              : Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isWhite ? const Color(0xFF101820) : Colors.white,
            fontSize: 24,
            height: .95,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PlayfulMonthGrid extends StatelessWidget {
  const _PlayfulMonthGrid({
    required this.month,
    required this.logs,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<DrinkLog> logs;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  static const _markerColors = [
    Color(0xFFB7F51A),
    Color(0xFFFFA726),
    Color(0xFF46C8FF),
    Color(0xFFC678FF),
    Color(0xFFFF6FA6),
  ];

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
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisSpacing = 6.0;
            const mainAxisSpacing = 7.0;
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
                  final isToday = inMonth && _isSameDay(DateTime.now(), day);
                  final isSelected = inMonth && _isSameDay(selectedDay, day);
                  return _DayTile(
                    day: displayDay,
                    inMonth: inMonth,
                    marker: marker,
                    isToday: isToday,
                    isSelected: isSelected,
                    column: index % 7,
                    onTap: inMonth ? () => onDaySelected(day) : null,
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
    final markers = <int, _Marker>{};
    for (final log in logs) {
      markers.putIfAbsent(log.date.day, () {
        final index = log.date.day % _markerColors.length;
        return _Marker(_markerColors[index]);
      });
    }
    return markers;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.inMonth,
    required this.marker,
    required this.isToday,
    required this.isSelected,
    required this.column,
    required this.onTap,
  });

  final int day;
  final bool inMonth;
  final _Marker? marker;
  final bool isToday;
  final bool isSelected;
  final int column;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final dayColor = !inMonth
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
          color: isSelected
              ? const Color(0xFF26D9C7).withValues(alpha: isWhite ? .14 : .22)
              : isWhite
              ? Colors.white
              : const Color(0xFF122233).withValues(alpha: .82),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF26D9C7)
                : isWhite
                ? const Color(0xFFDCE4EC)
                : Colors.white.withValues(alpha: .06),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF26D9C7).withValues(alpha: .20)
                  : Colors.black.withValues(alpha: isWhite ? .05 : .20),
              blurRadius: isSelected ? 18 : 12,
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
                  child: Container(
                    width: isToday ? 36 : null,
                    height: isToday ? 36 : null,
                    alignment: Alignment.center,
                    decoration: isToday
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFB7F51A),
                              width: 3,
                            ),
                          )
                        : null,
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
            ),
            if (marker != null) ...[
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: NomoGeneratedIcon(
                  CupertinoIcons.person_crop_circle_fill,
                  color: marker!.accent,
                  size: 26,
                ),
              ),
              Positioned(
                right: 10,
                top: 16,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: marker!.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedDayPosts extends StatelessWidget {
  const _SelectedDayPosts({required this.day, required this.logs});

  final DateTime day;
  final List<DrinkLog> logs;

  @override
  Widget build(BuildContext context) {
    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${day.month}/${day.day}の飲みログ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w900,
                letterSpacing: -.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF26D9C7).withValues(alpha: .16),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${sorted.length}',
                style: const TextStyle(
                  color: Color(0xFF26D9C7),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: sorted.isEmpty
              ? const _NoPostForDay()
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _CalendarPostCard(log: sorted[index]),
                ),
        ),
      ],
    );
  }
}

class _NoPostForDay extends StatelessWidget {
  const _NoPostForDay();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isWhite
            ? Colors.white
            : const Color(0xFF122233).withValues(alpha: .78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFDCE4EC)
              : Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Text(
        '飲みログがない',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isWhite
              ? const Color(0xFF7A8490)
              : Colors.white.withValues(alpha: .54),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CalendarPostCard extends StatelessWidget {
  const _CalendarPostCard({required this.log});

  final DrinkLog log;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subColor = isWhite
        ? const Color(0xFF7A8490)
        : Colors.white.withValues(alpha: .58);
    final body = _calendarPostBody(log);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWhite
            ? Colors.white
            : const Color(0xFF122233).withValues(alpha: .86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFDCE4EC)
              : Colors.white.withValues(alpha: .08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .05 : .18),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          _CalendarPostIcon(log: log),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    NomoGeneratedIcon(
                      CupertinoIcons.person_2_fill,
                      color: const Color(0xFF26D9C7),
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        log.friends.isEmpty ? 'ひとり飲み' : log.friendNames,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: subColor,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarPostIcon extends StatelessWidget {
  const _CalendarPostIcon({required this.log});

  final DrinkLog log;

  @override
  Widget build(BuildContext context) {
    final friend = log.friends.isNotEmpty ? log.friends.first : null;
    final avatar = friend?.avatar ?? NomoAvatar.defaultAvatar;
    final accent = friend?.accentColor ?? const Color(0xFF26D9C7);

    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: .20),
        border: Border.all(color: accent.withValues(alpha: .60), width: 2),
      ),
      child: ClipOval(child: NomoAvatarView(avatar: avatar, size: 48)),
    );
  }
}

String _calendarPostBody(DrinkLog _) {
  return '飲みログを追加しました。';
}

class _Marker {
  const _Marker(this.accent);

  final Color accent;
}
