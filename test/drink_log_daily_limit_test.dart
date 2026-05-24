import 'package:flutter_test/flutter_test.dart';
import 'package:nomo/core/models/drink_log.dart';
import 'package:nomo/features/logs/application/drink_log_daily_limit.dart';

void main() {
  test(
    'daily limit detects only the current user non-official log for the day',
    () {
      final logs = [
        _log(
          id: 'mine-today',
          ownerUserId: 'me',
          date: DateTime(2026, 5, 24, 21),
        ),
        _log(
          id: 'friend-today',
          ownerUserId: 'friend',
          date: DateTime(2026, 5, 24, 20),
        ),
        _log(
          id: 'official-today',
          ownerUserId: 'me',
          date: DateTime(2026, 5, 24, 19),
          isOfficial: true,
        ),
      ];

      expect(
        hasOwnDrinkLogOnDay(
          logs,
          DateTime(2026, 5, 24, 9),
          currentUserId: 'me',
        ),
        isTrue,
      );
      expect(
        hasOwnDrinkLogOnDay(
          logs,
          DateTime(2026, 5, 25, 9),
          currentUserId: 'me',
        ),
        isFalse,
      );
      expect(
        hasOwnDrinkLogOnDay(
          logs,
          DateTime(2026, 5, 24, 9),
          currentUserId: 'friend',
        ),
        isTrue,
      );
    },
  );

  test('daily limit alert title switches for today and another day', () {
    final now = DateTime(2026, 5, 24, 12);

    expect(
      drinkLogDailyLimitAlertTitle(day: DateTime(2026, 5, 24, 21), now: now),
      '今日はもう投稿済みです',
    );
    expect(
      drinkLogDailyLimitAlertTitle(day: DateTime(2026, 5, 23, 21), now: now),
      '5/23はもう投稿済みです',
    );
  });

  test('drinkLogLocalDateKey formats a zero-padded local date', () {
    expect(drinkLogLocalDateKey(DateTime(2026, 5, 4, 23)), '2026-05-04');
  });
}

DrinkLog _log({
  required String id,
  required String ownerUserId,
  required DateTime date,
  bool isOfficial = false,
}) {
  return DrinkLog(
    id: id,
    date: date,
    friends: const [],
    place: '',
    memo: '',
    ownerUserId: ownerUserId,
    isOfficial: isOfficial,
  );
}
