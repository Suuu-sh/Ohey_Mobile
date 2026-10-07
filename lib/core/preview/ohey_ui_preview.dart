import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart';

import '../data/backend_api_client.dart';
import '../data/clerk_auth_service.dart';
import 'ohey_preview_backend.dart';

/// Debug-only UI preview mode.
///
/// Runs the signed-in app against in-memory fixtures so every screen can be
/// reviewed in the Simulator without a Clerk account, a backend, or any other
/// network service. Enable with `--dart-define=OHEY_UI_PREVIEW=true`; release
/// builds always ignore the flag.
const oheyUiPreviewEnabled =
    !kReleaseMode && bool.fromEnvironment('OHEY_UI_PREVIEW');

/// With `--dart-define=OHEY_UI_PREVIEW_SIGNED_OUT=true` the preview starts
/// signed out, so the login and onboarding screens can be reviewed.
const oheyUiPreviewSignedOut = bool.fromEnvironment(
  'OHEY_UI_PREVIEW_SIGNED_OUT',
);

/// Provider overrides that swap auth and the backend for preview fakes.
List<Override> oheyUiPreviewOverrides() => [
  clerkAuthServiceProvider.overrideWith((ref) {
    final service = OheyPreviewAuthService();
    ref.onDispose(service.dispose);
    return service;
  }),
  backendApiClientProvider.overrideWith((ref) {
    final client = OheyPreviewBackendApiClient();
    ref.onDispose(client.close);
    return client;
  }),
];

/// Fixture auth session for [oheyUiPreviewEnabled]: signed in as the fixture
/// user, or signed out when [oheyUiPreviewSignedOut] is set.
class OheyPreviewAuthService extends ClerkAuthService {
  @override
  bool get isEnabled => true;

  @override
  bool get isInitialized => true;

  @override
  bool get isSignedIn => !oheyUiPreviewSignedOut;

  @override
  String? get currentUserId => isSignedIn ? OheyPreviewFixtures.meId : null;

  @override
  String? get currentUserEmail => isSignedIn ? 'preview@ohey.invalid' : null;

  @override
  String? get currentAccessToken => isSignedIn ? 'ohey-ui-preview' : null;

  @override
  Future<String?> currentAccessTokenOrRefresh() async => currentAccessToken;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> suspendCurrentSessionLocally() async {}

  @override
  Future<void> signOut() async {}
}
