part of 'profile_screen.dart';

Future<void> _openProfileWishListScreen(BuildContext context) async {
  await showOheyBottomSheet<void>(
    context: context,
    builder: (_) => const _ProfileWishListSheet(),
  );
}

class _ProfileWishListSheet extends ConsumerWidget {
  const _ProfileWishListSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishItemsAsync = ref.watch(wishItemControllerProvider);
    final wishItems = wishItemsAsync.asData?.value ?? const <WishItem>[];
    final listMaxHeight = MediaQuery.sizeOf(context).height * .42;

    return OheyBottomSheetShell(
      title: 'やりたいこと',
      showHandle: true,
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileWishListAddButton(
            onCreate: () => _showProfileCreateWishItemSheet(context, ref),
          ),
          if (wishItemsAsync.isLoading && wishItems.isEmpty) ...[
            const SizedBox(height: 10),
            const SizedBox(
              height: 54,
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ] else if (wishItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: listMaxHeight > 360 ? 360 : listMaxHeight,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                itemCount: wishItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final wish = wishItems[index];
                  return _ProfileWishListCard(
                    wish: wish,
                    onYurubo: () =>
                        _showProfileCreateYuruboSheet(context, ref, wish: wish),
                    onEdit: () => _showProfileCreateWishItemSheet(
                      context,
                      ref,
                      wish: wish,
                    ),
                    onDelete: () => _deleteProfileWishItem(context, ref, wish),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _deleteProfileWishItem(
  BuildContext context,
  WidgetRef ref,
  WishItem wish,
) async {
  final confirmed = await _confirmDeleteWishItem(context, wish);
  if (confirmed != true) return;
  try {
    await ref.read(wishItemControllerProvider.notifier).deleteWishItem(wish.id);
    if (!context.mounted) return;
    OheyToast.show(context, 'やりたいことを削除しました', icon: CupertinoIcons.trash_fill);
  } catch (_) {
    if (context.mounted) {
      OheyToast.show(context, '削除できなかったよ。あとでもう一度試してね');
    }
  }
}

Future<bool?> _confirmDeleteWishItem(BuildContext context, WishItem wish) {
  return showOheyConfirmSheet(
    context,
    title: 'やりたいことを削除しますか？',
    message: '「${wish.title}」を削除します。この操作は元に戻せません。',
    confirmLabel: '削除する',
    destructive: true,
    icon: CupertinoIcons.trash_fill,
  );
}

class _ProfileWishListAddButton extends StatelessWidget {
  const _ProfileWishListAddButton({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.light
        ? AppColors.cFF101820
        : AppColors.white;
    return OheyManageAddTile(
      label: 'やりたいことを追加',
      accent: AppColors.cFF20B9FF,
      foregroundColor: ink,
      onTap: () {
        HapticFeedback.selectionClick();
        onCreate();
      },
    );
  }
}

class _ProfileWishListCard extends StatelessWidget {
  const _ProfileWishListCard({
    required this.wish,
    required this.onYurubo,
    required this.onEdit,
    required this.onDelete,
  });

  final WishItem wish;
  final VoidCallback onYurubo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final place = wish.placeText.trim();
    return OheyManageListRow(
      title: wish.title,
      subtitle: place.isEmpty ? null : place,
      titleColor: AppColors.white,
      subtitleColor: _ProfileColors.sub,
      onTap: onYurubo,
      semanticLabel: '${wish.title}からゆるぼを作る',
      leading: const OheyPopIcon(
        icon: CupertinoIcons.sparkles,
        color: AppColors.cFF20B9FF,
        size: 36,
        iconSize: 18,
      ),
      actions: [
        OheyManageListIconButton(
          icon: CupertinoIcons.pencil,
          color: AppColors.cFF20B9FF,
          semanticLabel: '${wish.title}を編集',
          onTap: onEdit,
        ),
        OheyManageListIconButton(
          icon: CupertinoIcons.trash_fill,
          color: AppColors.cFFFF6B9A,
          semanticLabel: '${wish.title}を削除',
          onTap: onDelete,
        ),
      ],
    );
  }
}

Future<void> _openProfileYuruboListScreen(
  BuildContext context,
  WidgetRef ref,
) async {
  await showOheyBottomSheet<void>(
    context: context,
    builder: (_) => _ProfileYuruboListSheet(parentRef: ref),
  );
}

class _ProfileYuruboListSheet extends ConsumerWidget {
  const _ProfileYuruboListSheet({required this.parentRef});

  final WidgetRef parentRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yurubosAsync = ref.watch(yuruboControllerProvider);
    final currentUserId = ref.watch(authIdentityProvider).currentUserId;
    final yurubos = (yurubosAsync.asData?.value ?? const <Yurubo>[])
        .where((item) => item.ownerUserId == currentUserId)
        .toList(growable: false);
    final listMaxHeight = MediaQuery.sizeOf(context).height * .42;

    return OheyBottomSheetShell(
      title: 'ゆるぼ',
      showHandle: true,
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileYuruboListAddButton(
            onCreate: () => _showProfileCreateYuruboSheet(context, parentRef),
          ),
          if (yurubosAsync.isLoading && yurubos.isEmpty) ...[
            const SizedBox(height: 10),
            const SizedBox(
              height: 54,
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ] else if (yurubos.isNotEmpty) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: listMaxHeight > 360 ? 360 : listMaxHeight,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                itemCount: yurubos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final yurubo = yurubos[index];
                  return _ProfileYuruboListCard(
                    yurubo: yurubo,
                    onEdit: () =>
                        _showProfileEditYuruboSheet(context, parentRef, yurubo),
                    onDelete: () =>
                        _deleteProfileYurubo(context, parentRef, yurubo),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileYuruboListAddButton extends StatelessWidget {
  const _ProfileYuruboListAddButton({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.light
        ? AppColors.cFF101820
        : AppColors.white;
    return OheyManageAddTile(
      label: 'ゆるぼする',
      accent: AppColors.cFFC08BFF,
      foregroundColor: ink,
      onTap: () {
        HapticFeedback.selectionClick();
        onCreate();
      },
    );
  }
}

class _ProfileYuruboListCard extends StatelessWidget {
  const _ProfileYuruboListCard({
    required this.yurubo,
    required this.onEdit,
    required this.onDelete,
  });

  final Yurubo yurubo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final place = yurubo.placeText.trim();
    final title = yurubo.title.trim().isEmpty ? 'ゆるぼ' : yurubo.title.trim();
    return OheyManageListRow(
      title: title,
      subtitle: place.isEmpty ? null : place,
      titleColor: AppColors.white,
      subtitleColor: _ProfileColors.sub,
      semanticLabel: '$titleを管理',
      leading: const OheyPopIcon(
        icon: CupertinoIcons.bubble_left_bubble_right_fill,
        color: AppColors.cFFC08BFF,
        size: 36,
        iconSize: 18,
      ),
      actions: [
        OheyManageListIconButton(
          icon: CupertinoIcons.pencil,
          color: AppColors.cFF20B9FF,
          semanticLabel: '$titleを編集',
          onTap: onEdit,
        ),
        OheyManageListIconButton(
          icon: CupertinoIcons.trash_fill,
          color: AppColors.cFFFF6B9A,
          semanticLabel: '$titleを削除',
          onTap: onDelete,
        ),
      ],
    );
  }
}

Future<void> _deleteProfileYurubo(
  BuildContext context,
  WidgetRef ref,
  Yurubo yurubo,
) async {
  final confirmed = await showOheyBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => const _ProfileYuruboDeleteConfirmSheet(),
  );
  if (confirmed != true) return;
  try {
    await ref.read(yuruboControllerProvider.notifier).deleteYurubo(yurubo.id);
    if (!context.mounted) return;
    OheyToast.show(context, 'ゆるぼを削除しました', icon: CupertinoIcons.trash_fill);
  } catch (_) {
    if (context.mounted) {
      OheyToast.show(context, '削除できなかったよ。あとでもう一度試してね');
    }
  }
}

class _ProfileYuruboDeleteConfirmSheet extends StatelessWidget {
  const _ProfileYuruboDeleteConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? AppColors.cFF101820 : AppColors.white;
    final subtitleColor = isWhite
        ? AppColors.cFF697684
        : AppColors.white.withValues(alpha: .58);
    return OheyBottomSheetShell(
      showBottomCloseButton: false,
      showHandle: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: OheyPopIcon(
              icon: CupertinoIcons.trash_fill,
              color: AppColors.cFFFF5F8F,
              size: 64,
              iconSize: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ゆるぼを削除しますか？',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '削除したゆるぼは元に戻せません。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ProfileModalTextButton(
                  label: 'やめる',
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileModalTextButton(
                  label: '削除する',
                  color: AppColors.cFFFF5F8F,
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileModalTextButton extends StatelessWidget {
  const _ProfileModalTextButton({
    required this.label,
    required this.onTap,
    this.color = AppColors.cFFC08BFF,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final surfaceColor = isWhite
        ? Color.lerp(AppColors.white, color, .24)!
        : AppColors.darkBackground;
    return CupertinoButton(
      onPressed: onTap,
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isWhite
                ? color.withValues(alpha: .34)
                : AppColors.white.withValues(alpha: .12),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isWhite ? .10 : .16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -.35,
          ),
        ),
      ),
    );
  }
}

Future<void> _showProfileEditYuruboSheet(
  BuildContext context,
  WidgetRef ref,
  Yurubo yurubo,
) async {
  await showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => _ProfileEditYuruboSheet(ref: ref, yurubo: yurubo),
  );
}

class _ProfileEditYuruboSheet extends StatefulWidget {
  const _ProfileEditYuruboSheet({required this.ref, required this.yurubo});

  final WidgetRef ref;
  final Yurubo yurubo;

  @override
  State<_ProfileEditYuruboSheet> createState() =>
      _ProfileEditYuruboSheetState();
}

class _ProfileEditYuruboSheetState extends State<_ProfileEditYuruboSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  DateTime? _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.yurubo.title);
    _placeController = TextEditingController(text: widget.yurubo.placeText);
    _selectedDate = widget.yurubo.startsAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.ref
          .read(yuruboControllerProvider.notifier)
          .updateYurubo(
            widget.yurubo.id,
            YuruboUpdateDraft(
              title: title,
              body: widget.yurubo.body,
              placeText: _profileYuruboPlaceOrDefault(_placeController.text),
              timeLabel: _profileYuruboTimeLabel(_selectedDate),
              startsAt: _selectedDate == null
                  ? null
                  : _dateOnly(_selectedDate!),
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      OheyToast.show(context, 'ゆるぼを更新しました');
    } catch (_) {
      if (mounted) OheyToast.show(context, '更新できなかったよ。あとでもう一度試してね');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.light
        ? AppColors.cFF17212B
        : AppColors.white;
    return OheyBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ゆるぼを編集',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 14),
          _ProfileYuruboInput(
            controller: _titleController,
            placeholder: '今日夜、ご飯いける人いる？',
          ),
          const SizedBox(height: 10),
          _ProfileYuruboInput(
            controller: _placeController,
            placeholder: '場所（未入力ならどこでも）',
          ),
          const SizedBox(height: 10),
          _ProfileYuruboDateOption(
            selectedDate: _selectedDate,
            onTap: () async {
              final picked = await _showProfileYuruboDatePicker(
                context,
                _selectedDate,
              );
              if (picked != null && mounted) {
                setState(() => _selectedDate = picked);
              }
            },
            onClear: _selectedDate == null
                ? null
                : () => setState(() => _selectedDate = null),
          ),
          const SizedBox(height: 16),
          Ohey3DButton(
            label: _saving ? '保存中...' : '保存する',
            onTap: _saving ? null : _submit,
            height: 50,
            radius: 22,
            color: AppColors.cFFC08BFF,
            foregroundColor: AppColors.cFF101820,
            shadowColor: AppColors.cFF7F51C9,
          ),
        ],
      ),
    );
  }
}
