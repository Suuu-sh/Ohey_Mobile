import '../../../core/models/drink_log.dart';

const drinkLogDailyLimitAlertMessage = '投稿は1日1回までです。別の日の思い出を残してね。';

bool hasOwnDrinkLogOnDay(
  Iterable<DrinkLog> logs,
  DateTime day, {
  required String? currentUserId,
}) {
  return logs.any(
    (log) => isOwnDrinkLogOnDay(log, day, currentUserId: currentUserId),
  );
}

bool isOwnDrinkLogOnDay(
  DrinkLog log,
  DateTime day, {
  required String? currentUserId,
}) {
  final userId = currentUserId?.trim();
  if (userId == null || userId.isEmpty) return false;
  if (log.isOfficial || log.ownerUserId != userId) return false;
  return isSameLocalDate(log.date, day);
}

bool isSameLocalDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String drinkLogDailyLimitAlertTitle({
  required DateTime day,
  required DateTime now,
}) {
  if (isSameLocalDate(day, now)) return '今日はもう投稿済みです';
  return '${day.month}/${day.day}はもう投稿済みです';
}

String drinkLogLocalDateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
