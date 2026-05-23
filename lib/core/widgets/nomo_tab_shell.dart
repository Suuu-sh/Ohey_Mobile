import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/camera/presentation/nomo_camera_screen.dart';
import '../../features/friends/application/drink_invite_controller.dart';
import '../../features/friends/presentation/friends_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/logs/presentation/add_log_screen.dart';
import '../../features/notifications/application/notification_controller.dart';
import '../../features/notifications/application/os_notification_service.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/onboarding/presentation/create_user_dialog.dart';
import '../application/nomo_user_controller.dart';
import '../data/nomo_last_account_store.dart';
import '../data/supabase_client_provider.dart';
import '../models/nomo_drink_invite.dart';
import '../theme/app_colors.dart';
import '../theme/nomo_theme_mode.dart';
import 'nomo_3d_button.dart';
import 'nomo_backend_busy_screen.dart';
import 'nomo_pop_icon.dart';
import 'nomo_toast.dart';

class NomoTabShell extends ConsumerStatefulWidget {
  const NomoTabShell({super.key});

  @override
  ConsumerState<NomoTabShell> createState() => _NomoTabShellState();
}

class _NomoTabShellState extends ConsumerState<NomoTabShell>
    with WidgetsBindingObserver {
  static const _invitePollInterval = Duration(seconds: 15);

  int _selectedIndex = 0;
  bool _didScheduleProfileRestore = false;
  bool _didAttemptProfileRestore = false;
  bool _isOnboardingSeen = false;
  bool _onboardingPrefLoaded = false;
  bool _isDrinkInviteModalOpen = false;
  String? _lastPresentedDrinkInviteId;
  Timer? _invitePollTimer;
  final Set<String> _notifiedDrinkInviteIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOnboardingPref();
  }

  @override
  void dispose() {
    _invitePollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startInvitePolling();
    } else {
      _invitePollTimer?.cancel();
      _invitePollTimer = null;
    }
    if (state != AppLifecycleState.resumed) return;
    _lastPresentedDrinkInviteId = null;
    ref.invalidate(incomingDrinkInvitesProvider);
    ref.invalidate(notificationControllerProvider);
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

  List<Widget> get _pages => [
    HomeScreen(onAddLogPressed: _openDrinkLogFlow),
    const FriendsScreen(),
    CalendarScreen(onCreatePlan: _openDrinkLogFlow),
    const ProfileScreen(),
  ];

  Future<void> _openDrinkLogFlow() async {
    final action = await showModalBottomSheet<_DrinkLogStartAction>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .58),
      builder: (_) => const _DrinkLogStartSheet(),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _DrinkLogStartAction.camera:
        await _openCameraDrinkLogFlow();
      case _DrinkLogStartAction.noPhoto:
      case _DrinkLogStartAction.plan:
        await Navigator.of(
          context,
        ).push<void>(CupertinoPageRoute(builder: (_) => const AddLogScreen()));
      case _DrinkLogStartAction.gallery:
        await _openGalleryDrinkLogFlow();
    }
  }

  Future<void> _openCameraDrinkLogFlow() async {
    final result = await Navigator.of(context).push<NomoCameraResult>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NomoCameraScreen(),
      ),
    );
    if (!mounted || result == null) return;

    await Navigator.of(context).push<void>(
      CupertinoPageRoute(
        builder: (_) => AddLogScreen(initialPhotoPath: result.path),
      ),
    );
  }

  Future<void> _openGalleryDrinkLogFlow() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (!mounted || picked == null) return;

    await Navigator.of(context).push<void>(
      CupertinoPageRoute(
        builder: (_) => AddLogScreen(initialPhotoPath: picked.path),
      ),
    );
  }

  void _handleIncomingDrinkInvites(List<NomoDrinkInvite> invites) {
    if (ref.read(nomoUserProvider) == null) return;
    final pendingInvites = invites
        .where((invite) => invite.status == NomoDrinkInviteStatus.pending)
        .toList(growable: false);
    if (pendingInvites.isEmpty) return;

    for (final invite in pendingInvites) {
      if (!_notifiedDrinkInviteIds.add(invite.id)) continue;
      ref.read(osNotificationServiceProvider).showDrinkInviteReceived(invite);
    }

    final invite = pendingInvites.first;
    if (_isDrinkInviteModalOpen || _lastPresentedDrinkInviteId == invite.id) {
      return;
    }
    _lastPresentedDrinkInviteId = invite.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDrinkInviteModalOpen) return;
      _showIncomingDrinkInviteModal(invite);
    });
  }

  void _startInvitePolling() {
    if (!mounted || ref.read(nomoUserProvider) == null) return;
    if (_invitePollTimer?.isActive ?? false) return;
    _invitePollTimer = Timer.periodic(_invitePollInterval, (_) {
      if (!mounted || ref.read(nomoUserProvider) == null) {
        _invitePollTimer?.cancel();
        _invitePollTimer = null;
        return;
      }
      ref.invalidate(incomingDrinkInvitesProvider);
      ref.invalidate(notificationControllerProvider);
    });
  }

  Future<void> _showIncomingDrinkInviteModal(NomoDrinkInvite invite) async {
    _isDrinkInviteModalOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: .62),
        builder: (_) => _IncomingDrinkInviteSheet(
          invite: invite,
          onAccept: () async {
            await ref.read(drinkInviteControllerProvider).accept(invite.id);
            ref.invalidate(notificationControllerProvider);
          },
          onReject: () async {
            await ref.read(drinkInviteControllerProvider).reject(invite.id);
            ref.invalidate(notificationControllerProvider);
          },
        ),
      );
    } finally {
      _isDrinkInviteModalOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(nomoUserProvider);
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
    ref.watch(supabaseAuthStateProvider);
    final hasSession =
        ref.watch(supabaseClientProvider).auth.currentSession != null;
    final incomingDrinkInvitesAsync = ref.watch(incomingDrinkInvitesProvider);
    ref.listen<AsyncValue<List<NomoDrinkInvite>>>(
      incomingDrinkInvitesProvider,
      (previous, next) => next.whenData(_handleIncomingDrinkInvites),
    );

    if (user != null) {
      _startInvitePolling();
      incomingDrinkInvitesAsync.whenData(_handleIncomingDrinkInvites);
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
          await ref
              .read(nomoUserProvider.notifier)
              .loadFromBackendProfile()
              .timeout(const Duration(seconds: 10));
        } catch (_) {
          // Backend can be waking up from a cold start. After the friendly
          // waiting screen has had a chance to show, continue to the normal
          // logged-in/profile setup flow instead of leaving a blank page.
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
      _invitePollTimer?.cancel();
      _invitePollTimer = null;
      return const NomoBackendBusyScreen();
    }

    if (user == null && !_onboardingPrefLoaded) {
      _invitePollTimer?.cancel();
      _invitePollTimer = null;
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: isWhite
            ? Colors.white
            : AppColors.darkBackgroundBottom,
        body: const SizedBox.expand(),
      );
    }

    if (user == null) {
      _invitePollTimer?.cancel();
      _invitePollTimer = null;
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
                activeColor: const Color(0xFF22D7C5),
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

enum _DrinkLogStartAction { camera, noPhoto, gallery, plan }

class _DrinkLogStartSheet extends StatelessWidget {
  const _DrinkLogStartSheet();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final background = isWhite ? Colors.white : const Color(0xFF071320);
    final ink = isWhite ? const Color(0xFF17212B) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF667381)
        : Colors.white.withValues(alpha: .62);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isWhite
                ? const Color(0xFFDCE4EC)
                : Colors.white.withValues(alpha: .12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .28),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: sub.withValues(alpha: .34),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'どう残しますか？',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '写真なしでも、あとからでも飲みログを残せます。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: sub,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            _DrinkLogStartTile(
              icon: CupertinoIcons.camera_fill,
              color: AppColors.primaryAction,
              title: '写真を撮って残す',
              subtitle: '今の一杯を撮影して投稿',
              onTap: () =>
                  Navigator.of(context).pop(_DrinkLogStartAction.camera),
            ),
            const SizedBox(height: 10),
            _DrinkLogStartTile(
              icon: CupertinoIcons.text_badge_plus,
              color: AppColors.invite,
              title: '写真なしで残す',
              subtitle: '場所・フレンズ・コメントだけで記録',
              onTap: () =>
                  Navigator.of(context).pop(_DrinkLogStartAction.noPhoto),
            ),
            const SizedBox(height: 10),
            _DrinkLogStartTile(
              icon: CupertinoIcons.photo_on_rectangle,
              color: AppColors.info,
              title: '過去の写真から残す',
              subtitle: 'ライブラリの写真を使って投稿',
              onTap: () =>
                  Navigator.of(context).pop(_DrinkLogStartAction.gallery),
            ),
            const SizedBox(height: 10),
            _DrinkLogStartTile(
              icon: CupertinoIcons.calendar_badge_plus,
              color: AppColors.warning,
              title: '飲み予定を作る',
              subtitle: 'これからの予定を先にメモ',
              onTap: () => Navigator.of(context).pop(_DrinkLogStartAction.plan),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrinkLogStartTile extends StatelessWidget {
  const _DrinkLogStartTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF17212B) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF667381)
        : Colors.white.withValues(alpha: .58);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: isWhite
              ? const Color(0xFFF6F8FA)
              : Colors.white.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWhite
                ? const Color(0xFFE0E6ED)
                : Colors.white.withValues(alpha: .10),
          ),
        ),
        child: Row(
          children: [
            NomoPopIcon(icon: icon, color: color, size: 46, iconSize: 25),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            NomoGeneratedIcon(
              CupertinoIcons.chevron_right,
              color: sub,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingDrinkInviteSheet extends StatefulWidget {
  const _IncomingDrinkInviteSheet({
    required this.invite,
    required this.onAccept,
    required this.onReject,
  });

  final NomoDrinkInvite invite;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  State<_IncomingDrinkInviteSheet> createState() =>
      _IncomingDrinkInviteSheetState();
}

class _IncomingDrinkInviteSheetState extends State<_IncomingDrinkInviteSheet> {
  String? _busyAction;

  Future<void> _submit({required bool accept}) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = accept ? 'accept' : 'reject');
    try {
      if (accept) {
        await widget.onAccept();
      } else {
        await widget.onReject();
      }
      if (!mounted) return;
      NomoToast.show(context, accept ? '飲み予定を受け取りました' : '飲み予定を見送りました');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(
        context,
        accept ? '承認できなかったよ。少し時間をおいて試してみてね。' : '見送りできなかったよ。少し時間をおいて試してみてね。',
      );
      setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.invite.fromUser;
    return SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 620),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 38),
            child: Transform.scale(
              scale: .88 + value * .12,
              child: Opacity(opacity: value.clamp(0, 1), child: child),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF31104F), Color(0xFF071622)],
            ),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4FB5).withValues(alpha: .24),
                blurRadius: 36,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .34),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _InviteCelebrationBurst()),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const NomoPopIcon(
                        icon: CupertinoIcons.sparkles,
                        color: Color(0xFFFFD84D),
                        size: 54,
                        iconSize: 29,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '飲みのお誘いが届いたよ！',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFFFF4B8),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${from.name}から飲みのお誘い',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF4FB5,
                                ).withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFFD84D,
                                  ).withValues(alpha: .34),
                                ),
                              ),
                              child: const Text(
                                '返信待ち',
                                style: TextStyle(
                                  color: Color(0xFFFFD84D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        minimumSize: const Size(42, 42),
                        padding: EdgeInsets.zero,
                        onPressed: _busyAction == null
                            ? () => Navigator.of(context).pop()
                            : null,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .10),
                      ),
                    ),
                    child: Text(
                      '${from.name}さんから飲み予定が届いたよ。',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Nomo3DButton(
                    label: '承認して飲みに行く',
                    icon: CupertinoIcons.checkmark_circle_fill,
                    onTap: () => _submit(accept: true),
                    isLoading: _busyAction == 'accept',
                    enabled: _busyAction == null,
                    height: 54,
                    radius: 22,
                    color: AppColors.primaryAction,
                    shadowColor: AppColors.primaryActionShadow,
                    fontSize: 15,
                  ),
                  const SizedBox(height: 10),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _busyAction == null
                        ? () => _submit(accept: false)
                        : null,
                    child: Text(
                      _busyAction == 'reject' ? '見送り中...' : '今回は見送る',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .60),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteCelebrationBurst extends StatefulWidget {
  const _InviteCelebrationBurst();

  @override
  State<_InviteCelebrationBurst> createState() =>
      _InviteCelebrationBurstState();
}

class _InviteCelebrationBurstState extends State<_InviteCelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _InviteCelebrationPainter(progress: _controller.value),
        ),
      ),
    );
  }
}

class _InviteCelebrationPainter extends CustomPainter {
  const _InviteCelebrationPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .50, size.height * .16);
    final colors = [
      const Color(0xFFFFD84D),
      const Color(0xFFFF4FB5),
      const Color(0xFFC08BFF),
      const Color(0xFF9AF21A),
      Colors.white,
    ];
    for (var i = 0; i < 24; i++) {
      final angle = (math.pi * 2 / 24) * i - math.pi / 2;
      final distance = 18 + progress * (58 + (i % 5) * 9);
      final offset =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity * .90)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      if (i.isEven) {
        canvas.drawLine(
          offset,
          offset + Offset(math.cos(angle), math.sin(angle)) * 9,
          paint,
        );
      } else {
        canvas.drawCircle(offset, 2.2 + (i % 3), paint);
      }
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF4FB5).withValues(alpha: .22 * (1 - progress * .4)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 130));
    canvas.drawCircle(center, 130, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _InviteCelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
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
    scale: 1,
    child: CustomPaint(size: const Size(58, 56), painter: const _AddPainter()),
  );
}

class _AddPainter extends CustomPainter {
  const _AddPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .50),
      width: 52,
      height: 52,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(21));
    final path = Path()..addRRect(rrect);

    canvas.drawShadow(
      path,
      const Color(0xFFFF4FB5).withValues(alpha: .46),
      16,
      true,
    );

    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      Paint()..color = const Color(0xFF8E1A59).withValues(alpha: .42),
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, 2)),
      Paint()..color = const Color(0xFFC51D7A).withValues(alpha: .34),
    );

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFB8DD),
          Color(0xFFFF4FB5),
          Color(0xFFE91E8F),
          Color(0xFFB91472),
        ],
        stops: [0, .42, .72, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, fill);

    final bevel = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: .54),
          Colors.white.withValues(alpha: .08),
          const Color(0xFF7E104E).withValues(alpha: .22),
        ],
        stops: const [0, .46, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(2.2), bevel);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: .62),
    );

    canvas.drawRRect(
      rrect.deflate(3.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFFFFD7EC).withValues(alpha: .44),
    );

    final shine = Paint()..color = Colors.white.withValues(alpha: .36);
    canvas.drawCircle(Offset(size.width * .34, size.height * .28), 5.4, shine);
    canvas.drawCircle(
      Offset(size.width * .42, size.height * .22),
      2.2,
      Paint()..color = Colors.white.withValues(alpha: .48),
    );

    final plus = Paint()
      ..color = Colors.white.withValues(alpha: .96)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 5.4;
    final center = Offset(size.width / 2, size.height * .50);
    final plusShadow = Paint()
      ..color = const Color(0xFF7A0E4B).withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 6.2;
    canvas.drawLine(
      Offset(center.dx - 12, center.dy + 2),
      Offset(center.dx + 12, center.dy + 2),
      plusShadow,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 10),
      Offset(center.dx, center.dy + 14),
      plusShadow,
    );
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
