import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_drink_invite.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_scene_header_backdrop.dart';
import '../../friends/application/drink_invite_controller.dart';
import '../../logs/application/drink_log_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.onCreatePlan});

  final VoidCallback? onCreatePlan;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selectedDay = _dateOnly(DateTime.now());
  double _monthDragOffset = 0;

  void _moveMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _selectedDay = DateTime(_month.year, _month.month, 1);
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
    final todayReservations =
        ref.watch(todayReservationsProvider).asData?.value ??
        const <NomoDrinkInvite>[];
    final selectedLogs = userLogs
        .where((log) => _isSameDate(log.date, _selectedDay))
        .toList(growable: false);
    final selectedPlans = _isSameDate(_selectedDay, DateTime.now())
        ? todayReservations
        : const <NomoDrinkInvite>[];
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
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
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          NomoPageHeader.horizontalPadding,
                          14,
                          NomoPageHeader.horizontalPadding,
                          164,
                        ),
                        children: [
                          _PlayfulMonthGrid(
                            month: _month,
                            selectedDay: _selectedDay,
                            logs: monthlyLogs,
                            todayReservations: todayReservations,
                            onSelectDay: (day) =>
                                setState(() => _selectedDay = day),
                          ),
                          const SizedBox(height: 14),
                          _SelectedDayPanel(
                            day: _selectedDay,
                            logs: selectedLogs,
                            plans: selectedPlans,
                            isWhite: isWhite,
                            onCreatePlan: widget.onCreatePlan,
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
    required this.plans,
    required this.isWhite,
    required this.onCreatePlan,
  });

  final DateTime day;
  final List<DrinkLog> logs;
  final List<NomoDrinkInvite> plans;
  final bool isWhite;
  final VoidCallback? onCreatePlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isWhite
            ? Colors.white
            : const Color(0xFF122233).withValues(alpha: .82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFDCE4EC)
              : Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.month}/${day.day} の予定と飲みログ',
            style: TextStyle(
              color: isWhite ? const Color(0xFF101820) : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _CalendarSectionLabel(label: '予定', accent: AppColors.primaryAction),
          const SizedBox(height: 7),
          if (plans.isNotEmpty)
            _CalendarInfoRow(
              icon: CupertinoIcons.calendar_today,
              accent: AppColors.success,
              text: '${_reservationFriendLabel(plans)}との飲み予定',
              isWhite: isWhite,
            )
          else
            _CalendarEmptyRow(
              text: 'この日の飲み予定はまだありません',
              buttonLabel: 'この日に作る',
              isWhite: isWhite,
              onTap: onCreatePlan,
            ),
          const SizedBox(height: 12),
          _CalendarSectionLabel(label: '飲みログ', accent: const Color(0xFF54D7FF)),
          const SizedBox(height: 7),
          if (logs.isNotEmpty)
            ...logs.take(3).map((log) {
              final isPrivateRecord =
                  log.photoAssetPath == null ||
                  log.photoAssetPath!.trim().isEmpty;
              return _CalendarInfoRow(
                icon: isPrivateRecord
                    ? CupertinoIcons.lock_fill
                    : CupertinoIcons.photo_fill_on_rectangle_fill,
                accent: isPrivateRecord
                    ? AppColors.success
                    : const Color(0xFF54D7FF),
                text: log.memo.trim().isEmpty
                    ? (isPrivateRecord ? '記録だけ保存しました' : '飲みログを残しました')
                    : log.memo.trim(),
                isWhite: isWhite,
                badgeLabel: isPrivateRecord ? '記録のみ' : null,
                badgeColor: AppColors.success,
              );
            })
          else
            _CalendarEmptyRow(
              text: 'この日の飲みログはまだありません',
              buttonLabel: '飲みログを残す',
              isWhite: isWhite,
              onTap: onCreatePlan,
            ),
        ],
      ),
    );
  }
}

class _CalendarSectionLabel extends StatelessWidget {
  const _CalendarSectionLabel({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _CalendarInfoRow extends StatelessWidget {
  const _CalendarInfoRow({
    required this.icon,
    required this.accent,
    required this.text,
    required this.isWhite,
    this.badgeLabel,
    this.badgeColor,
  });

  final IconData icon;
  final Color accent;
  final String text;
  final bool isWhite;
  final String? badgeLabel;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        NomoGeneratedIcon(icon, color: accent, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWhite ? const Color(0xFF344152) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (badgeLabel != null) ...[
          const SizedBox(width: 8),
          _CalendarLogBadge(
            label: badgeLabel!,
            color: badgeColor ?? accent,
            isWhite: isWhite,
          ),
        ],
      ],
    ),
  );
}

class _CalendarLogBadge extends StatelessWidget {
  const _CalendarLogBadge({
    required this.label,
    required this.color,
    required this.isWhite,
  });

  final String label;
  final Color color;
  final bool isWhite;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: isWhite ? .13 : .20),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: isWhite ? .26 : .34)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: isWhite ? Color.lerp(color, Colors.black, .22)! : Colors.white,
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    ),
  );
}

class _CalendarEmptyRow extends StatelessWidget {
  const _CalendarEmptyRow({
    required this.text,
    required this.buttonLabel,
    required this.isWhite,
    required this.onTap,
  });

  final String text;
  final String buttonLabel;
  final bool isWhite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: isWhite
                ? const Color(0xFF657282)
                : Colors.white.withValues(alpha: .62),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 10),
      _MiniCalendarCta(
        label: buttonLabel,
        accent: AppColors.primaryAction,
        onTap: onTap,
      ),
    ],
  );
}

class _MiniCalendarCta extends StatelessWidget {
  const _MiniCalendarCta({
    required this.label,
    required this.accent,
    this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF06111D),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

String _reservationFriendLabel(List<NomoDrinkInvite> reservations) {
  if (reservations.isEmpty) return 'フレンズ';
  final first = reservations.first.fromUser.name;
  if (reservations.length == 1) return first;
  return '$firstほか${reservations.length - 1}人';
}

class _PlayfulMonthGrid extends StatelessWidget {
  const _PlayfulMonthGrid({
    required this.month,
    required this.selectedDay,
    required this.logs,
    required this.todayReservations,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime selectedDay;
  final List<DrinkLog> logs;
  final List<NomoDrinkInvite> todayReservations;
  final ValueChanged<DateTime> onSelectDay;

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
                  final isToday = inMonth && _isSameDate(DateTime.now(), day);
                  final hasPlan = isToday && todayReservations.isNotEmpty;
                  return _DayTile(
                    day: displayDay,
                    date: day,
                    inMonth: inMonth,
                    marker: marker,
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
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.date,
    required this.inMonth,
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
  final _Marker? marker;
  final bool isToday;
  final bool isSelected;
  final bool hasPlan;
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
              ? (isWhite ? const Color(0xFFEAF8FF) : const Color(0xFF123047))
              : isWhite
              ? Colors.white
              : const Color(0xFF122233).withValues(alpha: .82),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: hasPlan
                ? AppColors.primaryAction
                : isSelected
                ? const Color(0xFF54D7FF)
                : isWhite
                ? const Color(0xFFDCE4EC)
                : Colors.white.withValues(alpha: .06),
            width: isSelected || hasPlan ? 2 : 1,
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
            if (hasPlan)
              Positioned(
                left: 0,
                right: 0,
                bottom: marker == null ? 7 : 28,
                child: NomoGeneratedIcon(
                  CupertinoIcons.calendar_badge_plus,
                  color: AppColors.primaryAction,
                  size: 22,
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

class _Marker {
  const _Marker(this.accent);

  final Color accent;
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
