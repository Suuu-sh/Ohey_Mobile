import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/firebase_config.dart';
import '../data/push_token_repository.dart';

final oheyPushNotificationServiceProvider =
    Provider<OheyPushNotificationService>((ref) {
      final service = OheyPushNotificationService(ref);
      ref.onDispose(service.dispose);
      return service;
    });

class OheyPushNotificationService {
  OheyPushNotificationService(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _started = false;
  String? _lastRegisteredToken;

  Future<void> start() async {
    if (_started || kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    _started = true;

    try {
      if (Firebase.apps.isEmpty) {
        final options = OheyFirebaseConfig.currentPlatformOptions;
        await Firebase.initializeApp(options: options);
      }
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _registerCurrentToken();
      _tokenRefreshSub ??= messaging.onTokenRefresh.listen((token) {
        unawaited(
          _registerToken(token, retirePrevious: true).catchError((_) {}),
        );
      });
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Ohey push setup skipped.');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _registerCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await _registerToken(token, retirePrevious: false);
  }

  Future<void> registerCurrentTokenForSignedInUser() async {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    if (!_started) {
      await start();
      return;
    }
    try {
      await _registerCurrentToken();
    } catch (_) {
      // Push token registration should not block profile activation.
    }
  }

  Future<void> _registerToken(
    String token, {
    required bool retirePrevious,
  }) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    final repository = _ref.read(pushTokenRepositoryProvider);
    final previous = _lastRegisteredToken;
    if (retirePrevious && previous != null && previous != normalized) {
      await repository.unregisterToken(previous);
    }
    final registered = await repository.registerToken(normalized);
    if (registered) {
      _lastRegisteredToken = normalized;
    }
  }

  Future<void> unregisterCurrentToken() async {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    try {
      final token =
          _lastRegisteredToken ?? await FirebaseMessaging.instance.getToken();
      await _ref.read(pushTokenRepositoryProvider).unregisterToken(token);
      _lastRegisteredToken = null;
    } catch (_) {
      // Push token cleanup should never block logout.
    }
  }

  void dispose() {
    unawaited(_tokenRefreshSub?.cancel());
  }
}
