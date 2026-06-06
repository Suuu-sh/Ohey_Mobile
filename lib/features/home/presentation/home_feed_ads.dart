part of 'home_screen.dart';

const _oheyYuruboAdNativeFactoryId = 'ohey_yurubo_native_ad';
String get _oheyYuruboNativeAdUnitId => OheyAdsConfig.nativeAdUnitId;

List<_FeedEntry> _feedEntriesFromItems(
  List<_FeedItem> items, {
  required bool includeAds,
}) {
  if (!includeAds) {
    return [for (final item in items) _YuruboFeedEntry(item)];
  }

  return buildOheyAdEntries<_FeedItem, _FeedEntry>(
    items: items,
    itemEntryBuilder: _YuruboFeedEntry.new,
    adEntryBuilder: _YuruboAdFeedEntry.new,
  );
}

sealed class _FeedEntry {
  const _FeedEntry();
}

class _YuruboFeedEntry extends _FeedEntry {
  const _YuruboFeedEntry(this.item);

  final _FeedItem item;
}

class _YuruboAdFeedEntry extends _FeedEntry {
  const _YuruboAdFeedEntry(this.index);

  final int index;
}

class _YuruboNativeAdListItem extends StatefulWidget {
  const _YuruboNativeAdListItem({required this.index, required this.isWhite});

  final int index;
  final bool isWhite;

  @override
  State<_YuruboNativeAdListItem> createState() =>
      _YuruboNativeAdListItemState();
}

class _YuruboNativeAdListItemState extends State<_YuruboNativeAdListItem> {
  NativeAd? _ad;
  bool _isLoaded = false;
  bool _didFail = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adUnitId = _oheyYuruboNativeAdUnitId;
    if (adUnitId.isEmpty) {
      _didFail = true;
      return;
    }

    final canRequestAds = await OheyAdsConsentService.prepareToRequestAds();
    if (!mounted) return;
    if (!canRequestAds) {
      setState(() => _didFail = true);
      return;
    }

    final ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: _oheyYuruboAdNativeFactoryId,
      request: const AdRequest(),
      customOptions: const {'style': 'feed_block'},
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as NativeAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _didFail = true);
        },
      ),
    );
    ad.load().catchError((_) {
      if (!mounted) return;
      setState(() => _didFail = true);
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_didFail) return const SizedBox.shrink();
    if (!_isLoaded || _ad == null) {
      return _YuruboAdListBlock(
        isWhite: widget.isWhite,
        child: _YuruboAdPlaceholder(isWhite: widget.isWhite),
      );
    }
    return _YuruboAdListBlock(
      isWhite: widget.isWhite,
      child: Semantics(
        label: '広告',
        child: _YuruboAdCardFrame(
          isWhite: widget.isWhite,
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}

class _YuruboAdListBlock extends StatelessWidget {
  const _YuruboAdListBlock({required this.child, required this.isWhite});

  final Widget child;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 16),
        _YuruboAdPostSeparator(isWhite: isWhite),
      ],
    );
  }
}

class _YuruboAdPostSeparator extends StatelessWidget {
  const _YuruboAdPostSeparator({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final alpha = isWhite ? .42 : .76;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IgnorePointer(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            color: AppColors.cFFC08BFF.withValues(alpha: alpha),
            boxShadow: [
              BoxShadow(
                color: AppColors.cFFC08BFF.withValues(alpha: alpha * .62),
                blurRadius: 9,
                spreadRadius: .35,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YuruboAdCardFrame extends StatelessWidget {
  const _YuruboAdCardFrame({
    required this.child,
    required this.isWhite,
    this.padding,
  });

  final Widget child;
  final bool isWhite;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = OheyThemedPanel.surfaceColor(isWhite: isWhite);
    final radius = BorderRadius.circular(30);
    final frameColor = _FeedColors.teal.withValues(alpha: isWhite ? .28 : .46);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: _FeedColors.teal.withValues(alpha: isWhite ? .06 : .13),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 156,
              child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: frameColor, width: 1.2),
                  ),
                ),
              ),
            ),
            const _YuruboBlockGlowUnderline(),
          ],
        ),
      ),
    );
  }
}

class _YuruboAdPlaceholder extends StatelessWidget {
  const _YuruboAdPlaceholder({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return _YuruboAdCardFrame(
      isWhite: isWhite,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.white.withValues(alpha: .14)),
            ),
            child: Text(
              'PR',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: .76),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          FractionallySizedBox(
            widthFactor: .72,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
