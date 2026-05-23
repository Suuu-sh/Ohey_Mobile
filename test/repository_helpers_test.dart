import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nomo/core/data/auth_repository.dart';
import 'package:nomo/core/data/push_token_repository.dart';
import 'package:nomo/core/data/user_repository.dart';

void main() {
  test('authOAuthScopes returns provider-specific safe scopes', () {
    expect(authOAuthScopes(OAuthProvider.google), 'email profile');
    expect(authOAuthScopes(OAuthProvider.apple), 'name email');
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

  test('push platform helper emits supported API platform key', () {
    expect(currentPushPlatformKey(), isIn(<String>['ios', 'android']));
  });
}
