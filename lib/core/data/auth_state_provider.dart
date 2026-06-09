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

final hasAuthSessionProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  if (AuthProviderConfig.isClerkEnabled) {
    return ref.watch(clerkAuthServiceProvider).isSignedIn;
  }
  return ref.watch(supabaseClientProvider).auth.currentSession != null;
});
