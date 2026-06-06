import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/application/ohey_user_controller.dart';
import 'core/data/auth_session_guard.dart';
import 'core/data/supabase_client_provider.dart';
import 'core/services/ohey_push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/ohey_theme_mode.dart';
import 'core/widgets/ohey_tab_shell.dart';
import 'package:ohey/core/theme/app_colors.dart';

const _openingOheyAsset = 'assets/images/opening_ohey.png';
const _appDisplayName = 'Ohey';
const _minimumOpeningDuration = Duration(seconds: 1);
const _openingExitDurationMs = 520;

ui.Image? _openingOheyImage;

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();

  try {
    await _loadOpeningOheyImage().timeout(const Duration(seconds: 3));
  } on Object {
    // If decoding ever fails, fall back to the regular asset image below.
  }

  runApp(const ProviderScope(child: OheyApp()));
  binding.allowFirstFrame();
}

Future<void> _loadOpeningOheyImage() async {
  final data = await rootBundle.load(_openingOheyAsset);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  _openingOheyImage = frame.image;
}

final _oheyBootstrapProvider = FutureProvider<void>((ref) async {
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

    unawaited(MobileAds.instance.initialize());

    await AuthSessionGuard.clearIfProjectMismatch(
      Supabase.instance.client,
    ).timeout(const Duration(seconds: 4), onTimeout: () {});

    await _preloadBackendProfileIfSessionExists(ref);

    await ref
        .read(oheyPushNotificationServiceProvider)
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
        .read(oheyUserProvider.notifier)
        .loadFromBackendProfile()
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    // If the backend is cold-starting or unavailable, let OheyTabShell show the
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
    ref.listen<AsyncValue<void>>(_oheyBootstrapProvider, (previous, next) {
      if (next.isLoading) {
        _openingExitCompleted = false;
        _openingExitController.reset();
      }
    });

    final bootstrap = ref.watch(_oheyBootstrapProvider);
    return bootstrap.when(
      data: (_) {
        ref.watch(supabaseAuthStateProvider);
        ref.watch(supabaseClientProvider).auth.currentSession;
        _startOpeningExit();

        return Stack(
          fit: StackFit.expand,
          children: [
            const OheyTabShell(),
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.cFF02092B,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _OpeningOheyArtwork(),
          if (!hasError)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 42),
                  child: const _StartupWaitingMessage(),
                ),
              ),
            ),
          if (hasError)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.cFF08091F.withValues(alpha: .78),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.cFFFF5EA8.withValues(alpha: .28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            color: AppColors.cFFFF5EA8,
                            size: 32,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.white,
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
                                color: AppColors.white.withValues(alpha: .64),
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

class _OpeningOheyArtwork extends StatelessWidget {
  const _OpeningOheyArtwork();

  @override
  Widget build(BuildContext context) {
    final image = _openingOheyImage;
    if (image == null) {
      return Image.asset(_openingOheyAsset, fit: BoxFit.cover);
    }
    return RawImage(image: image, fit: BoxFit.cover);
  }
}

class _StartupWaitingMessage extends StatelessWidget {
  const _StartupWaitingMessage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _StartupWordmark(),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.cFF08091F.withValues(alpha: .34),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.white.withValues(alpha: .18)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: .18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '$_appDisplayNameを準備してるよ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'もうすぐ開きます',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: .76),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.1,
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StartupDot(),
                    SizedBox(width: 8),
                    _StartupDot(),
                    SizedBox(width: 8),
                    _StartupDot(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StartupWordmark extends StatelessWidget {
  const _StartupWordmark();

  @override
  Widget build(BuildContext context) {
    final strokeStyle = TextStyle(
      fontFamily: 'MPLUSRounded1c',
      fontSize: 48,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.2,
      foreground: ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = AppColors.cFF160C52.withValues(alpha: .50),
    );

    const fillStyle = TextStyle(
      color: AppColors.white,
      fontFamily: 'MPLUSRounded1c',
      fontSize: 48,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.2,
      shadows: [
        Shadow(
          color: AppColors.c99060A35,
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
        Shadow(
          color: AppColors.c99FF5EA8,
          blurRadius: 22,
          offset: Offset(0, 0),
        ),
      ],
    );

    return Semantics(
      label: _appDisplayName,
      child: ExcludeSemantics(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(_appDisplayName, style: strokeStyle),
            ShaderMask(
              blendMode: ui.BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.white,
                  AppColors.cFFFFF7B0,
                  AppColors.cFFFFA3D4,
                ],
              ).createShader(bounds),
              child: const Text(_appDisplayName, style: fillStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupDot extends StatelessWidget {
  const _StartupDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.cFF9AF21A,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.white.withValues(alpha: .24),
            blurRadius: 10,
          ),
        ],
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
