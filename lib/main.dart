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
      backgroundColor: const Color(0xFF0B1420),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xFF12C9A4).withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  child: hasError
                      ? const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFFF5EA8),
                          size: 34,
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF12C9A4),
                            strokeWidth: 4,
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                Text(
                  message ?? 'Nomoを起動中...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    detail!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .58),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: 18),
                  FilledButton(onPressed: onRetry, child: const Text('もう一度試す')),
                ],
              ],
            ),
          ),
        ),
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
