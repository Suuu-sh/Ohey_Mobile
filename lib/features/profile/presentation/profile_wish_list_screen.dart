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
    final isFriends = wish.visibility == 'friends';
    final visibilityLabel = isFriends ? '友達にも見える' : '自分だけのメモ';
    final visibilityIcon = isFriends
        ? CupertinoIcons.person_2_fill
        : CupertinoIcons.lock_fill;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .105),
            Colors.white.withValues(alpha: .055),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .20),
            blurRadius: 24,
            offset: const Offset(0, 14),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE5B7FF), Color(0xFF8F58DD)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC08BFF).withValues(alpha: .28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: Color(0xFF101820),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '誘いの種',
                      style: TextStyle(
                        color: Color(0xFFC08BFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      wish.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.location_solid,
                            color: _ProfileColors.sub,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ProfileColors.sub,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ProfileWishListPill(
                icon: visibilityIcon,
                label: visibilityLabel,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '内容はあとで編集できます',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: _ProfileColors.sub,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Ohey3DButton(
            label: 'この内容でゆるぼを作る',
            icon: CupertinoIcons.plus_bubble_fill,
            onTap: onYurubo,
            height: 48,
            radius: 21,
            color: const Color(0xFFC08BFF),
            foregroundColor: const Color(0xFF101820),
            shadowColor: const Color(0xFF7F51C9),
            fontSize: 13,
          ),
        ],
      ),
    );
  }
}

class _ProfileWishListPill extends StatelessWidget {
  const _ProfileWishListPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _ProfileColors.sub, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _ProfileColors.sub,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
