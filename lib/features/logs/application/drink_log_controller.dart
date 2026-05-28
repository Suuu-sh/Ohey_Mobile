import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/optimistic_update.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_friend.dart';
import '../data/drink_log_repository.dart';

final drinkLogControllerProvider =
    AsyncNotifierProvider<DrinkLogController, List<DrinkLog>>(
      DrinkLogController.new,
    );

final homeFeedControllerProvider =
    AsyncNotifierProvider<HomeFeedController, List<DrinkLog>>(
      HomeFeedController.new,
    );

final friendsControllerProvider = Provider<FriendsController>((ref) {
  return FriendsController(ref);
});

final friendsProvider = FutureProvider<List<NomoFriend>>((ref) async {
  return ref.watch(drinkLogRepositoryProvider).fetchFriends();
});

final friendsForDateProvider =
    FutureProvider.family<List<NomoFriend>, DateTime>((ref, date) async {
      return ref.watch(drinkLogRepositoryProvider).fetchFriends(date: date);
    });

class HomeFeedController extends AsyncNotifier<List<DrinkLog>> {
  @override
  Future<List<DrinkLog>> build() async {
    return ref.watch(drinkLogRepositoryProvider).fetchHomeFeed();
  }

  Future<void> toggleLike(String logId) async {
    final previous = state.asData?.value ?? const <DrinkLog>[];
    final index = previous.indexWhere((log) => log.id == logId);
    if (index == -1) return;

    final current = previous[index];
    final nextLiked = !current.likedByMe;
    final optimistic = current.copyWith(
      likedByMe: nextLiked,
      likeCount: (current.likeCount + (nextLiked ? 1 : -1)).clamp(0, 1 << 31),
    );
    try {
      await runOptimistic<DrinkLogLikeState>(
        apply: () => state = AsyncValue.data([
          for (var i = 0; i < previous.length; i++)
            i == index ? optimistic : previous[i],
        ]),
        rollback: () => state = AsyncValue.data(previous),
        commit: () => ref
            .read(drinkLogRepositoryProvider)
            .setLike(logId, liked: nextLiked),
        confirm: (likeState) {
          final latest = state.asData?.value ?? previous;
          state = AsyncValue.data([
            for (final log in latest)
              if (log.id == logId)
                log.copyWith(
                  likeCount: likeState.likeCount,
                  likedByMe: likeState.likedByMe,
                )
              else
                log,
          ]);
        },
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteLog(String logId) async {
    final previous = state.asData?.value ?? const <DrinkLog>[];
    state = AsyncValue.data([
      for (final log in previous)
        if (log.id != logId) log,
    ]);
    try {
      await ref.read(drinkLogRepositoryProvider).deleteLog(logId);
      ref.invalidate(drinkLogControllerProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.data(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reportLog(String logId) async {
    final previous = state.asData?.value ?? const <DrinkLog>[];
    try {
      await ref.read(drinkLogRepositoryProvider).reportLog(logId);
      state = AsyncValue.data([
        for (final log in previous)
          if (log.id != logId) log,
      ]);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class DrinkLogController extends AsyncNotifier<List<DrinkLog>> {
  @override
  Future<List<DrinkLog>> build() async {
    return ref.watch(drinkLogRepositoryProvider).fetchLogs();
  }

  Future<void> toggleLike(String logId) async {
    final previous = state.asData?.value ?? const <DrinkLog>[];
    final index = previous.indexWhere((log) => log.id == logId);
    if (index == -1) return;

    final current = previous[index];
    final nextLiked = !current.likedByMe;
    final optimistic = current.copyWith(
      likedByMe: nextLiked,
      likeCount: (current.likeCount + (nextLiked ? 1 : -1)).clamp(0, 1 << 31),
    );
    try {
      await runOptimistic<DrinkLogLikeState>(
        apply: () => state = AsyncValue.data([
          for (var i = 0; i < previous.length; i++)
            i == index ? optimistic : previous[i],
        ]),
        rollback: () => state = AsyncValue.data(previous),
        commit: () => ref
            .read(drinkLogRepositoryProvider)
            .setLike(logId, liked: nextLiked),
        confirm: (likeState) {
          final latest = state.asData?.value ?? previous;
          state = AsyncValue.data([
            for (final log in latest)
              if (log.id == logId)
                log.copyWith(
                  likeCount: likeState.likeCount,
                  likedByMe: likeState.likedByMe,
                )
              else
                log,
          ]);
        },
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteLog(String logId) async {
    final previous = state.asData?.value ?? const <DrinkLog>[];
    state = AsyncValue.data([
      for (final log in previous)
        if (log.id != logId) log,
    ]);
    try {
      await ref.read(drinkLogRepositoryProvider).deleteLog(logId);
    } catch (error, stackTrace) {
      state = AsyncValue.data(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reportLog(String logId) async {
    await ref.read(drinkLogRepositoryProvider).reportLog(logId);
  }

  Future<void> addLog({
    required DateTime date,
    required List<NomoFriend> friends,
    required String place,
    required String memo,
    String? photoAssetPath,
    double captionY = .5,
    double? placeLatitude,
    double? placeLongitude,
  }) async {
    final repository = ref.read(drinkLogRepositoryProvider);
    final previous = state.asData?.value ?? const <DrinkLog>[];
    final now = DateTime.now();
    final log = DrinkLog(
      id: 'log_${now.microsecondsSinceEpoch}',
      date: date,
      friends: friends,
      place: place.trim(),
      memo: String.fromCharCodes(memo.trim().runes.take(15)),
      photoAssetPath: photoAssetPath,
      captionY: captionY.clamp(0.0, 1.0),
      placeLatitude: placeLatitude,
      placeLongitude: placeLongitude,
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

class FriendsController {
  FriendsController(this._ref);

  final Ref _ref;

  Future<void> toggleFavorite({
    required String friendId,
    required bool isFavorite,
  }) async {
    await runOptimistic<void>(
      apply: () => _ref.invalidate(friendsProvider),
      rollback: () => _ref.invalidate(friendsProvider),
      commit: () => _ref
          .read(drinkLogRepositoryProvider)
          .setFriendFavorite(friendId, isFavorite: isFavorite),
      confirm: (_) => _ref.invalidate(friendsProvider),
    );
  }
}
