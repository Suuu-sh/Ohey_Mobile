import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_friend.dart';
import '../data/drink_log_repository.dart';

final drinkLogControllerProvider =
    AsyncNotifierProvider<DrinkLogController, List<DrinkLog>>(
      DrinkLogController.new,
    );

final friendsProvider = FutureProvider<List<NomoFriend>>((ref) async {
  return ref.watch(drinkLogRepositoryProvider).fetchFriends();
});

class DrinkLogController extends AsyncNotifier<List<DrinkLog>> {
  @override
  Future<List<DrinkLog>> build() async {
    return ref.watch(drinkLogRepositoryProvider).fetchLogs();
  }

  Future<void> addLog({
    required DateTime date,
    required List<NomoFriend> friends,
    required String place,
    required String memo,
  }) async {
    final repository = ref.read(drinkLogRepositoryProvider);
    final previous = state.asData?.value ?? const <DrinkLog>[];
    final log = DrinkLog(
      id: 'log_${DateTime.now().microsecondsSinceEpoch}',
      date: date,
      friends: friends,
      place: place.trim(),
      memo: memo.trim(),
    );

    try {
      final saved = await repository.addLog(log);
      state = AsyncValue.data([saved, ...previous]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
