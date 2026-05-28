import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ohey/core/data/auth_repository.dart';
import 'package:ohey/core/data/push_token_repository.dart';
import 'package:ohey/core/data/user_repository.dart';
import 'package:ohey/core/models/ohey_avatar.dart';
import 'package:ohey/core/models/ohey_gender.dart';
import 'package:ohey/features/friends/data/friend_repository.dart';

void main() {
  test('authOAuthScopes returns provider-specific safe scopes', () {
    expect(authOAuthScopes(OAuthProvider.google), 'email profile');
    expect(authOAuthScopes(OAuthProvider.apple), 'name email');
  });

  test('authProfileMetadata uses only profile fields accepted by backend', () {
    final payload = authProfileMetadata(
      userId: 'ohey_user',
      displayName: 'Ohey User',
      gender: OheyGender.female,
      avatar: OheyAvatar.defaultAvatar,
    );

    expect(payload['user_id'], 'ohey_user');
    expect(payload['display_name'], 'Ohey User');
    expect(payload['gender'], 'female');
    expect(payload['character_key'], 'avatar');
    expect(payload['avatar_url'], isA<String>());
    expect(payload.keys, hasLength(5));
  });

  test('Ohey user id helpers validate and derive stable defaults', () {
    expect(isValidOheyUserId('ohey_user_2026'), isTrue);
    expect(isValidOheyUserId('ab'), isFalse);
    expect(isValidOheyUserId('bad user'), isFalse);
    expect(
      defaultOheyUserId('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
      'ohey_aaaaaaaabbbb',
    );
  });

  test('profile payload helpers keep create and update scopes explicit', () {
    expect(
      createProfilePayload(
        name: 'Ohey User',
        userId: 'ohey_user',
        gender: OheyGender.male,
      ),
      <String, dynamic>{
        'user_id': 'ohey_user',
        'display_name': 'Ohey User',
        'gender': 'male',
        'character_key': 'avatar',
        'avatar_url': '',
      },
    );

    expect(
      updateProfilePayload(name: 'Renamed', userId: 'renamed_user'),
      <String, dynamic>{
        'user_id': 'renamed_user',
        'display_name': 'Renamed',
        'character_key': 'avatar',
        'avatar_url': '',
      },
    );
  });

  test('friend profile parser trims fallback fields safely', () {
    final profile = OheyFriendProfile.fromRow(<String, dynamic>{
      'id': 'friend-id',
      'user_id': 'friend_user',
      'display_name': '  ',
      'avatar_url': null,
    });

    expect(profile.id, 'friend-id');
    expect(profile.userId, 'friend_user');
    expect(profile.displayName, 'Ohey friend');
    expect(profile.avatar, OheyAvatar.defaultAvatar);
  });

  test('friend relationship parser defaults unknown states to none', () {
    final outgoing = OheyFriendRelationshipStatus.fromRow(<String, dynamic>{
      'already_friend': false,
      'request_state': 'outgoing',
    });
    final unknown = OheyFriendRelationshipStatus.fromRow(<String, dynamic>{});

    expect(outgoing.alreadyFriend, isFalse);
    expect(outgoing.requestState, OheyFriendRequestState.outgoing);
    expect(unknown.alreadyFriend, isFalse);
    expect(unknown.requestState, OheyFriendRequestState.none);
  });

  test('push platform and payload helpers emit supported API platform key', () {
    expect(currentPushPlatformKey(), isIn(<String>['ios', 'android']));
    expect(pushTokenPayload('device-token'), <String, dynamic>{
      'token': 'device-token',
      'platform': currentPushPlatformKey(),
    });
  });
}
