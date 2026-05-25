import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_drink_invite.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_bottom_sheet.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_scene_header_backdrop.dart';
import '../../../core/widgets/nomo_themed_panel.dart';
import '../../friends/application/drink_invite_controller.dart';
import '../../logs/application/drink_log_controller.dart';

const _calendarPrimaryActionColor = Color(0xFF20B9FF);
const _calendarPrimaryActionShadowColor = Color(0xFF0B78B7);
const _calendarPrimaryActionForegroundColor = Color(0xFF06111D);

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.onCreatePlan});

  final VoidCallback? onCreatePlan;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const _calendarIntroSeenKey = 'nomo_calendar_intro_seen';

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selectedDay = _dateOnly(DateTime.now());
  double _monthDragOffset = 0;
  bool _isIntroSeen = true;

  @override
  void initState() {
    super.initState();
    _loadIntroSeen();
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
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          NomoPageHeader.horizontalPadding,
                          8,
                          NomoPageHeader.horizontalPadding,
                          116,
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
                          if (!_isIntroSeen) ...[
                            const SizedBox(height: 14),
                            _CalendarIntroCard(
                              isWhite: isWhite,
                              onDismiss: _dismissIntro,
                            ),
                          ],
                          const SizedBox(height: 16),
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
    return NomoThemedPanel(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      accentColor: _calendarPrimaryActionColor,
      backgroundColor: NomoThemedPanel.surfaceColor(isWhite: isWhite),
      borderRadius: 24,
      borderAlpha: isWhite ? .46 : .52,
      glowAlpha: isWhite ? .12 : .20,
      glowBlur: 28,
      glowOffset: const Offset(0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.month}/${day.day} の予定と思い出',
            style: TextStyle(
              color: isWhite ? const Color(0xFF101820) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          _CalendarSectionLabel(
            label: '予定',
            accent: _calendarPrimaryActionColor,
          ),
          const SizedBox(height: 5),
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
          const SizedBox(height: 8),
          _CalendarSectionLabel(label: '思い出', accent: const Color(0xFF54D7FF)),
          const SizedBox(height: 5),
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
                    ? (isPrivateRecord ? '記録だけ保存しました' : '思い出を残しました')
                    : log.memo.trim(),
                isWhite: isWhite,
                badgeLabel: isPrivateRecord ? '記録のみ' : null,
                badgeColor: AppColors.success,
                actionLabel: isPrivateRecord ? null : '写真を見る',
                onActionTap: isPrivateRecord
                    ? null
                    : () => _showCalendarLogPhoto(context, log),
              );
            })
          else
            _CalendarEmptyRow(
              text: 'この日の思い出はまだありません',
              buttonLabel: '思い出を残す',
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
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          height: 1,
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
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final Color accent;
  final String text;
  final bool isWhite;
  final String? badgeLabel;
  final Color? badgeColor;
  final String? actionLabel;
  final VoidCallback? onActionTap;

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
        if (actionLabel != null && onActionTap != null) ...[
          const SizedBox(width: 8),
          _CalendarInlineButton(
            label: actionLabel!,
            color: accent,
            isWhite: isWhite,
            onTap: onActionTap!,
          ),
        ],
      ],
    ),
  );
}

class _CalendarInlineButton extends StatelessWidget {
  const _CalendarInlineButton({
    required this.label,
    required this.color,
    required this.isWhite,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isWhite ? .16 : .24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: isWhite ? .32 : .42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isWhite ? Color.lerp(color, Colors.black, .18)! : Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    ),
  );
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
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWhite
                  ? const Color(0xFF657282)
                  : Colors.white.withValues(alpha: .62),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _MiniCalendarCta(label: buttonLabel, onTap: onTap),
      ],
    ),
  );
}

class _MiniCalendarCta extends StatelessWidget {
  const _MiniCalendarCta({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = label.length >= 7 ? 116.0 : 104.0;
    return SizedBox(
      width: width,
      child: Nomo3DButton(
        label: label,
        onTap: onTap,
        height: 27,
        radius: 14,
        color: _calendarPrimaryActionColor,
        foregroundColor: _calendarPrimaryActionForegroundColor,
        shadowColor: _calendarPrimaryActionShadowColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        fontSize: 11,
      ),
    );
  }
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
          color: isWhite
              ? (isSelected ? const Color(0xFFEAF8FF) : Colors.white)
              : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: hasPlan
                ? _calendarPrimaryActionColor
                : isSelected
                ? const Color(0xFF54D7FF)
                : _calendarPrimaryActionColor.withValues(
                    alpha: isWhite ? .34 : .24,
                  ),
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
