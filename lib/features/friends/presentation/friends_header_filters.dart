part of 'friends_screen.dart';

class _FriendsHeaderBackdrop extends StatelessWidget {
  const _FriendsHeaderBackdrop({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return OheySceneHeaderBackdrop(
      assetPath: 'assets/images/friends_header_scene.png',
      fadeColor: isWhite ? Colors.white : AppColors.darkBackgroundBottom,
      accentColor: _FriendsColors.lime,
      topShadeOpacity: .12,
      fadeStartOpacity: .84,
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
    required this.onManageCustom,
  });

  final _FriendFilterType selected;
  final String? selectedCustomFilterId;
  final List<_CustomFriendFilter> customFilters;
  final ValueChanged<_FriendFilterType> onChanged;
  final ValueChanged<_CustomFriendFilter> onCustomChanged;
  final ValueChanged<_CustomFriendFilter> onCustomLongPress;
  final VoidCallback onManageCustom;

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
                onTap: () => onCustomChanged(customFilters[i]),
                onLongPress: () => onCustomLongPress(customFilters[i]),
              ),
              const SizedBox(width: 10),
            ],
            _FilterChip(
              label: '編集',
              accent: const Color(0xFF5DEBD3),
              selected: false,
              icon: CupertinoIcons.pencil,
              onTap: onManageCustom,
            ),
            const SizedBox(width: 10),
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
  });

  final String id;
  final String name;
  final List<String> friendIds;

  bool get hasCriteria => friendIds.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'friendIds': friendIds,
  };

  static _CustomFriendFilter? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = (value['id'] as String?)?.trim();
    final name = (value['name'] as String?)?.trim();
    final rawFriendIds = value['friendIds'] ?? value['friend_ids'];
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
    final filter = _CustomFriendFilter(
      id: id,
      name: name,
      friendIds: friendIds,
    );
    if (!filter.hasCriteria) return null;
    return filter;
  }
}

enum _CustomFilterSheetAction { save, delete }
