part of 'profile_screen.dart';

Future<void> _openProfileWishListScreen(BuildContext context) async {
  await Navigator.of(context).push<void>(
    CupertinoPageRoute(builder: (_) => const _ProfileWishListScreen()),
  );
}

class _ProfileWishListScreen extends ConsumerWidget {
  const _ProfileWishListScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishItemsAsync = ref.watch(wishItemControllerProvider);
    final wishItems = wishItemsAsync.asData?.value ?? const <WishItem>[];
    const background = AppColors.darkBackgroundBottom;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          const ColoredBox(color: background, child: SizedBox.expand()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  child: Row(
                    children: [
                      OheyHeaderIconButton(
                        icon: CupertinoIcons.chevron_left,
                        semanticLabel: '戻る',
                        color: const Color(0xFFC08BFF),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OheyPageHeader(
                          title: 'やりたいことリスト',
                          titleColor: const Color(0xFFC08BFF),
                          trailing: OheyHeaderIconButton(
                            icon: CupertinoIcons.plus,
                            semanticLabel: '追加',
                            color: const Color(0xFFC08BFF),
                            onTap: () =>
                                _showProfileCreateWishItemSheet(context, ref),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          itemCount: wishItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
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
        ],
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
              color: Color(0xFFC08BFF),
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'やりたいことを置いてみよう',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
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
              color: const Color(0xFFC08BFF),
              foregroundColor: const Color(0xFF101820),
              shadowColor: const Color(0xFF7F51C9),
            ),
          ],
        ),
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
    final visibilityLabel = wish.visibility == 'friends' ? '友達に公開' : '自分だけ';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .11)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC08BFF).withValues(alpha: .22),
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: Color(0xFFC08BFF),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wish.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                      ),
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place,
                        style: const TextStyle(
                          color: _ProfileColors.sub,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  visibilityLabel,
                  style: const TextStyle(
                    color: _ProfileColors.sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Ohey3DButton(
                label: 'ゆるぼにする',
                icon: CupertinoIcons.plus_bubble_fill,
                onTap: onYurubo,
                height: 42,
                radius: 18,
                color: const Color(0xFFC08BFF),
                foregroundColor: const Color(0xFF101820),
                shadowColor: const Color(0xFF7F51C9),
                fontSize: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
