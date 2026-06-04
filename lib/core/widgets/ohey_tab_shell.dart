import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/friends/application/invite_controller.dart';
import '../../features/friends/data/friend_repository.dart';
import '../../features/friends/presentation/friends_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/memories/application/memory_controller.dart';
import '../../features/notifications/application/notification_controller.dart';
import '../../features/notifications/application/os_notification_service.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/yurubos/application/yurubo_controller.dart';
import '../../features/onboarding/presentation/create_user_dialog.dart';
import '../application/ohey_user_controller.dart';
import '../data/ohey_last_account_store.dart';
import '../data/supabase_client_provider.dart';
import '../models/ohey_invite.dart';
import '../models/yurubo.dart';
import '../models/ohey_user.dart';
import '../theme/app_colors.dart';
import '../theme/ohey_theme_mode.dart';
import 'ohey_3d_button.dart';
import 'ohey_backend_busy_screen.dart';
import 'ohey_bottom_sheet.dart';
import 'ohey_daily_status_3d_option.dart';
import 'ohey_pop_icon.dart';
import 'ohey_toast.dart';
import 'ohey_avatar.dart';

class OheyTabShell extends ConsumerStatefulWidget {
  const OheyTabShell({super.key});

  @override
  ConsumerState<OheyTabShell> createState() => _OheyTabShellState();
}

class _OheyTabShellState extends ConsumerState<OheyTabShell>
    with WidgetsBindingObserver {
  static const _invitePollInterval = Duration(seconds: 15);
  static const _feedAccentColor = AppColors.cFFC08BFF;
  static const _friendsAccentColor = AppColors.cFF9AF21A;
  static const _calendarAccentColor = AppColors.cFF20B9FF;
  static const _profileAccentColor = AppColors.cFFFF75B5;

  int _selectedIndex = 0;
  bool _didScheduleProfileRestore = false;
  bool _didAttemptProfileRestore = false;
  bool _isOnboardingSeen = false;
  bool _onboardingPrefLoaded = false;
  bool _isInviteModalOpen = false;
  bool _isYuruboRequestModalOpen = false;
  bool _isDailyStatusPromptOpen = false;
  String? _lastDailyStatusPromptKey;
  String? _lastPresentedInviteId;
  String? _lastPresentedYuruboRequestKey;
  Timer? _invitePollTimer;
  StreamSubscription<Uri>? _appLinkSubscription;
  String? _pendingSharedYuruboId;
  bool _isHandlingSharedYurubo = false;
  final Set<String> _notifiedInviteIds = <String>{};
  final Set<String> _notifiedYuruboRequestKeys = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOnboardingPref();
    _startAppLinkListener();
  }

  @override
  void dispose() {
    _invitePollTimer?.cancel();
    _appLinkSubscription?.cancel();
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
    _lastPresentedInviteId = null;
    _lastPresentedYuruboRequestKey = null;
    _notifiedYuruboRequestKeys.clear();
    unawaited(
      ref
          .read(oheyUserProvider.notifier)
          .loadFromBackendProfile()
          .catchError((_) => false),
    );
    ref.invalidate(homeFeedControllerProvider);
    ref.invalidate(incomingInvitesProvider);
    ref.invalidate(yuruboControllerProvider);
    ref.invalidate(notificationControllerProvider);
  }

  Future<void> _loadOnboardingPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _onboardingPrefLoaded = true;
      _isOnboardingSeen =
          prefs.getBool(OheyLastAccountStore.onboardingSeenKey) ?? false;
    });
  }

  Future<void> _setOnboardingSeen() async {
    _isOnboardingSeen = true;
    await SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(OheyLastAccountStore.onboardingSeenKey, true),
    );
  }

  void _startAppLinkListener() {
    final appLinks = AppLinks();
    unawaited(
      appLinks
          .getInitialLink()
          .then((uri) {
            if (uri != null) _handleIncomingAppLink(uri);
          })
          .catchError((_) {}),
    );
    _appLinkSubscription = appLinks.uriLinkStream.listen(
      _handleIncomingAppLink,
      onError: (_) {},
    );
  }

  void _handleIncomingAppLink(Uri uri) {
    final yuruboId = _sharedYuruboIdFromUri(uri);
    if (yuruboId == null || yuruboId.isEmpty) return;
    _pendingSharedYuruboId = yuruboId;
    if (ref.read(oheyUserProvider) != null) {
      _consumePendingSharedYurubo();
    }
  }

  String? _sharedYuruboIdFromUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments;
    if ((scheme == 'app.ohey.com' || scheme == 'app.ohey.com.dev') &&
        host == 'yurubos' &&
        segments.isNotEmpty) {
      return segments.first;
    }
    if ((scheme == 'https' || scheme == 'http') &&
        segments.length >= 3 &&
        segments[0] == 'share' &&
        segments[1] == 'yurubos') {
      return segments[2];
    }
    return null;
  }

  void _consumePendingSharedYurubo() {
    if (_isHandlingSharedYurubo) return;
    final yuruboId = _pendingSharedYuruboId;
    if (yuruboId == null || yuruboId.isEmpty) return;
    _pendingSharedYuruboId = null;
    _isHandlingSharedYurubo = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _isHandlingSharedYurubo = false;
        return;
      }
      setState(() => _selectedIndex = 0);
      try {
        await ref.read(yuruboControllerProvider.notifier).participate(yuruboId);
        if (!mounted) return;
        OheyToast.show(
          context,
          '共有されたゆるぼに参加しました',
          icon: CupertinoIcons.checkmark_circle_fill,
        );
      } catch (_) {
        if (!mounted) return;
        OheyToast.show(
          context,
          'このゆるぼに参加できなかったよ。あとでもう一度試してね',
          icon: CupertinoIcons.exclamationmark_triangle_fill,
        );
      } finally {
        _isHandlingSharedYurubo = false;
      }
    });
  }

  Color get _selectedToastAccentColor => switch (_selectedIndex) {
    0 => _feedAccentColor,
    1 => _friendsAccentColor,
    2 => _calendarAccentColor,
    _ => _profileAccentColor,
  };

  List<Widget> get _pages => [
    OheyToastAccent(color: _feedAccentColor, child: HomeScreen()),
    const OheyToastAccent(color: _friendsAccentColor, child: FriendsScreen()),
    OheyToastAccent(color: _calendarAccentColor, child: CalendarScreen()),
    OheyToastAccent(
      color: _profileAccentColor,
      child: ProfileScreen(onOpenYurubo: () => _selectTab(0)),
    ),
  ];

  void _selectTab(int index) {
    if (_selectedIndex == index) {
      _refreshCurrentTabByIndex(index, showToast: true);
      return;
    }
    setState(() => _selectedIndex = index);
    if (index == 0) {
      _refreshFeedOnOpen();
    } else if (index == 1) {
      _refreshFriendsOnOpen();
    }
  }

  void _refreshCurrentTabByIndex(int index, {required bool showToast}) {
    switch (index) {
      case 0:
        HapticFeedback.selectionClick();
        _refreshFeedOnOpen();
        if (showToast) {
          OheyToast.show(
            context,
            'ゆるぼを更新しました',
            icon: CupertinoIcons.arrow_clockwise,
          );
        }
        break;
      case 1:
        HapticFeedback.selectionClick();
        _refreshFriendsOnOpen();
        if (showToast) {
          OheyToast.show(
            context,
            'フレンズを更新しました',
            icon: CupertinoIcons.arrow_clockwise,
          );
        }
        break;
      default:
        break;
    }
  }

  void _refreshFeedOnOpen() {
    ref.invalidate(homeFeedControllerProvider);
    ref.invalidate(friendsProvider);
    ref.invalidate(friendsForDateProvider);
    ref.invalidate(notificationControllerProvider);
  }

  void _refreshFriendsOnOpen() {
    ref.invalidate(friendsProvider);
    ref.invalidate(friendsForDateProvider);
    ref.invalidate(pendingFriendRequestsProvider);
    ref.invalidate(incomingInvitesProvider);
    ref.invalidate(yuruboControllerProvider);
    ref.invalidate(notificationControllerProvider);
  }

  void _handlePendingYuruboRequests(List<Yurubo> yurubos) {
    final currentUser = ref.read(oheyUserProvider);
    if (currentUser == null ||
        _isInviteModalOpen ||
        _isYuruboRequestModalOpen ||
        _isDailyStatusPromptOpen) {
      return;
    }
    for (final yurubo in yurubos) {
      if (yurubo.ownerUserId !=
          ref.read(supabaseClientProvider).auth.currentUser?.id) {
        continue;
      }
      final pending = yurubo.participants
          .where((participant) => participant.isPending)
          .toList(growable: false);
      if (pending.isEmpty) {
        continue;
      }
      final requestKey = '${yurubo.id}:${pending.first.userId}';
      if (_notifiedYuruboRequestKeys.add(requestKey)) {
        unawaited(
          ref
              .read(osNotificationServiceProvider)
              .showYuruboParticipationRequest(yurubo, pending.first),
        );
      }
      if (_lastPresentedYuruboRequestKey == requestKey) return;
      _lastPresentedYuruboRequestKey = requestKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _isInviteModalOpen ||
            _isYuruboRequestModalOpen ||
            _isDailyStatusPromptOpen) {
          return;
        }
        _showYuruboParticipationRequestModal(yurubo, pending);
      });
      return;
    }
  }

  Future<void> _showYuruboParticipationRequestModal(
    Yurubo yurubo,
    List<YuruboParticipant> participants,
  ) async {
    _isYuruboRequestModalOpen = true;
    try {
      await showOheyBottomSheet<void>(
        context: context,
        useSafeArea: true,
        useRootNavigator: true,
        barrierColor: AppColors.black.withValues(alpha: .62),
        builder: (_) => OheyToastAccent(
          color: _feedAccentColor,
          child: _YuruboParticipationRequestSheet(
            yurubo: yurubo,
            participants: participants,
            onApprove: (participant) async {
              await ref
                  .read(yuruboControllerProvider.notifier)
                  .approveReaction(yurubo.id, participant.userId);
              ref.invalidate(yuruboControllerProvider);
              ref.invalidate(notificationControllerProvider);
            },
          ),
        ),
      );
    } finally {
      _isYuruboRequestModalOpen = false;
    }
  }

  void _handleIncomingInvites(List<OheyInvite> invites) {
    final currentUser = ref.read(oheyUserProvider);
    if (currentUser == null ||
        currentUser.dailyStatus == OheyDailyStatus.unselected) {
      return;
    }
    final pendingInvites = invites
        .where((invite) => invite.status == OheyInviteStatus.pending)
        .toList(growable: false);
    if (pendingInvites.isEmpty) return;

    for (final invite in pendingInvites) {
      if (!_notifiedInviteIds.add(invite.id)) continue;
      ref.read(osNotificationServiceProvider).showInviteReceived(invite);
    }

    final invite = pendingInvites.first;
    if (_isInviteModalOpen || _lastPresentedInviteId == invite.id) {
      return;
    }
    _lastPresentedInviteId = invite.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isInviteModalOpen) return;
      _showIncomingInviteModal(invite);
    });
  }

  void _startInvitePolling() {
    if (!mounted || ref.read(oheyUserProvider) == null) return;
    if (_invitePollTimer?.isActive ?? false) return;
    _invitePollTimer = Timer.periodic(_invitePollInterval, (_) {
      if (!mounted || ref.read(oheyUserProvider) == null) {
        _invitePollTimer?.cancel();
        _invitePollTimer = null;
        return;
      }
      ref.invalidate(incomingInvitesProvider);
      ref.invalidate(notificationControllerProvider);
    });
  }

  Future<void> _showIncomingInviteModal(OheyInvite invite) async {
    _isInviteModalOpen = true;
    try {
      await showOheyBottomSheet<void>(
        context: context,
        useSafeArea: true,
        useRootNavigator: true,
        barrierColor: AppColors.black.withValues(alpha: .62),
        builder: (_) => OheyToastAccent(
          color: _selectedToastAccentColor,
          child: _IncomingInviteSheet(
            invite: invite,
            onAccept: () async {
              await ref.read(inviteControllerProvider).accept(invite.id);
              ref.invalidate(notificationControllerProvider);
            },
            onReject: () async {
              await ref.read(inviteControllerProvider).reject(invite.id);
              ref.invalidate(notificationControllerProvider);
            },
          ),
        ),
      );
    } finally {
      _isInviteModalOpen = false;
    }
  }

  void _maybeShowDailyStatusPrompt(OheyUser user) {
    if (user.dailyStatus != OheyDailyStatus.unselected ||
        _isDailyStatusPromptOpen) {
      return;
    }
    final promptKey = '${user.userId}-${_localDateKey(DateTime.now())}';
    if (_lastDailyStatusPromptKey == promptKey) return;
    _lastDailyStatusPromptKey = promptKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDailyStatusPromptOpen) return;
      final currentUser = ref.read(oheyUserProvider);
      if (currentUser == null ||
          currentUser.dailyStatus != OheyDailyStatus.unselected) {
        return;
      }
      _showDailyStatusPrompt();
    });
  }

  Future<void> _showDailyStatusPrompt() async {
    _isDailyStatusPromptOpen = true;
    try {
      await showOheyBottomSheet<void>(
        context: context,
        useSafeArea: true,
        useRootNavigator: true,
        isDismissible: false,
        enableDrag: false,
        barrierColor: AppColors.black.withValues(alpha: .72),
        builder: (_) => OheyToastAccent(
          color: AppColors.cFF20B9FF,
          child: _DailyStatusRequiredSheet(
            onSelect: (status) async {
              await ref
                  .read(oheyUserProvider.notifier)
                  .updateDailyStatus(status);
              ref.invalidate(friendsProvider);
              ref.invalidate(friendsForDateProvider);
              ref.invalidate(incomingInvitesProvider);
              ref.invalidate(notificationControllerProvider);
            },
          ),
        ),
      );
    } finally {
      _isDailyStatusPromptOpen = false;
      if (mounted &&
          ref.read(oheyUserProvider)?.dailyStatus ==
              OheyDailyStatus.unselected) {
        _lastDailyStatusPromptKey = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(oheyUserProvider);
    final isWhite = ref.watch(oheyThemeModeProvider).isWhite;
    ref.watch(supabaseAuthStateProvider);
    final hasSession =
        ref.watch(supabaseClientProvider).auth.currentSession != null;
    final incomingInvitesAsync = ref.watch(incomingInvitesProvider);
    final yurubosAsync = user == null
        ? const AsyncValue<List<Yurubo>>.data(<Yurubo>[])
        : ref.watch(yuruboControllerProvider);
    final pendingFriendRequestsAsync = user == null
        ? const AsyncValue<List<OheyFriendRequestItem>>.data(
            <OheyFriendRequestItem>[],
          )
        : ref.watch(pendingFriendRequestsProvider);
    final incomingFriendRequestCount = pendingFriendRequestsAsync.maybeWhen(
      data: (requests) =>
          requests.where((request) => request.isIncoming).length,
      orElse: () => 0,
    );
    ref.listen<AsyncValue<List<OheyInvite>>>(
      incomingInvitesProvider,
      (previous, next) => next.whenData(_handleIncomingInvites),
    );
    ref.listen<AsyncValue<List<Yurubo>>>(
      yuruboControllerProvider,
      (previous, next) => next.whenData(_handlePendingYuruboRequests),
    );

    if (user != null) {
      _maybeShowDailyStatusPrompt(user);
      _startInvitePolling();
      incomingInvitesAsync.whenData(_handleIncomingInvites);
      yurubosAsync.whenData(_handlePendingYuruboRequests);
      _didAttemptProfileRestore = false;
      _didScheduleProfileRestore = false;
      _consumePendingSharedYurubo();
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
              .read(oheyUserProvider.notifier)
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
      return const OheyBackendBusyScreen();
    }

    if (user == null && !_onboardingPrefLoaded) {
      _invitePollTimer?.cancel();
      _invitePollTimer = null;
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: isWhite
            ? AppColors.white
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 7),
        decoration: BoxDecoration(
          color: AppColors.darkBackgroundBottom,
          border: Border(
            top: BorderSide(
              color: _selectedToastAccentColor.withValues(alpha: .72),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: _selectedToastAccentColor.withValues(alpha: .28),
              blurRadius: 18,
              spreadRadius: .5,
              offset: const Offset(0, -5),
            ),
            BoxShadow(
              color: _selectedToastAccentColor.withValues(alpha: .16),
              blurRadius: 34,
              offset: const Offset(0, -9),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: SizedBox(
            height: 82,
            child: Row(
              children: [
                _TabItem(
                  customIcon: _FeedTabIcon(selected: _selectedIndex == 0),
                  label: 'ゆるぼ',
                  selected: _selectedIndex == 0,
                  activeColor: AppColors.cFF8A62FF,
                  onTap: () => _selectTab(0),
                ),
                _TabItem(
                  customIcon: _FriendsTabIcon(selected: _selectedIndex == 1),
                  label: 'フレンズ',
                  selected: _selectedIndex == 1,
                  activeColor: AppColors.cFF9AF21A,
                  badgeCount: incomingFriendRequestCount,
                  onTap: () => _selectTab(1),
                ),
                _TabItem(
                  customIcon: _CalendarTabIcon(selected: _selectedIndex == 2),
                  label: 'カレンダー',
                  selected: _selectedIndex == 2,
                  activeColor: AppColors.cFF20B9FF,
                  onTap: () => _selectTab(2),
                ),
                _TabItem(
                  customIcon: _ProfileTabIcon(selected: _selectedIndex == 3),
                  label: 'マイページ',
                  selected: _selectedIndex == 3,
                  activeColor: AppColors.cFFFF75B5,
                  onTap: () => _selectTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyStatusRequiredSheet extends ConsumerStatefulWidget {
  const _DailyStatusRequiredSheet({required this.onSelect});

  final Future<void> Function(OheyDailyStatus status) onSelect;

  @override
  ConsumerState<_DailyStatusRequiredSheet> createState() =>
      _DailyStatusRequiredSheetState();
}

class _DailyStatusRequiredSheetState
    extends ConsumerState<_DailyStatusRequiredSheet> {
  OheyDailyStatus? _savingStatus;

  Future<void> _select(OheyDailyStatus status) async {
    if (_savingStatus != null) return;
    HapticFeedback.selectionClick();
    setState(() => _savingStatus = status);
    try {
      await widget.onSelect(status);
      if (!mounted) return;
      Navigator.of(context).pop();
      OheyToast.show(context, '今日は「${status.label}」だね');
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingStatus = null);
      OheyToast.show(context, '設定できなかったよ。もう一度ためしてね');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .64);
    return PopScope(
      canPop: false,
      child: OheyBottomSheetShell(
        showHandle: true,
        showBottomCloseButton: false,
        maxHeightFactor: .88,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const OheyPopIcon(
                  icon: CupertinoIcons.calendar_badge_plus,
                  color: AppColors.cFF20B9FF,
                  size: 48,
                  iconSize: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日の予定、先に教えて',
                        style: TextStyle(
                          color: ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'みんなと予定を合わせやすいように、入室前に今日の気分をセットしてね',
                        style: TextStyle(
                          color: sub,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final status in OheyDailyStatus.selectable) ...[
              OheyDailyStatus3DOption(
                status: status,
                title: status.label,
                subtitle: status.shortCopy,
                onTap: () => _select(status),
                enabled: _savingStatus == null,
                isLoading: _savingStatus == status,
                showChevron: _savingStatus == null,
              ),
              if (status != OheyDailyStatus.selectable.last)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

String _localDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class _SheetInlineError extends StatelessWidget {
  const _SheetInlineError({required this.message, required this.isWhite});

  final String message;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final background = isWhite
        ? AppColors.danger.withValues(alpha: .10)
        : AppColors.danger.withValues(alpha: .14);
    final border = AppColors.danger.withValues(alpha: isWhite ? .26 : .34);
    final textColor = isWhite ? AppColors.cFF8F254B : AppColors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),
      ),
    );
  }
}

class _YuruboParticipationRequestSheet extends StatefulWidget {
  const _YuruboParticipationRequestSheet({
    required this.yurubo,
    required this.participants,
    required this.onApprove,
  });

  final Yurubo yurubo;
  final List<YuruboParticipant> participants;
  final Future<void> Function(YuruboParticipant participant) onApprove;

  @override
  State<_YuruboParticipationRequestSheet> createState() =>
      _YuruboParticipationRequestSheetState();
}

class _YuruboParticipationRequestSheetState
    extends State<_YuruboParticipationRequestSheet> {
  String? _busyUserId;
  String? _errorMessage;

  Future<void> _approve(YuruboParticipant participant) async {
    if (_busyUserId != null) return;
    setState(() {
      _busyUserId = participant.userId;
      _errorMessage = null;
    });
    try {
      await widget.onApprove(participant);
      if (!mounted) return;
      OheyToast.show(
        context,
        '参加申請を承認しました',
        icon: CupertinoIcons.checkmark_circle_fill,
        placement: OheyToastPlacement.bottom,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _busyUserId = null;
        _errorMessage = '承認できなかったよ。少し時間をおいて試してみてね。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final participants = widget.participants;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 30),
          child: Transform.scale(
            scale: .92 + value * .08,
            child: Opacity(opacity: value.clamp(0, 1), child: child),
          ),
        );
      },
      child: OheyBottomSheetShell(
        showHandle: false,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        radius: 34,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const OheyPopIcon(
                  icon: CupertinoIcons.person_2_fill,
                  color: AppColors.cFFC08BFF,
                  size: 54,
                  iconSize: 29,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '参加申請・参加者',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '「${widget.yurubo.title}」への申請です',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: .62),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                OheyCloseButton(
                  enabled: _busyUserId == null,
                  onTap: () => Navigator.of(context).pop(),
                  iconColor: AppColors.white,
                  backgroundColor: AppColors.white.withValues(alpha: .08),
                  borderColor: AppColors.white.withValues(alpha: .10),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...participants
                .take(3)
                .map(
                  (participant) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _YuruboParticipationRequestRow(
                      participant: participant,
                      yuruboTitle: widget.yurubo.title,
                      isBusy: _busyUserId == participant.userId,
                      disabled: _busyUserId != null,
                      onApprove: () => _approve(participant),
                    ),
                  ),
                ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _errorMessage == null
                  ? const SizedBox.shrink()
                  : Padding(
                      key: ValueKey(_errorMessage),
                      padding: const EdgeInsets.only(top: 4),
                      child: _SheetInlineError(
                        message: _errorMessage!,
                        isWhite: false,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YuruboParticipationRequestRow extends StatelessWidget {
  const _YuruboParticipationRequestRow({
    required this.participant,
    required this.yuruboTitle,
    required this.isBusy,
    required this.disabled,
    required this.onApprove,
  });

  final YuruboParticipant participant;
  final String yuruboTitle;
  final bool isBusy;
  final bool disabled;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Color.lerp(
          AppColors.darkBackgroundBottom,
          AppColors.cFF20B9FF,
          .22,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.cFF54D7FF.withValues(alpha: .42),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cFF20B9FF.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          OheyAvatarView(avatar: participant.avatar, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '申請先: ${yuruboTitle.trim().isEmpty ? 'ゆるぼ' : yuruboTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.cFFC08BFF.withValues(alpha: .90),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Ohey3DButton(
            label: isBusy ? '承認中' : '承認',
            onTap: disabled ? null : onApprove,
            isLoading: isBusy,
            height: 48,
            radius: 22,
            color: AppColors.cFF9AF21A,
            foregroundColor: AppColors.cFF101820,
            shadowColor: Color.lerp(AppColors.cFF9AF21A, AppColors.black, .36)!,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}

class _IncomingInviteSheet extends StatefulWidget {
  const _IncomingInviteSheet({
    required this.invite,
    required this.onAccept,
    required this.onReject,
  });

  final OheyInvite invite;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  State<_IncomingInviteSheet> createState() => _IncomingInviteSheetState();
}

class _IncomingInviteSheetState extends State<_IncomingInviteSheet> {
  String? _busyAction;
  String? _errorMessage;

  Future<void> _submit({required bool accept}) async {
    if (_busyAction != null) return;
    setState(() {
      _busyAction = accept ? 'accept' : 'reject';
      _errorMessage = null;
    });
    try {
      if (accept) {
        await widget.onAccept();
      } else {
        await widget.onReject();
      }
      if (!mounted) return;
      OheyToast.show(
        context,
        accept ? '予定を受け取りました' : 'お誘いを見送りました',
        icon: CupertinoIcons.checkmark_circle_fill,
        placement: OheyToastPlacement.bottom,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _busyAction = null;
        _errorMessage = accept
            ? '承認できなかったよ。少し時間をおいて試してみてね。'
            : '見送りできなかったよ。少し時間をおいて試してみてね。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.invite.inviter;
    return TweenAnimationBuilder<double>(
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
      child: OheyBottomSheetShell(
        showBottomCloseButton: false,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        radius: 34,
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
                      color: AppColors.white.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const OheyPopIcon(
                      icon: CupertinoIcons.sparkles,
                      color: AppColors.cFFFFD84D,
                      size: 54,
                      iconSize: 29,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'お誘いが届いたよ！',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.cFFFFF4B8,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${from.name}からお誘い',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
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
                                color: AppColors.cFFFFD84D,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OheyCloseButton(
                      enabled: _busyAction == null,
                      onTap: () => Navigator.of(context).pop(),
                      iconColor: AppColors.white,
                      backgroundColor: AppColors.white.withValues(alpha: .08),
                      borderColor: AppColors.white.withValues(alpha: .10),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: .10),
                    ),
                  ),
                  child: Text(
                    '${from.name}さんから${widget.invite.summary()}が届いたよ。',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: .82),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _errorMessage == null
                      ? const SizedBox.shrink()
                      : Padding(
                          key: ValueKey(_errorMessage),
                          padding: const EdgeInsets.only(top: 14),
                          child: _SheetInlineError(
                            message: _errorMessage!,
                            isWhite: false,
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                Ohey3DButton(
                  label: '承認して遊びに行く',
                  onTap: () => _submit(accept: true),
                  isLoading: _busyAction == 'accept',
                  enabled: _busyAction == null,
                  height: 54,
                  radius: 22,
                  color: AppColors.primaryAction,
                  shadowColor: AppColors.primaryActionShadow,
                  fontSize: 15,
                  outerShadows: const [],
                ),
                const SizedBox(height: 10),
                Ohey3DButton.secondary(
                  label: _busyAction == 'reject' ? '見送り中...' : '今回は見送る',
                  onTap: _busyAction == null
                      ? () => _submit(accept: false)
                      : null,
                  isLoading: _busyAction == 'reject',
                  enabled: _busyAction == null,
                  height: 48,
                  radius: 21,
                  color: AppColors.white.withValues(alpha: .07),
                  foregroundColor: AppColors.white.withValues(alpha: .72),
                  shadowColor: AppColors.cFF5B3A7A.withValues(alpha: .72),
                  fontSize: 14,
                  useGradient: false,
                  outerShadows: const [],
                ),
              ],
            ),
          ],
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
      AppColors.cFFFFD84D,
      AppColors.cFFFF4FB5,
      AppColors.cFFC08BFF,
      AppColors.cFF9AF21A,
      AppColors.white,
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
          AppColors.cFFFF4FB5.withValues(alpha: .22 * (1 - progress * .4)),
          AppColors.transparent,
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
    this.badgeCount = 0,
  });

  final Widget? customIcon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? activeColor : AppColors.cFFA5ADBC;
    final hasBadge = badgeCount > 0;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(
          button: true,
          label: hasBadge ? '$label、未処理申請$badgeCount件' : label,
          selected: selected,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 44,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _TabIconGlow(
                        selected: selected,
                        color: activeColor,
                        child: IconTheme(
                          data: IconThemeData(color: labelColor),
                          child: customIcon ?? const SizedBox.shrink(),
                        ),
                      ),
                      if (hasBadge)
                        Positioned(
                          right: 6,
                          top: 1,
                          child: _TabBadge(count: badgeCount),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 9.5,
                  height: 1,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                  letterSpacing: -.35,
                  shadows: selected
                      ? [
                          Shadow(
                            color: activeColor.withValues(alpha: .36),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBadge extends StatelessWidget {
  const _TabBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: .72, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.cFFFF5F8F, AppColors.cFFFF335F],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.darkBackgroundBottom, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.cFFFF4F7A.withValues(alpha: .42),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 9.5,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TabIconGlow extends StatelessWidget {
  const _TabIconGlow({
    required this.selected,
    required this.color,
    required this.child,
  });

  final bool selected;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    width: 64,
    height: 50,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (selected) ...[
          _TabIconShapeGlow(
            color: color,
            blur: 12,
            opacity: .24,
            scale: 1.14,
            child: child,
          ),
          _TabIconShapeGlow(
            color: color,
            blur: 6,
            opacity: .36,
            scale: 1.06,
            child: child,
          ),
        ],
        child,
      ],
    ),
  );
}

class _TabIconShapeGlow extends StatelessWidget {
  const _TabIconShapeGlow({
    required this.color,
    required this.blur,
    required this.opacity,
    required this.scale,
    required this.child,
  });

  final Color color;
  final double blur;
  final double opacity;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Opacity(
            opacity: opacity,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
              child: Center(
                child: Transform.scale(scale: scale, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
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
    final baseColor = active ? AppColors.cFF8A62FF : AppColors.cFF8F98A8;
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
            ? const [AppColors.cFFB392FF, AppColors.cFF6D4DFF]
            : const [AppColors.cFFB1BAC8, AppColors.cFF727C8D],
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
      Paint()..color = active ? AppColors.cFFB8EA00 : AppColors.cFF8F98A8,
    );
    final dotPaint = Paint()
      ..color = active ? AppColors.cFFC8F400 : AppColors.cFFD5DBE5;
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
        ? const [AppColors.cFF9AF21A, AppColors.cFF5DC86C]
        : const [AppColors.cFFB1BAC8, AppColors.cFF798393];
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
        ..color = AppColors.white.withValues(alpha: active ? .95 : .75);
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
      final spark = Paint()..color = AppColors.cFFC8F400;
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
        ? const [AppColors.cFF36C8FF, AppColors.cFF0875E8]
        : const [AppColors.cFFB1BAC8, AppColors.cFF738091];
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
      Paint()..color = AppColors.cFF06111D.withValues(alpha: .88),
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
      ..color = active ? AppColors.cFF36C8FF : AppColors.cFFB1BAC8;
    for (final y in [25.0, 33.0]) {
      for (final x in [19.0, 28.0, 37.0]) {
        canvas.drawCircle(Offset(x, y), 2.4, dotPaint);
      }
    }
    if (active) {
      final spark = Paint()..color = AppColors.cFF36C8FF;
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
        ? const [AppColors.cFFFF78C2, AppColors.cFFFF3E9D]
        : const [AppColors.cFFB1BAC8, AppColors.cFF778293];
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);

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
            ? const [AppColors.cFF8FE978, AppColors.cFF44BC55]
            : const [AppColors.cFFB9C1CF, AppColors.cFF858FA0],
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
      ..color = AppColors.cFF243041.withValues(alpha: active ? .95 : .75);
    final eyeHighlight = Paint()
      ..color = AppColors.white.withValues(alpha: .92);
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
      ..color = AppColors.cFF243041.withValues(alpha: active ? .72 : .55)
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
      final sparkle = Paint()..color = AppColors.cFFFF78C2;
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
