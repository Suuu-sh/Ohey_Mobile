import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/ohey_api_paths.dart';
import '../contracts/ohey_api_values.dart';
import 'auth_identity_provider.dart';
import 'backend_api_client.dart';

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  return PushTokenRepository(
    ref.watch(backendApiClientProvider),
    ref.watch(authIdentityProvider),
  );
});

class PushTokenRepository {
  const PushTokenRepository(this._client, this._identity);

  final BackendApiClient _client;
  final AuthIdentity _identity;

  bool get hasSignedInUser {
    final userId = _identity.currentUserId;
    return userId != null && userId.isNotEmpty;
  }

  Future<bool> registerToken(String token) async {
    if (!hasSignedInUser || token.trim().isEmpty) return false;
    await _client.put(OheyApiPaths.mePushToken, pushTokenPayload(token));
    return true;
  }

  Future<void> unregisterToken(String? token) async {
    final normalized = token?.trim();
    if (!hasSignedInUser || normalized == null || normalized.isEmpty) return;
    await _client.delete(OheyApiPaths.mePushToken, body: {'token': normalized});
  }
}

String currentPushPlatformKey() => Platform.isAndroid
    ? OheyPushPlatformKeys.android
    : OheyPushPlatformKeys.ios;

Map<String, dynamic> pushTokenPayload(String token) => {
  'token': token,
  'platform': currentPushPlatformKey(),
};
