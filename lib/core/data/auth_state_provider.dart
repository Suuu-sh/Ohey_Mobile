import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    if ((scheme != 'app.ohey.com' && scheme != 'app.ohey.com.dev') ||
        host != 'login-callback') {
      return false;
    }
    await _ref.read(clerkAuthServiceProvider).completeOAuthCallback(uri);
    return true;
  }
}

final hasAuthSessionProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(clerkAuthServiceProvider).isSignedIn;
});
