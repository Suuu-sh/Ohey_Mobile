import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/ohey_user.dart';
import '../theme/app_colors.dart';
import 'ohey_3d_button.dart';
import 'ohey_bottom_sheet.dart';
import 'ohey_daily_status_3d_option.dart';

class OheyCalendarStatusPickerResult {
  const OheyCalendarStatusPickerResult.status(this.status)
    : openMethods = false;
  const OheyCalendarStatusPickerResult.methods()
    : status = null,
      openMethods = true;

  final OheyDailyStatus? status;
  final bool openMethods;
}

class OheyCalendarStatusUpdateRequest {
  const OheyCalendarStatusUpdateRequest({
    required this.status,
    required this.days,
  });

  final OheyDailyStatus status;
  final List<DateTime> days;
}

String oheyFormatCalendarDay(DateTime day) => '${day.month}/${day.day}';

DateTime _oheyCalendarFirstWeekdayOnOrAfter(DateTime day, int weekday) {
  final start = _oheyDateOnly(day);
  final offset = (weekday - start.weekday + 7) % 7;
  return start.add(Duration(days: offset));
}

String _oheyCalendarWeekdayLabelByIndex(int weekday) =>
    const ['月', '火', '水', '木', '金', '土', '日'][weekday - 1];

List<DateTime> _oheyCalendarNextDays(DateTime day, int count) {
  final start = _oheyDateOnly(day);
  return [for (var i = 0; i < count; i++) start.add(Duration(days: i))];
}

List<DateTime> _oheyCalendarWeeklyRepeatDays(
  DateTime day,
  int count, {
  int? weekday,
}) {
  final start = weekday == null
      ? _oheyDateOnly(day)
      : _oheyCalendarFirstWeekdayOnOrAfter(day, weekday);
  return [for (var i = 0; i < count; i++) start.add(Duration(days: i * 7))];
}

class OheyCalendarStatusSheet extends StatelessWidget {
  const OheyCalendarStatusSheet({
    super.key,
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
    final titleColor = isWhite ? AppColors.cFF101820 : AppColors.white;
    final isToday = _oheyIsSameDate(day, DateTime.now());
    final title = isToday ? '今日の予定' : '${day.month}/${day.day}の予定';
    return OheyBottomSheetShell(
      showHandle: true,
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _OheyCalendarStatusHeaderActionButton(
                onTap: () => Navigator.of(
                  context,
                ).pop(const OheyCalendarStatusPickerResult.methods()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            showLockedExplanation
                ? '先に自分の予定を設定すると見られるよ。'
                : '${day.month}/${day.day} の予定決めに使えるよ。',
            style: TextStyle(color: sub, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          for (final status in OheyDailyStatus.selectable) ...[
            OheyDailyStatus3DOption(
              status: status,
              title: status.label,
              selected: status == selected,
              onTap: () => Navigator.of(
                context,
              ).pop(OheyCalendarStatusPickerResult.status(status)),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class OheyCalendarStatusMethodSheet extends StatefulWidget {
  const OheyCalendarStatusMethodSheet({
    super.key,
    required this.day,
    required this.selected,
  });

  final DateTime day;
  final OheyDailyStatus selected;

  @override
  State<OheyCalendarStatusMethodSheet> createState() =>
      OheyCalendarStatusMethodSheetState();
}

class OheyCalendarStatusMethodSheetState
    extends State<OheyCalendarStatusMethodSheet> {
  late OheyDailyStatus _selected = widget.selected == OheyDailyStatus.unselected
      ? OheyDailyStatus.selectable.first
      : widget.selected;
  bool _weeklyRepeat = false;
  int _dayCount = 7;
  int _repeatCount = 4;
  late int _weekday = widget.day.weekday;

  List<DateTime> get _targetDays => _weeklyRepeat
      ? _oheyCalendarWeeklyRepeatDays(
          widget.day,
          _repeatCount,
          weekday: _weekday,
        )
      : _oheyCalendarNextDays(widget.day, _dayCount);

  String get _summaryText {
    final days = _targetDays;
    if (days.isEmpty) return '';
    if (_weeklyRepeat) {
      return '${_oheyCalendarWeekdayLabelByIndex(_weekday)}曜に$_repeatCount回（${oheyFormatCalendarDay(days.first)}〜${oheyFormatCalendarDay(days.last)}）';
    }
    return '${oheyFormatCalendarDay(days.first)}〜${oheyFormatCalendarDay(days.last)} の$_dayCount日分';
  }

  void _submit() {
    Navigator.of(context).pop(
      OheyCalendarStatusUpdateRequest(status: _selected, days: _targetDays),
    );
  }

  void _setDayCount(int value) {
    setState(() => _dayCount = value.clamp(1, 31));
  }

  void _setRepeatCount(int value) {
    setState(() => _repeatCount = value.clamp(1, 12));
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite ? AppColors.cFF657282 : AppColors.white70;
    final accent = oheyDailyStatusColor(_selected);
    return OheyBottomSheetShell(
      title: '設定方法',
      showHandle: true,
      radius: 32,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'まとめて設定する予定・範囲・繰り返しをカスタムできます。',
              style: TextStyle(color: sub, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Text(
              '予定',
              style: TextStyle(color: sub, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final entry in OheyDailyStatus.selectable.indexed) ...[
                  if (entry.$1 > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _OheyCalendarStatusCompactChoice(
                      status: entry.$2,
                      selected: entry.$2 == _selected,
                      onTap: () => setState(() => _selected = entry.$2),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '設定タイプ',
              style: TextStyle(color: sub, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _OheyCalendarStatusModeButton(
                    title: '連続',
                    subtitle: '何日分かまとめる',
                    selected: !_weeklyRepeat,
                    accent: accent,
                    onTap: () => setState(() => _weeklyRepeat = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OheyCalendarStatusModeButton(
                    title: '毎週',
                    subtitle: '同じ曜日で繰り返す',
                    selected: _weeklyRepeat,
                    accent: accent,
                    onTap: () => setState(() => _weeklyRepeat = true),
                  ),
                ),
              ],
            ),
            if (_weeklyRepeat) ...[
              const SizedBox(height: 12),
              _OheyCalendarWeekdaySelector(
                selectedWeekday: _weekday,
                accent: accent,
                onChanged: (weekday) => setState(() => _weekday = weekday),
              ),
            ],
            const SizedBox(height: 12),
            _OheyCalendarStatusStepper(
              title: _weeklyRepeat ? '繰り返し回数' : 'まとめる日数',
              value: _weeklyRepeat ? _repeatCount : _dayCount,
              unit: _weeklyRepeat ? '回' : '日',
              min: 1,
              max: _weeklyRepeat ? 12 : 31,
              accent: accent,
              onChanged: _weeklyRepeat ? _setRepeatCount : _setDayCount,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: .28)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.calendar, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _summaryText,
                      style: TextStyle(
                        color: isWhite ? AppColors.cFF101820 : AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _OheyCalendarStatusSubmit3DButton(
              title: 'この内容で設定する',
              subtitle: '$_summaryText を${_selected.label}にします',
              accent: accent,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _OheyCalendarStatusCompactChoice extends StatelessWidget {
  const _OheyCalendarStatusCompactChoice({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final OheyDailyStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final foreground = selected
        ? AppColors.cFF06111D
        : isWhite
        ? AppColors.cFF101820
        : AppColors.white.withValues(alpha: .82);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: selected
              ? oheyDailyStatusColor(status)
              : isWhite
              ? AppColors.white.withValues(alpha: .88)
              : AppColors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.transparent
                : AppColors.white.withValues(alpha: .14),
          ),
        ),
        child: Text(
          status.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: status == OheyDailyStatus.maybeAvailable ? 11 : 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _OheyCalendarWeekdaySelector extends StatelessWidget {
  const _OheyCalendarWeekdaySelector({
    required this.selectedWeekday,
    required this.accent,
    required this.onChanged,
  });

  final int selectedWeekday;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite ? AppColors.cFF657282 : AppColors.white70;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWhite
            ? AppColors.white.withValues(alpha: .88)
            : AppColors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '曜日',
            style: TextStyle(color: sub, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var weekday = 1; weekday <= 7; weekday++) ...[
                if (weekday > 1) const SizedBox(width: 5),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onChanged(weekday),
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: weekday == selectedWeekday
                            ? accent
                            : AppColors.white.withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: weekday == selectedWeekday
                              ? AppColors.transparent
                              : AppColors.white.withValues(alpha: .10),
                        ),
                      ),
                      child: Text(
                        _oheyCalendarWeekdayLabelByIndex(weekday),
                        style: TextStyle(
                          color: weekday == selectedWeekday
                              ? AppColors.cFF06111D
                              : isWhite
                              ? AppColors.cFF101820
                              : AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OheyCalendarStatusSubmit3DButton extends StatelessWidget {
  const _OheyCalendarStatusSubmit3DButton({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Ohey3DButtonSurface(
      onTap: onTap,
      height: 76,
      radius: 20,
      color: accent,
      bottomColor: Color.lerp(accent, AppColors.black, .28)!,
      useGradient: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderColor: AppColors.white.withValues(alpha: .20),
      outerShadows: [
        BoxShadow(
          color: accent.withValues(alpha: .32),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      innerShadows: [
        BoxShadow(
          color: AppColors.white.withValues(alpha: .14),
          blurRadius: 10,
          offset: const Offset(-2, -2),
        ),
      ],
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: AppColors.cFF06111D,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.cFF06111D,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.cFF06111D.withValues(alpha: .68),
                    fontSize: 12,
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

class _OheyCalendarStatusModeButton extends StatelessWidget {
  const _OheyCalendarStatusModeButton({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final foreground = selected
        ? AppColors.cFF06111D
        : isWhite
        ? AppColors.cFF101820
        : AppColors.white;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : isWhite
              ? AppColors.white.withValues(alpha: .88)
              : AppColors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.transparent
                : AppColors.white.withValues(alpha: .12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: foreground.withValues(alpha: .72),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OheyCalendarStatusStepper extends StatelessWidget {
  const _OheyCalendarStatusStepper({
    required this.title,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  final String title;
  final int value;
  final String unit;
  final int min;
  final int max;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite ? AppColors.cFF657282 : AppColors.white70;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWhite
            ? AppColors.white.withValues(alpha: .88)
            : AppColors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: sub, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value$unit',
                  style: TextStyle(
                    color: isWhite ? AppColors.cFF101820 : AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _OheyCalendarStatusRoundButton(
            icon: CupertinoIcons.minus,
            enabled: value > min,
            accent: accent,
            onTap: () => onChanged(value - 1),
          ),
          const SizedBox(width: 8),
          _OheyCalendarStatusRoundButton(
            icon: CupertinoIcons.plus,
            enabled: value < max,
            accent: accent,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _OheyCalendarStatusRoundButton extends StatelessWidget {
  const _OheyCalendarStatusRoundButton({
    required this.icon,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: enabled ? .95 : .22),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.cFF06111D, size: 18),
      ),
    );
  }
}

class _OheyCalendarStatusHeaderActionButton extends StatelessWidget {
  const _OheyCalendarStatusHeaderActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(999),
      onPressed: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cFF54D7FF.withValues(alpha: isWhite ? .14 : .18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.cFF54D7FF.withValues(alpha: isWhite ? .34 : .42),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.rectangle_stack_badge_plus,
              color: AppColors.cFF54D7FF,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              '一括',
              style: TextStyle(
                color: AppColors.cFF54D7FF,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _oheyIsSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _oheyDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
