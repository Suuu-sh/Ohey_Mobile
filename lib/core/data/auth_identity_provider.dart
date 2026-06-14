import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clerk_auth_service.dart';

/// Auth identity/session boundary used by backend-facing code.
final authIdentityProvider = Provider<AuthIdentity>((ref) {
  final clerk = ref.watch(clerkAuthServiceProvider);
  return AuthIdentity(
    accessTokenProvider: () => clerk.currentAccessToken,
    accessTokenRefreshProvider: clerk.currentAccessTokenOrRefresh,
    userIdProvider: () => clerk.currentUserId,
    tokenValidator: (_) => true,
  );
});

class AuthIdentity {
  const AuthIdentity({
    required this.accessTokenProvider,
    this.accessTokenRefreshProvider,
    required this.userIdProvider,
    required this.tokenValidator,
  });

  final String? Function() accessTokenProvider;
  final Future<String?> Function()? accessTokenRefreshProvider;
  final String? Function() userIdProvider;
  final bool Function(String token) tokenValidator;

  String? get currentAccessToken => accessTokenProvider();

  Future<String?> currentAccessTokenOrRefresh() async {
    final token = accessTokenProvider();
    if (token?.trim().isNotEmpty == true) return token;
    return accessTokenRefreshProvider?.call();
  }

  String? get currentUserId => userIdProvider();

  bool isTokenValidForEnvironment(String token) => tokenValidator(token);
}
