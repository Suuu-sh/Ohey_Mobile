import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/models/nomo_gender.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_empty_state.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_scene_header_backdrop.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../application/drink_invite_controller.dart';
import '../../logs/application/drink_log_controller.dart';
import '../../profile/presentation/profile_screen.dart';

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
  bool _isRefreshingFriends = false;
  final Map<String, bool> _favoriteOverrides = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncCustomFiltersForUser(ref.read(nomoUserProvider)?.userId);
      }
    });
  }

  void _openAddFriend() {
    showMyQrDialog(context, ref.read(nomoUserProvider), ref);
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
    final raw = prefs.getString(_customFilterStorageKey(userId));
    final filters = _decodeCustomFilters(raw);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customFilterStorageKey(userId),
      jsonEncode([for (final filter in _customFilters) filter.toJson()]),
    );
  }

  Future<void> _openCustomFilterSheet({_CustomFriendFilter? filter}) async {
    final friends =
        ref.read(friendsProvider).asData?.value ?? const <NomoFriend>[];
    if (friends.isEmpty) {
      NomoToast.show(context, 'フレンズを追加するとフィルターを作れます');
      return;
    }
    HapticFeedback.selectionClick();
    final isWhite = ref.read(nomoThemeModeProvider).isWhite;
    final result = await showModalBottomSheet<_CustomFilterSheetResult>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
        if (mounted) NomoToast.show(context, 'フィルターを保存しました');
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
        if (mounted) NomoToast.show(context, 'フィルターを削除しました');
        break;
    }
  }

  Future<void> _refreshFriends() async {
    if (_isRefreshingFriends) return;
    HapticFeedback.selectionClick();
    setState(() => _isRefreshingFriends = true);
    try {
      final _ = await ref.refresh(friendsProvider.future);
      if (!mounted) return;
      NomoToast.show(
        context,
        'フレンズを更新しました',
        icon: CupertinoIcons.arrow_clockwise,
      );
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(
        context,
        'フレンズを更新できませんでした',
        icon: CupertinoIcons.arrow_clockwise,
      );
    } finally {
      if (mounted) setState(() => _isRefreshingFriends = false);
    }
  }

  void _onToggleFavorite(
    BuildContext context,
    NomoFriend friend,
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
          NomoToast.show(context, '変更できなかったよ。あとでもう一度試してね');
        });
  }

  Future<void> _sendDrinkInvite(NomoFriend friend) async {
    try {
      await ref.read(drinkInviteControllerProvider).sendTodayInvite(friend.id);
      if (!mounted) return;
      NomoToast.show(
        context,
        '${friend.name}に飲み招待を送りました。',
        icon: CupertinoIcons.checkmark_circle_fill,
        placement: NomoToastPlacement.bottom,
      );
    } catch (error) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      NomoToast.show(
        context,
        '招待を送れなかったよ。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        placement: NomoToastPlacement.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final user = ref.watch(nomoUserProvider);
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
    if (_customFilterUserId != user?.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncCustomFiltersForUser(user?.userId);
      });
    }
    final selectedCustomFilter = _findCustomFilter(
      _selectedCustomFilterId,
      _customFilters,
    );
    final headerBackgroundHeight = MediaQuery.paddingOf(context).top + 178;

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
                  NomoPageHeader.horizontalPadding,
                  NomoPageHeader.topPadding,
                  NomoPageHeader.horizontalPadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NomoPageHeader(
                      title: 'フレンズ',
                      titleColor: _FriendsColors.lime,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NomoHeaderIconButton(
                            icon: CupertinoIcons.arrow_clockwise,
                            semanticLabel: 'フレンズを更新',
                            color: _isRefreshingFriends
                                ? _FriendsColors.muted
                                : _FriendsColors.lime,
                            onTap: _isRefreshingFriends
                                ? () {}
                                : _refreshFriends,
                          ),
                          const SizedBox(width: 8),
                          NomoHeaderIconButton(
                            icon: CupertinoIcons.plus,
                            semanticLabel: 'フレンズを追加',
                            color: _FriendsColors.lime,
                            onTap: _openAddFriend,
                          ),
                        ],
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
                      onCreateCustom: () => _openCustomFilterSheet(),
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
                          userAvatar: user?.avatar ?? NomoAvatar.defaultAvatar,
                          selectedFilter: _selectedFilter,
                          selectedCustomFilter: selectedCustomFilter,
                          favoriteOverrides: _favoriteOverrides,
                          onFavoriteToggle: (friend, isFavorite) =>
                              _onToggleFavorite(context, friend, isFavorite),
                          onAddFriend: _openAddFriend,
                          onInvite: (friend) => _sendDrinkInvite(friend),
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
