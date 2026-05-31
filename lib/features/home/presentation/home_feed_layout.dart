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
        refreshTriggerPullDistance: 34,
        refreshIndicatorExtent: 24,
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
              triggerDistance: refreshTriggerPullDistance,
              indicatorExtent: refreshIndicatorExtent,
              topOffset: topPadding - 42,
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

  return withRefresh(
    SliverPadding(
      padding: EdgeInsets.fromLTRB(0, topPadding + 10, 0, _feedBottomPageInset),
      sliver: SliverList.separated(
        itemCount: items.length + (isLoading ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          if (index >= items.length - 3) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onPageChanged(index);
            });
          }
          final item = items[index];
          return _YuruboPostListItem(
            item: item,
            isWhite: isWhite,
            onInterested: item.isLikeable ? () => onLikePressed(item) : null,
            onInvite: item.id.isEmpty ? null : () => onSharePressed(item),
            onMore: item.id.isEmpty ? null : () => onMorePressed(item),
            onAuthorTap: () => onAuthorPressed(item),
          );
        },
      ),
    ),
  );
}

class _YuruboRefreshIndicator extends StatelessWidget {
  const _YuruboRefreshIndicator({
    required this.state,
    required this.pulledExtent,
    required this.triggerDistance,
    required this.indicatorExtent,
    required this.topOffset,
  });

  final RefreshIndicatorMode state;
  final double pulledExtent;
  final double triggerDistance;
  final double indicatorExtent;
  final double topOffset;

  @override
  Widget build(BuildContext context) {
    final progress = (pulledExtent / triggerDistance).clamp(0.0, 1.0);
    final isRefreshing =
        state == RefreshIndicatorMode.refresh ||
        state == RefreshIndicatorMode.armed;
    final label = switch (state) {
      RefreshIndicatorMode.inactive => '',
      RefreshIndicatorMode.drag => progress >= 1 ? '離して更新' : '下に引っ張って更新',
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
            opacity: state == RefreshIndicatorMode.inactive ? 0 : 1,
            child: Transform.translate(
              offset: Offset(0, topOffset.clamp(0, 220)),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRefreshing)
                      const CupertinoActivityIndicator(radius: 8)
                    else
                      Transform.rotate(
                        angle: progress * 3.14159,
                        child: Icon(
                          CupertinoIcons.arrow_down,
                          color: _feedPrimaryActionColor,
                          size: 16,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
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
        message: 'ご飯・作業・サウナなど、LINEで送るほどでもない誘いを軽く置けます。',
        accent: _feedPrimaryActionColor,
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
  final _timeController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _groupsFuture;
  String _visibility = 'friends';
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
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;
    if (_visibility == 'group' && (_groupId == null || _groupId!.isEmpty)) {
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
              timeLabel: _yuruboTimeOrDefault(_timeController.text),
              visibility: _visibility,
              groupId: _visibility == 'group' ? _groupId : null,
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
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          final groups = snapshot.data ?? const <Map<String, dynamic>>[];
          if (_visibility == 'group' && _groupId == null && groups.isNotEmpty) {
            _groupId =
                (groups.first['row_id'] ?? groups.first['id']) as String?;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_wishItemId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _feedPrimaryActionColor.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _feedPrimaryActionColor.withValues(alpha: .42),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.sparkles,
                        color: _feedPrimaryActionColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'やりたいことリストから作成中',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
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
                      selected: _visibility == 'friends',
                      onTap: () => setState(() => _visibility = 'friends'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _YuruboVisibilityChoice(
                      label: 'グループ',
                      selected: _visibility == 'group',
                      onTap: () => setState(() => _visibility = 'group'),
                    ),
                  ),
                ],
              ),
              if (_visibility == 'group') ...[
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
              _YuruboInput(
                controller: _timeController,
                placeholder: 'いつ（未入力ならいつでも）',
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
  late final TextEditingController _timeController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.body.trim());
    _placeController = TextEditingController(text: widget.item.place.trim());
    _timeController = TextEditingController(text: widget.item.timeLabel.trim());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _timeController.dispose();
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
              timeLabel: _yuruboTimeOrDefault(_timeController.text),
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
          _YuruboInput(
            controller: _timeController,
            placeholder: 'いつ（未入力ならいつでも）',
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

String _yuruboTimeOrDefault(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'いつでも' : trimmed;
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
