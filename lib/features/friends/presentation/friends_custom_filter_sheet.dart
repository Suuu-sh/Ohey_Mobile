part of 'friends_screen.dart';

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

enum _CustomFilterManageAction { add, edit, delete, reorder }

class _CustomFilterManageResult {
  const _CustomFilterManageResult._({
    required this.action,
    this.filter,
    this.filterId,
    this.filters,
  });

  const _CustomFilterManageResult.edit(_CustomFriendFilter filter)
    : this._(action: _CustomFilterManageAction.edit, filter: filter);

  const _CustomFilterManageResult.add()
    : this._(action: _CustomFilterManageAction.add);

  const _CustomFilterManageResult.delete(String filterId)
    : this._(action: _CustomFilterManageAction.delete, filterId: filterId);

  const _CustomFilterManageResult.reorder(List<_CustomFriendFilter> filters)
    : this._(action: _CustomFilterManageAction.reorder, filters: filters);

  final _CustomFilterManageAction action;
  final _CustomFriendFilter? filter;
  final String? filterId;
  final List<_CustomFriendFilter>? filters;
}

String _customFilterStorageKey(String userId) =>
    'ohey_custom_friend_filters_v1_$userId';

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
  AppColors.cFFC08BFF,
  AppColors.cFF18AFFF,
  AppColors.cFFFF5AA6,
  AppColors.cFFFFA700,
  AppColors.cFF46E68A,
];

Color _customFilterAccent(int index) =>
    _customFilterAccents[index % _customFilterAccents.length];

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
        ? AppColors.white
        : AppColors.cFF243344;
    final bottomColor = selected
        ? Color.lerp(accent, _FriendsColors.bg, .36)!
        : isWhite
        ? AppColors.cFFE7EDF3
        : AppColors.cFF152536;
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
                  : AppColors.black.withValues(alpha: isWhite ? .08 : .22),
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
                Color.lerp(topColor, AppColors.white, selected ? .22 : .06)!,
                topColor,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.white.withValues(alpha: .18)
                  : isWhite
                  ? AppColors.cFFDCE4EC
                  : AppColors.white.withValues(alpha: .10),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                OheyGeneratedIcon(
                  icon!,
                  color: selected
                      ? _FriendsColors.bg
                      : isWhite
                      ? AppColors.cFF101820
                      : AppColors.white,
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
                      ? AppColors.cFF101820
                      : AppColors.white,
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

class _CustomFilterManageSheet extends StatefulWidget {
  const _CustomFilterManageSheet({required this.filters});

  final List<_CustomFriendFilter> filters;

  @override
  State<_CustomFilterManageSheet> createState() =>
      _CustomFilterManageSheetState();
}

class _CustomFilterManageSheetState extends State<_CustomFilterManageSheet> {
  late List<_CustomFriendFilter> _filters;

  @override
  void initState() {
    super.initState();
    _filters = [...widget.filters];
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite ? AppColors.cFF657282 : AppColors.white70;
    return OheyBottomSheetShell(
      title: 'グループ編集',
      showHandle: true,
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '追加・並び替え・削除をここでまとめてできるよ。',
            style: TextStyle(color: sub, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _CustomFilterManageAddButton(isWhite: isWhite),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _filters.length,
              onReorder: (oldIndex, newIndex) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (oldIndex < newIndex) newIndex -= 1;
                  final item = _filters.removeAt(oldIndex);
                  _filters.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return _CustomFilterManageRow(
                  key: ValueKey(filter.id),
                  filter: filter,
                  index: index,
                  ink: ink,
                  onEdit: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(
                      context,
                    ).pop(_CustomFilterManageResult.edit(filter));
                  },
                  onDelete: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(
                      context,
                    ).pop(_CustomFilterManageResult.delete(filter.id));
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          OheyPrimaryButton(
            label: 'この順番で保存',
            icon: CupertinoIcons.checkmark_alt_circle_fill,
            onPressed: () => Navigator.of(
              context,
            ).pop(_CustomFilterManageResult.reorder(_filters)),
          ),
        ],
      ),
    );
  }
}

class _CustomFilterManageAddButton extends StatelessWidget {
  const _CustomFilterManageAddButton({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    return OheyManageAddTile(
      label: 'グループを追加',
      accent: _FriendsColors.lime,
      foregroundColor: ink,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(const _CustomFilterManageResult.add());
      },
    );
  }
}

class _CustomFilterManageRow extends StatelessWidget {
  const _CustomFilterManageRow({
    super.key,
    required this.filter,
    required this.index,
    required this.ink,
    required this.onEdit,
    required this.onDelete,
  });

  final _CustomFriendFilter filter;
  final int index;
  final Color ink;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = _customFilterAccent(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OheyManageListRow(
        title: filter.name,
        titleColor: ink,
        leading: ReorderableDragStartListener(
          index: index,
          child: OheyPopIcon(
            icon: CupertinoIcons.line_horizontal_3,
            color: accent,
            size: 36,
            iconSize: 18,
          ),
        ),
        actions: [
          OheyManageListIconButton(
            icon: CupertinoIcons.pencil,
            color: accent,
            semanticLabel: '${filter.name}を編集',
            onTap: onEdit,
          ),
          OheyManageListIconButton(
            icon: CupertinoIcons.trash_fill,
            color: AppColors.cFFFF6B9A,
            semanticLabel: '${filter.name}を削除',
            onTap: onDelete,
          ),
        ],
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

  final List<OheyFriend> friends;
  final bool isWhite;
  final _CustomFriendFilter? initialFilter;

  @override
  State<_CustomFilterSheet> createState() => _CustomFilterSheetState();
}

class _CustomFilterSheetState extends State<_CustomFilterSheet> {
  late final TextEditingController _nameController;
  late Set<String> _selectedFriendIds;
  String? _errorText;

  bool get _isEditing => widget.initialFilter != null;

  bool get _canSave => true;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialFilter?.name ?? '')
          ..addListener(() {
            setState(() => _errorText = null);
          });
    _selectedFriendIds = {...?widget.initialFilter?.friendIds};
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

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'グループ名を入れてね');
      OheyToast.show(
        context,
        'グループ名を入れてね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
      return;
    }
    if (_selectedFriendIds.isEmpty) {
      setState(() => _errorText = 'メンバーを1人以上選んでね');
      return;
    }
    final existingOrder = {
      for (var i = 0; i < widget.friends.length; i++) widget.friends[i].id: i,
    };
    final friendIds = _selectedFriendIds.toList()
      ..sort(
        (a, b) =>
            (existingOrder[a] ?? 9999).compareTo(existingOrder[b] ?? 9999),
      );
    Navigator.of(context).pop(
      _CustomFilterSheetResult.save(
        _CustomFriendFilter(
          id:
              widget.initialFilter?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          friendIds: friendIds,
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
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF687481
        : AppColors.white.withValues(alpha: .62);
    final fieldBg = isWhite
        ? AppColors.cFFF2F6FA
        : AppColors.white.withValues(alpha: .07);
    return OheyBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      radius: 30,
      maxHeightFactor: .88,
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
                    ? AppColors.cFFD5DEE8
                    : AppColors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OheyPopIcon(
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
                      _isEditing ? 'グループ編集' : 'グループ作成',
                      style: TextStyle(
                        color: ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'よく遊ぶメンバーをまとめておけるよ。',
                      style: TextStyle(
                        color: sub,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              OheyCloseButton(
                onTap: () => Navigator.of(context).pop(),
                iconColor: sub,
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
                      hintText: 'グループ名（例：いつメン）',
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
                  _FilterSectionTitle(label: 'フレンズ', color: ink),
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
                color: AppColors.cFFFF6B8A,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Ohey3DButton(
            label: _isEditing ? '保存する' : '作成する',
            icon: CupertinoIcons.checkmark_circle_fill,
            onTap: _canSave ? _save : null,
            enabled: _canSave,
            height: 48,
            radius: 20,
            color: _FriendsColors.lime,
            foregroundColor: _FriendsColors.bg,
            shadowColor: AppColors.cFF77A600,
            fontSize: 14,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            Ohey3DButton.destructive(
              label: '削除する',
              icon: CupertinoIcons.trash_fill,
              onTap: _delete,
              height: 46,
              radius: 20,
              color: AppColors.cFFFF6B8A,
              shadowColor: AppColors.cFFB9365A,
              fontSize: 13,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _FriendsColors.lime,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _CustomFilterFriendRow extends StatelessWidget {
  const _CustomFilterFriendRow({
    required this.friend,
    required this.selected,
    required this.isWhite,
    required this.onTap,
  });

  final OheyFriend friend;
  final bool selected;
  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF687481
        : AppColors.white.withValues(alpha: .62);
    final surface = selected
        ? _FriendsColors.lime.withValues(alpha: isWhite ? .24 : .18)
        : isWhite
        ? AppColors.cFFF7F9FB
        : AppColors.darkBackground;
    final bottom = selected
        ? ohey3DShadowColorFor(_FriendsColors.lime, lightnessScale: .60)
        : isWhite
        ? AppColors.cFFD9E2EB
        : AppColors.cFF09131D;
    return Ohey3DButtonSurface(
      onTap: onTap,
      height: 58,
      radius: 18,
      color: surface,
      bottomColor: bottom,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      borderColor: selected
          ? _FriendsColors.lime.withValues(alpha: .62)
          : isWhite
          ? AppColors.cFFDCE4EC
          : AppColors.white.withValues(alpha: .10),
      outerShadows: [
        BoxShadow(
          color: _FriendsColors.lime.withValues(
            alpha: selected ? (isWhite ? .14 : .22) : .07,
          ),
          blurRadius: selected ? 18 : 12,
          offset: const Offset(0, 6),
        ),
      ],
      child: Row(
        children: [
          OheyAvatarView(
            avatar: friend.avatar ?? _fallbackAvatarForFriend(friend),
            size: 42,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
              color: selected ? _FriendsColors.lime : AppColors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? _FriendsColors.lime
                    : isWhite
                    ? AppColors.cFFB8C4D0
                    : AppColors.white.withValues(alpha: .24),
                width: 1.5,
              ),
            ),
            child: selected
                ? const Center(
                    child: OheyGeneratedIcon(
                      CupertinoIcons.checkmark,
                      color: _FriendsColors.bg,
                      size: 18,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
