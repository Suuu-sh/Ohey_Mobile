part of 'profile_screen.dart';

class _ProfileStatusSheetContent extends StatefulWidget {
  const _ProfileStatusSheetContent({required this.selected, required this.ref});

  final OheyDailyStatus selected;
  final WidgetRef ref;

  @override
  State<_ProfileStatusSheetContent> createState() =>
      _ProfileStatusSheetContentState();
}

class _ProfileStatusSheetContentState
    extends State<_ProfileStatusSheetContent> {
  OheyDailyStatus? _savingStatus;

  Future<void> _selectStatus(OheyDailyStatus status) async {
    if (_savingStatus != null) return;
    final navigator = Navigator.of(context);
    setState(() => _savingStatus = status);
    try {
      await widget.ref
          .read(oheyUserProvider.notifier)
          .updateDailyStatus(status);
      if (navigator.mounted) navigator.pop();
      if (mounted) OheyToast.show(context, 'ステータスを「${status.label}」にしました。');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingStatus = null);
      OheyToast.show(context, '設定できなかったよ。あとでもう一度試してね');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite ? AppColors.cFF657282 : AppColors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${DateTime.now().month}/${DateTime.now().day} の予定決めに使えるよ。',
          style: TextStyle(color: sub, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        for (final status in OheyDailyStatus.selectable) ...[
          OheyDailyStatus3DOption(
            status: status,
            title: status.label,
            subtitle: status.description,
            selected: status == widget.selected,
            enabled: _savingStatus == null || _savingStatus == status,
            isLoading: _savingStatus == status,
            onTap: () => _selectStatus(status),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
