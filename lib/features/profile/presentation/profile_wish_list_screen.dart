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

    return OheyBottomSheetShell(
      maxHeightFactor: .9,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          children: [
            _ProfileWishListHeader(
              onCreate: () => _showProfileCreateWishItemSheet(context, ref),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: wishItemsAsync.isLoading && wishItems.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : wishItems.isEmpty
                  ? _ProfileWishListEmptyState(
                      onCreate: () =>
                          _showProfileCreateWishItemSheet(context, ref),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                      itemCount: wishItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final wish = wishItems[index];
                        return _ProfileWishListCard(
                          wish: wish,
                          onYurubo: () => _showProfileCreateYuruboSheet(
                            context,
                            ref,
                            wish: wish,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileWishListEmptyState extends StatelessWidget {
  const _ProfileWishListEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return OheyEmptyState(
      visual: const Icon(
        CupertinoIcons.sparkles,
        color: AppColors.cFF20B9FF,
        size: 46,
      ),
      title: 'やりたいことを保存しておこう',
      message: 'あとで誰かと行きたいことを保存できます。',
      titleColor: AppColors.white,
      messageColor: _ProfileColors.sub,
      hints: const ['焼肉', 'カフェ', '勉強'],
      action: SizedBox(
        width: 190,
        child: Ohey3DButton(
          label: '追加する',
          onTap: onCreate,
          height: 50,
          radius: 22,
          color: AppColors.cFF20B9FF,
          foregroundColor: AppColors.cFF101820,
          shadowColor: AppColors.cFF0B78B7,
        ),
      ),
    );
  }
}

class _ProfileWishListHeader extends StatelessWidget {
  const _ProfileWishListHeader({required this.onCreate});

  final VoidCallback onCreate;

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
                SizedBox(height: 5),
                Text(
                  'あとで誘いたいことをためておく場所',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ProfileColors.sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OheyHeaderIconButton(
            icon: CupertinoIcons.plus,
            semanticLabel: '追加',
            color: AppColors.cFF20B9FF,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

class _ProfileWishListCard extends StatelessWidget {
  const _ProfileWishListCard({required this.wish, required this.onYurubo});

  final WishItem wish;
  final VoidCallback onYurubo;

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
          icon: CupertinoIcons.plus,
          color: AppColors.cFF20B9FF,
          semanticLabel: '${wish.title}からゆるぼを作る',
          onTap: onYurubo,
        ),
      ],
    );
  }
}
