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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.sparkles,
              color: AppColors.cFFC08BFF,
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'やりたいことを置いてみよう',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '焼肉・サウナ・作業など、誘いの種をリストにためておけます。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ProfileColors.sub,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Ohey3DButton(
              label: '追加する',
              icon: CupertinoIcons.plus,
              onTap: onCreate,
              height: 50,
              radius: 22,
              color: AppColors.cFFC08BFF,
              foregroundColor: AppColors.cFF101820,
              shadowColor: AppColors.cFF7F51C9,
            ),
          ],
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
                    color: AppColors.cFFC08BFF,
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
            color: AppColors.cFFC08BFF,
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
    return Semantics(
      button: true,
      label: '${wish.title}からゆるぼを作る',
      child: CupertinoButton(
        onPressed: onYurubo,
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: .045),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.white.withValues(alpha: .08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      wish.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.45,
                      ),
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ProfileColors.sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cFFC08BFF.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.plus,
                  color: AppColors.cFFC08BFF,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
