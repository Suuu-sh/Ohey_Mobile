part of 'photo_archive_screen.dart';

class _ArchivePreviewCollage extends StatelessWidget {
  const _ArchivePreviewCollage({required this.logs, required this.totalCount});

  final List<DrinkLog> logs;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final first = logs.first;
    final second = logs.length > 1 ? logs[1] : null;
    final third = logs.length > 2 ? logs[2] : null;

    if (logs.length == 1) {
      return SizedBox(
        height: 174,
        child: _ArchivePhotoFrame(
          log: first,
          borderRadius: BorderRadius.circular(24),
          overlay: _PreviewOverlay(log: first),
        ),
      );
    }

    return SizedBox(
      height: 174,
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: _ArchivePhotoFrame(
              log: first,
              borderRadius: BorderRadius.circular(24),
              overlay: _PreviewOverlay(log: first),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: logs.length == 2
                ? _ArchivePhotoFrame(
                    log: second!,
                    borderRadius: BorderRadius.circular(20),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: _ArchivePhotoFrame(
                          log: second!,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _ArchivePhotoFrame(
                          log: third!,
                          borderRadius: BorderRadius.circular(20),
                          overlay: totalCount > 3
                              ? Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: .36),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '+${totalCount - 3}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                )
                              : null,
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

class _PreviewOverlay extends StatelessWidget {
  const _PreviewOverlay({required this.log});

  final DrinkLog log;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: .58)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _archiveTitle(log),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_memoryAgoLabel(log.date)}の思い出',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: .82),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveViewModeSelector extends StatelessWidget {
  const _ArchiveViewModeSelector({
    required this.value,
    required this.isWhite,
    required this.onChanged,
  });

  final _ArchiveViewMode value;
  final bool isWhite;
  final ValueChanged<_ArchiveViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isWhite
            ? Colors.white.withValues(alpha: .86)
            : Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isWhite
              ? Colors.black.withValues(alpha: .06)
              : Colors.white.withValues(alpha: .10),
        ),
      ),
      child: Row(
        children: [
          _ArchiveViewModeButton(
            icon: CupertinoIcons.square_grid_2x2_fill,
            label: '写真',
            selected: value == _ArchiveViewMode.grid,
            onTap: () => onChanged(_ArchiveViewMode.grid),
          ),
          _ArchiveViewModeButton(
            icon: CupertinoIcons.map_pin_ellipse,
            label: '場所',
            selected: value == _ArchiveViewMode.places,
            onTap: () => onChanged(_ArchiveViewMode.places),
          ),
        ],
      ),
    );
  }
}

class _ArchiveViewModeButton extends StatelessWidget {
  const _ArchiveViewModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryAction : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryAction.withValues(alpha: .30),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NomoGeneratedIcon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : CupertinoDynamicColor.resolve(
                        CupertinoColors.secondaryLabel,
                        context,
                      ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? Colors.white
                      : CupertinoDynamicColor.resolve(
                          CupertinoColors.secondaryLabel,
                          context,
                        ),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivePlacesView extends StatelessWidget {
  const _ArchivePlacesView({
    required this.logs,
    required this.isWhite,
    required this.onLogTap,
  });

  final List<DrinkLog> logs;
  final bool isWhite;
  final ValueChanged<DrinkLog> onLogTap;

  @override
  Widget build(BuildContext context) {
    final places = _archivePlaceGroups(logs);
    if (places.isEmpty) {
      return _ArchivePlacesEmpty(isWhite: isWhite);
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 130),
      children: [
        _ArchiveMapCard(
          places: places,
          isWhite: isWhite,
          onPlaceTap: (place) => onLogTap(place.latestLog),
        ),
        const SizedBox(height: 18),
        Text(
          '場所別アーカイブ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: isWhite ? const Color(0xFF101820) : Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        ...places.map(
          (place) => _ArchivePlaceTile(
            place: place,
            isWhite: isWhite,
            onTap: () => onLogTap(place.latestLog),
          ),
        ),
      ],
    );
  }
}

class _ArchiveMapCard extends StatelessWidget {
  const _ArchiveMapCard({
    required this.places,
    required this.isWhite,
    required this.onPlaceTap,
  });

  final List<_ArchivePlaceGroup> places;
  final bool isWhite;
  final ValueChanged<_ArchivePlaceGroup> onPlaceTap;

  @override
  Widget build(BuildContext context) {
    final visible = places.take(8).toList(growable: false);
    return Container(
      height: 430,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .16 : .40),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (Platform.isIOS && _archiveMapAnnotations(visible).isNotEmpty)
              _ArchiveAppleMap(places: visible)
            else
              const _ArchiveStylizedMapBackground(),
            if (!(Platform.isIOS && _archiveMapAnnotations(visible).isNotEmpty))
              for (var i = 0; i < visible.length; i++)
                _ArchiveMapPin(
                  place: visible[i],
                  alignment: _archivePinAlignment(visible[i].name, i),
                  onTap: () => onPlaceTap(visible[i]),
                ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '場所をタップして、その場所の思い出へ',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: .88),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .42),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .15),
                      ),
                    ),
                    child: const Center(
                      child: NomoGeneratedIcon(
                        CupertinoIcons.location_fill,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveAppleMap extends StatelessWidget {
  const _ArchiveAppleMap({required this.places});

  final List<_ArchivePlaceGroup> places;

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'nomo/archive_map',
      creationParams: {'annotations': _archiveMapAnnotations(places)},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

List<Map<String, Object?>> _archiveMapAnnotations(
  List<_ArchivePlaceGroup> places,
) {
  return places
      .where((place) => place.latestLog.hasPlaceCoordinate)
      .map(
        (place) => <String, Object?>{
          'title': place.name,
          'count': place.logs.length,
          'latitude': place.latestLog.placeLatitude,
          'longitude': place.latestLog.placeLongitude,
        },
      )
      .toList(growable: false);
}

class _ArchiveStylizedMapBackground extends StatelessWidget {
  const _ArchiveStylizedMapBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ArchiveMapPainter());
  }
}

class _ArchiveMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sea = Paint()..color = const Color(0xFF0D2B63).withValues(alpha: .55);
    final land = Paint()
      ..color = const Color(0xFF149178).withValues(alpha: .72);
    final road = Paint()
      ..color = Colors.white.withValues(alpha: .24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(Offset.zero & size, sea);

    Path island(double dx, double dy, double w, double h) => Path()
      ..moveTo(size.width * (dx + w * .18), size.height * dy)
      ..cubicTo(
        size.width * (dx + w * .92),
        size.height * (dy + h * .08),
        size.width * (dx + w * .84),
        size.height * (dy + h * .68),
        size.width * (dx + w * .42),
        size.height * (dy + h),
      )
      ..cubicTo(
        size.width * (dx - w * .04),
        size.height * (dy + h * .74),
        size.width * (dx + w * .02),
        size.height * (dy + h * .22),
        size.width * (dx + w * .18),
        size.height * dy,
      );

    final main = island(.22, .15, .56, .58);
    final west = island(.02, .46, .28, .24);
    final east = island(.68, .05, .24, .34);
    canvas.drawPath(main, land);
    canvas.drawPath(
      west,
      land..color = const Color(0xFF0F806F).withValues(alpha: .72),
    );
    canvas.drawPath(
      east,
      land..color = const Color(0xFF1BA184).withValues(alpha: .66),
    );

    final route = Path()
      ..moveTo(size.width * .10, size.height * .58)
      ..cubicTo(
        size.width * .28,
        size.height * .48,
        size.width * .38,
        size.height * .62,
        size.width * .50,
        size.height * .44,
      )
      ..cubicTo(
        size.width * .62,
        size.height * .26,
        size.width * .71,
        size.height * .34,
        size.width * .82,
        size.height * .18,
      );
    canvas.drawPath(route, road);

    final glow = Paint()
      ..color = const Color(0xFF7DF1FF).withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawPath(route, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArchiveMapPin extends StatelessWidget {
  const _ArchiveMapPin({
    required this.place,
    required this.alignment,
    required this.onTap,
  });

  final _ArchivePlaceGroup place;
  final Alignment alignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .38),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ArchivePhotoFrame(
                    log: place.latestLog,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  if (place.logs.length > 1)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '${place.logs.length}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Container(
              constraints: const BoxConstraints(maxWidth: 112),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .38),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchivePlaceTile extends StatelessWidget {
  const _ArchivePlaceTile({
    required this.place,
    required this.isWhite,
    required this.onTap,
  });

  final _ArchivePlaceGroup place;
  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isWhite ? Colors.white : Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isWhite
                  ? Colors.black.withValues(alpha: .06)
                  : Colors.white.withValues(alpha: .10),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: _ArchivePhotoFrame(
                  log: place.latestLog,
                  borderRadius: BorderRadius.circular(18),
                ),
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isWhite ? const Color(0xFF101820) : Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${place.logs.length}件の思い出 ・ ${_archiveDate(place.latestLog.date)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: CupertinoDynamicColor.resolve(
                          CupertinoColors.secondaryLabel,
                          context,
                        ),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const NomoGeneratedIcon(
                CupertinoIcons.chevron_forward,
                color: AppColors.primaryAction,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivePlacesEmpty extends StatelessWidget {
  const _ArchivePlacesEmpty({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: NomoEmptyState(
          visual: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: isWhite
                  ? AppColors.primaryAction.withValues(alpha: .10)
                  : Colors.white.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: NomoGeneratedIcon(
                CupertinoIcons.map,
                color: AppColors.primaryAction,
                size: 36,
              ),
            ),
          ),
          title: '場所つきの思い出はまだありません',
          message: '飲みログに場所を入れると、ここに地図みたいに並びます。',
        ),
      ),
    );
  }
}

class _ArchivePlaceGroup {
  const _ArchivePlaceGroup({required this.name, required this.logs});

  final String name;
  final List<DrinkLog> logs;

  DrinkLog get latestLog => logs.first;
}

List<_ArchivePlaceGroup> _archivePlaceGroups(List<DrinkLog> logs) {
  final grouped = <String, List<DrinkLog>>{};
  for (final log in logs) {
    final place = log.place.trim();
    if (place.isEmpty) continue;
    grouped.putIfAbsent(place, () => <DrinkLog>[]).add(log);
  }
  final places = grouped.entries
      .map((entry) => _ArchivePlaceGroup(name: entry.key, logs: entry.value))
      .toList();
  places.sort((a, b) {
    final countCompare = b.logs.length.compareTo(a.logs.length);
    if (countCompare != 0) return countCompare;
    return b.latestLog.date.compareTo(a.latestLog.date);
  });
  return places;
}

Alignment _archivePinAlignment(String name, int index) {
  const fallback = [
    Alignment(.52, -.10),
    Alignment(.08, -.42),
    Alignment(-.56, .36),
    Alignment(-.08, .14),
    Alignment(.62, .48),
    Alignment(-.68, -.12),
    Alignment(.30, .66),
    Alignment(-.34, -.66),
  ];
  if (name.isEmpty) return fallback[index % fallback.length];
  final hash = name.codeUnits.fold<int>(0, (value, code) => value + code * 31);
  final radius = .18 + (hash % 54) / 100;
  final angle = ((hash % 360) / 180) * math.pi;
  final x = (math.cos(angle) * radius).clamp(-.72, .72).toDouble();
  final y = (math.sin(angle) * radius * 1.28).clamp(-.72, .72).toDouble();
  return Alignment(x, y);
}

class _ArchiveStoriesView extends StatelessWidget {
  const _ArchiveStoriesView({
    required this.logs,
    required this.memoryLog,
    required this.isWhite,
    required this.onLogTap,
  });

  final List<DrinkLog> logs;
  final DrinkLog? memoryLog;
  final bool isWhite;
  final ValueChanged<DrinkLog> onLogTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1.5,
              mainAxisSpacing: 1.5,
              childAspectRatio: .62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ArchiveStoryTile(
                log: logs[index],
                onTap: () => onLogTap(logs[index]),
              ),
              childCount: logs.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ArchiveMemorySection(
            log: memoryLog ?? logs.first,
            isWhite: isWhite,
            onShare: () => onLogTap(memoryLog ?? logs.first),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 130)),
      ],
    );
  }
}

class _ArchiveStoryTile extends StatelessWidget {
  const _ArchiveStoryTile({required this.log, required this.onTap});

  final DrinkLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayLabel = log.date.day.toString().padLeft(2, '0');
    final monthLabel = '${log.date.month}月';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ArchivePhotoFrame(log: log, borderRadius: BorderRadius.zero),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .28),
                    Colors.transparent,
                    Colors.black.withValues(alpha: .22),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .58),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: .95,
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: .90),
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 7,
            right: 7,
            bottom: 7,
            child: Text(
              _archiveTitle(log),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: .70),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveMemorySection extends StatelessWidget {
  const _ArchiveMemorySection({
    required this.log,
    required this.isWhite,
    required this.onShare,
  });

  final DrinkLog log;
  final bool isWhite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subColor = CupertinoDynamicColor.resolve(
      CupertinoColors.secondaryLabel,
      context,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '思い出',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              NomoHeaderIconButton(
                icon: CupertinoIcons.xmark,
                color: subColor,
                semanticLabel: '思い出を閉じる',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isWhite ? .12 : .30,
                      ),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: _ArchivePhotoFrame(
                  log: log,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '過去のこの日',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_memoryAgoLabel(log.date)}の今日。',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: subColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      color: AppColors.primaryAction,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: onShare,
                      child: Text(
                        'シェア',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
