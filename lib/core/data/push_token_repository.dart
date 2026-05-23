import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  return PushTokenRepository(
    ref.watch(backendApiClientProvider),
    ref.watch(supabaseClientProvider),
  );
});

class PushTokenRepository {
  const PushTokenRepository(this._client, this._supabase);

  final BackendApiClient _client;
  final SupabaseClient _supabase;

  bool get hasSignedInUser {
    final userId = _supabase.auth.currentUser?.id;
    return userId != null && userId.isNotEmpty;
  }

  Future<void> registerToken(String token) async {
    if (!hasSignedInUser || token.trim().isEmpty) return;
    await _client.put('/v1/me/push-token', pushTokenPayload(token));
  }
}

String currentPushPlatformKey() => Platform.isAndroid ? 'android' : 'ios';

Map<String, dynamic> pushTokenPayload(String token) => {
  'token': token,
  'platform': currentPushPlatformKey(),
};
