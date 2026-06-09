import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:url_launcher/url_launcher.dart';

import '../models/ohey_avatar.dart';
import 'clerk_auth_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(clerkAuthServiceProvider));
});

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum OAuthProvider { google, apple }

class AuthRepository {
  const AuthRepository(this._clerk);

  final ClerkAuthService _clerk;

  bool get isSignedIn => _clerk.isSignedIn;

  String? get currentEmail => _clerk.currentUserEmail;

  Future<void> resetPasswordForEmail(String email) {
    throw const AuthException('パスワード再設定は現在準備中です。');
  }

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    final redirect = await _clerk.startOAuthSignIn(_clerkStrategyFor(provider));
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
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _clerk.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithProfileMetadata({
    required String email,
    required String password,
    required String userId,
    required String displayName,
    required OheyAvatar avatar,
  }) async {
    await _clerk.signUpWithPassword(
      email: email,
      password: password,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatar.encode(),
    );
  }

  Future<void> completeOAuthCallback(Uri uri) {
    return _clerk.completeOAuthCallback(uri);
  }

  Future<void> signOut() {
    return _clerk.signOut();
  }
}

clerk.Strategy _clerkStrategyFor(OAuthProvider provider) {
  return switch (provider) {
    OAuthProvider.google => clerk.Strategy.oauthGoogle,
    OAuthProvider.apple => clerk.Strategy.oauthApple,
  };
}
