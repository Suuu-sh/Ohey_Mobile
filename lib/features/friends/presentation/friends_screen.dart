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
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../application/drink_invite_controller.dart';
import '../../logs/application/drink_log_controller.dart';
import '../../profile/presentation/profile_screen.dart';

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
          NomoToast.show(context, 'お気に入り設定に失敗しました: $error');
        });
  }

  Future<void> _sendDrinkInvite(NomoFriend friend) async {
    try {
      await ref.read(drinkInviteControllerProvider).sendTodayInvite(friend.id);
      if (!mounted) return;
      NomoToast.show(context, '${friend.name}に飲み招待を送りました。');
    } catch (error) {
      if (!mounted) return;
      NomoToast.show(context, '招待を送れませんでした: $error');
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
                  6,
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
                    const SizedBox(height: 14),
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
                            const _LoadingState(label: '友達を読み込み中...'),
                        error: (error, stackTrace) => _ErrorState(
                          title: '友達を読み込めませんでした',
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

class _FriendsHeaderBackdrop extends StatelessWidget {
  const _FriendsHeaderBackdrop({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final fadeColor = isWhite ? Colors.white : AppColors.darkBackgroundBottom;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              'assets/images/friends_header_scene.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.05,
                colors: [
                  _FriendsColors.lime.withValues(alpha: .18),
                  Colors.transparent,
                ],
                stops: const [.06, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF03101E).withValues(alpha: .12),
                  const Color(0xFF03101E).withValues(alpha: .06),
                  fadeColor.withValues(alpha: .92),
                  fadeColor,
                ],
                stops: const [0, .48, .84, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF03101E).withValues(alpha: .26),
                  Colors.transparent,
                  const Color(0xFF03101E).withValues(alpha: .16),
                ],
                stops: const [0, .48, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _FriendFilterType { all }

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.selectedCustomFilterId,
    required this.customFilters,
    required this.onChanged,
    required this.onCustomChanged,
    required this.onCustomLongPress,
    required this.onCreateCustom,
  });

  final _FriendFilterType selected;
  final String? selectedCustomFilterId;
  final List<_CustomFriendFilter> customFilters;
  final ValueChanged<_FriendFilterType> onChanged;
  final ValueChanged<_CustomFriendFilter> onCustomChanged;
  final ValueChanged<_CustomFriendFilter> onCustomLongPress;
  final VoidCallback onCreateCustom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (var i = 0; i < _filters.length; i++) ...[
              _FilterChip(
                label: _filters[i].label,
                accent: _filters[i].accent,
                selected:
                    selectedCustomFilterId == null &&
                    selected == _filters[i].type,
                onTap: () => onChanged(_filters[i].type),
              ),
              const SizedBox(width: 10),
            ],
            for (var i = 0; i < customFilters.length; i++) ...[
              _FilterChip(
                label: customFilters[i].name,
                accent: _customFilterAccent(i),
                selected: selectedCustomFilterId == customFilters[i].id,
                icon: CupertinoIcons.person_2_fill,
                onTap: () => onCustomChanged(customFilters[i]),
                onLongPress: () => onCustomLongPress(customFilters[i]),
              ),
              const SizedBox(width: 10),
            ],
            _FilterChip(
              label: '作成',
              accent: _FriendsColors.lime,
              selected: false,
              icon: CupertinoIcons.plus,
              onTap: onCreateCustom,
            ),
          ],
        ),
      ),
    );
  }
}

const _filters = [
  _FriendFilter('みんな', _FriendFilterType.all, Color(0xFFB8FF00)),
];

class _FriendFilter {
  const _FriendFilter(this.label, this.type, this.accent);
  final String label;
  final _FriendFilterType type;
  final Color accent;
}

class _CustomFriendFilter {
  const _CustomFriendFilter({
    required this.id,
    required this.name,
    this.friendIds = const [],
    this.statusKeys = const [],
    this.genderKeys = const [],
    this.favoriteOnly = false,
    this.drinkableOnly = false,
    this.onlineOnly = false,
  });

  final String id;
  final String name;
  final List<String> friendIds;
  final List<String> statusKeys;
  final List<String> genderKeys;
  final bool favoriteOnly;
  final bool drinkableOnly;
  final bool onlineOnly;

  bool get hasCriteria =>
      friendIds.isNotEmpty ||
      statusKeys.isNotEmpty ||
      genderKeys.isNotEmpty ||
      favoriteOnly ||
      drinkableOnly ||
      onlineOnly;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'friendIds': friendIds,
    'statusKeys': statusKeys,
    'genderKeys': genderKeys,
    'favoriteOnly': favoriteOnly,
    'drinkableOnly': drinkableOnly,
    'onlineOnly': onlineOnly,
  };

  static _CustomFriendFilter? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = (value['id'] as String?)?.trim();
    final name = (value['name'] as String?)?.trim();
    final rawFriendIds = value['friendIds'];
    final rawStatusKeys = value['statusKeys'];
    final rawGenderKeys = value['genderKeys'];
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }
    final friendIds = rawFriendIds is List
        ? [
            for (final friendId in rawFriendIds)
              if (friendId is String && friendId.trim().isNotEmpty)
                friendId.trim(),
          ]
        : const <String>[];
    final statusKeys = rawStatusKeys is List
        ? [
            for (final statusKey in rawStatusKeys)
              if (statusKey is String && statusKey.trim().isNotEmpty)
                statusKey.trim(),
          ]
        : const <String>[];
    final genderKeys = rawGenderKeys is List
        ? [
            for (final genderKey in rawGenderKeys)
              if (genderKey is String && _isSelectableGenderKey(genderKey))
                genderKey.trim().toLowerCase(),
          ]
        : const <String>[];
    final filter = _CustomFriendFilter(
      id: id,
      name: name,
      friendIds: friendIds,
      statusKeys: statusKeys,
      genderKeys: genderKeys,
      favoriteOnly: value['favoriteOnly'] == true,
      drinkableOnly: value['drinkableOnly'] == true,
      onlineOnly: value['onlineOnly'] == true,
    );
    if (!filter.hasCriteria) return null;
    return filter;
  }
}

enum _CustomFilterSheetAction { save, delete }

class _CustomFilterSheetResult {
  const _CustomFilterSheetResult._({
    required this.action,
    this.filter,
    this.filterId,
  });

  const _CustomFilterSheetResult.save(_CustomFriendFilter filter)
    : this._(action: _CustomFilterSheetAction.save, filter: filter);

  const _CustomFilterSheetResult.delete(String filterId)
    : this._(action: _CustomFilterSheetAction.delete, filterId: filterId);

  final _CustomFilterSheetAction action;
  final _CustomFriendFilter? filter;
  final String? filterId;
}

String _customFilterStorageKey(String userId) =>
    'nomo_custom_friend_filters_v1_$userId';

bool _isSelectableGenderKey(String key) => selectableNomoGenders.any(
  (gender) => gender.key == key.trim().toLowerCase(),
);

List<_CustomFriendFilter> _decodeCustomFilters(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final filters = <_CustomFriendFilter>[];
    for (final item in decoded) {
      final filter = _CustomFriendFilter.fromJson(item);
      if (filter != null) filters.add(filter);
    }
    return filters;
  } catch (_) {
    return const [];
  }
}

_CustomFriendFilter? _findCustomFilter(
  String? id,
  List<_CustomFriendFilter> filters,
) {
  if (id == null) return null;
  for (final filter in filters) {
    if (filter.id == id) return filter;
  }
  return null;
}

const _customFilterAccents = [
  Color(0xFFC08BFF),
  Color(0xFF18AFFF),
  Color(0xFFFF5AA6),
  Color(0xFFFFA700),
  Color(0xFF46E68A),
];

Color _customFilterAccent(int index) =>
    _customFilterAccents[index % _customFilterAccents.length];

class _FriendStatusOption {
  const _FriendStatusOption({
    required this.key,
    required this.label,
    required this.enabled,
  });

  final String key;
  final String label;
  final bool enabled;
}

const _statusOptions = [
  _FriendStatusOption(key: 'can_drink_today', label: '今日飲める', enabled: true),
  _FriendStatusOption(key: 'non_alcohol', label: 'ノンアルなら', enabled: true),
  _FriendStatusOption(key: 'liver_rest', label: '休肝日', enabled: false),
  _FriendStatusOption(key: 'has_plans', label: '予定あり', enabled: false),
  _FriendStatusOption(key: 'unset', label: '未設定', enabled: true),
];

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.icon,
    this.onLongPress,
  });

  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final topColor = selected
        ? accent
        : isWhite
        ? Colors.white
        : const Color(0xFF243344);
    final bottomColor = selected
        ? Color.lerp(accent, _FriendsColors.bg, .36)!
        : isWhite
        ? const Color(0xFFE7EDF3)
        : const Color(0xFF152536);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 52,
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: bottomColor,
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? accent.withValues(alpha: .30)
                  : Colors.black.withValues(alpha: isWhite ? .08 : .22),
              blurRadius: selected ? 20 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(topColor, Colors.white, selected ? .22 : .06)!,
                topColor,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: .18)
                  : isWhite
                  ? const Color(0xFFDCE4EC)
                  : Colors.white.withValues(alpha: .10),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                NomoGeneratedIcon(
                  icon!,
                  color: selected
                      ? _FriendsColors.bg
                      : isWhite
                      ? const Color(0xFF101820)
                      : Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? _FriendsColors.bg
                      : isWhite
                      ? const Color(0xFF101820)
                      : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomFilterSheet extends StatefulWidget {
  const _CustomFilterSheet({
    required this.friends,
    required this.isWhite,
    this.initialFilter,
  });

  final List<NomoFriend> friends;
  final bool isWhite;
  final _CustomFriendFilter? initialFilter;

  @override
  State<_CustomFilterSheet> createState() => _CustomFilterSheetState();
}

class _CustomFilterSheetState extends State<_CustomFilterSheet> {
  late final TextEditingController _nameController;
  late Set<String> _selectedFriendIds;
  late Set<String> _selectedStatusKeys;
  late Set<String> _selectedGenderKeys;
  late bool _favoriteOnly;
  late bool _drinkableOnly;
  late bool _onlineOnly;
  String? _errorText;

  bool get _isEditing => widget.initialFilter != null;

  bool get _canSave => _nameController.text.trim().isNotEmpty && _hasCriteria;

  bool get _hasCriteria =>
      _selectedFriendIds.isNotEmpty ||
      _selectedStatusKeys.isNotEmpty ||
      _selectedGenderKeys.isNotEmpty ||
      _favoriteOnly ||
      _drinkableOnly ||
      _onlineOnly;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialFilter?.name ?? '')
          ..addListener(() {
            setState(() => _errorText = null);
          });
    _selectedFriendIds = {...?widget.initialFilter?.friendIds};
    _selectedStatusKeys = {...?widget.initialFilter?.statusKeys};
    _selectedGenderKeys = {...?widget.initialFilter?.genderKeys};
    _favoriteOnly = widget.initialFilter?.favoriteOnly ?? false;
    _drinkableOnly = widget.initialFilter?.drinkableOnly ?? false;
    _onlineOnly = widget.initialFilter?.onlineOnly ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleFriend(String friendId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedFriendIds.add(friendId)) {
        _selectedFriendIds.remove(friendId);
      }
      _errorText = null;
    });
  }

  void _toggleStatus(String statusKey) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedStatusKeys.add(statusKey)) {
        _selectedStatusKeys.remove(statusKey);
      }
      _errorText = null;
    });
  }

  void _toggleGender(String genderKey) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedGenderKeys.add(genderKey)) {
        _selectedGenderKeys.remove(genderKey);
      }
      _errorText = null;
    });
  }

  void _setBoolCondition({
    required bool value,
    required ValueChanged<bool> setter,
  }) {
    HapticFeedback.selectionClick();
    setState(() {
      setter(!value);
      _errorText = null;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'フィルター名を入力してね');
      return;
    }
    if (!_hasCriteria) {
      setState(() => _errorText = '条件を1つ以上選んでね');
      return;
    }
    final existingOrder = {
      for (var i = 0; i < widget.friends.length; i++) widget.friends[i].id: i,
    };
    final statusOrder = {
      for (var i = 0; i < _statusOptions.length; i++) _statusOptions[i].key: i,
    };
    final friendIds = _selectedFriendIds.toList()
      ..sort(
        (a, b) =>
            (existingOrder[a] ?? 9999).compareTo(existingOrder[b] ?? 9999),
      );
    final statusKeys = _selectedStatusKeys.toList()
      ..sort(
        (a, b) => (statusOrder[a] ?? 9999).compareTo(statusOrder[b] ?? 9999),
      );
    final genderOrder = {
      for (var i = 0; i < selectableNomoGenders.length; i++)
        selectableNomoGenders[i].key: i,
    };
    final genderKeys = _selectedGenderKeys.toList()
      ..sort(
        (a, b) => (genderOrder[a] ?? 9999).compareTo(genderOrder[b] ?? 9999),
      );
    Navigator.of(context).pop(
      _CustomFilterSheetResult.save(
        _CustomFriendFilter(
          id:
              widget.initialFilter?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          friendIds: friendIds,
          statusKeys: statusKeys,
          genderKeys: genderKeys,
          favoriteOnly: _favoriteOnly,
          drinkableOnly: _drinkableOnly,
          onlineOnly: _onlineOnly,
        ),
      ),
    );
  }

  void _delete() {
    final filter = widget.initialFilter;
    if (filter == null) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_CustomFilterSheetResult.delete(filter.id));
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = widget.isWhite;
    final bg = isWhite ? Colors.white : const Color(0xFF071622);
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF687481)
        : Colors.white.withValues(alpha: .62);
    final fieldBg = isWhite
        ? const Color(0xFFF2F6FA)
        : Colors.white.withValues(alpha: .07);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isWhite
                ? const Color(0xFFDCE4EC)
                : Colors.white.withValues(alpha: .12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isWhite ? .12 : .34),
              blurRadius: 28,
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
                  color: isWhite
                      ? const Color(0xFFD5DEE8)
                      : Colors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                NomoPopIcon(
                  icon: _isEditing
                      ? CupertinoIcons.slider_horizontal_3
                      : CupertinoIcons.person_2_fill,
                  color: _FriendsColors.lime,
                  size: 48,
                  iconSize: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'フィルター編集' : 'フィルター作成',
                        style: TextStyle(
                          color: ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'メンバー・性別・ステータス・お気に入りで絞り込めます',
                        style: TextStyle(
                          color: sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      cursorColor: _FriendsColors.lime,
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        hintText: '例：いつメン / 休肝日以外',
                        hintStyle: TextStyle(
                          color: sub,
                          fontWeight: FontWeight.w800,
                        ),
                        filled: true,
                        fillColor: fieldBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FilterSectionTitle(
                      label: '絞り込み条件',
                      helper: '複数選ぶとすべてに当てはまるフレンズだけ表示します',
                      color: ink,
                      helperColor: sub,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CriteriaToggleChip(
                          label: 'お気に入りのみ',
                          icon: CupertinoIcons.star_fill,
                          selected: _favoriteOnly,
                          accent: const Color(0xFFFFC700),
                          isWhite: isWhite,
                          onTap: () => _setBoolCondition(
                            value: _favoriteOnly,
                            setter: (value) => _favoriteOnly = value,
                          ),
                        ),
                        _CriteriaToggleChip(
                          label: '今日誘える',
                          icon: CupertinoIcons.paperplane_fill,
                          selected: _drinkableOnly,
                          accent: const Color(0xFF12C9A4),
                          isWhite: isWhite,
                          onTap: () => _setBoolCondition(
                            value: _drinkableOnly,
                            setter: (value) => _drinkableOnly = value,
                          ),
                        ),
                        _CriteriaToggleChip(
                          label: 'オンライン',
                          icon: CupertinoIcons.circle_fill,
                          selected: _onlineOnly,
                          accent: const Color(0xFF18AFFF),
                          isWhite: isWhite,
                          onTap: () => _setBoolCondition(
                            value: _onlineOnly,
                            setter: (value) => _onlineOnly = value,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FilterSectionTitle(
                      label: '性別',
                      helper: '何も選ばない場合は男女どちらも対象です',
                      color: ink,
                      helperColor: sub,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final gender in selectableNomoGenders)
                          _CriteriaToggleChip(
                            label: gender.label,
                            icon: gender == NomoGender.male
                                ? CupertinoIcons.person_fill
                                : CupertinoIcons.person_crop_circle_fill,
                            selected: _selectedGenderKeys.contains(gender.key),
                            accent: gender == NomoGender.male
                                ? const Color(0xFF18AFFF)
                                : const Color(0xFFFF5AA6),
                            isWhite: isWhite,
                            onTap: () => _toggleGender(gender.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FilterSectionTitle(
                      label: 'ステータス',
                      helper: '何も選ばない場合は全ステータスが対象です',
                      color: ink,
                      helperColor: sub,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in _statusOptions)
                          _CriteriaToggleChip(
                            label: option.label,
                            selected: _selectedStatusKeys.contains(option.key),
                            accent: option.enabled
                                ? _FriendsColors.lime
                                : _FriendsColors.muted,
                            isWhite: isWhite,
                            onTap: () => _toggleStatus(option.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FilterSectionTitle(
                      label: 'フレンズ',
                      helper: '何も選ばない場合は全員が対象です',
                      color: ink,
                      helperColor: sub,
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < widget.friends.length; i++) ...[
                      _CustomFilterFriendRow(
                        friend: widget.friends[i],
                        selected: _selectedFriendIds.contains(
                          widget.friends[i].id,
                        ),
                        isWhite: isWhite,
                        onTap: () => _toggleFriend(widget.friends[i].id),
                      ),
                      if (i != widget.friends.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: const TextStyle(
                  color: Color(0xFFFF6B8A),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Nomo3DButton(
              label: _isEditing ? '保存する' : '作成する',
              icon: CupertinoIcons.checkmark_circle_fill,
              onTap: _canSave ? _save : null,
              enabled: _canSave,
              height: 48,
              radius: 20,
              color: _FriendsColors.lime,
              foregroundColor: _FriendsColors.bg,
              shadowColor: const Color(0xFF77A600),
              fontSize: 14,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                onPressed: _delete,
                child: const Text(
                  '削除する',
                  style: TextStyle(
                    color: Color(0xFFFF6B8A),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({
    required this.label,
    required this.helper,
    required this.color,
    required this.helperColor,
  });

  final String label;
  final String helper;
  final Color color;
  final Color helperColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          helper,
          style: TextStyle(
            color: helperColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CriteriaToggleChip extends StatelessWidget {
  const _CriteriaToggleChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isWhite,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color accent;
  final bool isWhite;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ink = selected
        ? _FriendsColors.bg
        : isWhite
        ? const Color(0xFF101820)
        : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : isWhite
              ? const Color(0xFFF7F9FB)
              : Colors.white.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: .20)
                : isWhite
                ? const Color(0xFFDCE4EC)
                : Colors.white.withValues(alpha: .10),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: .20),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              NomoGeneratedIcon(icon!, color: ink, size: 15),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomFilterFriendRow extends StatelessWidget {
  const _CustomFilterFriendRow({
    required this.friend,
    required this.selected,
    required this.isWhite,
    required this.onTap,
  });

  final NomoFriend friend;
  final bool selected;
  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF687481)
        : Colors.white.withValues(alpha: .62);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _FriendsColors.lime.withValues(alpha: isWhite ? .18 : .14)
              : isWhite
              ? const Color(0xFFF7F9FB)
              : Colors.white.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _FriendsColors.lime.withValues(alpha: .62)
                : isWhite
                ? const Color(0xFFDCE4EC)
                : Colors.white.withValues(alpha: .08),
          ),
        ),
        child: Row(
          children: [
            NomoAvatarView(
              avatar: friend.avatar ?? _fallbackAvatarForFriend(friend),
              size: 42,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusForFriend(friend, 0).label,
                    style: TextStyle(
                      color: sub,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? _FriendsColors.lime : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? _FriendsColors.lime
                      : isWhite
                      ? const Color(0xFFB8C4D0)
                      : Colors.white.withValues(alpha: .24),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Center(
                      child: NomoGeneratedIcon(
                        CupertinoIcons.checkmark,
                        color: _FriendsColors.bg,
                        size: 18,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList({
    required this.friends,
    required this.userAvatar,
    required this.selectedFilter,
    required this.selectedCustomFilter,
    required this.favoriteOverrides,
    required this.onFavoriteToggle,
    required this.onInvite,
  });

  final List<NomoFriend> friends;
  final NomoAvatar userAvatar;
  final _FriendFilterType selectedFilter;
  final _CustomFriendFilter? selectedCustomFilter;
  final Map<String, bool> favoriteOverrides;
  final void Function(NomoFriend friend, bool isFavorite) onFavoriteToggle;
  final ValueChanged<NomoFriend> onInvite;

  @override
  Widget build(BuildContext context) {
    final decorated = [
      for (var i = 0; i < friends.length; i++)
        _DecoratedFriend(
          friend: _friendWithFavorite(
            friends[i],
            favoriteOverrides[friends[i].id] ?? friends[i].isFavorite,
          ),
          status: _statusForFriend(friends[i], i),
        ),
    ];
    final filtered = decorated.where((item) {
      if (selectedCustomFilter != null) {
        return _matchesCustomFilter(item, selectedCustomFilter!);
      }
      return switch (selectedFilter) {
        _FriendFilterType.all => true,
      };
    }).toList();

    if (filtered.isEmpty) {
      return _EmptyFriendsState(
        avatar: userAvatar,
        message: friends.isEmpty ? 'フレンズがいません' : 'この条件のフレンズはいません',
        subtitle: friends.isEmpty
            ? '右上の＋からフレンズを追加しよう'
            : selectedCustomFilter == null
            ? '別の条件を選ぶと見つかるかも'
            : 'フィルターを長押しすると編集できます',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 116),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _FriendCard(
          friend: item.friend,
          status: item.status,
          onFavoriteToggle: () =>
              onFavoriteToggle(item.friend, !item.friend.isFavorite),
          onInvite: () => onInvite(item.friend),
        );
      },
    );
  }
}

class _DecoratedFriend {
  const _DecoratedFriend({required this.friend, required this.status});

  final NomoFriend friend;
  final _FriendStatus status;
}

bool _matchesCustomFilter(_DecoratedFriend item, _CustomFriendFilter filter) {
  if (filter.friendIds.isNotEmpty &&
      !filter.friendIds.contains(item.friend.id)) {
    return false;
  }
  if (filter.statusKeys.isNotEmpty &&
      !filter.statusKeys.contains(_normalizedStatusKey(item.friend))) {
    return false;
  }
  if (filter.genderKeys.isNotEmpty &&
      !filter.genderKeys.contains(item.friend.gender.key)) {
    return false;
  }
  if (filter.favoriteOnly && !item.friend.isFavorite) return false;
  if (filter.drinkableOnly && !_isDrinkableStatus(item.status)) return false;
  if (filter.onlineOnly && item.friend.isOnline != true) return false;
  return true;
}

String _normalizedStatusKey(NomoFriend friend) {
  return switch (friend.statusKey) {
    'can_drink_today' => 'can_drink_today',
    'non_alcohol' => 'non_alcohol',
    'liver_rest' => 'liver_rest',
    'has_plans' => 'has_plans',
    _ => 'unset',
  };
}

NomoFriend _friendWithFavorite(NomoFriend friend, bool isFavorite) {
  if (friend.isFavorite == isFavorite) return friend;
  return NomoFriend(
    id: friend.id,
    name: friend.name,
    avatarEmoji: friend.avatarEmoji,
    vibe: friend.vibe,
    characterAssetPath: friend.characterAssetPath,
    kind: friend.kind,
    palette: friend.palette,
    gender: friend.gender,
    avatar: friend.avatar,
    monthlyCount: friend.monthlyCount,
    statusKey: friend.statusKey,
    isOnline: friend.isOnline,
    isFavorite: isFavorite,
  );
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState({
    required this.avatar,
    required this.message,
    required this.subtitle,
  });

  final NomoAvatar avatar;
  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF1B2633) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF6D7784)
        : Colors.white.withValues(alpha: .58);
    return Padding(
      padding: const EdgeInsets.only(bottom: 116),
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -42),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 132,
                height: 124,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _FriendsColors.lime.withValues(alpha: .26),
                            _FriendsColors.lime.withValues(alpha: .04),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 86,
                      height: 86,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isWhite
                            ? Colors.white
                            : Colors.white.withValues(alpha: .07),
                        border: Border.all(
                          color: _FriendsColors.lime.withValues(alpha: .45),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _FriendsColors.lime.withValues(alpha: .18),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: NomoAvatarView(avatar: avatar, size: 76),
                    ),
                    Positioned(
                      right: 14,
                      bottom: 18,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _FriendsColors.lime,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isWhite ? Colors.white : _FriendsColors.bg,
                            width: 3,
                          ),
                        ),
                        child: const Center(
                          child: NomoGeneratedIcon(
                            CupertinoIcons.plus,
                            color: _FriendsColors.bg,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isDrinkableStatus(_FriendStatus status) {
  return switch (status.label) {
    '今日飲める' || 'ノンアルなら' || '未設定' => true,
    _ => false,
  };
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.status,
    required this.onFavoriteToggle,
    required this.onInvite,
  });

  final NomoFriend friend;
  final _FriendStatus status;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForFriend(friend);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return Container(
      constraints: const BoxConstraints(minHeight: 98),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : _FriendsColors.block,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFDCE4EC)
              : Colors.white.withValues(alpha: .075),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .06 : .24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 62,
            height: 66,
            child: NomoAvatarView(
              avatar: friend.avatar ?? _fallbackAvatarForFriend(friend),
              size: 62,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        friend.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Semantics(
                      button: true,
                      label: friend.isFavorite ? 'お気に入りを解除' : 'お気に入りに追加',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onFavoriteToggle,
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: Center(
                            child: _FavoriteStarIcon(
                              filled: friend.isFavorite,
                              color: friend.isFavorite
                                  ? const Color(0xFFFFC700)
                                  : (isWhite
                                        ? const Color(0xFF8C9CAB)
                                        : _FriendsColors.muted),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                _StatusPill(status: status, accent: accent),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _InviteButton(
            status: status,
            accent: accent,
            name: friend.name,
            onInvite: onInvite,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.accent});

  final _FriendStatus status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: status.enabled ? .16 : .10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.enabled ? accent : _FriendsColors.muted,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _FavoriteStarIcon extends StatelessWidget {
  const _FavoriteStarIcon({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 21,
    height: 21,
    child: CustomPaint(
      painter: _FavoriteStarPainter(filled: filled, color: color),
    ),
  );
}

class _FavoriteStarPainter extends CustomPainter {
  const _FavoriteStarPainter({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final star = _starPath(size);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (filled) {
      canvas.drawPath(
        star.shift(Offset(size.width * .045, size.height * .055)),
        Paint()
          ..color = const Color(0xFF06111D).withValues(alpha: .26)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(star, Paint()..color = color);
      canvas.drawPath(
        star,
        stroke..color = Colors.white.withValues(alpha: .38),
      );
      canvas.drawCircle(
        Offset(size.width * .39, size.height * .35),
        size.width * .045,
        Paint()..color = Colors.white.withValues(alpha: .62),
      );
      return;
    }

    canvas.drawPath(star, stroke);
  }

  Path _starPath(Size size) {
    final points = <Offset>[
      Offset(size.width * .50, size.height * .08),
      Offset(size.width * .61, size.height * .36),
      Offset(size.width * .91, size.height * .36),
      Offset(size.width * .67, size.height * .55),
      Offset(size.width * .76, size.height * .85),
      Offset(size.width * .50, size.height * .68),
      Offset(size.width * .24, size.height * .85),
      Offset(size.width * .33, size.height * .55),
      Offset(size.width * .09, size.height * .36),
      Offset(size.width * .39, size.height * .36),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _FavoriteStarPainter oldDelegate) {
    return oldDelegate.filled != filled || oldDelegate.color != color;
  }
}

class _InviteButton extends StatelessWidget {
  const _InviteButton({
    required this.status,
    required this.accent,
    required this.name,
    required this.onInvite,
  });

  final _FriendStatus status;
  final Color accent;
  final String name;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final enabled = status.enabled;
    return SizedBox(
      width: 92,
      child: Nomo3DButton(
        label: '誘う',
        icon: CupertinoIcons.paperplane_fill,
        onTap: enabled ? onInvite : null,
        enabled: enabled,
        height: 36,
        radius: 18,
        color: const Color(0xFF12C9A4),
        shadowColor: const Color(0xFF079078),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        fontSize: 12,
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(color: Colors.white),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .64),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendStatus {
  const _FriendStatus({required this.label, required this.enabled});

  final String label;
  final bool enabled;
}

_FriendStatus _statusForFriend(NomoFriend friend, int _) {
  switch (friend.statusKey) {
    case 'can_drink_today':
      return const _FriendStatus(label: '今日飲める', enabled: true);
    case 'non_alcohol':
      return const _FriendStatus(label: 'ノンアルなら', enabled: true);
    case 'liver_rest':
      return const _FriendStatus(label: '休肝日', enabled: false);
    case 'has_plans':
      return const _FriendStatus(label: '予定あり', enabled: false);
    case 'unselected' || 'unset' || null || '':
      return const _FriendStatus(label: '未設定', enabled: true);
  }

  return const _FriendStatus(label: '未設定', enabled: true);
}

Color _accentForFriend(NomoFriend friend) {
  return switch (friend.palette) {
    NomiTomoPalette.peach => const Color(0xFFFFB03B),
    NomiTomoPalette.sky => const Color(0xFF18AFFF),
    NomiTomoPalette.lemon => _FriendsColors.lime,
    NomiTomoPalette.lavender => const Color(0xFFA855F7),
    NomiTomoPalette.mint => const Color(0xFF46E68A),
    NomiTomoPalette.blush => const Color(0xFFFF4B9A),
  };
}

NomoAvatar _fallbackAvatarForFriend(NomoFriend friend) {
  final hash = friend.id.hashCode.abs();
  return NomoAvatar(
    skin: hash % NomoAvatar.skinColors.length,
    hair: (hash ~/ 3) % NomoAvatar.hairStyles.length,
    shirt: (hash ~/ 5) % NomoAvatar.shirtColors.length,
    eyes: (hash ~/ 7) % NomoAvatar.eyeStyles.length,
    mouth: (hash ~/ 11) % NomoAvatar.mouthStyles.length,
    accessory: (hash ~/ 13) % NomoAvatar.accessoryStyles.length,
  );
}

class _FriendsColors {
  const _FriendsColors._();

  static const bg = AppColors.darkBackgroundBottom;
  static const block = Color(0xFF101B28);
  static const lime = Color(0xFFB8FF00);
  static const muted = Color(0xFF8792A3);
}
