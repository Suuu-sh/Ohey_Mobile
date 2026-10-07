import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One monotonic clock shared by app bootstrap and session restore so a delayed
/// hint is never restarted by an intermediate widget.
class OheyStartupClock {
  OheyStartupClock._();

  static final Stopwatch _stopwatch = Stopwatch();

  static Duration get elapsed => _stopwatch.elapsed;

  static void start() {
    _stopwatch
      ..reset()
      ..start();
  }
}

/// The Flutter handoff for the native launch splash, also used while a stored
/// session is being restored. A status hint is shown only after a real wait.
class OheyStartupSplash extends StatefulWidget {
  const OheyStartupSplash({
    super.key,
    this.message,
    this.detail,
    this.onRetry,
    this.elapsedAtStart,
    this.preparingAfter = const Duration(seconds: 5),
  });

  final String? message;
  final String? detail;
  final VoidCallback? onRetry;
  final Duration? elapsedAtStart;
  final Duration preparingAfter;

  @override
  State<OheyStartupSplash> createState() => _OheyStartupSplashState();
}

class _OheyStartupSplashState extends State<OheyStartupSplash> {
  late Duration _elapsedAtStart;
  Timer? _preparingTimer;
  bool _showPreparing = false;

  @override
  void initState() {
    super.initState();
    _elapsedAtStart = widget.elapsedAtStart ?? OheyStartupClock.elapsed;
    _schedulePreparingHint();
  }

  @override
  void didUpdateWidget(covariant OheyStartupSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elapsedAtStart != widget.elapsedAtStart ||
        oldWidget.preparingAfter != widget.preparingAfter) {
      _elapsedAtStart = widget.elapsedAtStart ?? OheyStartupClock.elapsed;
      _showPreparing = false;
      _schedulePreparingHint();
    }
  }

  void _schedulePreparingHint() {
    _preparingTimer?.cancel();
    final remaining = widget.preparingAfter - _elapsedAtStart;
    if (remaining <= Duration.zero) {
      _showPreparing = true;
      return;
    }
    _preparingTimer = Timer(remaining, () {
      if (mounted) setState(() => _showPreparing = true);
    });
  }

  @override
  void dispose() {
    _preparingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.message != null;
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
                  'Ohey',
                  style: TextStyle(
                    color: wordmarkColor,
                    fontFamily: 'MPLUSRounded1c',
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: !hasError && _showPreparing
                      ? Padding(
                          key: const ValueKey('preparing'),
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '準備中…',
                            style: TextStyle(
                              color: wordmarkColor.withValues(alpha: .52),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-preparing')),
                ),
                if (hasError) ...[
                  const SizedBox(height: 20),
                  _StartupError(
                    message: widget.message!,
                    detail: widget.detail,
                    onRetry: widget.onRetry,
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
