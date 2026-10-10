import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/contracts/ohey_api_paths.dart';
import 'package:ohey/core/data/backend_api_client.dart';
import 'package:ohey/core/data/user_repository.dart';
import 'package:ohey/core/models/ohey_avatar.dart';
import 'package:ohey/core/models/yurubo.dart';
import 'package:ohey/features/friends/data/friend_repository.dart';

void main() {
  late _ProfileIdentityClient client;

  setUp(() => client = _ProfileIdentityClient());
  tearDown(() => client.close());

  test(
    'resource ownership uses the backend profile ID, not Clerk identity',
    () async {
      final repository = UserRepository(client);
      final user = await repository.fetchCurrentUserProfile();
      final created = await repository.createProfile(
        name: 'Ohey User',
        userId: 'ohey_user',
      );
      final yurubo = _yurubo(ownerProfileId: _ProfileIdentityClient.profileId);

      expect(client.currentUserId, _ProfileIdentityClient.clerkUserId);
      expect(user?.profileId, _ProfileIdentityClient.profileId);
      expect(created.profileId, _ProfileIdentityClient.profileId);
      expect(yurubo.isOwnedByProfile(user?.profileId), isTrue);
      expect(yurubo.isOwnedByProfile(client.currentUserId), isFalse);
      expect(
        user?.copyWith(name: 'Updated').profileId,
        _ProfileIdentityClient.profileId,
      );
    },
  );

  test('friend request direction compares backend profile IDs', () {
    final row = <String, dynamic>{
      'id': 'request-id',
      'from_user_id': _ProfileIdentityClient.profileId,
      'to_user_id': 'other-profile-id',
      'invitee': <String, dynamic>{'id': 'other-profile-id'},
      'inviter': <String, dynamic>{'id': _ProfileIdentityClient.profileId},
    };

    expect(
      OheyFriendRequestItem.fromRow(
        row,
        _ProfileIdentityClient.profileId,
      ).isOutgoing,
      isTrue,
    );
    expect(
      OheyFriendRequestItem.fromRow(
        row,
        _ProfileIdentityClient.clerkUserId,
      ).isIncoming,
      isTrue,
    );
  });
}

Yurubo _yurubo({required String ownerProfileId}) => Yurubo(
  id: 'yurubo-id',
  ownerUserId: ownerProfileId,
  userName: 'Me',
  avatar: OheyAvatar.defaultAvatar,
  title: 'Test',
  body: '',
  category: 'other',
  placeText: '',
  timeLabel: '',
  status: 'open',
  visibility: 'friends',
  visibilityLabel: 'Friends',
  createdAt: DateTime(2026),
  reactionCount: 0,
  reactedByMe: false,
);

class _ProfileIdentityClient extends BackendApiClient {
  _ProfileIdentityClient()
    : super(
        baseUrl: 'https://profile-identity.invalid',
        accessTokenProvider: () => 'test-token',
        userIdProvider: () => clerkUserId,
        tokenValidator: (_) => true,
      );

  static const clerkUserId = 'user_clerk_test';
  static const profileId = 'cbdc84ab-f11c-43cc-ae8a-03df6e8f8994';

  @override
  Future<Map<String, dynamic>> getRow(
    String path, {
    Map<String, String>? query,
  }) async {
    if (path != OheyApiPaths.meProfile) {
      throw StateError('Unexpected endpoint: $path');
    }
    return <String, dynamic>{
      'id': profileId,
      'user_id': 'ohey_user',
      'display_name': 'Ohey User',
      'avatar_url': '',
      'is_plus': false,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getRows(
    String path, {
    Map<String, String>? query,
  }) async => const <Map<String, dynamic>>[];

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    if (path != OheyApiPaths.meProfile) {
      throw StateError('Unexpected endpoint: $path');
    }
    return <String, dynamic>{
      'id': profileId,
      'user_id': body['user_id'],
      'display_name': body['display_name'],
      'avatar_url': body['avatar_url'],
      'is_plus': false,
    };
  }
}
