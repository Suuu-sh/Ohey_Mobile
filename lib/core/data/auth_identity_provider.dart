import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/auth_provider_config.dart';
import 'auth_session_guard.dart';
import 'clerk_auth_service.dart';
import 'supabase_client_provider.dart';

/// Auth identity/session boundary used by backend-facing code.
///
/// The current implementation still reads Supabase Auth, but callers should use
/// this provider instead of depending on Supabase directly. During the Clerk
/// migration this is the seam that will switch to Clerk session tokens and
/// Clerk user ids.
final authIdentityProvider = Provider<AuthIdentity>((ref) {
  if (AuthProviderConfig.isClerkEnabled) {
    final clerk = ref.watch(clerkAuthServiceProvider);
    return AuthIdentity(
      accessTokenProvider: () => clerk.currentAccessToken,
      userIdProvider: () => clerk.currentUserId,
      tokenValidator: (_) => true,
    );
  }

  final supabase = ref.watch(supabaseClientProvider);
  return AuthIdentity(
    accessTokenProvider: () => supabase.auth.currentSession?.accessToken,
    userIdProvider: () => supabase.auth.currentUser?.id,
    tokenValidator: AuthSessionGuard.isTokenForCurrentProject,
  );
});

class AuthIdentity {
  const AuthIdentity({
    required this.accessTokenProvider,
    required this.userIdProvider,
    required this.tokenValidator,
  });

  final String? Function() accessTokenProvider;
  final String? Function() userIdProvider;
  final bool Function(String token) tokenValidator;

  String? get currentAccessToken => accessTokenProvider();

  String? get currentUserId => userIdProvider();

  bool isTokenValidForEnvironment(String token) => tokenValidator(token);
}
