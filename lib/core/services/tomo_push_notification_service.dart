import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/firebase_config.dart';
import '../data/push_token_repository.dart';

final tomoPushNotificationServiceProvider =
    Provider<TomoPushNotificationService>((ref) {
      final service = TomoPushNotificationService(ref);
      ref.onDispose(service.dispose);
      return service;
    });

class TomoPushNotificationService {
  TomoPushNotificationService(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _started = false;
  String? _lastRegisteredToken;

  Future<void> start() async {
    if (_started || kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    _started = true;

    try {
      if (Firebase.apps.isEmpty) {
        final options = TomoFirebaseConfig.currentPlatformOptions;
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
        unawaited(_registerToken(token, retirePrevious: true));
      });
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Tomo push setup skipped.');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _registerCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await _registerToken(token, retirePrevious: false);
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
    await repository.registerToken(normalized);
    _lastRegisteredToken = normalized;
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
