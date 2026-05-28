part of 'add_memory_screen.dart';

class _PlaceSearchScreen extends ConsumerStatefulWidget {
  const _PlaceSearchScreen({required this.initialQuery});

  final String initialQuery;

  @override
  ConsumerState<_PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends ConsumerState<_PlaceSearchScreen> {
  late final TextEditingController _queryController;
  Timer? _debounce;
  List<OheyPlaceSearchResult> _places = const [];
  String? _errorMessage;
  bool _isLoading = false;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery.trim());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search(_queryController.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _scheduleSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), () => _search(query));
  }

  Future<void> _search(String query) async {
    final generation = ++_searchGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final places = await ref
          .read(oheyPlaceSearchServiceProvider)
          .searchNearby(query: query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _places = const [];
        _isLoading = false;
        _errorMessage = _placeSearchErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _AddMemoryColors.pageBackgroundFor(context),
      body: DecoratedBox(
        decoration: _AddMemoryColors.pageDecorationFor(context),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: _PlaceSearchHeader(
                  onClose: () => Navigator.of(context).maybePop(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _PlaceSearchInput(
                  controller: _queryController,
                  isLoading: _isLoading,
                  onChanged: _scheduleSearch,
                  onSubmitted: _search,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _PlaceSearchQuickChips(
                  onSelected: (query) {
                    _queryController.text = query;
                    _queryController.selection = TextSelection.collapsed(
                      offset: query.length,
                    );
                    _search(query);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _places.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_errorMessage != null) {
      return _PlaceSearchMessage(
        icon: CupertinoIcons.location_slash_fill,
        title: 'お店を検索できませんでした',
        message: _errorMessage!,
        actionLabel: 'もう一度探す',
        onAction: () => _search(_queryController.text),
      );
    }
    if (_places.isEmpty) {
      return const _PlaceSearchMessage(
        icon: CupertinoIcons.map_fill,
        title: '近くのお店が見つかりません',
        message: '店名や「居酒屋」「バー」などで検索してみてください。',
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      itemCount: _places.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _PlaceSearchTile(
        place: _places[index],
        onTap: () => Navigator.of(context).pop(_places[index]),
      ),
    );
  }
}

class _PlaceSearchHeader extends StatelessWidget {
  const _PlaceSearchHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final titleColor = _AddMemoryColors.primaryTextFor(context);
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _AddMemoryColors.surfaceFor(context),
              shape: BoxShape.circle,
              border: Border.all(color: _AddMemoryColors.lineFor(context)),
            ),
            child: Center(
              child: OheyGeneratedIcon(
                CupertinoIcons.chevron_left,
                color: titleColor,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '場所を検索',
          style: TextStyle(
            color: titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
      ],
    );
  }
}

class _PlaceSearchInput extends StatelessWidget {
  const _PlaceSearchInput({
    required this.controller,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => _DarkShell(
    padding: const EdgeInsets.fromLTRB(15, 12, 12, 12),
    child: Row(
      children: [
        const OheyPopIcon(
          icon: CupertinoIcons.search,
          color: _AddMemoryColors.placeIcon,
          size: 32,
          iconSize: 18,
          shadow: false,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              counterText: '',
              hintText: '店名・居酒屋・バーなど',
              hintStyle: TextStyle(
                color: _AddMemoryColors.secondaryTextFor(context),
                fontWeight: FontWeight.w800,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              color: _AddMemoryColors.primaryTextFor(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (isLoading)
          const CupertinoActivityIndicator(radius: 10)
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSubmitted(controller.text),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: OheyGeneratedIcon(
                CupertinoIcons.arrow_clockwise,
                color: _AddMemoryColors.placeIcon,
                size: 20,
              ),
            ),
          ),
      ],
    ),
  );
}

class _PlaceSearchQuickChips extends StatelessWidget {
  const _PlaceSearchQuickChips({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const queries = ['居酒屋', 'バー', '焼き鳥', 'レストラン'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final query in queries) ...[
            GestureDetector(
              onTap: () => onSelected(query),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _AddMemoryColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _AddMemoryColors.lineFor(context)),
                ),
                child: Text(
                  query,
                  style: TextStyle(
                    color: _AddMemoryColors.primaryTextFor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PlaceSearchTile extends StatelessWidget {
  const _PlaceSearchTile({required this.place, required this.onTap});

  final OheyPlaceSearchResult place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (place.subtitle.isNotEmpty) place.subtitle,
      _formatPlaceDistance(place.distanceMeters),
    ];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _DarkShell(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        child: Row(
          children: [
            const OheyPopIcon(
              icon: CupertinoIcons.location_solid,
              color: _AddMemoryColors.placeIcon,
              size: 40,
              iconSize: 22,
              shadow: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _AddMemoryColors.primaryTextFor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleParts.join(' ・ '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _AddMemoryColors.secondaryTextFor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OheyGeneratedIcon(
              CupertinoIcons.chevron_right,
              color: _AddMemoryColors.secondaryTextFor(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceSearchMessage extends StatelessWidget {
  const _PlaceSearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 44, 28, 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OheyPopIcon(
          icon: icon,
          color: _AddMemoryColors.placeIcon,
          size: 62,
          iconSize: 34,
          shadow: false,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _AddMemoryColors.primaryTextFor(context),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _AddMemoryColors.secondaryTextFor(context),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.45,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _AddMemoryColors.placeIcon.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _AddMemoryColors.placeIcon.withValues(alpha: .30),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: _AddMemoryColors.placeIcon,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

String _formatPlaceDistance(double meters) {
  if (meters <= 0) return '現在地周辺';
  if (meters < 1000) return '${meters.round()}m';
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)}km';
}

String _placeSearchErrorMessage(Object error) {
  if (error is PlatformException) {
    return switch (error.code) {
      'permission_denied' => '設定アプリで位置情報を許可してね。',
      'location_unavailable' => '現在地を取れなかったよ。あとで試してね。',
      'not_available' => 'この端末では現在地からのお店検索を利用できません。',
      _ => error.message ?? '位置情報からお店を検索できませんでした。',
    };
  }
  return '位置情報からお店を検索できませんでした。';
}
