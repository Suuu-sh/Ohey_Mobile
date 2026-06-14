import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/auth_provider_config.dart';

final clerkAuthServiceProvider = Provider<ClerkAuthService>((ref) {
  final service = ClerkAuthService();
  ref.onDispose(service.dispose);
  return service;
});

class ClerkAuthService {
  ClerkAuthService();

  ClerkOheyAuth? _auth;
  Future<void>? _initializeFuture;
  clerk.SessionToken? _sessionToken;
  bool _sessionSuspendedLocally = false;
  StreamSubscription<clerk.SessionToken>? _tokenSubscription;
  final _authChanges = StreamController<void>.broadcast();

  bool get isEnabled => AuthProviderConfig.isClerkEnabled;

  bool get isInitialized => _auth != null;

  String? get _rawCurrentUserId => _auth?.user?.id;

  String? get currentUserId => isSignedIn ? _rawCurrentUserId : null;

  String? get currentUserEmail => isSignedIn ? _auth?.user?.email : null;

  String? get currentAccessToken =>
      _sessionSuspendedLocally ? null : _sessionToken?.jwt;

  Future<String?> currentAccessTokenOrRefresh() async {
    if (_sessionSuspendedLocally) return null;
    if (_sessionToken?.jwt.trim().isNotEmpty == true) {
      return _sessionToken?.jwt;
    }
    await initialize();
    await _refreshCachedSessionTokenWithRetry();
    return _sessionSuspendedLocally ? null : _sessionToken?.jwt;
  }

  bool get isSignedIn =>
      currentAccessToken?.trim().isNotEmpty == true &&
      _rawCurrentUserId?.trim().isNotEmpty == true;

  Stream<void> get authChanges => _authChanges.stream;

  Future<void> initialize() {
    if (!isEnabled) return Future<void>.value();
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    final auth = ClerkOheyAuth(
      config: clerk.AuthConfig(
        publishableKey: AuthProviderConfig.clerkPublishableKey,
        persistor: SharedPreferencesClerkPersistor(),
      ),
      onUpdated: _refreshCachedSessionToken,
    );
    _auth = auth;
    await auth.initialize();
    _tokenSubscription = auth.sessionTokenStream.listen((token) {
      _sessionToken = token;
      _authChanges.add(null);
    });
    await _refreshCachedSessionToken();
  }

  Future<void> _refreshCachedSessionToken() async {
    final auth = _auth;
    if (_sessionSuspendedLocally || auth == null || !auth.isSignedIn) {
      _sessionToken = null;
      return;
    }
    try {
      final token = await auth.sessionToken();
      _sessionToken = _sessionSuspendedLocally ? null : token;
    } catch (_) {
      _sessionToken = null;
    }
  }

  Future<void> _refreshCachedSessionTokenWithRetry() async {
    for (var attempt = 0; attempt < 10; attempt += 1) {
      await _refreshCachedSessionToken();
      if (_sessionToken?.jwt.trim().isNotEmpty == true &&
          _rawCurrentUserId != null) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> signInWithGoogleIdToken(String idToken) async {
    await initialize();
    final auth = _requireAuth();
    _sessionSuspendedLocally = false;
    await auth.idTokenSignIn(
      provider: clerk.IdTokenProvider.google,
      token: idToken.trim(),
    );
    await _refreshCachedSessionTokenWithRetry();
    _authChanges.add(null);
  }

  Future<void> signInWithAppleIdToken(String idToken) async {
    await initialize();
    final auth = _requireAuth();
    _sessionSuspendedLocally = false;
    await auth.idTokenSignIn(
      provider: clerk.IdTokenProvider.apple,
      token: idToken.trim(),
    );
    await _refreshCachedSessionTokenWithRetry();
    _authChanges.add(null);
  }

  Future<void> sendPasswordResetCode(String email) async {
    await initialize();
    final auth = _requireAuth();
    _sessionSuspendedLocally = false;
    await auth.initiatePasswordReset(
      identifier: email.trim(),
      strategy: clerk.Strategy.resetPasswordEmailCode,
    );
    _authChanges.add(null);
  }

  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await initialize();
    final auth = _requireAuth();
    _sessionSuspendedLocally = false;
    await auth.attemptSignIn(
      strategy: clerk.Strategy.resetPasswordEmailCode,
      identifier: email.trim(),
      code: code.trim(),
      password: newPassword,
    );
    await _activateSessionForEmail(email);
    await _refreshCachedSessionTokenWithRetry();
    _authChanges.add(null);
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await initialize();
    final auth = _requireAuth();
    _sessionSuspendedLocally = false;
    await auth.attemptSignIn(
      strategy: clerk.Strategy.password,
      identifier: email,
      password: password,
    );
    await _activateSessionForEmail(email);
    await _refreshCachedSessionTokenWithRetry();
    _authChanges.add(null);
  }

  Future<Uri?> startOAuthSignIn(clerk.Strategy strategy) async {
    await initialize();
    final auth = _requireAuth();
    _sessionSuspendedLocally = false;
    await auth.oauthSignIn(
      strategy: strategy,
      redirect: Uri.parse(AuthProviderConfig.redirectUrl),
    );
    return Uri.tryParse(
      auth.signIn?.verification?.externalVerificationRedirectUrl ??
          auth
              .signUp
              ?.verifications
              .values
              .firstOrNull
              ?.externalVerificationRedirectUrl ??
          '',
    );
  }

  Future<void> completeOAuthCallback(Uri uri) async {
    if (!isEnabled) return;
    await initialize();
    final token =
        uri.queryParameters['token'] ??
        uri.queryParameters['code'] ??
        uri.queryParameters['ticket'];
    if (token == null || token.trim().isEmpty) return;
    _sessionSuspendedLocally = false;
    await _requireAuth().completeOAuthSignIn(token: token);
    await _refreshCachedSessionTokenWithRetry();
    _authChanges.add(null);
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
    required String displayName,
    required String userId,
    required String avatarUrl,
  }) async {
    await initialize();
    final auth = _requireAuth();
    _sessionSuspendedLocally = false;
    await auth.attemptSignUp(
      strategy: clerk.Strategy.password,
      emailAddress: email,
      password: password,
      passwordConfirmation: password,
      firstName: displayName,
      metadata: {
        'user_id': userId,
        'display_name': displayName,
        'character_key': 'avatar',
        'avatar_url': avatarUrl,
      },
    );
    await _refreshCachedSessionToken();
    _authChanges.add(null);
  }

  Future<bool> _activateSessionForEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return false;
    final auth = _requireAuth();
    for (final session in auth.client.sessions) {
      if (session.user.email?.trim().toLowerCase() == normalizedEmail) {
        await auth.activate(session);
        return true;
      }
    }
    return false;
  }

  Future<bool> switchToSavedAccount(String email) async {
    await initialize();
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return false;
    final auth = _requireAuth();
    for (final session in auth.client.sessions) {
      if (session.user.email?.trim().toLowerCase() == normalizedEmail) {
        _sessionSuspendedLocally = false;
        await auth.activate(session);
        await _refreshCachedSessionTokenWithRetry();
        _authChanges.add(null);
        return _sessionToken?.jwt.trim().isNotEmpty == true;
      }
    }
    return false;
  }

  Future<void> suspendCurrentSessionLocally() async {
    await initialize();
    _sessionSuspendedLocally = true;
    _sessionToken = null;
    _authChanges.add(null);
  }

  Future<void> signOut() async {
    await initialize();
    final auth = _auth;
    if (auth == null) return;
    await auth.signOut();
    _sessionSuspendedLocally = false;
    _sessionToken = null;
    _authChanges.add(null);
  }

  ClerkOheyAuth _requireAuth() {
    final auth = _auth;
    if (auth == null) {
      throw const clerk.ClerkError(
        code: clerk.ClerkErrorCode.clientAppError,
        message: 'Clerk is not initialized',
      );
    }
    return auth;
  }

  void dispose() {
    _tokenSubscription?.cancel();
    _authChanges.close();
    try {
      if (_auth != null && _initializeFuture != null) {
        _auth?.terminate();
      }
    } catch (_) {
      // clerk_auth can throw if the Auth instance did not finish initializing.
    }
  }
}

class ClerkOheyAuth extends clerk.Auth {
  ClerkOheyAuth({required super.config, required this.onUpdated});

  final FutureOr<void> Function() onUpdated;

  @override
  void update() {
    super.update();
    unawaited(Future<void>.sync(onUpdated));
  }
}

class SharedPreferencesClerkPersistor implements clerk.Persistor {
  SharedPreferences? _prefs;

  static const _prefix = 'clerk_auth:';

  @override
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  void terminate() {}

  @override
  FutureOr<T?> read<T>(String key) {
    final value = _prefs?.getString('$_prefix$key');
    if (value == null) return null;
    if (T == String) return value as T;
    return null;
  }

  @override
  FutureOr<void> write<T>(String key, T value) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', value.toString());
  }

  @override
  FutureOr<void> delete(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }
}
