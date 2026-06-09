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
  StreamSubscription<clerk.SessionToken>? _tokenSubscription;

  bool get isEnabled => AuthProviderConfig.isClerkEnabled;

  bool get isInitialized => _auth != null;

  String? get currentUserId => _auth?.user?.id;

  String? get currentUserEmail => _auth?.user?.email;

  String? get currentAccessToken => _sessionToken?.jwt;

  bool get isSignedIn => _auth?.isSignedIn == true;

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
    });
    await _refreshCachedSessionToken();
  }

  Future<void> _refreshCachedSessionToken() async {
    final auth = _auth;
    if (auth == null || !auth.isSignedIn) {
      _sessionToken = null;
      return;
    }
    try {
      _sessionToken = await auth.sessionToken();
    } catch (_) {
      _sessionToken = null;
    }
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await initialize();
    final auth = _requireAuth();
    await auth.attemptSignIn(
      strategy: clerk.Strategy.password,
      identifier: email,
      password: password,
    );
    await _refreshCachedSessionToken();
  }

  Future<void> signOut() async {
    await initialize();
    final auth = _auth;
    if (auth == null) return;
    await auth.signOut();
    _sessionToken = null;
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
    _auth?.terminate();
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
