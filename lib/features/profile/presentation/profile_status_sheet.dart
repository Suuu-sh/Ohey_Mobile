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
      NomoToast.show(context, '設定できませんでした: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
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
              : (isWhite
                    ? const Color(0xFFF6F8FA)
                    : Colors.white.withValues(alpha: .055)),
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
