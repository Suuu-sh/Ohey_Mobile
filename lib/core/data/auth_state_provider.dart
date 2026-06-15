import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/auth_provider_config.dart';
import 'clerk_auth_service.dart';

final authStateProvider = StreamProvider<void>((ref) {
  return ref.watch(clerkAuthServiceProvider).authChanges;
});

final clerkOAuthCallbackProvider = Provider<ClerkOAuthCallbackHandler>((ref) {
  return ClerkOAuthCallbackHandler(ref);
});

class ClerkOAuthCallbackHandler {
  const ClerkOAuthCallbackHandler(this._ref);

  final Ref _ref;

  Future<bool> handle(Uri uri) async {
    if (!AuthProviderConfig.isAllowedOAuthCallback(uri) ||
        !_hasOAuthCallbackToken(uri)) {
      return false;
    }
    await _ref.read(clerkAuthServiceProvider).completeOAuthCallback(uri);
    return true;
  }
}

bool _hasOAuthCallbackToken(Uri uri) {
  for (final key in const ['token', 'code', 'ticket']) {
    if (uri.queryParameters[key]?.trim().isNotEmpty == true) return true;
  }
  return false;
}

final hasAuthSessionProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(clerkAuthServiceProvider).isSignedIn;
});
