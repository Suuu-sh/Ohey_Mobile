import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nomo/core/data/auth_repository.dart';
import 'package:nomo/core/data/push_token_repository.dart';
import 'package:nomo/core/data/user_repository.dart';
import 'package:nomo/core/models/nomo_avatar.dart';
import 'package:nomo/core/models/nomo_gender.dart';
import 'package:nomo/features/friends/data/friend_repository.dart';

void main() {
  test('authOAuthScopes returns provider-specific safe scopes', () {
    expect(authOAuthScopes(OAuthProvider.google), 'email profile');
    expect(authOAuthScopes(OAuthProvider.apple), 'name email');
  });

  test('authProfileMetadata uses only profile fields accepted by backend', () {
    final payload = authProfileMetadata(
      userId: 'nomo_user',
      displayName: 'Nomo User',
      gender: NomoGender.female,
      avatar: NomoAvatar.defaultAvatar,
    );

    expect(payload['user_id'], 'nomo_user');
    expect(payload['display_name'], 'Nomo User');
    expect(payload['gender'], 'female');
    expect(payload['character_key'], 'avatar');
    expect(payload['avatar_url'], isA<String>());
    expect(payload.keys, hasLength(5));
  });

  test('Nomo user id helpers validate and derive stable defaults', () {
    expect(isValidNomoUserId('nomo_user_2026'), isTrue);
    expect(isValidNomoUserId('ab'), isFalse);
    expect(isValidNomoUserId('bad user'), isFalse);
    expect(
      defaultNomoUserId('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
      'nomo_aaaaaaaabbbb',
    );
  });

  test('profile payload helpers keep create and update scopes explicit', () {
    expect(
      createProfilePayload(
        name: 'Nomo User',
        userId: 'nomo_user',
        gender: NomoGender.male,
      ),
      <String, dynamic>{
        'user_id': 'nomo_user',
        'display_name': 'Nomo User',
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
    final profile = NomoFriendProfile.fromRow(<String, dynamic>{
      'id': 'friend-id',
      'user_id': 'friend_user',
      'display_name': '  ',
      'avatar_url': null,
    });

    expect(profile.id, 'friend-id');
    expect(profile.userId, 'friend_user');
    expect(profile.displayName, 'Nomo friend');
    expect(profile.avatar, NomoAvatar.defaultAvatar);
  });

  test('friend relationship parser defaults unknown states to none', () {
    final outgoing = NomoFriendRelationshipStatus.fromRow(<String, dynamic>{
      'already_friend': false,
      'request_state': 'outgoing',
    });
    final unknown = NomoFriendRelationshipStatus.fromRow(<String, dynamic>{});

    expect(outgoing.alreadyFriend, isFalse);
    expect(outgoing.requestState, NomoFriendRequestState.outgoing);
    expect(unknown.alreadyFriend, isFalse);
    expect(unknown.requestState, NomoFriendRequestState.none);
  });

  test('push platform and payload helpers emit supported API platform key', () {
    expect(currentPushPlatformKey(), isIn(<String>['ios', 'android']));
    expect(pushTokenPayload('device-token'), <String, dynamic>{
      'token': 'device-token',
      'platform': currentPushPlatformKey(),
    });
  });
}
