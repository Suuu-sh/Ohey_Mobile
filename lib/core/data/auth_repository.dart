import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/nomo_avatar.dart';
import '../models/nomo_gender.dart';
import 'supabase_client_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

class AuthRepository {
  const AuthRepository(this._supabase);

  final SupabaseClient _supabase;

  Session? get currentSession => _supabase.auth.currentSession;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  Future<void> resetPasswordForEmail(String email) {
    return _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  Future<void> signInWithOAuth(OAuthProvider provider) {
    return _supabase.auth.signInWithOAuth(
      provider,
      redirectTo: SupabaseConfig.authRedirectUrl,
      scopes: authOAuthScopes(provider),
    );
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithProfileMetadata({
    required String email,
    required String password,
    required String userId,
    required String displayName,
    required NomoGender gender,
    required NomoAvatar avatar,
  }) {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
      data: {
        'user_id': userId,
        'display_name': displayName,
        'gender': gender.key,
        'character_key': 'avatar',
        'avatar_url': avatar.encode(),
      },
    );
  }
}

String authOAuthScopes(OAuthProvider provider) {
  return switch (provider) {
    OAuthProvider.google => 'email profile',
    OAuthProvider.apple => 'name email',
    _ => 'email profile',
  };
}
