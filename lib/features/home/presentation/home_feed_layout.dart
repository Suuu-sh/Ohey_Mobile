part of 'home_screen.dart';

double _feedHeaderScrollInset(BuildContext context) {
  // Match the latest reference feed capture: header scene ends at y≈505 on
  // a 1200px-wide crop. Keeping this width ratio locks the visible image
  // crop to the reference instead of depending on safe-area heuristics.
  const referenceWidth = 1200.0;
  const referenceHeaderBottom = 505.0;
  return MediaQuery.sizeOf(context).width *
      referenceHeaderBottom /
      referenceWidth;
}

const _feedBottomPageInset = 124.0;
const _feedPrimaryActionColor = AppColors.cFFC08BFF;
const _feedPrimaryActionShadowColor = AppColors.cFF7F51C9;

Widget _buildFeedPage({
  required double topPadding,
  required List<_FeedItem> items,
  required bool isWhite,
  required bool isLoading,
  required bool showSwipeTutorial,
  required VoidCallback onSwipeTutorialDismissed,
  required ValueChanged<int> onPageChanged,
  required bool isPlus,
  required VoidCallback onCreateYuruboPressed,
  required Future<void> Function() onRefresh,
  required ValueChanged<_FeedItem> onLikePressed,
  required ValueChanged<_FeedItem> onSharePressed,
  required ValueChanged<_FeedItem> onMorePressed,
  required ValueChanged<_FeedItem> onAuthorPressed,
}) {
  if (isLoading && items.isEmpty) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: topPadding, bottom: _feedBottomPageInset),
      children: const [
        Padding(
          padding: EdgeInsets.all(36),
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ],
    );
  }

  Widget withRefresh(Widget child) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    ),
    slivers: [
      CupertinoSliverRefreshControl(
        refreshTriggerPullDistance: 104,
        refreshIndicatorExtent: 64,
        onRefresh: onRefresh,
        builder:
            (
              context,
              refreshState,
              pulledExtent,
              refreshTriggerPullDistance,
              refreshIndicatorExtent,
            ) => _YuruboRefreshIndicator(
              state: refreshState,
              pulledExtent: pulledExtent,
            ),
      ),
      child,
    ],
  );

  if (items.isEmpty) {
    return withRefresh(
      SliverPadding(
        padding: EdgeInsets.only(top: topPadding, bottom: _feedBottomPageInset),
        sliver: SliverList.list(
          children: [
            _FeedSectionEmptyState(
              isWhite: isWhite,
              onCreateYuruboPressed: onCreateYuruboPressed,
            ),
          ],
        ),
      ),
    );
  }

  final entries = _feedEntriesFromItems(items, includeAds: !isPlus);
  return withRefresh(
    SliverPadding(
      padding: EdgeInsets.fromLTRB(0, topPadding + 10, 0, _feedBottomPageInset),
      sliver: SliverList.separated(
        itemCount: entries.length + (isLoading ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= entries.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          final entry = entries[index];
          return switch (entry) {
            _YuruboFeedEntry(:final item) => _YuruboPostListItem(
              item: item,
              isWhite: isWhite,
              onInterested: item.isLikeable ? () => onLikePressed(item) : null,
              onInvite: item.id.isEmpty ? null : () => onSharePressed(item),
              onMore: item.id.isEmpty ? null : () => onMorePressed(item),
              onAuthorTap: () => onAuthorPressed(item),
            ),
            _YuruboAdFeedEntry(:final index) => _YuruboNativeAdListItem(
              index: index,
              isWhite: isWhite,
            ),
          };
        },
      ),
    ),
  );
}

class _YuruboRefreshIndicator extends StatelessWidget {
  const _YuruboRefreshIndicator({
    required this.state,
    required this.pulledExtent,
  });

  final RefreshIndicatorMode state;
  final double pulledExtent;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      RefreshIndicatorMode.inactive || RefreshIndicatorMode.drag => '',
      RefreshIndicatorMode.armed || RefreshIndicatorMode.refresh => '更新中...',
      RefreshIndicatorMode.done => '更新しました',
    };

    return SizedBox(
      height: pulledExtent,
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        minHeight: 0,
        maxHeight: 60,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: label.isEmpty ? 0 : 1,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: AppColors.cFF101C2B.withValues(alpha: .82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _feedPrimaryActionColor.withValues(alpha: .22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _feedPrimaryActionColor.withValues(alpha: .18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YuruboPostListItem extends StatelessWidget {
  const _YuruboPostListItem({
    required this.item,
    required this.isWhite,
    this.onInterested,
    this.onInvite,
    this.onMore,
    this.onAuthorTap,
  });

  final _FeedItem item;
  final bool isWhite;
  final VoidCallback? onInterested;
  final VoidCallback? onInvite;
  final VoidCallback? onMore;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _FeedPostCard(
        item: item,
        isWhite: isWhite,
        compactYurubo: true,
        onLike: onInterested,
        onShare: onInvite,
        onMore: onMore,
        onAuthorTap: onAuthorTap,
      ),
    );
  }
}

class _FeedSectionEmptyState extends StatelessWidget {
  const _FeedSectionEmptyState({
    required this.isWhite,
    required this.onCreateYuruboPressed,
  });

  final bool isWhite;
  final VoidCallback onCreateYuruboPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: _FeedEmptyState(
        icon: CupertinoIcons.plus_bubble_fill,
        isWhite: isWhite,
        title: '最初のゆるぼを出そう',
        message:
            'ホームが静かな時は、Oheyが小さな募集ボードになります。ゆるぼは予定日を過ぎると消えます。いつでもは30日後まで表示されます。',
        accent: _feedPrimaryActionColor,
        hints: const ['今ひま？', '今度ここ行こ', '一緒に作業しよ'],
        action: SizedBox(
          width: 240,
          child: Ohey3DButton(
            label: 'ゆるぼする',
            icon: CupertinoIcons.plus_bubble_fill,
            onTap: onCreateYuruboPressed,
            height: 50,
            radius: 22,
            color: _feedPrimaryActionColor,
            foregroundColor: AppColors.cFF101820,
            shadowColor: _feedPrimaryActionShadowColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

Future<void> _showFeedPostActions(
  BuildContext context,
  WidgetRef ref,
  _FeedItem item,
) async {
  final body = item.body.trim();
  HapticFeedback.selectionClick();
  final action = await showOheyBottomSheet<_FeedPostAction>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (context) => _FeedPostActionsSheet(item: item, body: body),
  );
  if (!context.mounted || action == null) return;

  switch (action) {
    case _FeedPostAction.edit:
      if (!item.ownedByMe) return;
      await _showEditYuruboSheet(context, ref, item);
      break;
    case _FeedPostAction.delete:
      final confirmed = await _confirmDeleteFeedPost(context);
      if (!confirmed || !context.mounted) return;
      try {
        await ref.read(yuruboControllerProvider.notifier).deleteYurubo(item.id);
        ref.invalidate(homeFeedControllerProvider);
        if (context.mounted) OheyToast.show(context, 'ゆるぼを削除しました');
      } catch (error) {
        if (context.mounted) {
          OheyToast.show(context, '削除できなかったよ。あとでもう一度試してね');
        }
      }
    case _FeedPostAction.report:
      final reason = await _selectReportReason(context);
      if (!context.mounted || reason == null) return;
      try {
        await ref
            .read(homeFeedControllerProvider.notifier)
            .reportMemory(item.id, reason: reason.value);
        if (context.mounted) {
          OheyToast.show(context, '「${reason.label}」として報告しました');
        }
      } catch (error) {
        if (context.mounted) {
          OheyToast.show(context, '報告できなかったよ。あとでもう一度試してね');
        }
      }
    case _FeedPostAction.hide:
      try {
        await ref.read(homeFeedControllerProvider.notifier).hideMemory(item.id);
        if (context.mounted) OheyToast.show(context, 'フィードから非表示にしました');
      } catch (_) {
        if (context.mounted) {
          OheyToast.show(context, '非表示にできなかったよ。あとでもう一度試してね');
        }
      }
    case _FeedPostAction.muteUser:
      if (item.ownerUserId.trim().isEmpty) return;
      try {
        await ref
            .read(homeFeedControllerProvider.notifier)
            .muteUser(item.ownerUserId);
        if (context.mounted) {
          _showUserSafetyUndoToast(
            context,
            message: '${item.userName}さんをミュートしました',
            undoLabel: '元に戻す',
            onUndo: () async {
              await ref
                  .read(userSafetyRepositoryProvider)
                  .unmuteUser(item.ownerUserId);
              ref.invalidate(mutedUsersProvider);
              ref.invalidate(homeFeedControllerProvider);
            },
          );
        }
      } catch (_) {
        if (context.mounted) {
          OheyToast.show(context, 'ミュートできなかったよ。あとでもう一度試してね');
        }
      }
    case _FeedPostAction.blockUser:
      if (item.ownerUserId.trim().isEmpty) return;
      final confirmed = await _confirmUserSafetyAction(
        context,
        title: '${item.userName}さんをブロックしますか？',
        message: '相手のゆるぼやお誘いが表示されにくくなります。必要ならあとで解除できます。',
        actionLabel: 'ブロックする',
        color: AppColors.cFFFF5F8F,
      );
      if (!confirmed || !context.mounted) return;
      try {
        await ref
            .read(homeFeedControllerProvider.notifier)
            .blockUser(item.ownerUserId);
        if (context.mounted) {
          _showUserSafetyUndoToast(
            context,
            message: '${item.userName}さんをブロックしました',
            undoLabel: '元に戻す',
            onUndo: () async {
              await ref
                  .read(userSafetyRepositoryProvider)
                  .unblockUser(item.ownerUserId);
              ref.invalidate(blockedUsersProvider);
              ref.invalidate(friendsProvider);
              ref.invalidate(homeFeedControllerProvider);
            },
          );
        }
      } catch (_) {
        if (context.mounted) {
          OheyToast.show(context, 'ブロックできなかったよ。あとでもう一度試してね');
        }
      }
  }
}

void _showUserSafetyUndoToast(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required Future<void> Function() onUndo,
}) {
  OheyToast.show(
    context,
    message,
    icon: CupertinoIcons.checkmark_circle_fill,
    duration: const Duration(milliseconds: 5200),
    actionLabel: undoLabel,
    onAction: () async {
      try {
        await onUndo();
        if (context.mounted) {
          OheyToast.show(
            context,
            '元に戻しました',
            icon: CupertinoIcons.arrow_uturn_left_circle_fill,
          );
        }
      } catch (_) {
        if (context.mounted) {
          OheyToast.show(
            context,
            '元に戻せませんでした。あとでもう一度試してね',
            icon: CupertinoIcons.exclamationmark_triangle_fill,
          );
        }
      }
    },
  );
}

Future<bool> _confirmDeleteFeedPost(BuildContext context) async {
  final result = await showOheyBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .62),
    builder: (context) => const _FeedDeleteConfirmSheet(),
  );
  return result ?? false;
}

Future<_FeedReportReason?> _selectReportReason(BuildContext context) async {
  return showOheyBottomSheet<_FeedReportReason>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .62),
    builder: (context) => const _FeedReportReasonSheet(),
  );
}

Future<bool> _confirmUserSafetyAction(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  required Color color,
}) async {
  final result = await showOheyBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .62),
    builder: (context) => _FeedUserSafetyConfirmSheet(
      title: title,
      message: message,
      actionLabel: actionLabel,
      color: color,
    ),
  );
  return result ?? false;
}

Future<void> _showCreateYuruboSheet(
  BuildContext context,
  WidgetRef ref, {
  WishItem? wish,
}) async {
  await showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => _CreateYuruboSheet(ref: ref, initialWish: wish),
  );
}

class _CreateYuruboSheet extends StatefulWidget {
  const _CreateYuruboSheet({required this.ref, this.initialWish});

  final WidgetRef ref;
  final WishItem? initialWish;

  @override
  State<_CreateYuruboSheet> createState() => _CreateYuruboSheetState();
}

class _CreateYuruboSheetState extends State<_CreateYuruboSheet> {
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  DateTime? _selectedDate;
  late Future<List<Map<String, dynamic>>> _groupsFuture;
  String _visibility = OheyVisibility.friends.key;
  String? _groupId;
  String? _wishItemId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initialWish = widget.initialWish;
    if (initialWish != null) {
      _titleController.text = initialWish.title;
      _placeController.text = initialWish.placeText;
      _wishItemId = initialWish.id;
    }
    _groupsFuture = widget.ref
        .read(friendRepositoryProvider)
        .fetchFriendGroups();
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
    if (_visibility.requiresVisibilityGroup &&
        (_groupId == null || _groupId!.isEmpty)) {
      OheyToast.show(context, 'グループを選んでね');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.ref
          .read(yuruboControllerProvider.notifier)
          .createYurubo(
            YuruboCreateDraft(
              title: title,
              placeText: _yuruboPlaceOrDefault(_placeController.text),
              timeLabel: _yuruboTimeLabel(_selectedDate),
              startsAt: _selectedDate == null
                  ? null
                  : _dateOnly(_selectedDate!),
              visibility: _visibility,
              groupId: _visibility.requiresVisibilityGroup ? _groupId : null,
              wishItemId: _wishItemId,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      OheyToast.show(context, 'ゆるぼしました', icon: CupertinoIcons.plus_bubble_fill);
    } catch (_) {
      if (mounted) OheyToast.show(context, 'ゆるぼできなかったよ。あとでもう一度試してね');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF17212B : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .62);
    final wishItems =
        widget.ref.watch(wishItemControllerProvider).asData?.value ??
        const <WishItem>[];
    return OheyBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      radius: 32,
      showBottomCloseButton: false,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          final groups = snapshot.data ?? const <Map<String, dynamic>>[];
          if (_visibility.requiresVisibilityGroup &&
              _groupId == null &&
              groups.isNotEmpty) {
            _groupId =
                (groups.first['row_id'] ?? groups.first['id']) as String?;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '誰に募集する？',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _YuruboVisibilityChoice(
                      label: '全フレンズ',
                      selected: _visibility == OheyVisibility.friends.key,
                      onTap: () => setState(
                        () => _visibility = OheyVisibility.friends.key,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _YuruboVisibilityChoice(
                      label: 'グループ',
                      selected: _visibility == OheyVisibility.group.key,
                      onTap: () => setState(
                        () => _visibility = OheyVisibility.group.key,
                      ),
                    ),
                  ),
                ],
              ),
              if (_visibility.requiresVisibilityGroup) ...[
                const SizedBox(height: 12),
                if (groups.isEmpty)
                  Text(
                    '先にフレンズ画面でグループを作ってね',
                    style: TextStyle(color: sub, fontWeight: FontWeight.w800),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final group in groups)
                        _YuruboGroupChip(
                          label: (group['name'] as String?) ?? 'グループ',
                          selected:
                              _groupId ==
                              ((group['row_id'] ?? group['id']) as String?),
                          onTap: () => setState(
                            () => _groupId =
                                (group['row_id'] ?? group['id']) as String?,
                          ),
                        ),
                    ],
                  ),
              ],
              const SizedBox(height: 14),
              if (wishItems.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'やりたいことリストから選ぶ',
                    style: TextStyle(
                      color: sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: wishItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final wish = wishItems[index];
                      final selected = _wishItemId == wish.id;
                      return _YuruboGroupChip(
                        label: wish.title,
                        selected: selected,
                        onTap: () => setState(() {
                          _wishItemId = wish.id;
                          _titleController.text = wish.title;
                          _placeController.text = wish.placeText;
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _YuruboInput(
                controller: _titleController,
                placeholder: '今日夜、ご飯いける人いる？',
              ),
              const SizedBox(height: 10),
              _YuruboInput(
                controller: _placeController,
                placeholder: '場所（未入力ならどこでも）',
              ),
              const SizedBox(height: 10),
              _YuruboDateOption(
                selectedDate: _selectedDate,
                onTap: () async {
                  final picked = await _showYuruboDatePicker(
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
                label: _saving ? '送信中...' : 'ゆるぼする',
                icon: CupertinoIcons.plus_bubble_fill,
                onTap: _saving ? null : _submit,
                height: 50,
                radius: 22,
                color: _feedPrimaryActionColor,
                foregroundColor: AppColors.cFF101820,
                shadowColor: _feedPrimaryActionShadowColor,
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showEditYuruboSheet(
  BuildContext context,
  WidgetRef ref,
  _FeedItem item,
) async {
  await showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => _EditYuruboSheet(ref: ref, item: item),
  );
}

class _EditYuruboSheet extends StatefulWidget {
  const _EditYuruboSheet({required this.ref, required this.item});

  final WidgetRef ref;
  final _FeedItem item;

  @override
  State<_EditYuruboSheet> createState() => _EditYuruboSheetState();
}

class _EditYuruboSheetState extends State<_EditYuruboSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  DateTime? _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.body.trim());
    _placeController = TextEditingController(text: widget.item.place.trim());
    _selectedDate = widget.item.startsAt;
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
            widget.item.id,
            YuruboUpdateDraft(
              title: title,
              placeText: _yuruboPlaceOrDefault(_placeController.text),
              timeLabel: _yuruboTimeLabel(_selectedDate),
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
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF17212B : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .62);
    return OheyBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      radius: 32,
      showBottomCloseButton: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: sub.withValues(alpha: .34),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          _YuruboInput(
            controller: _titleController,
            placeholder: '今日夜、ご飯いける人いる？',
          ),
          const SizedBox(height: 10),
          _YuruboInput(
            controller: _placeController,
            placeholder: '場所（未入力ならどこでも）',
          ),
          const SizedBox(height: 10),
          _YuruboDateOption(
            selectedDate: _selectedDate,
            onTap: () async {
              final picked = await _showYuruboDatePicker(
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
            icon: CupertinoIcons.checkmark_circle_fill,
            onTap: _saving ? null : _submit,
            height: 50,
            radius: 22,
            color: _feedPrimaryActionColor,
            foregroundColor: AppColors.cFF101820,
            shadowColor: _feedPrimaryActionShadowColor,
          ),
        ],
      ),
    );
  }
}

String _yuruboPlaceOrDefault(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'どこでも' : trimmed;
}

String _yuruboTimeLabel(DateTime? value) {
  if (value == null) return 'いつでも';
  final date = _dateOnly(value);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = date.difference(today).inDays;
  return switch (diff) {
    0 => '今日',
    1 => '明日',
    _ => '${date.month}/${date.day}(${_shortWeekday(date)})',
  };
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _shortWeekday(DateTime value) =>
    const ['月', '火', '水', '木', '金', '土', '日'][value.weekday - 1];

Future<DateTime?> _showYuruboDatePicker(
  BuildContext context,
  DateTime? selected,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var focused = _dateOnly(selected ?? today);
  if (focused.isBefore(today)) focused = today;
  var visibleMonth = DateTime(focused.year, focused.month);
  return showOheyBottomSheet<DateTime>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) => OheyBottomSheetShell(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        radius: 32,
        child: _YuruboCalendarPicker(
          visibleMonth: visibleMonth,
          selectedDate: focused,
          firstDate: today,
          onPreviousMonth: () => setModalState(() {
            final previous = DateTime(
              visibleMonth.year,
              visibleMonth.month - 1,
            );
            if (!_isBeforeMonth(previous, today)) visibleMonth = previous;
          }),
          onNextMonth: () => setModalState(() {
            visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + 1);
          }),
          onDateSelected: (date) => setModalState(() => focused = date),
          onConfirm: () => Navigator.of(context).pop(focused),
        ),
      ),
    ),
  );
}

bool _isBeforeMonth(DateTime month, DateTime date) =>
    month.year < date.year ||
    (month.year == date.year && month.month < date.month);

class _YuruboCalendarPicker extends StatelessWidget {
  const _YuruboCalendarPicker({
    required this.visibleMonth,
    required this.selectedDate,
    required this.firstDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
    required this.onConfirm,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final DateTime firstDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final canGoPrevious = !_isBeforeMonth(
      DateTime(visibleMonth.year, visibleMonth.month - 1),
      firstDate,
    );
    final days = _calendarDays(visibleMonth);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _YuruboCalendarArrow(
              icon: CupertinoIcons.chevron_left,
              enabled: canGoPrevious,
              onTap: onPreviousMonth,
            ),
            Expanded(
              child: Text(
                '${visibleMonth.year}/${visibleMonth.month.toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
            ),
            _YuruboCalendarArrow(
              icon: CupertinoIcons.chevron_right,
              enabled: true,
              onTap: onNextMonth,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            for (final label in const ['日', '月', '火', '水', '木', '金', '土'])
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: label == '日'
                        ? AppColors.cFFFF75B5
                        : label == '土'
                        ? AppColors.cFF54D7FF
                        : AppColors.white.withValues(alpha: .72),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 9),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final date = days[index];
            final inMonth = date.month == visibleMonth.month;
            final disabled = date.isBefore(firstDate);
            final selected = _dateOnly(date) == _dateOnly(selectedDate);
            return _YuruboCalendarDayCell(
              date: date,
              inMonth: inMonth,
              disabled: disabled,
              selected: selected,
              onTap: disabled ? null : () => onDateSelected(date),
            );
          },
        ),
        const SizedBox(height: 18),
        Ohey3DButton(
          label:
              '${selectedDate.month}/${selectedDate.day}(${_shortWeekday(selectedDate)}) にする',
          icon: CupertinoIcons.calendar_badge_plus,
          onTap: onConfirm,
          height: 48,
          radius: 22,
          color: _feedPrimaryActionColor,
          foregroundColor: AppColors.cFF101820,
          shadowColor: _feedPrimaryActionShadowColor,
        ),
      ],
    );
  }
}

List<DateTime> _calendarDays(DateTime month) {
  final first = DateTime(month.year, month.month);
  final start = first.subtract(Duration(days: first.weekday % 7));
  return List<DateTime>.generate(
    35,
    (index) => start.add(Duration(days: index)),
  );
}

class _YuruboCalendarArrow extends StatelessWidget {
  const _YuruboCalendarArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: enabled ? .12 : .05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: .11)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: .18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: AppColors.white.withValues(alpha: enabled ? .92 : .22),
        size: 26,
      ),
    ),
  );
}

class _YuruboCalendarDayCell extends StatelessWidget {
  const _YuruboCalendarDayCell({
    required this.date,
    required this.inMonth,
    required this.disabled,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final bool disabled;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSunday = date.weekday == DateTime.sunday;
    final isSaturday = date.weekday == DateTime.saturday;
    final textColor = disabled || !inMonth
        ? AppColors.white.withValues(alpha: .18)
        : selected
        ? AppColors.white
        : isSunday
        ? AppColors.cFFFF75B5
        : isSaturday
        ? AppColors.cFF54D7FF
        : AppColors.white;
    final fillColor = selected
        ? const Color(0xFF0CA7DF).withValues(alpha: .74)
        : isSunday && inMonth && !disabled
        ? AppColors.cFFFF75B5.withValues(alpha: .42)
        : const Color(0xFF061724);
    final borderColor = selected
        ? AppColors.cFF54D7FF
        : isSunday && inMonth && !disabled
        ? AppColors.cFFFF75B5.withValues(alpha: .72)
        : const Color(0xFF0A75A4).withValues(alpha: inMonth ? .62 : .28);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 2 : 1.2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.cFF54D7FF.withValues(alpha: .26),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _YuruboDateOption extends StatelessWidget {
  const _YuruboDateOption({
    required this.selectedDate,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? selectedDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final label = selectedDate == null
        ? 'いつ（任意）'
        : _yuruboTimeLabel(selectedDate);
    final subLabel = selectedDate == null ? 'カレンダーで日程を設定' : 'タップして日程を変更';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.white.withValues(alpha: .13)),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.calendar,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subLabel,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: .5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(30),
                onPressed: onClear,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: AppColors.white.withValues(alpha: .58),
                  size: 21,
                ),
              )
            else
              Icon(
                CupertinoIcons.chevron_down,
                color: AppColors.white.withValues(alpha: .58),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _YuruboVisibilityChoice extends StatelessWidget {
  const _YuruboVisibilityChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Ohey3DButtonSurface(
    onTap: onTap,
    height: 46,
    radius: 20,
    color: selected ? _feedPrimaryActionColor : AppColors.cFF263348,
    bottomColor: selected ? _feedPrimaryActionShadowColor : AppColors.cFF151D2A,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Center(
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.cFF101820 : AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _YuruboGroupChip extends StatelessWidget {
  const _YuruboGroupChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (selected ? _FeedColors.teal : AppColors.white).withValues(
          alpha: selected ? .26 : .08,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _FeedColors.teal.withValues(alpha: selected ? .7 : .25),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _YuruboInput extends StatelessWidget {
  const _YuruboInput({required this.controller, required this.placeholder});
  final TextEditingController controller;
  final String placeholder;
  @override
  Widget build(BuildContext context) => CupertinoTextField(
    controller: controller,
    placeholder: placeholder,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.white.withValues(alpha: .13)),
    ),
    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
    placeholderStyle: TextStyle(
      color: AppColors.white.withValues(alpha: .42),
      fontWeight: FontWeight.w700,
    ),
  );
}
