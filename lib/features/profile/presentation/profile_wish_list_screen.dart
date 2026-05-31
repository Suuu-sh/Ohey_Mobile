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
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                  child: _ProfileWishListHeader(
                    onBack: () => Navigator.of(context).pop(),
                    onCreate: () =>
                        _showProfileCreateWishItemSheet(context, ref),
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
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
                          itemCount: wishItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox.shrink(),
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

class _ProfileWishListHeader extends StatelessWidget {
  const _ProfileWishListHeader({required this.onBack, required this.onCreate});

  final VoidCallback onBack;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          OheyHeaderIconButton(
            icon: CupertinoIcons.chevron_left,
            semanticLabel: '戻る',
            color: const Color(0xFFC08BFF),
            onTap: onBack,
          ),
          const SizedBox(width: 6),
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
                    color: Color(0xFFC08BFF),
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
            color: const Color(0xFFC08BFF),
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
      label: '${wish.title}のやりたいこと',
      child: OheyThemedPanel(
        accentColor: const Color(0xFFC08BFF),
        backgroundColor: AppColors.darkBackground,
        borderRadius: 0,
        border: OheyThemedPanelBorder.horizontal,
        borderWidth: 0,
        borderAlpha: 0,
        glowAlpha: 0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (place.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _ProfileWishMetaChip(
                        icon: CupertinoIcons.location_fill,
                        label: place,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    wish.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.55,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      OheyPostActionPill(
                        semanticLabel: 'このやりたいことからゆるぼを作る',
                        icon: CupertinoIcons.plus,
                        label: 'ゆるぼを作る',
                        color: const Color(0xFFC08BFF),
                        isWhite: false,
                        onTap: onYurubo,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const _ProfileWishBlockUnderline(),
          ],
        ),
      ),
    );
  }
}

class _ProfileWishMetaChip extends StatelessWidget {
  const _ProfileWishMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFC08BFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileWishBlockUnderline extends StatelessWidget {
  const _ProfileWishBlockUnderline();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            color: const Color(0xFFC08BFF).withValues(alpha: .82),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC08BFF).withValues(alpha: .58),
                blurRadius: 9,
                spreadRadius: .4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
