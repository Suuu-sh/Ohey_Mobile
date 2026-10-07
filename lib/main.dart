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
import 'features/onboarding/application/ohey_auth_flow_policy.dart';
import 'package:ohey/core/theme/app_colors.dart';

const _appDisplayName = 'Ohey';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      loading: () => const _StartupScreen(),
      error: (error, stackTrace) => _StartupScreen(
        message: '起動に失敗しました',
        detail: kDebugMode ? '$error' : null,
        onRetry: () => ref.invalidate(_oheyBootstrapProvider),
      ),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen({this.message, this.detail, this.onRetry});

  final String? message;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final hasError = message != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordmarkColor = isDark ? AppColors.white : const Color(0xFF3C1237);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FractionallySizedBox(
                  widthFactor: .72,
                  child: Image.asset(
                    'assets/images/mascot/ohey_mascot_fullbody.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _appDisplayName,
                  style: TextStyle(
                    color: wordmarkColor,
                    fontFamily: 'MPLUSRounded1c',
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 20),
                  _StartupError(
                    message: message!,
                    detail: detail,
                    onRetry: onRetry,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({
    required this.message,
    required this.isDark,
    this.detail,
    this.onRetry,
  });

  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.white : const Color(0xFF3C1237);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
        ),
        if (detail != null) ...[
          const SizedBox(height: 8),
          Text(
            detail!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withValues(alpha: .72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('もう一度試す')),
        ],
      ],
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
