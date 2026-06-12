import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/auth_provider_config.dart';

class GoogleAuthTokens {
  const GoogleAuthTokens({
    required this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
  });

  final String idToken;
  final String? accessToken;
  final String? email;
  final String? displayName;
}

class GoogleAuthService {
  GoogleAuthService()
    : _googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: _emptyToNull(AuthProviderConfig.googleWebClientId),
        clientId: _emptyToNull(AuthProviderConfig.googleIosClientId),
      );

  static const _interactiveTimeout = Duration(seconds: 90);
  static const _tokenFetchTimeout = Duration(seconds: 20);

  final GoogleSignIn _googleSignIn;

  Future<GoogleAuthTokens?> signIn() async {
    if (AuthProviderConfig.googleWebClientId.trim().isEmpty) {
      throw const GoogleAuthException('Googleログイン設定が不足しています。');
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        AuthProviderConfig.googleIosClientId.trim().isEmpty) {
      throw const GoogleAuthException('iOSのGoogleログイン設定が不足しています。');
    }

    try {
      final account = await _googleSignIn.signIn().timeout(_interactiveTimeout);
      if (account == null) return null;

      final auth = await account.authentication.timeout(_tokenFetchTimeout);
      final idToken = auth.idToken?.trim();
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleAuthException('Google認証トークンを取得できませんでした。');
      }

      return GoogleAuthTokens(
        idToken: idToken,
        accessToken: auth.accessToken,
        email: account.email,
        displayName: account.displayName,
      );
    } on TimeoutException {
      throw const GoogleAuthException('Google認証がタイムアウトしました。もう一度試してね。');
    }
  }

  Future<void> signOutSilently() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  static String? _emptyToNull(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
