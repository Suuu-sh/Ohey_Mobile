import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> toggleParticipation(String yuruboId) async {
    final current = state.asData?.value ?? const <Yurubo>[];
    final index = current.indexWhere((item) => item.id == yuruboId);
    if (index < 0) return;
    final item = current[index];
    final nextReacted = !item.reactedByMe;
    final nextCount = (item.reactionCount + (nextReacted ? 1 : -1)).clamp(
      0,
      1 << 30,
    );
    state = AsyncData([
      for (var i = 0; i < current.length; i++)
        i == index
            ? item.copyWith(reactionCount: nextCount, reactedByMe: nextReacted)
            : current[i],
    ]);
    try {
      await ref
          .read(yuruboRepositoryProvider)
          .setReaction(yuruboId, reacted: nextReacted);
      ref.invalidateSelf();
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
