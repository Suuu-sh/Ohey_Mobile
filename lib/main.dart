import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/application/nomo_user_controller.dart';
import 'core/data/auth_session_guard.dart';
import 'core/data/supabase_client_provider.dart';
import 'core/services/nomo_push_notification_service.dart';
import 'core/services/nomo_widget_sync.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/nomo_theme_mode.dart';
import 'core/widgets/nomo_tab_shell.dart';

const _openingNomoAsset = 'assets/images/opening_nomo.png';
const _openingNomoArtworkOffset = Offset(18, 0);
const _minimumOpeningDuration = Duration(seconds: 1);
const _openingExitDurationMs = 520;

ui.Image? _openingNomoImage;

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();

  try {
    await _loadOpeningNomoImage().timeout(const Duration(seconds: 3));
  } on Object {
    // If decoding ever fails, fall back to the regular asset image below.
  }

  runApp(const ProviderScope(child: NomoApp()));
  binding.allowFirstFrame();
}

Future<void> _loadOpeningNomoImage() async {
  final data = await rootBundle.load(_openingNomoAsset);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  _openingNomoImage = frame.image;
}

final _nomoBootstrapProvider = FutureProvider<void>((ref) async {
  final alreadyInitialized = _isSupabaseInitialized();
  final minimumOpening = alreadyInitialized
      ? Future<void>.value()
      : Future<void>.delayed(_minimumOpeningDuration);
  try {
    if (!alreadyInitialized) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.publishableKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          detectSessionInUri: true,
        ),
      ).timeout(const Duration(seconds: 12));
    }

    await AuthSessionGuard.clearIfProjectMismatch(
      Supabase.instance.client,
    ).timeout(const Duration(seconds: 4), onTimeout: () {});

    await _preloadBackendProfileIfSessionExists(ref);

    await ref
        .read(nomoPushNotificationServiceProvider)
        .start()
        .timeout(const Duration(seconds: 8), onTimeout: () {});
  } finally {
    await minimumOpening;
  }
});

Future<void> _preloadBackendProfileIfSessionExists(Ref ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return;

  try {
    await ref
        .read(nomoUserProvider.notifier)
        .loadFromBackendProfile()
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    // If the backend is cold-starting or unavailable, let NomoTabShell show the
    // friendly waiting screen and retry instead of blocking the opening screen.
  }
}

bool _isSupabaseInitialized() {
  try {
    return Supabase.instance.isInitialized;
  } catch (_) {
    return false;
  }
}

class _BootstrapGate extends ConsumerStatefulWidget {
  const _BootstrapGate();

  @override
  ConsumerState<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends ConsumerState<_BootstrapGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _openingExitController;
  late final Animation<double> _openingExitFade;
  bool _openingExitCompleted = false;

  @override
  void initState() {
    super.initState();
    _openingExitController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: _openingExitDurationMs),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _openingExitCompleted = true);
          }
        });
    _openingExitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _openingExitController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _openingExitController.dispose();
    super.dispose();
  }

  void _startOpeningExit() {
    if (_openingExitCompleted ||
        _openingExitController.isAnimating ||
        _openingExitController.value > 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _openingExitCompleted ||
          _openingExitController.isAnimating ||
          _openingExitController.value > 0) {
        return;
      }
      _openingExitController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(_nomoBootstrapProvider, (previous, next) {
      if (next.isLoading) {
        _openingExitCompleted = false;
        _openingExitController.reset();
      }
    });

    final bootstrap = ref.watch(_nomoBootstrapProvider);
    return bootstrap.when(
      data: (_) {
        ref.watch(supabaseAuthStateProvider);
        ref.watch(supabaseClientProvider).auth.currentSession;
        _startOpeningExit();

        return Stack(
          fit: StackFit.expand,
          children: [
            const NomoTabShell(),
            const NomoWidgetSnapshotSync(),
            if (!_openingExitCompleted)
              FadeTransition(
                opacity: _openingExitFade,
                child: const _StartupScreen(),
              ),
          ],
        );
      },
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
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFF0A8D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _OpeningNomoArtwork(),
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

class _OpeningNomoArtwork extends StatelessWidget {
  const _OpeningNomoArtwork();

  @override
  Widget build(BuildContext context) {
    final image = _openingNomoImage;
    if (image == null) {
      return Transform.translate(
        offset: _openingNomoArtworkOffset,
        child: Image.asset(_openingNomoAsset, fit: BoxFit.cover),
      );
    }
    return Transform.translate(
      offset: _openingNomoArtworkOffset,
      child: RawImage(image: image, fit: BoxFit.cover),
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
