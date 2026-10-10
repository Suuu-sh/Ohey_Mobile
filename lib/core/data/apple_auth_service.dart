import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'apple_auth_diagnostics.dart';

class AppleAuthTokens {
  const AppleAuthTokens({
    required this.idToken,
    required this.nonce,
    this.authorizationCode,
    this.email,
    this.givenName,
    this.familyName,
  });

  final String idToken;
  final String nonce;
  final String? authorizationCode;
  final String? email;
  final String? givenName;
  final String? familyName;
}

class AppleAuthService {
  static const _interactiveTimeout = Duration(seconds: 90);
  static const _defaultAvailabilityTimeout = Duration(seconds: 10);

  AppleAuthService({
    Future<bool> Function()? availabilityChecker,
    bool Function()? platformSupportChecker,
    Duration availabilityTimeout = _defaultAvailabilityTimeout,
  }) : _availabilityChecker =
           availabilityChecker ?? SignInWithApple.isAvailable,
       _platformSupportChecker = platformSupportChecker,
       _availabilityTimeout = availabilityTimeout;

  final Future<bool> Function() _availabilityChecker;
  final bool Function()? _platformSupportChecker;
  final Duration _availabilityTimeout;

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  bool get _supportsPlatform =>
      _platformSupportChecker?.call() ?? _isSupportedPlatform;

  Future<bool> isSupportedAndAvailable() async {
    if (!_supportsPlatform) return false;
    try {
      return await _availabilityChecker().timeout(_availabilityTimeout);
    } catch (error) {
      logAppleAuthFailure(
        stage: AppleAuthDiagnosticStage.availabilityProbe,
        error: error,
      );
      return false;
    }
  }

  Future<AppleAuthTokens?> signIn() async {
    if (!_supportsPlatform) {
      const error = AppleAuthException('AppleログインはApple端末でのみ利用できます。');
      logAppleAuthFailure(
        stage: AppleAuthDiagnosticStage.credential,
        error: error,
        safeReason: 'unsupported_platform',
      );
      throw error;
    }
    if (!await isSupportedAndAvailable()) {
      const error = AppleAuthException('この端末ではAppleログインを利用できません。');
      logAppleAuthFailure(
        stage: AppleAuthDiagnosticStage.credential,
        error: error,
        safeReason: 'unavailable',
      );
      throw error;
    }

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256OfString(rawNonce);

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      ).timeout(_interactiveTimeout);
    } on TimeoutException catch (error) {
      logAppleAuthFailure(
        stage: AppleAuthDiagnosticStage.credential,
        error: error,
        safeReason: 'timeout',
      );
      throw const AppleAuthException('Apple認証がタイムアウトしました。もう一度試してね。');
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      logAppleAuthFailure(
        stage: AppleAuthDiagnosticStage.credential,
        error: error,
        safeReason: error.code.name,
      );
      throw AppleAuthException(_mapAuthorizationError(error));
    } catch (error) {
      logAppleAuthFailure(
        stage: AppleAuthDiagnosticStage.credential,
        error: error,
      );
      rethrow;
    }

    final idToken = credential.identityToken?.trim();
    if (idToken == null || idToken.isEmpty) {
      const error = AppleAuthException('Apple認証トークンを取得できませんでした。');
      logAppleAuthFailure(
        stage: AppleAuthDiagnosticStage.credential,
        error: error,
        safeReason: 'missing_identity_token',
      );
      throw error;
    }

    final code = credential.authorizationCode.trim();
    return AppleAuthTokens(
      idToken: idToken,
      nonce: rawNonce,
      authorizationCode: code.isEmpty ? null : code,
      email: _trimOrNull(credential.email),
      givenName: _trimOrNull(credential.givenName),
      familyName: _trimOrNull(credential.familyName),
    );
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256OfString(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _mapAuthorizationError(
    SignInWithAppleAuthorizationException error,
  ) {
    return switch (error.code) {
      AuthorizationErrorCode.invalidResponse => 'Apple認証の応答が不正です。もう一度試してね。',
      AuthorizationErrorCode.notHandled => 'Apple認証が完了しませんでした。もう一度試してね。',
      AuthorizationErrorCode.failed => 'Apple認証に失敗しました。もう一度試してね。',
      AuthorizationErrorCode.unknown => 'Apple認証で不明なエラーが発生しました。',
      AuthorizationErrorCode.canceled => 'Apple認証がキャンセルされました。',
      AuthorizationErrorCode.notInteractive => 'Apple認証を表示できませんでした。もう一度試してね。',
      AuthorizationErrorCode.matchedExcludedCredential =>
        'このApple IDではログインできません。',
      AuthorizationErrorCode.credentialImport => 'Apple認証情報を取り込めませんでした。',
      AuthorizationErrorCode.credentialExport => 'Apple認証情報を出力できませんでした。',
    };
  }
}

class AppleAuthException implements Exception {
  const AppleAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
