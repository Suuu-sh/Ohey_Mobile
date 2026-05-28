// ignore_for_file: invalid_use_of_protected_member

part of 'add_log_screen.dart';

extension _AddLogScreenLayout on _AddLogScreenState {
  Widget _buildAddLogScreen(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final user = ref.watch(nomoUserProvider);
    final selectedFriends =
        friendsAsync.asData?.value
            .where((friend) => _selectedFriendIds.contains(friend.id))
            .toList(growable: false) ??
        const <NomoFriend>[];
    final friendEditor = _FriendSelectCard(
      search: _InputBox(
        icon: CupertinoIcons.search,
        iconColor: _AddLogColors.searchIcon,
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
                icon: const NomoGeneratedIcon(
                  CupertinoIcons.xmark_circle_fill,
                  color: _AddLogColors.clearIcon,
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
      iconColor: _AddLogColors.placeIcon,
      hint: 'どこで？（任意）',
      controller: _placeController,
      maxLines: 1,
      onChanged: (_) => setState(() {}),
      suffix: _PlaceSearchButton(onTap: _openPlaceSearch),
    );
    final dateEditor = _DateTimeBox(
      icon: CupertinoIcons.calendar,
      iconColor: _AddLogColors.calendarIcon,
      label: _addLogDateTimeLabel(_selectedDate),
      onTap: _pickDateTime,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _AddLogColors.pageBackgroundFor(context),
      body: DecoratedBox(
        decoration: _AddLogColors.pageDecorationFor(context),
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
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 26),
                  children: [
                    if (_hasPhoto) ...[
                      _PostPreviewCard(
                        path: _photoPath!,
                        userName: _previewUserName(user?.name),
                        avatar: user?.avatar ?? NomoAvatar.defaultAvatar,
                        memoController: _memoController,
                        captionY: _captionY,
                        place: _placeController.text,
                        date: _selectedDate,
                        friends: selectedFriends,
                        dateEditor: dateEditor,
                        friendEditor: friendEditor,
                        placeEditor: placeEditor,
                        onEditDateTime: _pickDateTime,
                        onMemoChanged: (_) => setState(() {}),
                        onCaptionYChanged: (value) =>
                            setState(() => _captionY = value),
                        onRetake: _openNomoCamera,
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _PhotoCapturePrompt(onTap: _openNomoCamera),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: dateEditor,
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _InputBox(
                          icon: CupertinoIcons.text_quote,
                          iconColor: _AddLogColors.impressionIcon,
                          hint: 'コメント（任意・15文字まで）',
                          controller: _memoController,
                          maxLines: 3,
                          maxLength: _drinkLogCommentMaxLength,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (!_hasPhoto) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: friendEditor,
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: placeEditor,
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: _SaveButton(
                    label: _hasPhoto ? 'この1枚を投稿する' : '記録だけ保存する',
                    isSaving: _isSaving,
                    onPressed: () => _save(
                      friendsAsync.asData?.value ?? const <NomoFriend>[],
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
