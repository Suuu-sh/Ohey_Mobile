import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/application/ohey_user_controller.dart';
import 'package:ohey/core/models/ohey_avatar.dart';
import 'package:ohey/core/models/ohey_user.dart';
import 'package:ohey/core/models/yurubo.dart';
import 'package:ohey/features/friends/application/invite_controller.dart';
import 'package:ohey/features/home/presentation/home_screen.dart';
import 'package:ohey/features/notifications/application/notification_controller.dart';
import 'package:ohey/features/yurubos/data/yurubo_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('feed participation semantics match owner and reaction state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FeedYuruboRepository([
      _yurubo('mine', ownerUserId: 'me'),
      _yurubo('liked', ownerUserId: 'friend', reactedByMe: true),
      _yurubo('unliked', ownerUserId: 'another-friend'),
    ]);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          yuruboRepositoryProvider.overrideWithValue(repository),
          oheyUserProvider.overrideWith(_CurrentUserController.new),
          hasUnreadNotificationsProvider.overrideWith((ref) => false),
          incomingInvitesProvider.overrideWith((ref) async => const []),
          todayReservationsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plan mine'), findsOneWidget);

    final ownerCard = find.bySemanticsLabel(RegExp(r'User mineのゆるぼ[\s\S]*募集主'));
    expect(ownerCard, findsOneWidget);
    final ownerSemantics = tester.getSemantics(ownerCard).getSemanticsData();
    expect(ownerSemantics.label, isNot(contains('参加申請を取り消す')));
    expect('募集主'.allMatches(ownerSemantics.label), hasLength(1));
    expect(ownerSemantics.hasAction(SemanticsAction.tap), isFalse);

    final likedAction = find.bySemanticsLabel(RegExp(r'参加申請を取り消す[\s\S]*申請中'));
    expect(likedAction, findsOneWidget);
    expect(
      tester
          .getSemantics(likedAction)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    final unlikedAction = find.bySemanticsLabel(
      RegExp(r'このゆるぼに参加申請する[\s\S]*参加する'),
    );
    expect(unlikedAction, findsOneWidget);
    expect(
      tester
          .getSemantics(unlikedAction)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });
}

Yurubo _yurubo(
  String id, {
  required String ownerUserId,
  bool reactedByMe = false,
}) => Yurubo(
  id: id,
  ownerUserId: ownerUserId,
  userName: 'User $id',
  avatar: OheyAvatar.defaultAvatar,
  title: 'Plan $id',
  body: '',
  category: 'other',
  placeText: 'Somewhere',
  timeLabel: 'Anytime',
  status: 'open',
  visibility: 'friends',
  visibilityLabel: '全フレンズ',
  createdAt: DateTime(2026),
  reactionCount: reactedByMe ? 1 : 0,
  reactedByMe: reactedByMe,
  myReactionType: reactedByMe ? oheyYuruboInterestedReactionKey : '',
);

class _FeedYuruboRepository implements YuruboRepository {
  const _FeedYuruboRepository(this.items);

  final List<Yurubo> items;

  @override
  Future<List<Yurubo>> fetchYurubos({int limit = 50}) async => items;

  @override
  Future<void> approveReaction(String yuruboId, String userId) async {}

  @override
  Future<void> createYurubo(YuruboCreateDraft draft) async {}

  @override
  Future<void> deleteYurubo(String yuruboId) async {}

  @override
  Future<void> setReaction(String yuruboId, {required bool reacted}) async {}

  @override
  Future<void> updateYurubo(String yuruboId, YuruboUpdateDraft draft) async {}
}

class _CurrentUserController extends OheyUserController {
  @override
  OheyUser? build() =>
      const OheyUser(name: 'Me', userId: 'me', profileId: 'me', isPlus: true);
}
