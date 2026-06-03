import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/ohey_api_values.dart';
import '../../../core/models/yurubo.dart';
import '../data/yurubo_repository.dart';

final yuruboControllerProvider =
    AsyncNotifierProvider<YuruboController, List<Yurubo>>(YuruboController.new);

class YuruboController extends AsyncNotifier<List<Yurubo>> {
  @override
  Future<List<Yurubo>> build() async {
    return ref.read(yuruboRepositoryProvider).fetchYurubos();
  }

  Future<void> createYurubo(YuruboCreateDraft draft) async {
    await ref.read(yuruboRepositoryProvider).createYurubo(draft);
    ref.invalidateSelf();
  }

  Future<void> updateYurubo(String yuruboId, YuruboUpdateDraft draft) async {
    await ref.read(yuruboRepositoryProvider).updateYurubo(yuruboId, draft);
    ref.invalidateSelf();
  }

  Future<void> deleteYurubo(String yuruboId) async {
    await ref.read(yuruboRepositoryProvider).deleteYurubo(yuruboId);
    ref.invalidateSelf();
  }

  Future<void> approveReaction(String yuruboId, String userId) async {
    await ref.read(yuruboRepositoryProvider).approveReaction(yuruboId, userId);
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData([
        for (final item in current)
          if (item.id == yuruboId)
            item.copyWith(
              reactionCount:
                  item.participants.any(
                    (participant) =>
                        participant.userId == userId && participant.isPending,
                  )
                  ? item.reactionCount + 1
                  : item.reactionCount,
              participants: [
                for (final participant in item.participants)
                  participant.userId == userId
                      ? participant.copyWith(
                          reactionType: OheyReactionTypeKeys.available,
                        )
                      : participant,
              ],
            )
          else
            item,
      ]);
    }
    ref.invalidateSelf();
  }

  Future<void> toggleParticipation(String yuruboId) async {
    final current = state.asData?.value ?? const <Yurubo>[];
    final index = current.indexWhere((item) => item.id == yuruboId);
    if (index < 0) return;
    final item = current[index];
    await _setParticipation(
      yuruboId,
      reacted: !item.reactedByMe,
      current: current,
      index: index,
    );
  }

  Future<void> participate(String yuruboId) async {
    final current = state.asData?.value ?? const <Yurubo>[];
    final index = current.indexWhere((item) => item.id == yuruboId);
    if (index >= 0 && current[index].reactedByMe) return;
    await _setParticipation(
      yuruboId,
      reacted: true,
      current: current,
      index: index,
    );
  }

  Future<void> _setParticipation(
    String yuruboId, {
    required bool reacted,
    required List<Yurubo> current,
    required int index,
  }) async {
    if (index >= 0) {
      final item = current[index];
      final nextCount = reacted
          ? item.reactionCount
          : (item.reactionCount - 1).clamp(0, 1 << 30);
      state = AsyncData([
        for (var i = 0; i < current.length; i++)
          i == index
              ? item.copyWith(
                  reactionCount: nextCount,
                  reactedByMe: reacted,
                  myReactionType: reacted
                      ? OheyReactionTypeKeys.interested
                      : '',
                )
              : current[i],
      ]);
    }
    try {
      await ref
          .read(yuruboRepositoryProvider)
          .setReaction(yuruboId, reacted: reacted);
      ref.invalidateSelf();
    } catch (_) {
      if (index >= 0) state = AsyncData(current);
      rethrow;
    }
  }
}
