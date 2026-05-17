import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/data/auth_session_guard.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/nomo_theme_mode.dart';
import 'core/widgets/nomo_tab_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NomoApp()));
}

final _nomoBootstrapProvider = FutureProvider<void>((ref) async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: true,
    ),
  ).timeout(const Duration(seconds: 12));

  await AuthSessionGuard.clearIfProjectMismatch(
    Supabase.instance.client,
  ).timeout(const Duration(seconds: 4), onTimeout: () {});
});

class _BootstrapGate extends ConsumerWidget {
  const _BootstrapGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(_nomoBootstrapProvider);
    return bootstrap.when(
      data: (_) => const NomoTabShell(),
      loading: () => const _StartupScreen(),
      error: (error, stackTrace) => _StartupScreen(
        message: '起動に失敗しました',
        detail: '$error',
        onRetry: () => ref.invalidate(_nomoBootstrapProvider),
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
    return Scaffold(
      backgroundColor: const Color(0xFF020312),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage('assets/images/nomo_opening.png'),
            fit: BoxFit.cover,
          ),
          if (hasError)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF08091F).withValues(alpha: .78),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFF5EA8).withValues(alpha: .28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            color: Color(0xFFFF5EA8),
                            size: 32,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          if (detail != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              detail!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .64),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (onRetry != null) ...[
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: onRetry,
                              child: const Text('もう一度試す'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NomoApp extends ConsumerWidget {
  const NomoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(nomoThemeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nomo',
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
