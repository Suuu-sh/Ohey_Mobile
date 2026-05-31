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
        '最初の1枚、待ってるよ',
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
  Widget build(BuildContext context) => OheyEmptyState(
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
      child: const OheyGeneratedIcon(
        CupertinoIcons.photo_on_rectangle,
        color: Colors.white,
        size: 42,
      ),
    ),
    title: 'ゆるぼアルバムを育てよう',
    message: '写真のゆるぼが増えたら、ここがアルバムになるよ。',
    titleColor: isWhite ? const Color(0xFF101820) : Colors.white,
    messageColor: isWhite ? const Color(0xFF7A8490) : Colors.white60,
    padding: const EdgeInsets.symmetric(horizontal: 30),
  );
}

List<Memory> _archivePreviewMemories(List<Memory> sorted) {
  final featuredMemory = _randomFeaturedMemory(sorted);
  if (featuredMemory == null) return const <Memory>[];
  final rest = sorted.where((memory) => memory.id != featuredMemory.id).take(2);
  return [featuredMemory, ...rest];
}

Memory? _randomFeaturedMemory(List<Memory> sorted) {
  if (sorted.isEmpty) return null;
  if (sorted.length == 1) return sorted.first;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final olderMemories = sorted
      .where(
        (memory) => DateTime(
          memory.date.year,
          memory.date.month,
          memory.date.day,
        ).isBefore(today),
      )
      .toList(growable: false);
  final pool = olderMemories.isEmpty ? sorted : olderMemories;
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

List<Memory> _sortedPhotoMemories(List<Memory> memories) {
  final sorted = memories.where(_hasDisplayablePhoto).toList(growable: false);
  return [...sorted]..sort((a, b) => b.date.compareTo(a.date));
}

bool _hasDisplayablePhoto(Memory memory) {
  final path = memory.photoAssetPath?.trim();
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

String _archiveTitle(Memory memory) {
  final place = memory.place.trim();
  if (place.isNotEmpty) return place;
  final memo = memory.memo.trim();
  if (memo.isNotEmpty) return memo;
  return 'ゆるぼ';
}

String _archiveDate(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
