part of 'friends_screen.dart';

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
