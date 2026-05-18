import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/camera/presentation/nomo_camera_screen.dart';
import '../../features/friends/presentation/friends_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/logs/presentation/add_log_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/onboarding/presentation/create_user_dialog.dart';
import '../application/nomo_user_controller.dart';
import '../data/nomo_last_account_store.dart';
import '../data/supabase_client_provider.dart';
import '../theme/nomo_theme_mode.dart';

class NomoTabShell extends ConsumerStatefulWidget {
  const NomoTabShell({super.key});

  @override
  ConsumerState<NomoTabShell> createState() => _NomoTabShellState();
}

class _NomoTabShellState extends ConsumerState<NomoTabShell> {
  int _selectedIndex = 0;
  bool _didScheduleProfileRestore = false;
  bool _didAttemptProfileRestore = false;
  bool _isOnboardingSeen = false;
  bool _onboardingPrefLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadOnboardingPref();
  }

  Future<void> _loadOnboardingPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _onboardingPrefLoaded = true;
      _isOnboardingSeen =
          prefs.getBool(NomoLastAccountStore.onboardingSeenKey) ?? false;
    });
  }

  Future<void> _setOnboardingSeen() async {
    _isOnboardingSeen = true;
    await SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(NomoLastAccountStore.onboardingSeenKey, true),
    );
  }

  static const _pages = [
    HomeScreen(),
    FriendsScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  Future<void> _openDrinkLogFlow() async {
    final result = await Navigator.of(context).push<NomoCameraResult>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NomoCameraScreen(returnPhoto: true),
      ),
    );
    if (!mounted || result == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .45),
      builder: (_) => AddLogScreen(initialPhotoPath: result.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(nomoUserProvider);
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
    ref.watch(supabaseAuthStateProvider);
    final hasSession =
        ref.watch(supabaseClientProvider).auth.currentSession != null;

    if (user != null) {
      _didAttemptProfileRestore = false;
      _didScheduleProfileRestore = false;
      if (_onboardingPrefLoaded && !_isOnboardingSeen) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted || _isOnboardingSeen) return;
          await _setOnboardingSeen();
          if (mounted) setState(() => _isOnboardingSeen = true);
        });
      }
    }

    if (user == null &&
        hasSession &&
        !_didAttemptProfileRestore &&
        !_didScheduleProfileRestore) {
      _didScheduleProfileRestore = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await ref.read(nomoUserProvider.notifier).loadFromBackendProfile();
        } finally {
          if (mounted) {
            setState(() {
              _didAttemptProfileRestore = true;
              _didScheduleProfileRestore = false;
            });
          }
        }
      });
    }

    if (user == null && hasSession && !_didAttemptProfileRestore) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: isWhite ? Colors.white : const Color(0xFF0B1420),
        body: const SizedBox.expand(),
      );
    }

    if (user == null && !_onboardingPrefLoaded) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: isWhite ? Colors.white : const Color(0xFF0B1420),
        body: const SizedBox.expand(),
      );
    }

    if (user == null) {
      return CreateUserDialog(startAtLogin: _isOnboardingSeen);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Container(
          height: 94,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isWhite
                    ? Colors.white.withValues(alpha: .92)
                    : const Color(0xFF132234).withValues(alpha: .92),
                isWhite
                    ? const Color(0xFFF1F4F8).withValues(alpha: .94)
                    : const Color(0xFF06111D).withValues(alpha: .94),
              ],
            ),
            borderRadius: BorderRadius.circular(42),
            border: Border.all(
              color: isWhite
                  ? const Color(0xFFDCE3EA)
                  : Colors.white.withValues(alpha: .16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .34),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: const Color(0xFFC8F400).withValues(alpha: .08),
                blurRadius: 52,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _TabItem(
                customIcon: _FeedTabIcon(selected: _selectedIndex == 0),
                label: 'フィード',
                selected: _selectedIndex == 0,
                activeColor: const Color(0xFFB188FF),
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _TabItem(
                customIcon: _FriendsTabIcon(selected: _selectedIndex == 1),
                label: 'フレンズ',
                selected: _selectedIndex == 1,
                activeColor: const Color(0xFF9AF21A),
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -2),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openDrinkLogFlow,
                      child: Semantics(
                        button: true,
                        label: '飲みログを追加',
                        child: const _AddTabIcon(),
                      ),
                    ),
                  ),
                ),
              ),
              _TabItem(
                customIcon: _CalendarTabIcon(selected: _selectedIndex == 2),
                label: 'カレンダー',
                selected: _selectedIndex == 2,
                activeColor: const Color(0xFF20B9FF),
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _TabItem(
                customIcon: _ProfileTabIcon(selected: _selectedIndex == 3),
                label: 'マイページ',
                selected: _selectedIndex == 3,
                activeColor: const Color(0xFFFF75B5),
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    this.customIcon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final Widget? customIcon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? activeColor : const Color(0xFFA5ADBC);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 42,
              child: Center(child: customIcon ?? const SizedBox.shrink()),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                height: 1,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                letterSpacing: -.4,
                shadows: selected
                    ? [
                        Shadow(
                          color: activeColor.withValues(alpha: .34),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTabIcon extends StatelessWidget {
  const _AddTabIcon();

  @override
  Widget build(BuildContext context) => AnimatedScale(
    duration: const Duration(milliseconds: 180),
    scale: .98,
    child: CustomPaint(size: const Size(56, 54), painter: const _AddPainter()),
  );
}

class _AddPainter extends CustomPainter {
  const _AddPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .50),
      width: 50,
      height: 50,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    final path = Path()..addRRect(rrect);

    canvas.drawShadow(
      path,
      const Color(0xFFC8F400).withValues(alpha: .36),
      12,
      true,
    );

    final shadowPaint = Paint()
      ..color = const Color(0xFF72A600).withValues(alpha: .24);
    canvas.drawRRect(rrect.shift(const Offset(0, 3)), shadowPaint);

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFDFFF22), Color(0xFF9AF21A)],
      ).createShader(rect);
    canvas.drawRRect(rrect, fill);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: .26),
    );

    final shine = Paint()..color = Colors.white.withValues(alpha: .26);
    canvas.drawCircle(Offset(size.width * .34, size.height * .28), 5, shine);

    final plus = Paint()
      ..color = const Color(0xFF06111D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4.8;
    final center = Offset(size.width / 2, size.height * .50);
    canvas.drawLine(
      Offset(center.dx - 12, center.dy),
      Offset(center.dx + 12, center.dy),
      plus,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy + 12),
      plus,
    );
  }

  @override
  bool shouldRepaint(covariant _AddPainter oldDelegate) => false;
}

class _PopTabIcon extends StatelessWidget {
  const _PopTabIcon({required this.selected, required this.painter});

  final bool selected;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    duration: const Duration(milliseconds: 180),
    scale: selected ? 1.08 : .95,
    child: CustomPaint(size: const Size(48, 42), painter: painter),
  );
}

class _FeedTabIcon extends StatelessWidget {
  const _FeedTabIcon({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) => _PopTabIcon(
    selected: selected,
    painter: _FeedPainter(active: selected),
  );
}

class _FriendsTabIcon extends StatelessWidget {
  const _FriendsTabIcon({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) => _PopTabIcon(
    selected: selected,
    painter: _FriendsPainter(active: selected),
  );
}

class _CalendarTabIcon extends StatelessWidget {
  const _CalendarTabIcon({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) => _PopTabIcon(
    selected: selected,
    painter: _CalendarPainter(active: selected),
  );
}

class _FeedPainter extends CustomPainter {
  const _FeedPainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final roof = Path()
      ..moveTo(size.width * .14, size.height * .48)
      ..lineTo(size.width * .50, size.height * .16)
      ..lineTo(size.width * .86, size.height * .48)
      ..quadraticBezierTo(
        size.width * .91,
        size.height * .54,
        size.width * .84,
        size.height * .58,
      )
      ..lineTo(size.width * .78, size.height * .58)
      ..lineTo(size.width * .78, size.height * .82)
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .90,
        size.width * .70,
        size.height * .90,
      )
      ..lineTo(size.width * .30, size.height * .90)
      ..quadraticBezierTo(
        size.width * .22,
        size.height * .90,
        size.width * .22,
        size.height * .82,
      )
      ..lineTo(size.width * .22, size.height * .58)
      ..lineTo(size.width * .16, size.height * .58)
      ..quadraticBezierTo(
        size.width * .09,
        size.height * .54,
        size.width * .14,
        size.height * .48,
      )
      ..close();
    final baseColor = active
        ? const Color(0xFF8A62FF)
        : const Color(0xFF8F98A8);
    canvas.drawShadow(
      roof,
      baseColor.withValues(alpha: active ? .55 : .18),
      active ? 10 : 4,
      true,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: active
            ? const [Color(0xFFB392FF), Color(0xFF6D4DFF)]
            : const [Color(0xFFB1BAC8), Color(0xFF727C8D)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(roof, paint);
    final door = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .43,
        size.height * .63,
        size.width * .16,
        size.height * .27,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      door,
      Paint()
        ..color = active ? const Color(0xFFB8EA00) : const Color(0xFF8F98A8),
    );
    final dotPaint = Paint()
      ..color = active ? const Color(0xFFC8F400) : const Color(0xFFD5DBE5);
    for (final offset in [
      const Offset(.44, .43),
      const Offset(.56, .43),
      const Offset(.44, .54),
      const Offset(.56, .54),
    ]) {
      canvas.drawCircle(
        Offset(size.width * offset.dx, size.height * offset.dy),
        2.2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FeedPainter oldDelegate) =>
      oldDelegate.active != active;
}

class _FriendsPainter extends CustomPainter {
  const _FriendsPainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = active
        ? const [Color(0xFF9AF21A), Color(0xFF5DC86C)]
        : const [Color(0xFFB1BAC8), Color(0xFF798393)];
    final glow = Paint()
      ..color = colors.first.withValues(alpha: active ? .18 : .05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .49, size.height * .55),
        width: 46,
        height: 34,
      ),
      glow,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);
    void person(Offset center, double scale) {
      canvas.drawCircle(
        Offset(center.dx, center.dy - 9 * scale),
        9 * scale,
        paint,
      );
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 8 * scale),
          width: 24 * scale,
          height: 24 * scale,
        ),
        Radius.circular(12 * scale),
      );
      canvas.drawRRect(body, paint);
      final eye = Paint()
        ..color = Colors.white.withValues(alpha: active ? .95 : .75);
      canvas.drawCircle(
        Offset(center.dx - 3 * scale, center.dy - 10 * scale),
        1.8 * scale,
        eye,
      );
      canvas.drawCircle(
        Offset(center.dx + 3 * scale, center.dy - 10 * scale),
        1.8 * scale,
        eye,
      );
    }

    person(Offset(size.width * .38, size.height * .52), 1.05);
    person(Offset(size.width * .64, size.height * .58), .78);
    if (active) {
      final spark = Paint()..color = const Color(0xFFC8F400);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * .78, 2, 5, 14),
          const Radius.circular(3),
        ),
        spark,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * .90, 8, 4, 12),
          const Radius.circular(3),
        ),
        spark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FriendsPainter oldDelegate) =>
      oldDelegate.active != active;
}

class _CalendarPainter extends CustomPainter {
  const _CalendarPainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = active
        ? const [Color(0xFF36C8FF), Color(0xFF0875E8)]
        : const [Color(0xFFB1BAC8), Color(0xFF738091)];
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 8, size.width - 12, size.height - 10),
      const Radius.circular(12),
    );
    canvas.drawShadow(
      Path()..addRRect(rect),
      colors.last.withValues(alpha: active ? .40 : .15),
      active ? 10 : 4,
      true,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rect, paint);
    final cutout = RRect.fromRectAndRadius(
      Rect.fromLTWH(13, 18, size.width - 26, size.height - 24),
      const Radius.circular(7),
    );
    canvas.drawRRect(
      cutout,
      Paint()..color = const Color(0xFF06111D).withValues(alpha: .88),
    );
    final tabPaint = Paint()..color = colors.first;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(15, 2, 6, 13),
        const Radius.circular(3),
      ),
      tabPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 21, 2, 6, 13),
        const Radius.circular(3),
      ),
      tabPaint,
    );
    final dotPaint = Paint()
      ..color = active ? const Color(0xFF36C8FF) : const Color(0xFFB1BAC8);
    for (final y in [25.0, 33.0]) {
      for (final x in [19.0, 28.0, 37.0]) {
        canvas.drawCircle(Offset(x, y), 2.4, dotPaint);
      }
    }
    if (active) {
      final spark = Paint()..color = const Color(0xFF36C8FF);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width - 6, 0, 6, 14),
          const Radius.circular(4),
        ),
        spark,
      );
      canvas.drawCircle(Offset(size.width - 2, 21), 3, spark);
    }
  }

  @override
  bool shouldRepaint(covariant _CalendarPainter oldDelegate) =>
      oldDelegate.active != active;
}

class _ProfileTabIcon extends StatelessWidget {
  const _ProfileTabIcon({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) => _PopTabIcon(
    selected: selected,
    painter: _ProfilePainter(active: selected),
  );
}

class _ProfilePainter extends CustomPainter {
  const _ProfilePainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = active
        ? const [Color(0xFFFF78C2), Color(0xFFFF3E9D)]
        : const [Color(0xFFB1BAC8), Color(0xFF778293)];
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);

    final glow = Paint()
      ..color = colors.first.withValues(alpha: active ? .18 : .05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .52, size.height * .62),
        width: 40,
        height: 28,
      ),
      glow,
    );

    final blob = Path()
      ..moveTo(size.width * .23, size.height * .78)
      ..cubicTo(
        size.width * .14,
        size.height * .48,
        size.width * .24,
        size.height * .24,
        size.width * .50,
        size.height * .22,
      )
      ..cubicTo(
        size.width * .78,
        size.height * .20,
        size.width * .91,
        size.height * .44,
        size.width * .82,
        size.height * .76,
      )
      ..quadraticBezierTo(
        size.width * .52,
        size.height * .92,
        size.width * .23,
        size.height * .78,
      )
      ..close();
    canvas.drawShadow(
      blob,
      colors.last.withValues(alpha: active ? .42 : .16),
      active ? 10 : 4,
      true,
    );
    canvas.drawPath(blob, bodyPaint);

    final capPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: active
            ? const [Color(0xFF8FE978), Color(0xFF44BC55)]
            : const [Color(0xFFB9C1CF), Color(0xFF858FA0)],
      ).createShader(Offset.zero & size);
    final cap = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .48,
        size.height * .05,
        size.width * .26,
        size.height * .18,
      ),
      const Radius.circular(9),
    );
    canvas.drawRRect(cap, capPaint);

    final eyePaint = Paint()
      ..color = const Color(0xFF243041).withValues(alpha: active ? .95 : .75);
    final eyeHighlight = Paint()..color = Colors.white.withValues(alpha: .92);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .40, size.height * .48),
        width: 9,
        height: 13,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .63, size.height * .48),
        width: 9,
        height: 13,
      ),
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.width * .38, size.height * .45),
      1.8,
      eyeHighlight,
    );
    canvas.drawCircle(
      Offset(size.width * .61, size.height * .45),
      1.8,
      eyeHighlight,
    );

    final smilePaint = Paint()
      ..color = const Color(0xFF243041).withValues(alpha: active ? .72 : .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final smile = Path()
      ..moveTo(size.width * .43, size.height * .64)
      ..quadraticBezierTo(
        size.width * .52,
        size.height * .70,
        size.width * .61,
        size.height * .64,
      );
    canvas.drawPath(smile, smilePaint);

    if (active) {
      final sparkle = Paint()..color = const Color(0xFFFF78C2);
      final star = Path()
        ..moveTo(size.width * .90, size.height * .27)
        ..lineTo(size.width * .94, size.height * .35)
        ..lineTo(size.width * 1.02, size.height * .39)
        ..lineTo(size.width * .94, size.height * .43)
        ..lineTo(size.width * .90, size.height * .51)
        ..lineTo(size.width * .86, size.height * .43)
        ..lineTo(size.width * .78, size.height * .39)
        ..lineTo(size.width * .86, size.height * .35)
        ..close();
      canvas.drawPath(star, sparkle);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter oldDelegate) =>
      oldDelegate.active != active;
}
