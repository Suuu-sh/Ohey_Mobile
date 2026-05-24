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
    final bg = NomoThemedPanel.surfaceColor(isWhite: isWhite);
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
          gradient: isWhite
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF7FAFD)],
                )
              : null,
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
                        'よく使う条件だけ選んで保存できます',
                        style: TextStyle(
                          color: sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(42, 42),
                  borderRadius: BorderRadius.circular(18),
                  onPressed: () => Navigator.of(context).pop(),
                  child: NomoGeneratedIcon(
                    CupertinoIcons.xmark,
                    color: sub,
                    size: 24,
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
                        hintText: 'フィルター名（例：いつメン）',
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
                    _FilterSectionTitle(label: 'よく使う条件', color: ink),
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
                    _FilterSectionTitle(label: '性別', color: ink),
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
                    _FilterSectionTitle(label: 'ステータス', color: ink),
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
              : AppColors.darkBackground,
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
              : AppColors.darkBackground,
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
