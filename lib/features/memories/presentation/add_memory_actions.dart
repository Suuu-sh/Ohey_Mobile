// ignore_for_file: invalid_use_of_protected_member

part of 'add_memory_screen.dart';

extension _AddMemoryScreenActions on _AddMemoryScreenState {
  List<TomoFriend> _filteredFriends(List<TomoFriend> friends) {
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

  bool get _hasPhoto => _photoPath != null && _photoPath!.trim().isNotEmpty;

  Future<bool> _openTomoCamera() async {
    final result = await Navigator.of(context).push<TomoCameraResult>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const TomoCameraScreen(),
      ),
    );
    if (result == null || !mounted) return false;
    setState(() {
      _photoPath = result.path;
    });
    return true;
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
                  surface: Colors.white,
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
    if (picked == null) return;
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) => Theme(
        data: (isWhite ? ThemeData.light() : ThemeData.dark()).copyWith(
          colorScheme: isWhite
              ? const ColorScheme.light(
                  primary: _AddMemoryColors.lime,
                  surface: Colors.white,
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
    final selected = await Navigator.of(context).push<TomoPlaceSearchResult>(
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

  Future<void> _save(List<TomoFriend> friends) async {
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
      final photoPath = await _photoPathForSave();
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
            captionY: _captionY,
            photoAssetPath: photoPath,
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
        isPrivateRecord: photoPath == null,
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
      TomoToast.show(context, '保存できなかったよ。あとでもう一度試してね');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      TomoToast.show(context, '保存できなかったよ。あとでもう一度試してね');
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
    required List<TomoFriend> friends,
    required int monthlyCount,
    required bool isPrivateRecord,
  }) async {
    final openCalendar = await showTomoBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (_) => _MemorySuccessSheet(
        friends: friends,
        monthlyCount: monthlyCount,
        isPrivateRecord: isPrivateRecord,
      ),
    );
    return openCalendar ?? false;
  }

  Future<String?> _photoPathForSave() async {
    final path = _photoPath;
    if (path == null || path.isEmpty) return null;
    if (!await tomoIsSquareOrLandscapePhoto(path)) {
      throw StateError('正方形または16:9の横長写真のみ投稿できます。');
    }

    return _copyPhotoToPermanentStorage(path);
  }

  Future<String> _copyPhotoToPermanentStorage(String path) async {
    final source = File(path);
    if (!await source.exists()) return path;
    final directory = await _tomoPhotoDirectory();
    final extension = _fileExtension(path, fallback: '.jpg');
    final outputPath =
        '${directory.path}/tomo_photo_${DateTime.now().microsecondsSinceEpoch}$extension';
    return source.copy(outputPath).then((file) => file.path);
  }

  Future<Directory> _tomoPhotoDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/tomo_photos');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _fileExtension(String path, {required String fallback}) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return fallback;
    final extension = name.substring(dot).toLowerCase();
    if (extension.length > 8) return fallback;
    return extension;
  }

  String _addMemoryDateTimeLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}年${date.month}月${date.day}日（${_addMemoryWeekday(date)}） $hour:$minute';
  }

  String _addMemoryWeekday(DateTime date) =>
      const ['月', '火', '水', '木', '金', '土', '日'][date.weekday - 1];
}
