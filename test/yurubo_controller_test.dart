import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/models/ohey_avatar.dart';
import 'package:ohey/core/models/yurubo.dart';
import 'package:ohey/features/yurubos/application/yurubo_controller.dart';
import 'package:ohey/features/yurubos/data/yurubo_repository.dart';

void main() {
  test(
    'failed reaction rollback preserves another in-flight item update',
    () async {
      final repository = _ControlledYuruboRepository();
      final container = ProviderContainer(
        overrides: [yuruboRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(yuruboControllerProvider.future);
      final controller = container.read(yuruboControllerProvider.notifier);

      final first = controller.toggleParticipation('first');
      final second = controller.toggleParticipation('second');
      repository.complete('second');
      await second;
      await container.read(yuruboControllerProvider.future);

      repository.fail('first');
      await expectLater(first, throwsStateError);
      final finalItems = await container.read(yuruboControllerProvider.future);

      expect(
        finalItems.singleWhere((item) => item.id == 'first').reactedByMe,
        isFalse,
      );
      expect(
        finalItems.singleWhere((item) => item.id == 'second').reactedByMe,
        isTrue,
      );
    },
  );
}

class _ControlledYuruboRepository implements YuruboRepository {
  final _serverReactions = <String, bool>{'first': false, 'second': false};
  final _pending = <String, Completer<void>>{};

  @override
  Future<List<Yurubo>> fetchYurubos({int limit = 50}) async => [
    for (final entry in _serverReactions.entries)
      _item(entry.key, reacted: entry.value),
  ];

  @override
  Future<void> setReaction(String yuruboId, {required bool reacted}) {
    final completer = Completer<void>();
    _pending[yuruboId] = completer;
    return completer.future.then((_) {
      _serverReactions[yuruboId] = reacted;
    });
  }

  void complete(String id) => _pending.remove(id)!.complete();

  void fail(String id) => _pending
      .remove(id)!
      .completeError(StateError('simulated request failure'));

  @override
  Future<void> approveReaction(String yuruboId, String userId) async {}

  @override
  Future<void> createYurubo(YuruboCreateDraft draft) async {}

  @override
  Future<void> deleteYurubo(String yuruboId) async {}

  @override
  Future<void> updateYurubo(String yuruboId, YuruboUpdateDraft draft) async {}
}

Yurubo _item(String id, {required bool reacted}) => Yurubo(
  id: id,
  ownerUserId: 'owner',
  userName: 'Owner',
  avatar: OheyAvatar.defaultAvatar,
  title: id,
  body: '',
  category: 'other',
  placeText: '',
  timeLabel: '',
  status: 'open',
  visibility: 'friends',
  visibilityLabel: 'Friends',
  createdAt: DateTime(2026),
  reactionCount: reacted ? 1 : 0,
  reactedByMe: reacted,
  myReactionType: reacted ? oheyYuruboInterestedReactionKey : '',
);
