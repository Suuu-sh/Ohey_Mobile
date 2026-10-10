import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/data/user_repository.dart';
import 'package:ohey/core/models/ohey_user.dart';
import 'package:ohey/core/preview/ohey_preview_backend.dart';
import 'package:ohey/features/friends/data/friend_repository.dart';
import 'package:ohey/features/notifications/data/notification_repository.dart';
import 'package:ohey/features/wish_items/data/wish_item_repository.dart';
import 'package:ohey/features/yurubos/data/yurubo_repository.dart';

void main() {
  late OheyPreviewBackendApiClient client;

  setUp(() => client = OheyPreviewBackendApiClient());
  tearDown(() => client.close());

  test('preview fixtures parse through the real repositories', () async {
    final user = await UserRepository(client).fetchCurrentUserProfile();
    expect(user?.name, 'みーむ');
    expect(user?.profileId, OheyPreviewFixtures.meId);

    final friends = await FriendRepository(
      client,
      currentProfileId: user?.profileId,
    ).fetchFriends();
    expect(friends, hasLength(5));
    expect(friends.where((friend) => friend.isFavorite), hasLength(1));

    final requests = await FriendRepository(
      client,
      currentProfileId: user?.profileId,
    ).fetchPendingFriendRequests();
    expect(requests.single.isIncoming, isTrue);

    expect(await BackendYuruboRepository(client).fetchYurubos(), isNotEmpty);
    expect(
      await BackendWishItemRepository(client).fetchWishItems(),
      isNotEmpty,
    );
    expect(
      await BackendNotificationRepository(client).fetchNotifications(),
      isNotEmpty,
    );
  });

  test('preview writes are kept for the session', () async {
    final users = UserRepository(client);
    await users.updateDailyStatus(OheyDailyStatus.available);
    expect(
      await users.fetchDailyStatus(DateTime.now()),
      OheyDailyStatus.available,
    );

    final yurubos = BackendYuruboRepository(client);
    final target = (await yurubos.fetchYurubos()).firstWhere(
      (yurubo) => !yurubo.reactedByMe,
    );
    await yurubos.setReaction(target.id, reacted: true);
    final updated = (await yurubos.fetchYurubos()).firstWhere(
      (yurubo) => yurubo.id == target.id,
    );
    expect(updated.reactedByMe, isTrue);
    expect(updated.reactionCount, target.reactionCount + 1);
  });
}
