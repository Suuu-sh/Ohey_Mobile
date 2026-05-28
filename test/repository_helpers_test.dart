import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tomo/core/data/auth_repository.dart';
import 'package:tomo/core/data/push_token_repository.dart';
import 'package:tomo/core/data/user_repository.dart';
import 'package:tomo/core/models/tomo_avatar.dart';
import 'package:tomo/core/models/tomo_gender.dart';
import 'package:tomo/features/friends/data/friend_repository.dart';

void main() {
  test('authOAuthScopes returns provider-specific safe scopes', () {
    expect(authOAuthScopes(OAuthProvider.google), 'email profile');
    expect(authOAuthScopes(OAuthProvider.apple), 'name email');
  });

  test('authProfileMetadata uses only profile fields accepted by backend', () {
    final payload = authProfileMetadata(
      userId: 'tomo_user',
      displayName: 'Tomo User',
      gender: TomoGender.female,
      avatar: TomoAvatar.defaultAvatar,
    );

    expect(payload['user_id'], 'tomo_user');
    expect(payload['display_name'], 'Tomo User');
    expect(payload['gender'], 'female');
    expect(payload['character_key'], 'avatar');
    expect(payload['avatar_url'], isA<String>());
    expect(payload.keys, hasLength(5));
  });

  test('Tomo user id helpers validate and derive stable defaults', () {
    expect(isValidTomoUserId('tomo_user_2026'), isTrue);
    expect(isValidTomoUserId('ab'), isFalse);
    expect(isValidTomoUserId('bad user'), isFalse);
    expect(
      defaultTomoUserId('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
      'tomo_aaaaaaaabbbb',
    );
  });

  test('profile payload helpers keep create and update scopes explicit', () {
    expect(
      createProfilePayload(
        name: 'Tomo User',
        userId: 'tomo_user',
        gender: TomoGender.male,
      ),
      <String, dynamic>{
        'user_id': 'tomo_user',
        'display_name': 'Tomo User',
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
    final profile = TomoFriendProfile.fromRow(<String, dynamic>{
      'id': 'friend-id',
      'user_id': 'friend_user',
      'display_name': '  ',
      'avatar_url': null,
    });

    expect(profile.id, 'friend-id');
    expect(profile.userId, 'friend_user');
    expect(profile.displayName, 'Tomo friend');
    expect(profile.avatar, TomoAvatar.defaultAvatar);
  });

  test('friend relationship parser defaults unknown states to none', () {
    final outgoing = TomoFriendRelationshipStatus.fromRow(<String, dynamic>{
      'already_friend': false,
      'request_state': 'outgoing',
    });
    final unknown = TomoFriendRelationshipStatus.fromRow(<String, dynamic>{});

    expect(outgoing.alreadyFriend, isFalse);
    expect(outgoing.requestState, TomoFriendRequestState.outgoing);
    expect(unknown.alreadyFriend, isFalse);
    expect(unknown.requestState, TomoFriendRequestState.none);
  });

  test('push platform and payload helpers emit supported API platform key', () {
    expect(currentPushPlatformKey(), isIn(<String>['ios', 'android']));
    expect(pushTokenPayload('device-token'), <String, dynamic>{
      'token': 'device-token',
      'platform': currentPushPlatformKey(),
    });
  });
}
