part of 'profile_screen.dart';

class _ProfileStatusSheetContent extends StatefulWidget {
  const _ProfileStatusSheetContent({required this.selected, required this.ref});

  final NomoDailyStatus selected;
  final WidgetRef ref;

  @override
  State<_ProfileStatusSheetContent> createState() =>
      _ProfileStatusSheetContentState();
}

class _ProfileStatusSheetContentState
    extends State<_ProfileStatusSheetContent> {
  NomoDailyStatus? _savingStatus;

  Future<void> _selectStatus(NomoDailyStatus status) async {
    if (_savingStatus != null) return;
    final navigator = Navigator.of(context);
    setState(() => _savingStatus = status);
    try {
      await widget.ref
          .read(nomoUserProvider.notifier)
          .updateDailyStatus(status);
      if (navigator.mounted) navigator.pop();
      if (mounted) NomoToast.show(context, 'ステータスを「${status.label}」にしました。');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingStatus = null);
      NomoToast.show(context, '設定できなかったよ。あとでもう一度試してね');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final isUnset = widget.selected == NomoDailyStatus.unselected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProfileStatusHelpCard(isWhite: isWhite, isUnset: isUnset),
        const SizedBox(height: 14),
        for (final status in _selectableDailyStatuses) ...[
          _ProfileStatusOption(
            status: status,
            selected: status == widget.selected,
            saving: _savingStatus == status,
            disabled: _savingStatus != null,
            onTap: () => _selectStatus(status),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ProfileStatusHelpCard extends StatelessWidget {
  const _ProfileStatusHelpCard({required this.isWhite, required this.isUnset});

  final bool isWhite;
  final bool isUnset;

  @override
  Widget build(BuildContext context) {
    final accent = isUnset ? AppColors.primaryAction : AppColors.invite;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isWhite ? .12 : .16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: .34)),
      ),
      child: Row(
        children: [
          NomoPopIcon(
            icon: isUnset
                ? CupertinoIcons.exclamationmark_bubble_fill
                : CupertinoIcons.checkmark_circle_fill,
            color: accent,
            size: 42,
            iconSize: 23,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUnset ? '未設定だと誘われにくいかも' : 'ステータス設定中',
                  style: TextStyle(
                    color: isWhite ? const Color(0xFF17212B) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '今日遊べるか、休みたいかを出しておくとフレンズが誘いやすくなります。',
                  style: TextStyle(
                    color: isWhite
                        ? const Color(0xFF667381)
                        : Colors.white.withValues(alpha: .64),
                    fontSize: 12,
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

class _ProfileStatusOption extends StatelessWidget {
  const _ProfileStatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
    this.saving = false,
    this.disabled = false,
  });

  final NomoDailyStatus status;
  final bool selected;
  final VoidCallback onTap;
  final bool saving;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: .16)
              : (isWhite ? const Color(0xFFF6F8FA) : AppColors.darkBackground),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? color
                : (isWhite
                      ? const Color(0xFFDDE4EA)
                      : Colors.white.withValues(alpha: .10)),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            NomoPopIcon(icon: _statusIcon(status), color: color, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isWhite
                          ? const Color(0xFF687481)
                          : _ProfileColors.sub,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (saving)
              CupertinoActivityIndicator(color: color)
            else
              NomoGeneratedIcon(
                selected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                color: selected ? color : ink.withValues(alpha: .22),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
