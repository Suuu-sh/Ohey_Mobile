import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clerk_auth_service.dart';

/// Auth identity/session boundary used by backend-facing code.
final authIdentityProvider = Provider<AuthIdentity>((ref) {
  final clerk = ref.watch(clerkAuthServiceProvider);
  return AuthIdentity(
    accessTokenProvider: () => clerk.currentAccessToken,
    userIdProvider: () => clerk.currentUserId,
    tokenValidator: (_) => true,
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
