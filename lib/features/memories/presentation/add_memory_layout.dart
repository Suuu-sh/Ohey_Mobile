// ignore_for_file: invalid_use_of_protected_member

part of 'add_memory_screen.dart';

extension _AddMemoryScreenLayout on _AddMemoryScreenState {
  Widget _buildAddMemoryScreen(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final friendEditor = _FriendSelectCard(
      search: _InputBox(
        icon: CupertinoIcons.search,
        iconColor: _AddMemoryColors.searchIcon,
        hint: '誰と？（任意）',
        controller: _friendSearchController,
        maxLines: 1,
        borderless: true,
        onChanged: (value) => setState(() => _friendSearchQuery = value),
        suffix: _friendSearchQuery.isEmpty
            ? null
            : IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  _friendSearchController.clear();
                  _friendSearchQuery = '';
                }),
                icon: const OheyGeneratedIcon(
                  CupertinoIcons.xmark_circle_fill,
                  color: _AddMemoryColors.clearIcon,
                ),
              ),
      ),
      chips: SizedBox(
        height: 58,
        child: friendsAsync.when(
          data: (friends) => _FriendChips(
            friends: _filteredFriends(friends),
            selectedIds: _selectedFriendIds,
            onChanged: _toggleFriend,
            emptyMessage: _friendSearchQuery.trim().isEmpty
                ? 'まだフレンズがいません'
                : '該当するフレンズがいません',
          ),
          loading: () => const _LoadingBox(compact: true),
          error: (error, stackTrace) =>
              const _ErrorBox(message: '読み込めなかったよ。あとでもう一度試してね', compact: true),
        ),
      ),
    );
    final placeEditor = _InputBox(
      icon: CupertinoIcons.location_solid,
      iconColor: _AddMemoryColors.placeIcon,
      hint: 'どこで？（任意）',
      controller: _placeController,
      maxLines: 1,
      onChanged: (_) => setState(() {}),
      suffix: _PlaceSearchButton(onTap: _openPlaceSearch),
    );
    final dateEditor = _DateTimeBox(
      icon: CupertinoIcons.calendar,
      iconColor: _AddMemoryColors.calendarIcon,
      label: _addMemoryDateTimeLabel(_selectedDate),
      onTap: _pickDateTime,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _AddMemoryColors.pageBackgroundFor(context),
      body: DecoratedBox(
        decoration: _AddMemoryColors.pageDecorationFor(context),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                child: _Header(onClose: () => Navigator.of(context).maybePop()),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
                  children: [
                    dateEditor,
                    const SizedBox(height: 14),
                    _InputBox(
                      icon: CupertinoIcons.text_quote,
                      iconColor: _AddMemoryColors.impressionIcon,
                      hint: 'コメント（任意・15文字まで）',
                      controller: _memoController,
                      maxLines: 3,
                      maxLength: _memoryCommentMaxLength,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    friendEditor,
                    const SizedBox(height: 14),
                    placeEditor,
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: _SaveButton(
                    label: '記録を保存する',
                    isSaving: _isSaving,
                    onPressed: () => _save(
                      friendsAsync.asData?.value ?? const <OheyFriend>[],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
