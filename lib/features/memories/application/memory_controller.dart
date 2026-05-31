import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/optimistic_update.dart';
import '../../../core/models/memory.dart';
import '../../../core/models/ohey_friend.dart';
import '../data/memory_repository.dart';

final homeFeedControllerProvider =
    AsyncNotifierProvider<HomeFeedController, List<Memory>>(
      HomeFeedController.new,
    );

final friendsControllerProvider = Provider<FriendsController>((ref) {
  return FriendsController(ref);
});

final friendsProvider = FutureProvider<List<OheyFriend>>((ref) async {
  return ref.watch(memoryRepositoryProvider).fetchFriends();
});

final friendsForDateProvider =
    FutureProvider.family<List<OheyFriend>, DateTime>((ref, date) async {
      return ref.watch(memoryRepositoryProvider).fetchFriends(date: date);
    });

class HomeFeedController extends AsyncNotifier<List<Memory>> {
  static const _pageSize = 20;

  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<Memory>> build() async {
    final page = await ref
        .watch(memoryRepositoryProvider)
        .fetchHomeFeedPage(limit: _pageSize);
    _nextCursor = page.nextCursor;
    _hasMore = page.memories.length == _pageSize && page.hasMore;
    return page.memories;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    final cursor = _nextCursor?.trim();
    if (cursor == null || cursor.isEmpty) {
      _hasMore = false;
      return;
    }
    _isLoadingMore = true;
    try {
      final previous = state.asData?.value ?? const <Memory>[];
      final page = await ref
          .read(memoryRepositoryProvider)
          .fetchHomeFeedPage(limit: _pageSize, cursor: cursor);
      final seen = previous.map((memory) => memory.id).toSet();
      final appended = [
        ...previous,
        for (final memory in page.memories)
          if (seen.add(memory.id)) memory,
      ];
      _nextCursor = page.nextCursor;
      _hasMore = page.memories.length == _pageSize && page.hasMore;
      state = AsyncValue.data(appended);
    } catch (_) {
      // Keep the current feed; the next page-change can retry.
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> toggleLike(String memoryId) async {
    final previous = state.asData?.value ?? const <Memory>[];
    final index = previous.indexWhere((memory) => memory.id == memoryId);
    if (index == -1) return;

    final current = previous[index];
    final nextLiked = !current.likedByMe;
    final optimistic = current.copyWith(
      likedByMe: nextLiked,
      likeCount: (current.likeCount + (nextLiked ? 1 : -1)).clamp(0, 1 << 31),
    );
    try {
      await runOptimistic<MemoryLikeState>(
        apply: () => state = AsyncValue.data([
          for (var i = 0; i < previous.length; i++)
            i == index ? optimistic : previous[i],
        ]),
        rollback: () => state = AsyncValue.data(previous),
        commit: () => ref
            .read(memoryRepositoryProvider)
            .setLike(memoryId, liked: nextLiked),
        confirm: (likeState) {
          final latest = state.asData?.value ?? previous;
          state = AsyncValue.data([
            for (final memory in latest)
              if (memory.id == memoryId)
                memory.copyWith(
                  likeCount: likeState.likeCount,
                  likedByMe: likeState.likedByMe,
                )
              else
                memory,
          ]);
        },
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteMemory(String memoryId) async {
    final previous = state.asData?.value ?? const <Memory>[];
    state = AsyncValue.data([
      for (final memory in previous)
        if (memory.id != memoryId) memory,
    ]);
    try {
      await ref.read(memoryRepositoryProvider).deleteMemory(memoryId);
    } catch (error, stackTrace) {
      state = AsyncValue.data(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reportMemory(String memoryId, {String reason = 'other'}) async {
    final previous = state.asData?.value ?? const <Memory>[];
    try {
      await ref
          .read(memoryRepositoryProvider)
          .reportMemory(memoryId, reason: reason);
      state = AsyncValue.data([
        for (final memory in previous)
          if (memory.id != memoryId) memory,
      ]);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> hideMemory(String memoryId) async {
    final previous = state.asData?.value ?? const <Memory>[];
    state = AsyncValue.data([
      for (final memory in previous)
        if (memory.id != memoryId) memory,
    ]);
    try {
      await ref.read(memoryRepositoryProvider).hideMemoryFromFeed(memoryId);
    } catch (error, stackTrace) {
      state = AsyncValue.data(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> muteUser(String userId) async {
    await _hideUserPosts(
      userId,
      () => ref.read(memoryRepositoryProvider).muteUser(userId),
    );
  }

  Future<void> blockUser(String userId) async {
    await _hideUserPosts(
      userId,
      () => ref.read(memoryRepositoryProvider).blockUser(userId),
    );
  }

  Future<void> _hideUserPosts(
    String userId,
    Future<void> Function() commit,
  ) async {
    final previous = state.asData?.value ?? const <Memory>[];
    state = AsyncValue.data([
      for (final memory in previous)
        if (memory.ownerUserId != userId) memory,
    ]);
    try {
      await commit();
      ref.invalidate(friendsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.data(previous);
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
          .read(memoryRepositoryProvider)
          .setFriendFavorite(friendId, isFavorite: isFavorite),
      confirm: (_) => _ref.invalidate(friendsProvider),
    );
  }
}
