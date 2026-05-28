import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/core/models/memory.dart';
import 'package:tomo/features/memories/application/memory_daily_limit.dart';

void main() {
  test(
    'daily limit detects only the current user non-official memory for the day',
    () {
      final memories = [
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
        hasOwnMemoryOnDay(
          memories,
          DateTime(2026, 5, 24, 9),
          currentUserId: 'me',
        ),
        isTrue,
      );
      expect(
        hasOwnMemoryOnDay(
          memories,
          DateTime(2026, 5, 25, 9),
          currentUserId: 'me',
        ),
        isFalse,
      );
      expect(
        hasOwnMemoryOnDay(
          memories,
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
      memoryDailyLimitAlertTitle(day: DateTime(2026, 5, 24, 21), now: now),
      '今日はもう投稿済みです',
    );
    expect(
      memoryDailyLimitAlertTitle(day: DateTime(2026, 5, 23, 21), now: now),
      '5/23はもう投稿済みです',
    );
  });

  test('memoryLocalDateKey formats a zero-padded local date', () {
    expect(memoryLocalDateKey(DateTime(2026, 5, 4, 23)), '2026-05-04');
  });
}

Memory _log({
  required String id,
  required String ownerUserId,
  required DateTime date,
  bool isOfficial = false,
}) {
  return Memory(
    id: id,
    date: date,
    friends: const [],
    place: '',
    memo: '',
    ownerUserId: ownerUserId,
    isOfficial: isOfficial,
  );
}
