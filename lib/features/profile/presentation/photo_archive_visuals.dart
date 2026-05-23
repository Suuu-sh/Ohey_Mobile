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

class _ArchiveHeroCard extends StatelessWidget {
  const _ArchiveHeroCard({required this.log});

  final DrinkLog log;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 292,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .13 : .34),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: _ArchivePhotoFrame(
        log: log,
        borderRadius: BorderRadius.circular(34),
        overlay: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: .08),
                Colors.black.withValues(alpha: .68),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .25),
                    ),
                  ),
                  child: Text(
                    '${_memoryAgoLabel(log.date)}の思い出',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _archiveTitle(log),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _archiveDate(log.date),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: .84),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveGridTile extends StatelessWidget {
  const _ArchiveGridTile({
    required this.log,
    required this.index,
    required this.onTap,
  });

  final DrinkLog log;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: _ArchivePhotoFrame(
              log: log,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Positioned(
            left: 7,
            right: 7,
            bottom: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .44),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _shortArchiveDate(log.date),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
