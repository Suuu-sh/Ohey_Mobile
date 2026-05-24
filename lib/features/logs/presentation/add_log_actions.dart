// ignore_for_file: invalid_use_of_protected_member

part of 'add_log_screen.dart';

extension _AddLogScreenActions on _AddLogScreenState {
  List<NomoFriend> _filteredFriends(List<NomoFriend> friends) {
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

  Future<bool> _openNomoCamera() async {
    final result = await Navigator.of(context).push<NomoCameraResult>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NomoCameraScreen(),
      ),
    );
    if (result == null || !mounted) return false;
    setState(() {
      _photoPath = result.path;
    });
    return true;
  }

  Future<void> _pickDateTime() async {
    final isWhite = _AddLogColors.isWhite(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) => Theme(
        data: (isWhite ? ThemeData.light() : ThemeData.dark()).copyWith(
          colorScheme: isWhite
              ? const ColorScheme.light(
                  primary: _AddLogColors.lime,
                  surface: Colors.white,
                  onSurface: _AddLogColors.lightText,
                )
              : const ColorScheme.dark(
                  primary: _AddLogColors.lime,
                  surface: _AddLogColors.surface,
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
                  primary: _AddLogColors.lime,
                  surface: Colors.white,
                  onSurface: _AddLogColors.lightText,
                )
              : const ColorScheme.dark(
                  primary: _AddLogColors.lime,
                  surface: _AddLogColors.surface,
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
    final selected = await Navigator.of(context).push<NomoPlaceSearchResult>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PlaceSearchScreen(initialQuery: _placeController.text),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _placeController.text = selected.name;
    });
  }

  Future<void> _save(List<NomoFriend> friends) async {
    if (_isSaving) return;
    if (await _hasExistingDrinkLogOn(_selectedDate)) {
      if (!mounted) return;
      await showDrinkLogDailyLimitDialog(context, _selectedDate);
      return;
    }

    setState(() => _isSaving = true);
    final selectedFriends = friends
        .where((friend) => _selectedFriendIds.contains(friend.id))
        .toList(growable: false);
    try {
      final photoPath = await _photoPathForSave();
      final previousLogs =
          ref.read(drinkLogControllerProvider).asData?.value ??
          const <DrinkLog>[];
      await ref
          .read(drinkLogControllerProvider.notifier)
          .addLog(
            date: _selectedDate,
            friends: selectedFriends,
            place: _placeController.text,
            memo: _memoController.text,
            photoAssetPath: photoPath,
          );
      if (!mounted) return;
      setState(() => _isSaving = false);
      final monthlyCount = _monthlyLogCountAfterSave(previousLogs);
      final openCalendar = await _showDrinkLogSuccessSheet(
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
        await showDrinkLogDailyLimitDialog(context, _selectedDate);
        return;
      }
      NomoToast.show(context, '保存できなかったよ。あとでもう一度試してね');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      NomoToast.show(context, '保存できなかったよ。あとでもう一度試してね');
    }
  }

  Future<bool> _hasExistingDrinkLogOn(DateTime day) async {
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final currentLogs = ref.read(drinkLogControllerProvider).asData?.value;
    if (currentLogs != null) {
      return hasOwnDrinkLogOnDay(
        currentLogs,
        day,
        currentUserId: currentUserId,
      );
    }

    try {
      final logs = await ref.read(drinkLogControllerProvider.future);
      return hasOwnDrinkLogOnDay(logs, day, currentUserId: currentUserId);
    } catch (_) {
      return false;
    }
  }

  int _monthlyLogCountAfterSave(List<DrinkLog> previousLogs) {
    final countBefore = previousLogs.where((log) {
      if (log.isOfficial) return false;
      return log.date.year == _selectedDate.year &&
          log.date.month == _selectedDate.month;
    }).length;
    return countBefore + 1;
  }

  Future<bool> _showDrinkLogSuccessSheet({
    required List<NomoFriend> friends,
    required int monthlyCount,
    required bool isPrivateRecord,
  }) async {
    final openCalendar = await showNomoBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (_) => _DrinkLogSuccessSheet(
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
    if (!await nomoIsSquareOrLandscapePhoto(path)) {
      throw StateError('正方形または16:9の横長写真のみ投稿できます。');
    }

    return _copyPhotoToPermanentStorage(path);
  }

  Future<String> _copyPhotoToPermanentStorage(String path) async {
    final source = File(path);
    if (!await source.exists()) return path;
    final directory = await _nomoPhotoDirectory();
    final extension = _fileExtension(path, fallback: '.jpg');
    final outputPath =
        '${directory.path}/nomo_photo_${DateTime.now().microsecondsSinceEpoch}$extension';
    return source.copy(outputPath).then((file) => file.path);
  }

  Future<Directory> _nomoPhotoDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/nomo_photos');
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

  String _addLogDateTimeLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}年${date.month}月${date.day}日（${_addLogWeekday(date)}） $hour:$minute';
  }

  String _addLogWeekday(DateTime date) =>
      const ['月', '火', '水', '木', '金', '土', '日'][date.weekday - 1];
}
