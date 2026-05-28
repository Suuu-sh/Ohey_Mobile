part of 'profile_screen.dart';

class _ProfileStatusSheetContent extends StatefulWidget {
  const _ProfileStatusSheetContent({required this.selected, required this.ref});

  final TomoDailyStatus selected;
  final WidgetRef ref;

  @override
  State<_ProfileStatusSheetContent> createState() =>
      _ProfileStatusSheetContentState();
}

class _ProfileStatusSheetContentState
    extends State<_ProfileStatusSheetContent> {
  TomoDailyStatus? _savingStatus;

  Future<void> _selectStatus(TomoDailyStatus status) async {
    if (_savingStatus != null) return;
    final navigator = Navigator.of(context);
    setState(() => _savingStatus = status);
    try {
      await widget.ref
          .read(tomoUserProvider.notifier)
          .updateDailyStatus(status);
      if (navigator.mounted) navigator.pop();
      if (mounted) TomoToast.show(context, 'ステータスを「${status.label}」にしました。');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingStatus = null);
      TomoToast.show(context, '設定できなかったよ。あとでもう一度試してね');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final isUnset = widget.selected == TomoDailyStatus.unselected;
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
          TomoPopIcon(
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
                  isUnset ? '今の気分、選んでみよ。' : '今の気分だよ',
                  style: TextStyle(
                    color: isWhite ? const Color(0xFF17212B) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '今空いてるか、時間次第かを出しておくとフレンズと予定を合わせやすくなります。',
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

  final TomoDailyStatus status;
  final bool selected;
  final VoidCallback onTap;
  final bool saving;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final surface = selected
        ? color.withValues(alpha: isWhite ? .24 : .20)
        : (isWhite ? const Color(0xFFF6F8FA) : AppColors.darkBackground);
    final bottom = selected
        ? tomo3DShadowColorFor(color, lightnessScale: isWhite ? .72 : .60)
        : isWhite
        ? const Color(0xFFD8E1EA)
        : const Color(0xFF09131D);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: disabled && !saving ? .55 : 1,
      child: Tomo3DButtonSurface(
        onTap: disabled ? null : onTap,
        enabled: !disabled || saving,
        height: 82,
        radius: 22,
        color: surface,
        bottomColor: bottom,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        borderColor: selected
            ? color
            : (isWhite
                  ? const Color(0xFFDDE4EA)
                  : Colors.white.withValues(alpha: .12)),
        borderWidth: selected ? 1.6 : 1,
        outerShadows: [
          BoxShadow(
            color: color.withValues(alpha: isWhite ? .10 : .18),
            blurRadius: selected ? 22 : 16,
            offset: const Offset(0, 8),
          ),
        ],
        innerShadows: [
          BoxShadow(
            color: Colors.white.withValues(alpha: isWhite ? .42 : .08),
            blurRadius: 10,
            offset: const Offset(-2, -2),
          ),
        ],
        child: Row(
          children: [
            TomoPopIcon(icon: _statusIcon(status), color: color, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
              TomoGeneratedIcon(
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
