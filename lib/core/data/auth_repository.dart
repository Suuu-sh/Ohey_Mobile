import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/auth_provider_config.dart';
import '../config/backend_config.dart';
import '../config/supabase_config.dart';
import '../contracts/ohey_api_paths.dart';
import '../models/ohey_avatar.dart';
import 'clerk_auth_service.dart';
import 'supabase_client_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    AuthProviderConfig.isClerkEnabled
        ? null
        : ref.watch(supabaseClientProvider),
    ref.watch(clerkAuthServiceProvider),
  );
});

class AuthRepository {
  const AuthRepository(this._supabase, this._clerk);

  final SupabaseClient? _supabase;
  final ClerkAuthService _clerk;

  Session? get currentSession => AuthProviderConfig.isClerkEnabled
      ? null
      : _requireSupabase().auth.currentSession;

  bool get isSignedIn => AuthProviderConfig.isClerkEnabled
      ? _clerk.isSignedIn
      : _requireSupabase().auth.currentSession != null;

  String? get currentEmail => AuthProviderConfig.isClerkEnabled
      ? _clerk.currentUserEmail
      : _requireSupabase().auth.currentUser?.email;

  User? get currentUser => AuthProviderConfig.isClerkEnabled
      ? null
      : _requireSupabase().auth.currentUser;

  Stream<AuthState> get onAuthStateChange =>
      _requireSupabase().auth.onAuthStateChange;

  Future<void> resetPasswordForEmail(String email) {
    if (AuthProviderConfig.isClerkEnabled) {
      throw const AuthException('パスワード再設定は現在準備中です。');
    }
    return _requireSupabase().auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    if (AuthProviderConfig.isClerkEnabled) {
      final redirect = await _clerk.startOAuthSignIn(
        _clerkStrategyFor(provider),
      );
      if (redirect == null) {
        throw const AuthException('OAuth redirect URL is unavailable.');
      }
      final launched = await launchUrl(
        redirect,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const AuthException('OAuth provider could not be opened.');
      }
      return;
    }
    await _requireSupabase().auth.signInWithOAuth(
      provider,
      redirectTo: SupabaseConfig.authRedirectUrl,
      scopes: authOAuthScopes(provider),
      // On iOS, Apple sign-in can leave SFSafariViewController on a blank
      // appleid.apple.com page after the deep link succeeds. Opening Apple
      // OAuth externally lets iOS return to Ohey via the redirect without
      // keeping that stale in-app browser over the already-authenticated app.
      authScreenLaunchMode: provider == OAuthProvider.apple
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault,
    );
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    if (AuthProviderConfig.isClerkEnabled) {
      return _clerk.signInWithPassword(email: email, password: password);
    }
    return _requireSupabase().auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse?> signUpWithProfileMetadata({
    required String email,
    required String password,
    required String userId,
    required String displayName,
    required OheyAvatar avatar,
  }) async {
    final metadata = authProfileMetadata(
      userId: userId,
      displayName: displayName,
      avatar: avatar,
    );
    if (AuthProviderConfig.isClerkEnabled) {
      await _clerk.signUpWithPassword(
        email: email,
        password: password,
        userId: userId,
        displayName: displayName,
        avatarUrl: avatar.encode(),
      );
      return null;
    }
    await _createConfirmedAuthUser(
      email: email,
      password: password,
      metadata: metadata,
    );
    return _requireSupabase().auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> completeOAuthCallback(Uri uri) {
    if (AuthProviderConfig.isClerkEnabled) {
      return _clerk.completeOAuthCallback(uri);
    }
    return Future<void>.value();
  }

  Future<void> signOut() {
    if (AuthProviderConfig.isClerkEnabled) {
      return _clerk.signOut();
    }
    return _requireSupabase().auth.signOut(scope: SignOutScope.local);
  }

  Future<void> _createConfirmedAuthUser({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    final client = HttpClient();
    try {
      final baseUri = Uri.parse(BackendConfig.baseUrl);
      final uri = baseUri.replace(
        path: _joinPath(baseUri.path, OheyApiPaths.authSignup),
      );
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 12));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'email': email,
          'password': password,
          'user_id': metadata['user_id'],
          'display_name': metadata['display_name'],
          'avatar_url': metadata['avatar_url'],
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      final text = await utf8.decoder.bind(response).join();
      throw AuthException(_authSignupErrorMessage(text));
    } finally {
      client.close(force: true);
    }
  }

  SupabaseClient _requireSupabase() {
    final supabase = _supabase;
    if (supabase == null) {
      throw StateError('Supabase auth is disabled in Clerk mode.');
    }
    return supabase;
  }

  @Deprecated('Use signUpWithProfileMetadata for confirmed signup.')
  Future<AuthResponse> signUpWithProfileMetadataDirect({
    required String email,
    required String password,
    required String userId,
    required String displayName,
    required OheyAvatar avatar,
  }) {
    return _requireSupabase().auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
      data: authProfileMetadata(
        userId: userId,
        displayName: displayName,
        avatar: avatar,
      ),
    );
  }
}

String _joinPath(String basePath, String path) {
  final left = basePath.endsWith('/')
      ? basePath.substring(0, basePath.length - 1)
      : basePath;
  final right = path.startsWith('/') ? path : '/$path';
  return '$left$right';
}

String _authSignupErrorMessage(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map && decoded['error'] is String) {
      return decoded['error'] as String;
    }
  } catch (_) {
    // Use fallback below.
  }
  return '登録できなかったよ。あとでもう一度試してね。';
}

String authOAuthScopes(OAuthProvider provider) {
  return switch (provider) {
    OAuthProvider.google => 'email profile',
    OAuthProvider.apple => 'name email',
    _ => 'email profile',
  };
}

Map<String, dynamic> authProfileMetadata({
  required String userId,
  required String displayName,
  required OheyAvatar avatar,
}) {
  return {
    'user_id': userId,
    'display_name': displayName,
    'character_key': 'avatar',
    'avatar_url': avatar.encode(),
  };
}

clerk.Strategy _clerkStrategyFor(OAuthProvider provider) {
  return switch (provider) {
    OAuthProvider.google => clerk.Strategy.oauthGoogle,
    OAuthProvider.apple => clerk.Strategy.oauthApple,
    _ => clerk.Strategy.oauthGoogle,
  };
}
