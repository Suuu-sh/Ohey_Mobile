import '../../../core/models/memory.dart';

const memoryDailyLimitAlertMessage = '投稿は1日1つまでです。別の日の思い出を残してね。';

bool hasOwnMemoryOnDay(
  Iterable<Memory> memories,
  DateTime day, {
  required String? currentUserId,
}) {
  return memories.any(
    (memory) => isOwnMemoryOnDay(memory, day, currentUserId: currentUserId),
  );
}

bool isOwnMemoryOnDay(
  Memory memory,
  DateTime day, {
  required String? currentUserId,
}) {
  final userId = currentUserId?.trim();
  if (userId == null || userId.isEmpty) return false;
  if (memory.isOfficial || memory.ownerUserId != userId) return false;
  return isSameLocalDate(memory.date, day);
}

bool isSameLocalDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String memoryDailyLimitAlertTitle({
  required DateTime day,
  required DateTime now,
}) {
  if (isSameLocalDate(day, now)) return '今日はもう投稿済みです';
  return '${day.month}/${day.day}はもう投稿済みです';
}

String memoryLocalDateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
