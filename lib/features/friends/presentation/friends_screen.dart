import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/application/ohey_user_controller.dart';
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
      barrierColor: Colors.black.withValues(alpha: .58),
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
      barrierColor: Colors.black.withValues(alpha: .58),
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
        setState(() {
          _customFilters = [
            for (final item in _customFilters)
              if (item.id != filterId) item,
          ];
          if (_selectedCustomFilterId == filterId) {
            _selectedCustomFilterId = null;
            _selectedFilter = _FriendFilterType.all;
          }
        });
        await _persistCustomFilters();
        if (mounted) OheyToast.show(context, 'グループを削除したよ');
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
        '招待を送れなかったよ。あとでもう一度試してね',
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
        'まとめて招待できなかったよ。あとでもう一度試してね',
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
  }) {
    HapticFeedback.selectionClick();
    return showOheyBottomSheet<_InviteDraft>(
      context: context,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: .58),
      builder: (_) => _InviteOptionsSheet(
        title: title,
        subtitle: subtitle,
        primaryLabel: primaryLabel,
      ),
    );
  }

  void _markInviteSent(OheyFriend friend) {
    if (!mounted) return;
    setState(() => _invitedFriendIds.add(friend.id));
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final persistedInvitedFriendIds =
        ref
            .watch(outgoingActiveInvitesProvider(null))
            .asData
            ?.value
            .map((invite) => invite.inviteeUserId)
            .toSet() ??
        const <String>{};
    final invitedFriendIds = {
      ...persistedInvitedFriendIds,
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
        statusBarColor: Colors.transparent,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWhite
                ? const [Colors.white, Colors.white, Color(0xFFF7F9FB)]
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
                    const SizedBox(height: 18),
                    Expanded(
                      child: friendsAsync.when(
                        loading: () =>
                            const _LoadingState(label: 'フレンズを読み込み中...'),
                        error: (error, stackTrace) => _ErrorState(
                          title: '読み込めなかったよ。あとでもう一度試してね',
                          message: '$error',
                        ),
                        data: (friends) => _FriendsList(
                          friends: friends,
                          onRefresh: () async {
                            HapticFeedback.lightImpact();
                            ref.invalidate(friendsProvider);
                            ref.invalidate(outgoingActiveInvitesProvider(null));
                            await ref.read(friendsProvider.future);
                          },
                          userAvatar: user?.avatar ?? OheyAvatar.defaultAvatar,
                          selectedFilter: _selectedFilter,
                          selectedCustomFilter: selectedCustomFilter,
                          favoriteOverrides: _favoriteOverrides,
                          invitedFriendIds: invitedFriendIds,
                          isSendingGroupInvite: _isSendingGroupInvite,
                          onFavoriteToggle: (friend, isFavorite) =>
                              _onToggleFavorite(context, friend, isFavorite),
                          onAddFriend: _openAddFriend,
                          onInvite: (friend) => _sendInvite(friend),
                          onGroupInvite: _sendGroupInvites,
                          onInviteAnimationComplete: _markInviteSent,
                          onProfile: (friend, status) =>
                              _openFriendProfile(friend, status),
                        ),
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
}

class _InviteCancelled implements Exception {
  const _InviteCancelled();
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

class _InviteOptionsSheet extends StatefulWidget {
  const _InviteOptionsSheet({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;

  @override
  State<_InviteOptionsSheet> createState() => _InviteOptionsSheetState();
}

class _InviteOptionsSheetState extends State<_InviteOptionsSheet> {
  static const _activityOptions = <String>[
    '飲みに行く',
    'ごはん',
    'カフェ',
    'カラオケ',
    '散歩',
    '相談する',
  ];

  late DateTime _selectedDate;
  bool _isCustomDate = false;
  String? _activityLabel = _activityOptions.first;
  late final TextEditingController _customActivityController;
  late final FocusNode _customActivityFocusNode;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _today;
    _customActivityController = TextEditingController();
    _customActivityFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _customActivityController.dispose();
    _customActivityFocusNode.dispose();
    super.dispose();
  }

  void _selectToday() {
    _customActivityFocusNode.unfocus();
    setState(() {
      _isCustomDate = false;
      _selectedDate = _today;
    });
  }

  void _selectCustomDate() {
    _customActivityFocusNode.unfocus();
    setState(() {
      _isCustomDate = true;
      if (!_selectedDate.isAfter(_today)) {
        _selectedDate = _today.add(const Duration(days: 1));
      }
    });
  }

  void _selectActivity(String? label) {
    _customActivityFocusNode.unfocus();
    _customActivityController.clear();
    setState(() => _activityLabel = label);
  }

  void _useCustomActivity(String value) {
    setState(() => _activityLabel = value.trim());
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
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF667381)
        : Colors.white.withValues(alpha: .66);
    final pickerBackground = isWhite
        ? const Color(0xFFF4F8F1)
        : Colors.white.withValues(alpha: .06);

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
                      key: const ValueKey('date-picker'),
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        height: 152,
                        decoration: BoxDecoration(
                          color: pickerBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primaryAction.withValues(
                              alpha: isWhite ? .28 : .18,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          minimumDate: _today,
                          maximumDate: _today.add(const Duration(days: 120)),
                          initialDateTime: _selectedDate,
                          onDateTimeChanged: (value) {
                            setState(() {
                              _selectedDate = DateTime(
                                value.year,
                                value.month,
                                value.day,
                              );
                            });
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            _InviteSectionLabel(label: 'なにをする？（任意）', color: ink),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _activityOptions)
                  _InviteOptionPill(
                    label: option,
                    compact: true,
                    selected: _activityLabel == option,
                    onTap: () => _selectActivity(option),
                  ),
                _InviteOptionPill(
                  label: 'まだ決めない',
                  compact: true,
                  selected: _activityLabel == null || _activityLabel!.isEmpty,
                  onTap: () => _selectActivity(null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _customActivityController,
              focusNode: _customActivityFocusNode,
              placeholder: 'その他（例: 焼肉、映画）',
              maxLength: 40,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              style: TextStyle(
                color: ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              placeholderStyle: TextStyle(
                color: sub,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: BoxDecoration(
                color: pickerBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primaryAction.withValues(
                    alpha: isWhite ? .20 : .14,
                  ),
                ),
              ),
              onTap: () {
                if (_customActivityController.text.trim().isNotEmpty) {
                  _useCustomActivity(_customActivityController.text);
                }
              },
              onChanged: _useCustomActivity,
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
        ? const Color(0xFFF1F5EF)
        : Colors.white.withValues(alpha: .08);
    final foreground = selected
        ? const Color(0xFF101820)
        : isWhite
        ? const Color(0xFF263340)
        : Colors.white.withValues(alpha: .82);
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
