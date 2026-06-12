import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:url_launcher/url_launcher.dart';

import '../config/backend_config.dart';
import 'google_auth_service.dart';
import '../contracts/ohey_api_paths.dart';
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
  AuthRepository(this._clerk, {GoogleAuthService? googleAuthService})
    : _googleAuthService = googleAuthService ?? GoogleAuthService();

  final ClerkAuthService _clerk;
  final GoogleAuthService _googleAuthService;

  bool get isSignedIn => _clerk.isSignedIn;

  String? get currentEmail => _clerk.currentUserEmail;

  Future<void> resetPasswordForEmail(String email) {
    throw const AuthException('パスワード再設定は現在準備中です。');
  }

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    if (provider == OAuthProvider.google) {
      try {
        final tokens = await _googleAuthService.signIn();
        if (tokens == null) return;
        await _clerk.signInWithGoogleIdToken(tokens.idToken);
        return;
      } on GoogleAuthException catch (e) {
        throw AuthException(e.message);
      }
    }

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
    // Ohey backend owns public signup so the app can create a Clerk user
    // without depending on a client-side Clerk signup session/verification state.
    await _createBackendClerkUser(
      email: email,
      password: password,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatar.encode(),
    );
    await _clerk.signInWithPassword(email: email, password: password);
  }

  Future<void> _createBackendClerkUser({
    required String email,
    required String password,
    required String userId,
    required String displayName,
    required String avatarUrl,
  }) async {
    final baseUri = Uri.parse(BackendConfig.baseUrl);
    final uri = baseUri.replace(
      path: _joinPath(baseUri.path, OheyApiPaths.authSignup),
    );
    final client = HttpClient();
    try {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 12));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'email': email,
          'password': password,
          'user_id': userId,
          'display_name': displayName,
          'avatar_url': avatarUrl,
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final text = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(_friendlySignupError(text));
      }
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException('通信がタイムアウトしました。もう一度試してね。');
    } on SocketException {
      throw const AuthException('ネットワーク接続を確認してね。');
    } finally {
      client.close(force: true);
    }
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

String _joinPath(String basePath, String path) {
  final base = basePath.endsWith('/')
      ? basePath.substring(0, basePath.length - 1)
      : basePath;
  final child = path.startsWith('/') ? path : '/$path';
  return '$base$child';
}

String _friendlySignupError(String responseText) {
  try {
    final decoded = jsonDecode(responseText);
    if (decoded is Map) {
      final message = decoded['error'] ?? decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
  } catch (_) {
    // Fall back to a generic message below.
  }
  return '登録情報を確認してください。';
}
