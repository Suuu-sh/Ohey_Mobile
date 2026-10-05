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

/// Always-signed-in auth session for [oheyUiPreviewEnabled].
class OheyPreviewAuthService extends ClerkAuthService {
  @override
  bool get isEnabled => true;

  @override
  bool get isInitialized => true;

  @override
  bool get isSignedIn => true;

  @override
  String? get currentUserId => OheyPreviewFixtures.meId;

  @override
  String? get currentUserEmail => 'preview@ohey.invalid';

  @override
  String? get currentAccessToken => 'ohey-ui-preview';

  @override
  Future<String?> currentAccessTokenOrRefresh() async => currentAccessToken;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> suspendCurrentSessionLocally() async {}

  @override
  Future<void> signOut() async {}
}
