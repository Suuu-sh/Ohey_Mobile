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

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: true,
    ),
  );

  await AuthSessionGuard.clearIfProjectMismatch(Supabase.instance.client);

  runApp(const ProviderScope(child: NomoApp()));
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
              minScaleFactor: 0.86,
              maxScaleFactor: 0.92,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const NomoTabShell(),
    );
  }
}
