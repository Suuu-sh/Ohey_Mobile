part of 'photo_archive_screen.dart';

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
  Widget build(BuildContext context) => NomoEmptyState(
    visual: Container(
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
    title: 'まだ写真がありません',
    message: '写真付きの飲みログをここで見返せます。',
    titleColor: isWhite ? const Color(0xFF101820) : Colors.white,
    messageColor: isWhite ? const Color(0xFF7A8490) : Colors.white60,
    padding: const EdgeInsets.symmetric(horizontal: 30),
  );
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
