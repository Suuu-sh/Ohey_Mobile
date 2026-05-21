import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';

class PhotoArchivePreview extends StatelessWidget {
  const PhotoArchivePreview({
    super.key,
    required this.logs,
    required this.isWhite,
    required this.onTap,
  });

  final List<DrinkLog> logs;
  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedPhotoLogs(logs);
    final memoryLog = _randomMemoryLog(sorted);
    final previewLogs = _archivePreviewLogs(sorted);
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subColor = isWhite
        ? const Color(0xFF7A8490)
        : Colors.white.withValues(alpha: .66);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isWhite
                ? const [Color(0xFFFFFFFF), Color(0xFFF2F7FB)]
                : const [Color(0xFF15273C), Color(0xFF0E1825)],
          ),
          border: Border.all(
            color: isWhite
                ? const Color(0xFFE1E8EF)
                : Colors.white.withValues(alpha: .09),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isWhite ? .07 : .22),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6FA8), Color(0xFFFFC46B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6FA8).withValues(alpha: .30),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const NomoGeneratedIcon(
                    CupertinoIcons.photo_on_rectangle,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'フォトアーカイブ',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.3,
                            ),
                      ),
                      Text(
                        memoryLog == null
                            ? '自分の投稿写真をおしゃれに見返す'
                            : '${_memoryAgoLabel(memoryLog.date)}の思い出',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: subColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '開く',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFFF6FA8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                const NomoGeneratedIcon(
                  CupertinoIcons.chevron_forward,
                  color: Color(0xFFFF6FA8),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (sorted.isEmpty)
              _ArchiveEmptyPreview(isWhite: isWhite)
            else
              _ArchivePreviewCollage(
                logs: previewLogs,
                totalCount: sorted.length,
              ),
          ],
        ),
      ),
    );
  }
}

class PhotoArchiveScreen extends StatelessWidget {
  const PhotoArchiveScreen({super.key, required this.logs});

  final List<DrinkLog> logs;

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedPhotoLogs(logs);
    final memoryLog = _randomMemoryLog(sorted);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final background = isWhite
        ? const Color(0xFFF7F9FC)
        : AppColors.darkBackgroundBottom;

    return Scaffold(
      backgroundColor: background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWhite
                ? const [Colors.white, Color(0xFFF7F9FC)]
                : AppColors.darkBackgroundGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  NomoPageHeader.horizontalPadding,
                  NomoPageHeader.topPadding,
                  NomoPageHeader.horizontalPadding,
                  0,
                ),
                child: NomoPageHeader(
                  title: 'アーカイブ',
                  trailing: NomoHeaderIconButton(
                    icon: CupertinoIcons.xmark,
                    color: isWhite ? const Color(0xFF101820) : Colors.white,
                    semanticLabel: '閉じる',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
                child: sorted.isEmpty
                    ? _ArchiveEmptyState(isWhite: isWhite)
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                            sliver: SliverToBoxAdapter(
                              child: _ArchiveHeroCard(
                                log: memoryLog ?? sorted.first,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(22, 0, 22, 130),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: .78,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _ArchiveGridTile(
                                  log: sorted[index],
                                  index: index,
                                  onTap: () => _showArchiveDetail(
                                    context,
                                    sorted[index],
                                  ),
                                ),
                                childCount: sorted.length,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArchiveDetail(BuildContext context, DrinkLog log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ArchiveDetailSheet(log: log),
    );
  }
}

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

class _ArchiveDetailSheet extends StatelessWidget {
  const _ArchiveDetailSheet({required this.log});

  final DrinkLog log;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subColor = isWhite
        ? const Color(0xFF7A8490)
        : Colors.white.withValues(alpha: .68);
    final comment = log.memo.trim();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : const Color(0xFF101B28),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          border: Border.all(
            color: isWhite
                ? const Color(0xFFE1E8EF)
                : Colors.white.withValues(alpha: .08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: subColor.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _ArchivePhotoFrame(
                log: log,
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _archiveTitle(log),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _archiveDate(log.date),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: subColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (log.friendNames.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _ArchiveInfoPill(
                icon: CupertinoIcons.person_2_fill,
                text: log.friendNames.trim(),
              ),
            ],
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                comment,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: titleColor.withValues(alpha: .88),
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArchiveInfoPill extends StatelessWidget {
  const _ArchiveInfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF26D9C7).withValues(alpha: .14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NomoGeneratedIcon(icon, color: const Color(0xFF26D9C7), size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF26D9C7),
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

class _ArchivePhotoFrame extends StatelessWidget {
  const _ArchivePhotoFrame({
    required this.log,
    required this.borderRadius,
    this.overlay,
  });

  final DrinkLog log;
  final BorderRadius borderRadius;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final provider = _imageProviderFor(log.photoAssetPath);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (provider == null)
            const _ArchivePhotoPlaceholder()
          else
            Image(
              image: provider,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  const _ArchivePhotoPlaceholder(),
            ),
          ?overlay,
        ],
      ),
    );
  }
}

class _ArchivePhotoPlaceholder extends StatelessWidget {
  const _ArchivePhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182B44), Color(0xFF44203A)],
        ),
      ),
      child: const Center(
        child: NomoGeneratedIcon(
          CupertinoIcons.photo_fill_on_rectangle_fill,
          color: Colors.white70,
          size: 32,
        ),
      ),
    );
  }
}

class _ArchiveEmptyPreview extends StatelessWidget {
  const _ArchiveEmptyPreview({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFE4E9EF)
              : Colors.white.withValues(alpha: .08),
        ),
        gradient: LinearGradient(
          colors: isWhite
              ? const [Color(0xFFF9FBFD), Color(0xFFF1F5F9)]
              : const [Color(0xFF102033), Color(0xFF111724)],
        ),
      ),
      child: Text(
        '写真付きで投稿するとここに並びます',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: isWhite ? const Color(0xFF7A8490) : Colors.white60,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ArchiveEmptyState extends StatelessWidget {
  const _ArchiveEmptyState({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subColor = isWhite ? const Color(0xFF7A8490) : Colors.white60;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6FA8), Color(0xFFFFC46B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6FA8).withValues(alpha: .24),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const NomoGeneratedIcon(
                CupertinoIcons.photo_on_rectangle,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'まだ写真がありません',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '写真付きで飲みログを投稿すると、インスタのアーカイブみたいにここで見返せます。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: subColor,
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<DrinkLog> _archivePreviewLogs(List<DrinkLog> sorted) {
  final memoryLog = _randomMemoryLog(sorted);
  if (memoryLog == null) return const <DrinkLog>[];
  final rest = sorted.where((log) => log.id != memoryLog.id).take(2);
  return [memoryLog, ...rest];
}

DrinkLog? _randomMemoryLog(List<DrinkLog> sorted) {
  if (sorted.isEmpty) return null;
  if (sorted.length == 1) return sorted.first;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final olderLogs = sorted
      .where(
        (log) => DateTime(
          log.date.year,
          log.date.month,
          log.date.day,
        ).isBefore(today),
      )
      .toList(growable: false);
  final pool = olderLogs.isEmpty ? sorted : olderLogs;
  final seed = today.year * 10000 + today.month * 100 + today.day + pool.length;
  return pool[seed % pool.length];
}

String _memoryAgoLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return '今日';
  if (days == 1) return '昨日';
  if (days < 30) return '$days日前';
  if (days < 365) {
    final months = (days / 30).floor().clamp(1, 11);
    return '$monthsか月前';
  }
  final years = (days / 365).floor();
  return '$years年前';
}

List<DrinkLog> _sortedPhotoLogs(List<DrinkLog> logs) {
  final sorted = logs.where(_hasDisplayablePhoto).toList(growable: false);
  return [...sorted]..sort((a, b) => b.date.compareTo(a.date));
}

bool _hasDisplayablePhoto(DrinkLog log) {
  final path = log.photoAssetPath?.trim();
  return path != null && path.isNotEmpty;
}

ImageProvider? _imageProviderFor(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return NetworkImage(normalized);
  }
  if (normalized.startsWith('/')) {
    final file = File(normalized);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }
  if (normalized.startsWith('assets/')) return AssetImage(normalized);
  return null;
}

String _archiveTitle(DrinkLog log) {
  final place = log.place.trim();
  if (place.isNotEmpty) return place;
  final memo = log.memo.trim();
  if (memo.isNotEmpty) return memo;
  return '飲みログ';
}

String _archiveDate(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

String _shortArchiveDate(DateTime date) => '${date.month}/${date.day}';
