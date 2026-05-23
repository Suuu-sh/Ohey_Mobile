import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_scene_header_backdrop.dart';
import '../../logs/application/drink_log_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  double _monthDragOffset = 0;

  void _moveMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
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
    final userLogs = logs.where((log) => !log.isOfficial);
    final monthlyLogs = userLogs.where((log) => log.isInMonth(_month)).toList();
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
    final headerBackgroundHeight = NomoPageHeader.sceneBackdropHeight(context);

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
                        padding: const EdgeInsets.fromLTRB(
                          NomoPageHeader.horizontalPadding,
                          14,
                          NomoPageHeader.horizontalPadding,
                          148,
                        ),
                        child: Column(
                          children: [
                            _PlayfulMonthGrid(month: _month, logs: monthlyLogs),
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

class _PlayfulMonthGrid extends StatelessWidget {
  const _PlayfulMonthGrid({required this.month, required this.logs});

  final DateTime month;
  final List<DrinkLog> logs;

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
                  return _DayTile(
                    day: displayDay,
                    inMonth: inMonth,
                    marker: marker,
                    isToday: isToday,
                    column: index % 7,
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
    required this.column,
  });

  final int day;
  final bool inMonth;
  final _Marker? marker;
  final bool isToday;
  final int column;

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: isWhite
            ? Colors.white
            : const Color(0xFF122233).withValues(alpha: .82),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFDCE4EC)
              : Colors.white.withValues(alpha: .06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .05 : .20),
            blurRadius: 12,
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
    );
  }
}

class _Marker {
  const _Marker(this.accent);

  final Color accent;
}
