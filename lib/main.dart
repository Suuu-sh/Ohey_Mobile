import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/ohey_ads_config.dart';
import 'core/application/ohey_user_controller.dart';
import 'core/data/auth_identity_provider.dart';
import 'core/data/auth_state_provider.dart';
import 'core/data/clerk_auth_service.dart';
import 'core/data/ohey_last_account_store.dart';
import 'core/preview/ohey_ui_preview.dart';
import 'core/services/ohey_ads_consent_service.dart';
import 'core/services/ohey_plus_service.dart';
import 'core/services/ohey_push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/ohey_theme_mode.dart';
import 'core/widgets/ohey_tab_shell.dart';
import 'core/widgets/ohey_startup_splash.dart';
import 'features/onboarding/application/ohey_auth_flow_policy.dart';

const _appDisplayName = 'Ohey';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  OheyStartupClock.start();

  await OheyThemeModeController.preload();

  if (oheyUiPreviewEnabled) {
    await OheyLastAccountStore.setSessionRestoreSuppressed(false);
  }

  runApp(
    ProviderScope(
      overrides: oheyUiPreviewEnabled ? oheyUiPreviewOverrides() : const [],
      child: const OheyApp(),
    ),
  );
}

final _oheyBootstrapProvider = FutureProvider<void>((ref) async {
  await ref
      .read(clerkAuthServiceProvider)
      .initialize()
      .timeout(const Duration(seconds: 12));

  if (oheyUiPreviewEnabled) {
    // Preview mode stays fully offline: no ads, purchases, or push setup.
    await _preloadBackendProfileIfSessionExists(ref);
    return;
  }

  if (OheyAdsConfig.isEnabled) {
    try {
      // Do not overlap UMP/ATT with the system notification prompt. Consent
      // dialogs must complete before push setup can request permission.
      await OheyAdsConsentService.prepareToRequestAds();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Ohey ad consent setup skipped: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  await _preloadBackendProfileIfSessionExists(ref);
  await ref
      .read(oheyPlusServiceProvider)
      .configureForCurrentUser()
      .timeout(const Duration(seconds: 4), onTimeout: () => false);
  ref.invalidate(oheyPlusCustomerInfoProvider);

  await ref
      .read(oheyPushNotificationServiceProvider)
      .start()
      .timeout(const Duration(seconds: 8), onTimeout: () {});
});

Future<void> _preloadBackendProfileIfSessionExists(Ref ref) async {
  final identity = ref.read(authIdentityProvider);
  final canPreload = OheyAuthFlowPolicy.shouldPreloadStoredSession(
    hasActiveSession:
        identity.currentAccessToken != null && identity.currentUserId != null,
    isSessionRestoreSuppressed:
        await OheyLastAccountStore.isSessionRestoreSuppressed(),
  );
  if (!canPreload) return;

  try {
    await ref
        .read(oheyUserProvider.notifier)
        .loadFromBackendProfile()
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    // If the backend is cold-starting or unavailable, let OheyTabShell show the
    // friendly waiting screen and retry instead of blocking the opening screen.
  }
}

class _BootstrapGate extends ConsumerStatefulWidget {
  const _BootstrapGate();

  @override
  ConsumerState<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends ConsumerState<_BootstrapGate> {
  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(_oheyBootstrapProvider);
    return bootstrap.when(
      data: (_) {
        ref.watch(authStateProvider);
        ref.watch(hasAuthSessionProvider);
        return const OheyTabShell();
      },
      loading: () => const OheyStartupSplash(),
      error: (error, stackTrace) => OheyStartupSplash(
        message: '起動に失敗しました',
        detail: kDebugMode ? '$error' : null,
        onRetry: () => ref.invalidate(_oheyBootstrapProvider),
      ),
    );
  }
}

class OheyApp extends ConsumerWidget {
  const OheyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(oheyThemeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _appDisplayName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode.isWhite ? ThemeMode.light : ThemeMode.dark,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.92,
              maxScaleFactor: 0.92,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _BootstrapGate(),
    );
  }
}
