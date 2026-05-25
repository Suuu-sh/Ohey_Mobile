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

class _ArchiveMapPage extends StatelessWidget {
  const _ArchiveMapPage({
    required this.logs,
    required this.isWhite,
    required this.onLogTap,
  });

  final List<DrinkLog> logs;
  final bool isWhite;
  final ValueChanged<DrinkLog> onLogTap;

  @override
  Widget build(BuildContext context) {
    final mapLogs = logs
        .where((log) => log.place.trim().isNotEmpty || log.hasPlaceCoordinate)
        .toList(growable: false);
    if (mapLogs.isEmpty) {
      return _ArchivePlacesEmpty(isWhite: isWhite);
    }

    if (Platform.isIOS) {
      return _ArchiveAppleMap(
        annotations: _archiveLogMapAnnotations(mapLogs),
        onAnnotationTap: (id) {
          final index = mapLogs.indexWhere((log) => log.id == id);
          if (index >= 0) onLogTap(mapLogs[index]);
        },
      );
    }

    final places = _archivePlaceGroups(mapLogs);
    return Stack(
      fit: StackFit.expand,
      children: [
        const _ArchiveStylizedMapBackground(),
        for (var i = 0; i < places.length; i++)
          _ArchiveMapPin(
            place: places[i],
            alignment: _archivePinAlignment(places[i].name, i),
            onTap: () => onLogTap(places[i].latestLog),
          ),
      ],
    );
  }
}

class _ArchiveAppleMap extends StatelessWidget {
  const _ArchiveAppleMap({required this.annotations, this.onAnnotationTap});

  final List<Map<String, Object?>> annotations;
  final ValueChanged<String>? onAnnotationTap;

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'nomo/archive_map',
      creationParams: {'annotations': annotations},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (id) {
        final handler = onAnnotationTap;
        if (handler == null) return;
        MethodChannel('nomo/archive_map_$id').setMethodCallHandler((
          call,
        ) async {
          if (call.method != 'annotationSelected') return;
          final args = call.arguments;
          if (args is Map) {
            final value = args['id']?.toString();
            if (value != null && value.isNotEmpty) handler(value);
          }
        });
      },
    );
  }
}

List<Map<String, Object?>> _archiveLogMapAnnotations(List<DrinkLog> logs) {
  return logs
      .map(
        (log) => <String, Object?>{
          'id': log.id,
          'title': _archiveTitle(log),
          'subtitle': _archiveDate(log.date),
          'place': log.place.trim(),
          if (log.hasPlaceCoordinate) ...{
            'latitude': log.placeLatitude,
            'longitude': log.placeLongitude,
          },
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
    final background = Paint()..color = const Color(0xFF14233B);
    canvas.drawRect(Offset.zero & size, background);

    final blockPaint = Paint()..color = const Color(0xFF1A2B45);
    final parkPaint = Paint()
      ..color = const Color(0xFF1E6B5D).withValues(alpha: .72);
    final waterPaint = Paint()
      ..color = const Color(0xFF123860).withValues(alpha: .84);
    final minorRoad = Paint()
      ..color = const Color(0xFF7E8EA6).withValues(alpha: .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final mainRoadOuter = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final mainRoadInner = Paint()
      ..color = const Color(0xFFF7F3DA).withValues(alpha: .70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final highway = Paint()
      ..color = const Color(0xFFFFB14A).withValues(alpha: .62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rail = Paint()
      ..color = const Color(0xFF92A1B4).withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    RRect block(double l, double t, double r, double b, [double radius = 18]) =>
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            size.width * l,
            size.height * t,
            size.width * r,
            size.height * b,
          ),
          Radius.circular(radius),
        );

    for (final rect in [
      block(.04, .06, .25, .24),
      block(.28, .04, .54, .20),
      block(.60, .05, .93, .22),
      block(.07, .29, .32, .46),
      block(.38, .27, .61, .43),
      block(.67, .30, .94, .48),
      block(.05, .53, .28, .73),
      block(.35, .55, .57, .72),
      block(.64, .57, .93, .75),
      block(.18, .79, .44, .93),
      block(.51, .80, .82, .94),
    ]) {
      canvas.drawRRect(rect, blockPaint);
    }

    canvas.drawRRect(block(.70, .10, .90, .28, 26), parkPaint);
    canvas.drawRRect(block(.10, .58, .30, .76, 26), parkPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .38, size.height * .32),
        width: size.width * .25,
        height: size.height * .17,
      ),
      parkPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .00, size.height * .18)
        ..cubicTo(
          size.width * .16,
          size.height * .12,
          size.width * .22,
          size.height * .30,
          size.width * .12,
          size.height * .45,
        )
        ..cubicTo(
          size.width * .05,
          size.height * .55,
          size.width * .08,
          size.height * .72,
          size.width * .00,
          size.height * .82,
        )
        ..close(),
      waterPaint,
    );

    Path path(List<Offset> points) {
      final p = Path()
        ..moveTo(size.width * points.first.dx, size.height * points.first.dy);
      for (final point in points.skip(1)) {
        p.lineTo(size.width * point.dx, size.height * point.dy);
      }
      return p;
    }

    final main = Path()
      ..moveTo(size.width * .03, size.height * .72)
      ..cubicTo(
        size.width * .20,
        size.height * .62,
        size.width * .29,
        size.height * .66,
        size.width * .42,
        size.height * .53,
      )
      ..cubicTo(
        size.width * .57,
        size.height * .38,
        size.width * .58,
        size.height * .25,
        size.width * .78,
        size.height * .18,
      )
      ..cubicTo(
        size.width * .87,
        size.height * .15,
        size.width * .91,
        size.height * .11,
        size.width * .98,
        size.height * .06,
      );
    canvas.drawPath(main, mainRoadOuter);
    canvas.drawPath(main, mainRoadInner);

    final diagonal = path([
      const Offset(.02, .28),
      const Offset(.20, .34),
      const Offset(.44, .30),
      const Offset(.68, .42),
      const Offset(.96, .38),
    ]);
    final horizontal = path([
      const Offset(.00, .50),
      const Offset(.18, .50),
      const Offset(.36, .47),
      const Offset(.60, .52),
      const Offset(1.00, .49),
    ]);
    final lower = path([
      const Offset(.12, .90),
      const Offset(.24, .78),
      const Offset(.47, .77),
      const Offset(.72, .69),
      const Offset(.96, .75),
    ]);
    final vertical1 = path([
      const Offset(.33, .00),
      const Offset(.30, .22),
      const Offset(.36, .45),
      const Offset(.32, .70),
      const Offset(.38, 1.00),
    ]);
    final vertical2 = path([
      const Offset(.63, .00),
      const Offset(.66, .20),
      const Offset(.61, .45),
      const Offset(.66, .70),
      const Offset(.62, 1.00),
    ]);
    for (final p in [diagonal, horizontal, lower, vertical1, vertical2]) {
      canvas.drawPath(p, minorRoad);
    }

    final expressway = Path()
      ..moveTo(size.width * .18, size.height * .08)
      ..cubicTo(
        size.width * .36,
        size.height * .16,
        size.width * .44,
        size.height * .18,
        size.width * .55,
        size.height * .09,
      )
      ..cubicTo(
        size.width * .68,
        size.height * -.02,
        size.width * .76,
        size.height * .02,
        size.width * .94,
        size.height * .13,
      );
    canvas.drawPath(expressway, highway);

    final railPath = Path()
      ..moveTo(size.width * .00, size.height * .36)
      ..cubicTo(
        size.width * .20,
        size.height * .24,
        size.width * .39,
        size.height * .42,
        size.width * .55,
        size.height * .33,
      )
      ..cubicTo(
        size.width * .73,
        size.height * .24,
        size.width * .78,
        size.height * .48,
        size.width * 1.00,
        size.height * .30,
      );
    canvas.drawPath(railPath, rail);
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 18; i++) {
      final x = size.width * (i / 17);
      canvas.drawLine(
        Offset(x, size.height * (.35 + math.sin(i * .9) * .04)),
        Offset(x + 7, size.height * (.35 + math.sin(i * .9) * .04)),
        dashPaint,
      );
    }

    void label(String text, double x, double y, {double alpha = .58}) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: alpha),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: -.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(size.width * x, size.height * y));
    }

    label('中央通り', .48, .46, alpha: .64);
    label('Nomo Park', .70, .18, alpha: .50);
    label('Station', .18, .34, alpha: .46);
    label('Cafe area', .62, .63, alpha: .46);
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
          message: '場所つきの思い出、まだないみたい。',
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
