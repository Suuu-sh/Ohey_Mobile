part of 'home_screen.dart';

const _oheyYuruboAdNativeFactoryId = 'ohey_yurubo_native_ad';
const _oheyYuruboAdFrequency = 8;
const _oheyYuruboFirstAdAfter = 3;

String get _oheyYuruboNativeAdUnitId {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return 'ca-app-pub-3940256099942544/3986624511';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'ca-app-pub-3940256099942544/2247696110';
  }
  return '';
}

List<_FeedEntry> _feedEntriesFromItems(List<_FeedItem> items) {
  if (items.length < _oheyYuruboFirstAdAfter) {
    return [for (final item in items) _YuruboFeedEntry(item)];
  }

  final entries = <_FeedEntry>[];
  var adIndex = 0;
  for (var index = 0; index < items.length; index++) {
    entries.add(_YuruboFeedEntry(items[index]));
    final position = index + 1;
    final shouldInsertAd =
        position == _oheyYuruboFirstAdAfter ||
        (position > _oheyYuruboFirstAdAfter &&
            (position - _oheyYuruboFirstAdAfter) % _oheyYuruboAdFrequency == 0);
    if (shouldInsertAd) {
      entries.add(_YuruboAdFeedEntry(adIndex++));
    }
  }
  return entries;
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

  void _loadAd() {
    final adUnitId = _oheyYuruboNativeAdUnitId;
    if (adUnitId.isEmpty) {
      _didFail = true;
      return;
    }

    final ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: _oheyYuruboAdNativeFactoryId,
      request: const AdRequest(),
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
      return _YuruboAdPlaceholder(isWhite: widget.isWhite);
    }
    return Semantics(
      label: '広告',
      child: _YuruboAdCardFrame(child: AdWidget(ad: _ad!)),
    );
  }
}

class _YuruboAdCardFrame extends StatelessWidget {
  const _YuruboAdCardFrame({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 156,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          clipBehavior: Clip.antiAlias,
          padding: padding,
          decoration: _feedCardDecoration(radius: 30),
          child: child,
        ),
        const SizedBox(height: 18),
        const _YuruboAdGlowBlock(),
      ],
    );
  }
}

class _YuruboAdPlaceholder extends StatelessWidget {
  const _YuruboAdPlaceholder({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return _YuruboAdCardFrame(
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

class _YuruboAdGlowBlock extends StatelessWidget {
  const _YuruboAdGlowBlock();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.cFFC08BFF.withValues(alpha: .82),
          boxShadow: [
            BoxShadow(
              color: AppColors.cFFC08BFF.withValues(alpha: .58),
              blurRadius: 9,
              spreadRadius: .4,
            ),
          ],
        ),
      ),
    );
  }
}
