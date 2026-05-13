import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_character.dart';
import '../../logs/application/drink_log_controller.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(drinkLogControllerProvider);
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 112),
            sliver: SliverList.list(
              children: [
                Text(
                  'カレンダー',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 22),
                logsAsync.when(
                  loading: () =>
                      const Center(child: CupertinoActivityIndicator()),
                  error: (error, stackTrace) =>
                      Text('カレンダーを読み込めませんでした: $error'),
                  data: (logs) => _CalendarBody(month: month, logs: logs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarBody extends StatefulWidget {
  const _CalendarBody({required this.month, required this.logs});

  final DateTime month;
  final List<DrinkLog> logs;

  @override
  State<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<_CalendarBody> {
  late DateTime _month = widget.month;

  void _moveMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final month = _month;
    final monthlyLogs = widget.logs
        .where((log) => log.isInMonth(month))
        .toList();
    final markedDays = <int, int>{};
    for (final log in monthlyLogs) {
      markedDays.update(log.date.day, (value) => value + 1, ifAbsent: () => 1);
    }
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _moveMonth(-1),
              icon: const Icon(
                CupertinoIcons.chevron_left,
                color: AppColors.navy,
              ),
            ),
            Expanded(
              child: Text(
                '${month.year}年${month.month}月',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _moveMonth(1),
              icon: const Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MonthGrid(month: month, markedDays: markedDays),
        const SizedBox(height: 24),
        Container(
          height: 132,
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.softBlue,
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: .04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 6,
                bottom: -18,
                child: NomoCharacter(
                  pose: nomoPoseForDrinkCount(monthlyLogs.length),
                  width: 138,
                  height: 138,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今月の飲み回数',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${monthlyLogs.length}',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w900,
                              height: .9,
                            ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '回',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Positioned(
                right: 118,
                top: 20,
                child: Icon(
                  CupertinoIcons.sparkles,
                  color: AppColors.sky,
                  size: 16,
                ),
              ),
              const Positioned(
                right: 88,
                top: 6,
                child: Icon(
                  CupertinoIcons.sparkles,
                  color: AppColors.beer,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (monthlyLogs.isNotEmpty)
          ...monthlyLogs.take(4).map((log) => _LogMiniRow(log: log)),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.markedDays});
  final DateTime month;
  final Map<int, int> markedDays;

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
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: AppColors.mutedInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: rows * 7,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 14,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingEmptyCells + 1;
            final inMonth = dayNumber >= 1 && dayNumber <= daysInMonth;
            final displayDay = inMonth
                ? dayNumber
                : (dayNumber < 1
                      ? previousMonthDays + dayNumber
                      : dayNumber - daysInMonth);
            final count = inMonth ? (markedDays[dayNumber] ?? 0) : 0;
            return _DayCell(day: displayDay, count: count, inMonth: inMonth);
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.inMonth,
  });
  final int day;
  final int count;
  final bool inMonth;
  @override
  Widget build(BuildContext context) {
    final hasLog = count > 0;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasLog ? AppColors.navy : Colors.transparent,
      ),
      child: Text(
        '$day',
        style: TextStyle(
          color: hasLog
              ? Colors.white
              : (inMonth ? AppColors.navy : const Color(0xFFC2C6D5)),
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _LogMiniRow extends StatelessWidget {
  const _LogMiniRow({required this.log});
  final DrinkLog log;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.softBlue,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${log.date.day}',
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.place,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                log.friendNames,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
