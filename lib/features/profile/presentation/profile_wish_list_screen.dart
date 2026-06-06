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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ProfileWishListHeader(),
          const SizedBox(height: 14),
          _ProfileWishListAddButton(
            onCreate: () => _showProfileCreateWishItemSheet(context, ref),
          ),
          const SizedBox(height: 10),
          if (wishItemsAsync.isLoading && wishItems.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (wishItems.isEmpty)
            const _ProfileWishListEmptyState()
          else
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

class _ProfileWishListEmptyState extends StatelessWidget {
  const _ProfileWishListEmptyState();

  @override
  Widget build(BuildContext context) {
    return OheyEmptyState(
      visual: const Icon(
        CupertinoIcons.sparkles,
        color: AppColors.cFF20B9FF,
        size: 46,
      ),
      title: 'やりたいことを保存しておこう',
      titleColor: AppColors.white,
      messageColor: _ProfileColors.sub,
    );
  }
}

class _ProfileWishListHeader extends StatelessWidget {
  const _ProfileWishListHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'やりたいこと',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.cFF20B9FF,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
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
