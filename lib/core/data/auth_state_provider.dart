import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/auth_provider_config.dart';
import 'clerk_auth_service.dart';
import 'supabase_client_provider.dart';

final authStateProvider = StreamProvider<void>((ref) {
  if (AuthProviderConfig.isClerkEnabled) {
    return ref.watch(clerkAuthServiceProvider).authChanges;
  }
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange.map((_) {});
});

final clerkOAuthCallbackProvider = Provider<ClerkOAuthCallbackHandler>((ref) {
  return ClerkOAuthCallbackHandler(ref);
});

class ClerkOAuthCallbackHandler {
  const ClerkOAuthCallbackHandler(this._ref);

  final Ref _ref;

  Future<bool> handle(Uri uri) async {
    if (!AuthProviderConfig.isClerkEnabled) return false;
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
  if (AuthProviderConfig.isClerkEnabled) {
    return ref.watch(clerkAuthServiceProvider).isSignedIn;
  }
  return ref.watch(supabaseClientProvider).auth.currentSession != null;
});
