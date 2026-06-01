import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/application/ohey_user_controller.dart';
import '../../../core/data/user_repository.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/models/ohey_friend.dart';
import '../../../core/models/ohey_user.dart';
import '../../../core/models/wish_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ohey_theme_mode.dart';
import '../../../core/widgets/ohey_avatar.dart';
import '../../../core/widgets/ohey_action_tile.dart';
import '../../../core/widgets/ohey_empty_state.dart';
import '../../../core/widgets/ohey_friend_user_block.dart';
import '../../../core/widgets/ohey_invite_success_burst.dart';
import '../../../core/widgets/ohey_3d_button.dart';
import '../../../core/widgets/ohey_bottom_sheet.dart';
import '../../../core/widgets/ohey_page_header.dart';
import '../../../core/widgets/ohey_pop_icon.dart';
import '../../../core/widgets/ohey_primary_button.dart';
import '../../../core/widgets/ohey_profile_hero_header.dart';
import '../../../core/widgets/ohey_scene_header_backdrop.dart';
import '../../../core/widgets/ohey_toast.dart';
import '../../../core/widgets/ohey_themed_panel.dart';
import '../application/invite_controller.dart';
import '../data/friend_repository.dart';
import 'friend_add_sheet.dart';
import '../../memories/application/memory_controller.dart';
import '../../profile/data/user_safety_repository.dart';
import '../../wish_items/application/wish_item_controller.dart';

part 'friends_header_filters.dart';
part 'friends_custom_filter_sheet.dart';
part 'friends_list_widgets.dart';
part 'friends_card_widgets.dart';
part 'friends_state_widgets.dart';

Future<bool?> _confirmDeleteCustomFilter(
  BuildContext context,
  _CustomFriendFilter filter,
) {
  return showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('グループを削除しますか？'),
      content: Text('「${filter.name}」を削除します。この操作は元に戻せません。'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('キャンセル'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('削除する'),
        ),
      ],
    ),
  );
}

Future<void> _holdRefreshIndicatorUntilDone() async {
  const doneVisibleDuration = Duration(milliseconds: 650);
  await Future<void>.delayed(doneVisibleDuration);
}

final _friendMonthlyDailyStatusesProvider = FutureProvider.autoDispose
    .family<Map<String, OheyDailyStatus>, ({String friendId, DateTime month})>((
      ref,
      key,
    ) async {
      if (key.friendId.trim().isEmpty) return const <String, OheyDailyStatus>{};
      return ref
          .read(userRepositoryProvider)
          .fetchFriendDailyStatusesForMonth(key.friendId.trim(), key.month);
    });

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  _FriendFilterType _selectedFilter = _FriendFilterType.all;
  String? _selectedCustomFilterId;
  String? _customFilterUserId;
  List<_CustomFriendFilter> _customFilters = const [];
  bool _isSendingGroupInvite = false;
  bool _showRefreshDone = false;
  final Map<String, bool> _favoriteOverrides = {};
  final Set<String> _invitedFriendIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncCustomFiltersForUser(ref.read(oheyUserProvider)?.userId);
      }
    });
  }

  void _openAddFriend() {
    showFriendAddSheet(context, ref);
  }

  void _syncCustomFiltersForUser(String? userId) {
    if (_customFilterUserId == userId) return;
    _customFilterUserId = userId;
    if (mounted) {
      setState(() {
        _customFilters = const [];
        _selectedCustomFilterId = null;
      });
    }
    if (userId != null && userId.trim().isNotEmpty) {
      _loadCustomFilters(userId);
    }
  }

  Future<void> _loadCustomFilters(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedFilters = _decodeCustomFilters(
      prefs.getString(_customFilterStorageKey(userId)),
    );
    var filters = cachedFilters;
    try {
      final rows = await ref.read(friendRepositoryProvider).fetchFriendGroups();
      filters = rows
          .map(_CustomFriendFilter.fromJson)
          .whereType<_CustomFriendFilter>()
          .toList(growable: false);
      await prefs.setString(
        _customFilterStorageKey(userId),
        jsonEncode([for (final filter in filters) filter.toJson()]),
      );
    } catch (_) {
      // Backend group sync is best-effort while the migration rolls out.
      filters = cachedFilters;
    }
    if (!mounted || _customFilterUserId != userId) return;
    setState(() {
      _customFilters = filters;
      if (_selectedCustomFilterId != null &&
          !_customFilters.any(
            (filter) => filter.id == _selectedCustomFilterId,
          )) {
        _selectedCustomFilterId = null;
        _selectedFilter = _FriendFilterType.all;
      }
    });
  }

  Future<void> _persistCustomFilters() async {
    final userId = _customFilterUserId;
    if (userId == null || userId.trim().isEmpty) return;
    final payload = [for (final filter in _customFilters) filter.toJson()];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customFilterStorageKey(userId), jsonEncode(payload));
    try {
      final rows = await ref
          .read(friendRepositoryProvider)
          .saveFriendGroups(payload);
      final synced = rows
          .map(_CustomFriendFilter.fromJson)
          .whereType<_CustomFriendFilter>()
          .toList(growable: false);
      if (mounted && synced.isNotEmpty) {
        setState(() => _customFilters = synced);
        await prefs.setString(
          _customFilterStorageKey(userId),
          jsonEncode([for (final filter in synced) filter.toJson()]),
        );
      }
    } catch (_) {
      // Keep local cache when backend tables are not available yet.
    }
  }

  Future<void> _deleteCustomFilter(_CustomFriendFilter filter) async {
    HapticFeedback.mediumImpact();
    final confirmed = await _confirmDeleteCustomFilter(context, filter);
    if (confirmed != true || !mounted) return;
    setState(() {
      _customFilters = [
        for (final item in _customFilters)
          if (item.id != filter.id) item,
      ];
      if (_selectedCustomFilterId == filter.id) {
        _selectedCustomFilterId = null;
        _selectedFilter = _FriendFilterType.all;
      }
    });
    await _persistCustomFilters();
    if (mounted) OheyToast.show(context, 'グループを削除したよ');
  }

  Future<void> _openCustomFilterManageSheet() async {
    HapticFeedback.selectionClick();
    final result = await showOheyBottomSheet<_CustomFilterManageResult>(
      context: context,
      useSafeArea: true,
      barrierColor: AppColors.black.withValues(alpha: .58),
      builder: (_) => _CustomFilterManageSheet(filters: _customFilters),
    );
    if (!mounted || result == null) return;

    switch (result.action) {
      case _CustomFilterManageAction.add:
        await _openCustomFilterSheet();
        break;
      case _CustomFilterManageAction.edit:
        await _openCustomFilterSheet(filter: result.filter);
        break;
      case _CustomFilterManageAction.delete:
        final filterId = result.filterId;
        _CustomFriendFilter? filter;
        for (final item in _customFilters) {
          if (item.id == filterId) {
            filter = item;
            break;
          }
        }
        if (filter != null) await _deleteCustomFilter(filter);
        break;
      case _CustomFilterManageAction.reorder:
        final filters = result.filters;
        if (filters == null) return;
        setState(() => _customFilters = filters);
        await _persistCustomFilters();
        if (mounted) OheyToast.show(context, 'グループの順番を保存したよ');
        break;
    }
  }

  Future<void> _openCustomFilterSheet({_CustomFriendFilter? filter}) async {
    final friends =
        ref.read(friendsProvider).asData?.value ?? const <OheyFriend>[];
    if (friends.isEmpty) {
      OheyToast.show(context, 'フレンズを追加するとグループを作れるよ');
      return;
    }
    HapticFeedback.selectionClick();
    final isWhite = ref.read(oheyThemeModeProvider).isWhite;
    final result = await showOheyBottomSheet<_CustomFilterSheetResult>(
      context: context,
      useSafeArea: true,
      barrierColor: AppColors.black.withValues(alpha: .58),
      builder: (_) => _CustomFilterSheet(
        friends: friends,
        initialFilter: filter,
        isWhite: isWhite,
      ),
    );
    if (!mounted || result == null) return;

    switch (result.action) {
      case _CustomFilterSheetAction.save:
        final saved = result.filter!;
        setState(() {
          final index = _customFilters.indexWhere(
            (item) => item.id == saved.id,
          );
          if (index == -1) {
            _customFilters = [..._customFilters, saved];
          } else {
            _customFilters = [
              for (var i = 0; i < _customFilters.length; i++)
                if (i == index) saved else _customFilters[i],
            ];
          }
          _selectedCustomFilterId = saved.id;
        });
        await _persistCustomFilters();
        if (mounted) OheyToast.show(context, 'グループを保存したよ');
        break;
      case _CustomFilterSheetAction.delete:
        final filterId = result.filterId!;
        _CustomFriendFilter? filter;
        for (final item in _customFilters) {
          if (item.id == filterId) {
            filter = item;
            break;
          }
        }
        if (filter != null) await _deleteCustomFilter(filter);
        break;
    }
  }

  void _onToggleFavorite(
    BuildContext context,
    OheyFriend friend,
    bool isFavorite,
  ) {
    final previous = _favoriteOverrides[friend.id] ?? friend.isFavorite;
    HapticFeedback.selectionClick();
    setState(() => _favoriteOverrides[friend.id] = isFavorite);

    ref
        .read(friendsControllerProvider)
        .toggleFavorite(friendId: friend.id, isFavorite: isFavorite)
        .catchError((error) {
          if (mounted) {
            setState(() => _favoriteOverrides[friend.id] = previous);
          }
          if (!context.mounted) return;
          OheyToast.show(context, '変更できなかったよ。あとでもう一度試してね');
        });
  }

  Future<void> _openFriendProfile(
    OheyFriend friend,
    _FriendStatus status,
  ) async {
    HapticFeedback.selectionClick();
    await _showFriendProfileSheet(context, friend: friend, status: status);
  }

  Future<void> _sendInvite(OheyFriend friend) async {
    final draft = await _showInviteOptionsSheet(
      title: '${friend.name}を誘う',
      subtitle: 'いつ・なにをするかを選んで送ろう。',
      primaryLabel: '${friend.name}に送る',
      friendIds: [friend.id],
    );
    if (draft == null) throw const _InviteCancelled();
    try {
      await ref
          .read(inviteControllerProvider)
          .sendInvite(
            friendId: friend.id,
            date: draft.date,
            activityLabel: draft.activityLabel,
          );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      OheyToast.show(
        context,
        '${draft.toastPrefix}で${friend.name}にお誘いを送りました。',
        icon: CupertinoIcons.checkmark_circle_fill,
        placement: OheyToastPlacement.bottom,
      );
    } catch (error) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      OheyToast.show(
        context,
        '誘えなかったよ。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        placement: OheyToastPlacement.bottom,
      );
      rethrow;
    }
  }

  Future<void> _sendGroupInvites(List<OheyFriend> friends) async {
    if (_isSendingGroupInvite || friends.isEmpty) return;
    final draft = await _showInviteOptionsSheet(
      title: '${friends.length}人をまとめて誘う',
      subtitle: 'グループにも日程とやることをつけられるよ。',
      primaryLabel: '${friends.length}人に送る',
      friendIds: friends.map((friend) => friend.id).toList(growable: false),
    );
    if (draft == null) return;
    setState(() => _isSendingGroupInvite = true);
    try {
      await ref
          .read(inviteControllerProvider)
          .sendInvites(
            friendIds: friends.map((friend) => friend.id),
            date: draft.date,
            activityLabel: draft.activityLabel,
          );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        for (final friend in friends) {
          _invitedFriendIds.add(friend.id);
        }
      });
      OheyToast.show(
        context,
        '${draft.toastPrefix}で${friends.length}人にまとめてお誘いを送りました。',
        icon: CupertinoIcons.checkmark_circle_fill,
        placement: OheyToastPlacement.bottom,
      );
    } catch (_) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      OheyToast.show(
        context,
        'まとめて誘えなかったよ。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        placement: OheyToastPlacement.bottom,
      );
    } finally {
      if (mounted) setState(() => _isSendingGroupInvite = false);
    }
  }

  Future<_InviteDraft?> _showInviteOptionsSheet({
    required String title,
    required String subtitle,
    required String primaryLabel,
    required List<String> friendIds,
  }) {
    HapticFeedback.selectionClick();
    return showOheyBottomSheet<_InviteDraft>(
      context: context,
      useSafeArea: true,
      barrierColor: AppColors.black.withValues(alpha: .58),
      builder: (_) => _InviteOptionsSheet(
        title: title,
        subtitle: subtitle,
        primaryLabel: primaryLabel,
        friendIds: friendIds,
      ),
    );
  }

  void _markInviteSent(OheyFriend friend) {
    if (!mounted) return;
    setState(() => _invitedFriendIds.add(friend.id));
  }

  Future<void> _refreshFriends() async {
    HapticFeedback.lightImpact();
    if (mounted) setState(() => _showRefreshDone = false);
    ref.invalidate(pendingFriendRequestsProvider);
    ref.invalidate(friendsForDateProvider);
    ref.invalidate(outgoingActiveInvitesProvider(null));
    ref.invalidate(todayReservationsProvider);
    await Future.wait([
      ref.refresh(friendsProvider.future),
      ref.refresh(pendingFriendRequestsProvider.future),
      ref.refresh(outgoingActiveInvitesProvider(null).future),
      ref.refresh(todayReservationsProvider.future),
    ]);
    if (mounted) setState(() => _showRefreshDone = true);
    await _holdRefreshIndicatorUntilDone();
    if (mounted) setState(() => _showRefreshDone = false);
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final pendingFriendRequestsAsync = ref.watch(pendingFriendRequestsProvider);
    final incomingFriendRequests =
        pendingFriendRequestsAsync.asData?.value
            .where((request) => request.isIncoming)
            .toList(growable: false) ??
        const <OheyFriendRequestItem>[];
    final currentFriends = friendsAsync.value;
    final persistedInvitedFriendIds =
        ref
            .watch(outgoingActiveInvitesProvider(null))
            .asData
            ?.value
            .map((invite) => invite.inviteeUserId)
            .toSet() ??
        const <String>{};
    final reservedFriendIds =
        ref
            .watch(todayReservationsProvider)
            .asData
            ?.value
            .expand((invite) => [invite.inviterUserId, invite.inviteeUserId])
            .toSet() ??
        const <String>{};
    final invitedFriendIds = {
      ...persistedInvitedFriendIds,
      ...reservedFriendIds,
      ..._invitedFriendIds,
    };
    final user = ref.watch(oheyUserProvider);
    final isWhite = ref.watch(oheyThemeModeProvider).isWhite;
    if (_customFilterUserId != user?.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncCustomFiltersForUser(user?.userId);
      });
    }
    final selectedCustomFilter = _findCustomFilter(
      _selectedCustomFilterId,
      _customFilters,
    );
    final headerBackgroundHeight =
        OheyPageHeader.contentTopInset(context) + 100;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWhite
                ? const [AppColors.white, AppColors.white, AppColors.cFFF7F9FB]
                : AppColors.darkBackgroundGradient,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: headerBackgroundHeight,
              child: _FriendsHeaderBackdrop(isWhite: isWhite),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  OheyPageHeader.horizontalPadding,
                  OheyPageHeader.topPadding,
                  OheyPageHeader.horizontalPadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OheyPageHeader(
                      title: 'フレンズ',
                      titleColor: _FriendsColors.lime,
                      trailing: OheyHeaderIconButton(
                        icon: CupertinoIcons.plus,
                        semanticLabel: 'フレンズを追加',
                        color: _FriendsColors.lime,
                        onTap: _openAddFriend,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FilterBar(
                      selected: _selectedFilter,
                      selectedCustomFilterId: _selectedCustomFilterId,
                      customFilters: _customFilters,
                      onChanged: (filter) => setState(() {
                        _selectedFilter = filter;
                        _selectedCustomFilterId = null;
                      }),
                      onCustomChanged: (filter) => setState(() {
                        _selectedCustomFilterId = filter.id;
                      }),
                      onCustomLongPress: (filter) =>
                          _openCustomFilterSheet(filter: filter),
                      onManageCustom: _openCustomFilterManageSheet,
                    ),
                    if (incomingFriendRequests.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _IncomingFriendRequestBanner(
                        requests: incomingFriendRequests,
                        onAccept: _acceptFriendRequest,
                        onReject: _rejectFriendRequest,
                      ),
                    ],
                    const SizedBox(height: 18),
                    Expanded(
                      child: currentFriends == null
                          ? friendsAsync.when(
                              loading: () =>
                                  const _LoadingState(label: 'フレンズを読み込み中...'),
                              error: (error, stackTrace) => _ErrorState(
                                title: '読み込めなかったよ。あとでもう一度試してね',
                                message: '$error',
                              ),
                              data: (friends) => _FriendsList(
                                friends: friends,
                                onRefresh: _refreshFriends,
                                showRefreshDone: _showRefreshDone,
                                userAvatar:
                                    user?.avatar ?? OheyAvatar.defaultAvatar,
                                selectedFilter: _selectedFilter,
                                selectedCustomFilter: selectedCustomFilter,
                                favoriteOverrides: _favoriteOverrides,
                                invitedFriendIds: invitedFriendIds,
                                isSendingGroupInvite: _isSendingGroupInvite,
                                onFavoriteToggle: (friend, isFavorite) =>
                                    _onToggleFavorite(
                                      context,
                                      friend,
                                      isFavorite,
                                    ),
                                onAddFriend: _openAddFriend,
                                onInvite: (friend) => _sendInvite(friend),
                                onGroupInvite: _sendGroupInvites,
                                onInviteAnimationComplete: _markInviteSent,
                                onProfile: (friend, status) =>
                                    _openFriendProfile(friend, status),
                              ),
                            )
                          : _FriendsList(
                              friends: currentFriends,
                              onRefresh: _refreshFriends,
                              showRefreshDone: _showRefreshDone,
                              userAvatar:
                                  user?.avatar ?? OheyAvatar.defaultAvatar,
                              selectedFilter: _selectedFilter,
                              selectedCustomFilter: selectedCustomFilter,
                              favoriteOverrides: _favoriteOverrides,
                              invitedFriendIds: invitedFriendIds,
                              isSendingGroupInvite: _isSendingGroupInvite,
                              onFavoriteToggle: (friend, isFavorite) =>
                                  _onToggleFavorite(
                                    context,
                                    friend,
                                    isFavorite,
                                  ),
                              onAddFriend: _openAddFriend,
                              onInvite: (friend) => _sendInvite(friend),
                              onGroupInvite: _sendGroupInvites,
                              onInviteAnimationComplete: _markInviteSent,
                              onProfile: (friend, status) =>
                                  _openFriendProfile(friend, status),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptFriendRequest(OheyFriendRequestItem request) async {
    await _respondToFriendRequest(request, 'accepted');
  }

  Future<void> _rejectFriendRequest(OheyFriendRequestItem request) async {
    await _respondToFriendRequest(request, 'rejected');
  }

  Future<void> _respondToFriendRequest(
    OheyFriendRequestItem request,
    String status,
  ) async {
    try {
      HapticFeedback.lightImpact();
      await ref
          .read(friendRepositoryProvider)
          .updateFriendRequest(request.id, status);
      ref.invalidate(pendingFriendRequestsProvider);
      ref.invalidate(friendsProvider);
      ref.invalidate(friendsForDateProvider);
      if (!mounted) return;
      OheyToast.show(
        context,
        status == 'accepted' ? 'フレンズ申請を承認しました' : '申請を見送りました',
      );
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(
        context,
        '処理できませんでした。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    }
  }
}

class _InviteCancelled implements Exception {
  const _InviteCancelled();
}

class _IncomingFriendRequestBanner extends StatefulWidget {
  const _IncomingFriendRequestBanner({
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });

  final List<OheyFriendRequestItem> requests;
  final Future<void> Function(OheyFriendRequestItem request) onAccept;
  final Future<void> Function(OheyFriendRequestItem request) onReject;

  @override
  State<_IncomingFriendRequestBanner> createState() =>
      _IncomingFriendRequestBannerState();
}

class _IncomingFriendRequestBannerState
    extends State<_IncomingFriendRequestBanner> {
  String? _busyRequestId;

  Future<void> _run(
    OheyFriendRequestItem request,
    Future<void> Function(OheyFriendRequestItem request) action,
  ) async {
    if (_busyRequestId != null) return;
    setState(() => _busyRequestId = request.id);
    try {
      await action(request);
    } finally {
      if (mounted) setState(() => _busyRequestId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final request = widget.requests.first;
    final profile = request.otherUser;
    final count = widget.requests.length;
    final title = count == 1
        ? '${profile.displayName}さんから申請'
        : 'フレンズ申請が$count件届いています';
    final subtitle = count == 1
        ? 'ここからすぐ承認・見送りできます。'
        : '${profile.displayName}さんほか、未対応の申請があります。';
    final busy = _busyRequestId == request.id;
    final ink = isWhite ? AppColors.cFF111820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF6D7884
        : AppColors.white.withValues(alpha: .68);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWhite
            ? AppColors.white
            : AppColors.darkBackgroundBottom.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _FriendsColors.lime.withValues(alpha: isWhite ? .28 : .36),
        ),
        boxShadow: [
          BoxShadow(
            color: _FriendsColors.lime.withValues(alpha: isWhite ? .12 : .18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  OheyAvatarView(avatar: profile.avatar, size: 46),
                  if (count > 1)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: _IncomingFriendRequestCountBadge(count: count),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Ohey3DButton.secondary(
                  label: '見送る',
                  onTap: busy ? null : () => _run(request, widget.onReject),
                  height: 42,
                  radius: 18,
                  color: AppColors.white.withValues(alpha: .07),
                  foregroundColor: AppColors.white.withValues(alpha: .72),
                  shadowColor: AppColors.cFF573D7A.withValues(alpha: .72),
                  fontSize: 13,
                  useGradient: false,
                  outerShadows: const [],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Ohey3DButton(
                  label: busy ? '処理中' : '承認する',
                  onTap: busy ? null : () => _run(request, widget.onAccept),
                  isLoading: busy,
                  height: 42,
                  radius: 18,
                  color: AppColors.success,
                  shadowColor: AppColors.successShadow,
                  fontSize: 13,
                  outerShadows: const [],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomingFriendRequestCountBadge extends StatelessWidget {
  const _IncomingFriendRequestCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cFFFF4FA3,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white, width: 2),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _InviteDraft {
  const _InviteDraft({required this.date, required this.activityLabel});

  final DateTime date;
  final String? activityLabel;

  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return '今日';
    return '${day.month}/${day.day}';
  }

  String get toastPrefix {
    final activity = activityLabel?.trim();
    if (activity == null || activity.isEmpty) return dateLabel;
    return '$dateLabel・$activity';
  }
}

class _InviteOptionsSheet extends ConsumerStatefulWidget {
  const _InviteOptionsSheet({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.friendIds,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final List<String> friendIds;

  @override
  ConsumerState<_InviteOptionsSheet> createState() =>
      _InviteOptionsSheetState();
}

enum _InviteWishListSource { mine, friend }

class _InviteOptionsSheetState extends ConsumerState<_InviteOptionsSheet> {
  late DateTime _selectedDate;
  bool _isCustomDate = false;
  String? _activityLabel;
  _InviteWishListSource? _wishListSource;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _today;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _selectToday() {
    setState(() {
      _isCustomDate = false;
      _selectedDate = _today;
    });
  }

  void _selectCustomDate() {
    setState(() {
      _isCustomDate = true;
      if (!_selectedDate.isAfter(_today)) {
        _selectedDate = _today.add(const Duration(days: 1));
      }
    });
  }

  void _selectActivity(String label) {
    setState(() => _activityLabel = _activityLabel == label ? null : label);
  }

  void _selectWishListSource(_InviteWishListSource source) {
    setState(() {
      _wishListSource = source;
      _activityLabel = null;
    });
  }

  void _submit() {
    final activity = _activityLabel?.trim();
    Navigator.of(context).pop(
      _InviteDraft(
        date: _selectedDate,
        activityLabel: activity == null || activity.isEmpty ? null : activity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF667381
        : AppColors.white.withValues(alpha: .66);
    return OheyBottomSheetShell(
      title: widget.title,
      maxHeightFactor: .92,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.subtitle,
              style: TextStyle(
                color: sub,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            _InviteSectionLabel(label: 'いつ誘う？', color: ink),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InviteOptionPill(
                    label: '今日',
                    icon: CupertinoIcons.sun_max_fill,
                    selected: !_isCustomDate,
                    onTap: _selectToday,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InviteOptionPill(
                    label: '日程を選択',
                    icon: CupertinoIcons.calendar_badge_plus,
                    selected: _isCustomDate,
                    onTap: _selectCustomDate,
                  ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _isCustomDate
                  ? Padding(
                      key: const ValueKey('date-options'),
                      padding: const EdgeInsets.only(top: 12),
                      child: _InviteAvailableDateOptions(
                        friendIds: widget.friendIds,
                        selectedDate: _selectedDate,
                        onSelected: (date) => setState(() {
                          _selectedDate = date;
                        }),
                        emptyColor: sub,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            _InviteSectionLabel(label: 'なにをする？（任意）', color: ink),
            const SizedBox(height: 10),
            _InviteWishListOptions(
              friendIds: widget.friendIds,
              source: _wishListSource,
              selectedLabel: _activityLabel,
              onSourceSelected: _selectWishListSource,
              onSelected: _selectActivity,
              emptyColor: sub,
            ),
            const SizedBox(height: 20),
            Ohey3DButton(
              label: widget.primaryLabel,
              icon: CupertinoIcons.paperplane_fill,
              onTap: _submit,
              color: AppColors.primaryAction,
              shadowColor: AppColors.primaryActionShadow,
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteAvailableDateOptions extends ConsumerWidget {
  const _InviteAvailableDateOptions({
    required this.friendIds,
    required this.selectedDate,
    required this.onSelected,
    required this.emptyColor,
  });

  final List<String> friendIds;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final Color emptyColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = _dateOnly(DateTime.now());
    final months = _monthsFrom(today, count: 5);
    final blockedKeys = <String>{};
    var isLoading = false;

    for (final friendId in friendIds) {
      for (final month in months) {
        final statuses = ref.watch(
          _friendMonthlyDailyStatusesProvider((
            friendId: friendId,
            month: month,
          )),
        );
        isLoading = isLoading || statuses.isLoading;
        final values =
            statuses.asData?.value ?? const <String, OheyDailyStatus>{};
        for (final entry in values.entries) {
          if (entry.value == OheyDailyStatus.hasPlans) {
            blockedKeys.add(entry.key);
          }
        }
      }
    }

    final candidates = [
      for (var index = 1; index <= 120; index++)
        today.add(Duration(days: index)),
    ].where((date) => !blockedKeys.contains(_inviteDateKey(date))).toList();

    if (candidates.isEmpty) {
      return Text(
        isLoading ? '相手の予定を確認中…' : '選べる日程がまだないよ。',
        style: TextStyle(
          color: emptyColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading) ...[
          Text(
            '相手の予定ありの日を除いて表示中…',
            style: TextStyle(
              color: emptyColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: candidates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = candidates[index];
              return _InviteOptionPill(
                label: _inviteDateLabel(date, today: today),
                compact: true,
                selected: _isSameInviteDate(selectedDate, date),
                onTap: () => onSelected(date),
              );
            },
          ),
        ),
      ],
    );
  }

  List<DateTime> _monthsFrom(DateTime start, {required int count}) {
    return [
      for (var index = 0; index < count; index++)
        DateTime(start.year, start.month + index),
    ];
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameInviteDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _inviteDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _inviteDateLabel(DateTime date, {required DateTime today}) {
  final diff = _dateOnly(date).difference(today).inDays;
  final weekday = const ['月', '火', '水', '木', '金', '土', '日'][date.weekday - 1];
  if (diff == 1) return '明日';
  return '${date.month}/${date.day}($weekday)';
}

class _InviteWishListOptions extends ConsumerWidget {
  const _InviteWishListOptions({
    required this.friendIds,
    required this.source,
    required this.selectedLabel,
    required this.onSourceSelected,
    required this.onSelected,
    required this.emptyColor,
  });

  final List<String> friendIds;
  final _InviteWishListSource? source;
  final String? selectedLabel;
  final ValueChanged<_InviteWishListSource> onSourceSelected;
  final ValueChanged<String> onSelected;
  final Color emptyColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownItems =
        ref.watch(wishItemControllerProvider).asData?.value ??
        const <WishItem>[];
    final friendStatusValues = [
      for (final friendId in friendIds)
        ref.watch(profileWishItemsProvider(friendId)),
    ];
    final friendItems = <WishItem>[
      for (final status in friendStatusValues) ...?status.asData?.value,
    ];
    final options = source == null
        ? const <String>[]
        : _uniqueWishTitles(
            source == _InviteWishListSource.mine ? ownItems : friendItems,
          );
    final isLoading =
        ref.watch(wishItemControllerProvider).isLoading ||
        friendStatusValues.any((status) => status.isLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InviteOptionPill(
              label: '私のリスト',
              compact: true,
              selected: source == _InviteWishListSource.mine,
              onTap: () => onSourceSelected(_InviteWishListSource.mine),
            ),
            _InviteOptionPill(
              label: '相手のリスト',
              compact: true,
              selected: source == _InviteWishListSource.friend,
              onTap: () => onSourceSelected(_InviteWishListSource.friend),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (source == null)
          Text(
            'まずはどちらのリストから選ぶか選択してね。',
            style: TextStyle(
              color: emptyColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          )
        else if (options.isEmpty)
          Text(
            isLoading ? 'リストを読み込み中…' : 'このリストはまだ空だよ。',
            style: TextStyle(
              color: emptyColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                _InviteOptionPill(
                  label: option,
                  compact: true,
                  selected: selectedLabel == option,
                  onTap: () => onSelected(option),
                ),
            ],
          ),
      ],
    );
  }

  List<String> _uniqueWishTitles(List<WishItem> items) {
    final seen = <String>{};
    final titles = <String>[];
    for (final item in items) {
      final title = item.title.trim();
      if (title.isEmpty) continue;
      final key = title.toLowerCase();
      if (seen.add(key)) titles.add(title);
    }
    return titles;
  }
}

class _InviteSectionLabel extends StatelessWidget {
  const _InviteSectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: color,
      fontSize: 14,
      fontWeight: FontWeight.w900,
      letterSpacing: -.2,
    ),
  );
}

class _InviteOptionPill extends StatelessWidget {
  const _InviteOptionPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final selectedColor = AppColors.primaryAction;
    final background = selected
        ? selectedColor
        : isWhite
        ? AppColors.cFFF1F5EF
        : AppColors.white.withValues(alpha: .08);
    final foreground = selected
        ? AppColors.cFF101820
        : isWhite
        ? AppColors.cFF263340
        : AppColors.white.withValues(alpha: .82);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 13,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? selectedColor
                  : foreground.withValues(alpha: isWhite ? .10 : .16),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: .20),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                OheyGeneratedIcon(icon!, color: foreground, size: 17),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: compact ? 12.5 : 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
