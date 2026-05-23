import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/firebase_config.dart';
import '../data/push_token_repository.dart';

final nomoPushNotificationServiceProvider =
    Provider<NomoPushNotificationService>((ref) {
      final service = NomoPushNotificationService(ref);
      ref.onDispose(service.dispose);
      return service;
    });

class NomoPushNotificationService {
  NomoPushNotificationService(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _started = false;

  Future<void> start() async {
    if (_started || kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    _started = true;

    try {
      if (Firebase.apps.isEmpty) {
        final options = NomoFirebaseConfig.currentPlatformOptions;
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
      _tokenRefreshSub ??= messaging.onTokenRefresh.listen((_) {
        unawaited(_registerCurrentToken());
      });
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Nomo push setup skipped.');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _registerCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await _ref.read(pushTokenRepositoryProvider).registerToken(token);
  }

  void dispose() {
    unawaited(_tokenRefreshSub?.cancel());
  }
}
