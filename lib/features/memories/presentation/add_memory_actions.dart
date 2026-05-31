// ignore_for_file: invalid_use_of_protected_member

part of 'add_memory_screen.dart';

extension _AddMemoryScreenActions on _AddMemoryScreenState {
  List<OheyFriend> _filteredFriends(List<OheyFriend> friends) {
    final query = _friendSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return friends;
    return friends
        .where((friend) {
          final target = '${friend.name} ${friend.vibe}'.toLowerCase();
          return target.contains(query);
        })
        .toList(growable: false);
  }

  void _toggleFriend(String id) {
    setState(() {
      if (_selectedFriendIds.contains(id)) {
        _selectedFriendIds.remove(id);
      } else {
        _selectedFriendIds.add(id);
      }
    });
  }

  Future<void> _pickDateTime() async {
    final isWhite = _AddMemoryColors.isWhite(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) => Theme(
        data: (isWhite ? ThemeData.light() : ThemeData.dark()).copyWith(
          colorScheme: isWhite
              ? const ColorScheme.light(
                  primary: _AddMemoryColors.lime,
                  surface: AppColors.white,
                  onSurface: _AddMemoryColors.lightText,
                )
              : const ColorScheme.dark(
                  primary: _AddMemoryColors.lime,
                  surface: _AddMemoryColors.surface,
                ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) => Theme(
        data: (isWhite ? ThemeData.light() : ThemeData.dark()).copyWith(
          colorScheme: isWhite
              ? const ColorScheme.light(
                  primary: _AddMemoryColors.lime,
                  surface: AppColors.white,
                  onSurface: _AddMemoryColors.lightText,
                )
              : const ColorScheme.dark(
                  primary: _AddMemoryColors.lime,
                  surface: _AddMemoryColors.surface,
                ),
        ),
        child: child!,
      ),
    );
    final time = pickedTime ?? TimeOfDay.fromDateTime(_selectedDate);
    setState(
      () => _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _openPlaceSearch() async {
    final selected = await Navigator.of(context).push<OheyPlaceSearchResult>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PlaceSearchScreen(initialQuery: _placeController.text),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _placeController.text = selected.name;
      _selectedPlaceName = selected.name;
      _selectedPlaceLatitude = selected.latitude;
      _selectedPlaceLongitude = selected.longitude;
    });
  }

  Future<void> _save(List<OheyFriend> friends) async {
    if (_isSaving) return;
    if (await _hasExistingMemoryOn(_selectedDate)) {
      if (!mounted) return;
      await showMemoryDailyLimitDialog(context, _selectedDate);
      return;
    }

    setState(() => _isSaving = true);
    final selectedFriends = friends
        .where((friend) => _selectedFriendIds.contains(friend.id))
        .toList(growable: false);
    try {
      final previousMemories =
          ref.read(memoryControllerProvider).asData?.value ?? const <Memory>[];
      final placeText = _placeController.text.trim();
      final hasSelectedPlaceCoordinate =
          _selectedPlaceName != null && placeText == _selectedPlaceName!.trim();
      await ref
          .read(memoryControllerProvider.notifier)
          .addMemory(
            date: _selectedDate,
            friends: selectedFriends,
            place: placeText,
            memo: _memoController.text,
            placeLatitude: hasSelectedPlaceCoordinate
                ? _selectedPlaceLatitude
                : null,
            placeLongitude: hasSelectedPlaceCoordinate
                ? _selectedPlaceLongitude
                : null,
          );
      if (!mounted) return;
      setState(() => _isSaving = false);
      final monthlyCount = _monthlyMemoryCountAfterSave(previousMemories);
      final openCalendar = await _showMemorySuccessSheet(
        friends: selectedFriends,
        monthlyCount: monthlyCount,
      );
      if (!mounted) return;
      Navigator.of(context).pop(openCalendar);
    } on BackendApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (error.statusCode == 409) {
        await showMemoryDailyLimitDialog(context, _selectedDate);
        return;
      }
      OheyToast.show(context, '保存できなかったよ。あとでもう一度試してね');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      OheyToast.show(context, '保存できなかったよ。あとでもう一度試してね');
    }
  }

  Future<bool> _hasExistingMemoryOn(DateTime day) async {
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final currentMemories = ref.read(memoryControllerProvider).asData?.value;
    if (currentMemories != null) {
      return hasOwnMemoryOnDay(
        currentMemories,
        day,
        currentUserId: currentUserId,
      );
    }

    try {
      final memories = await ref.read(memoryControllerProvider.future);
      return hasOwnMemoryOnDay(memories, day, currentUserId: currentUserId);
    } catch (_) {
      return false;
    }
  }

  int _monthlyMemoryCountAfterSave(List<Memory> previousMemories) {
    final countBefore = previousMemories.where((memory) {
      if (memory.isOfficial) return false;
      return memory.date.year == _selectedDate.year &&
          memory.date.month == _selectedDate.month;
    }).length;
    return countBefore + 1;
  }

  Future<bool> _showMemorySuccessSheet({
    required List<OheyFriend> friends,
    required int monthlyCount,
  }) async {
    final openCalendar = await showOheyBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      barrierColor: AppColors.black.withValues(alpha: .62),
      builder: (_) =>
          _MemorySuccessSheet(friends: friends, monthlyCount: monthlyCount),
    );
    return openCalendar ?? false;
  }
}
