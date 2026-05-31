part of 'add_memory_screen.dart';

String _addMemoryDateTimeLabel(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$year/$month/$day $hour:$minute';
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final titleColor = _AddMemoryColors.primaryTextFor(context);
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _AddMemoryColors.surfaceFor(context),
              shape: BoxShape.circle,
              border: Border.all(color: _AddMemoryColors.lineFor(context)),
            ),
            child: Center(
              child: OheyGeneratedIcon(
                CupertinoIcons.chevron_left,
                color: titleColor,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '思い出作成',
          style: TextStyle(
            color: titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _PlaceSearchButton extends StatelessWidget {
  const _PlaceSearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _AddMemoryColors.placeIcon.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _AddMemoryColors.placeIcon.withValues(alpha: .30),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OheyGeneratedIcon(
            CupertinoIcons.location_fill,
            color: _AddMemoryColors.placeIcon,
            size: 14,
          ),
          SizedBox(width: 5),
          Text(
            '探す',
            style: TextStyle(
              color: _AddMemoryColors.placeIcon,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MemorySuccessSheet extends StatefulWidget {
  const _MemorySuccessSheet({
    required this.friends,
    required this.monthlyCount,
  });

  final List<OheyFriend> friends;
  final int monthlyCount;

  @override
  State<_MemorySuccessSheet> createState() => _MemorySuccessSheetState();
}

class _MemorySuccessSheetState extends State<_MemorySuccessSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _friendSummary {
    if (widget.friends.isEmpty) return '自分だけの記録にしたよ。';
    final first = widget.friends.first.name;
    final others = widget.friends.length - 1;
    if (others <= 0) return '$firstとの記録を残したよ。';
    return '$firstほか$others人との記録を残したよ。';
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final background = isWhite ? AppColors.white : AppColors.cFF071320;
    final ink = isWhite ? AppColors.cFF17212B : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .64);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: isWhite
                ? AppColors.cFFDCE4EC
                : AppColors.white.withValues(alpha: .12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: .20),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale =
                    .78 + Curves.elasticOut.transform(_controller.value) * .22;
                return Transform.scale(scale: scale, child: child);
              },
              child: const OheyPopIcon(
                icon: CupertinoIcons.checkmark_alt,
                color: AppColors.success,
                size: 70,
                iconSize: 38,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '記録しました！',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '今月${widget.monthlyCount}個目の思い出が増えました',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _friendSummary,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: sub,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Ohey3DButton.secondary(
                    label: '閉じる',
                    onTap: () => Navigator.of(context).pop(false),
                    height: 48,
                    radius: 22,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Ohey3DButton(
                    label: 'カレンダーへ',
                    icon: CupertinoIcons.calendar_today,
                    onTap: () => Navigator.of(context).pop(true),
                    height: 48,
                    radius: 22,
                    color: AppColors.success,
                    shadowColor: AppColors.successShadow,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
