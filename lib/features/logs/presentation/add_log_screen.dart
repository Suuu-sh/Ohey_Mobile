import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../../core/utils/nomo_photo_orientation.dart';
import '../../camera/presentation/nomo_camera_screen.dart';
import '../application/drink_log_controller.dart';
import '../data/nomo_place_search_service.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key, this.initialPhotoPath});

  final String? initialPhotoPath;

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedFriendIds = {};
  final _placeController = TextEditingController();
  final _memoController = TextEditingController();
  final _friendSearchController = TextEditingController();
  String _friendSearchQuery = '';
  String? _photoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;
  }

  @override
  void dispose() {
    _placeController.dispose();
    _memoController.dispose();
    _friendSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final user = ref.watch(nomoUserProvider);
    final selectedFriends =
        friendsAsync.asData?.value
            .where((friend) => _selectedFriendIds.contains(friend.id))
            .toList(growable: false) ??
        const <NomoFriend>[];

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
                        place: _placeController.text,
                        date: _selectedDate,
                        friends: selectedFriends,
                        onEditDateTime: _pickDateTime,
                        onMemoChanged: (_) => setState(() {}),
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
                        child: _DateTimeBox(
                          icon: CupertinoIcons.calendar,
                          iconColor: _AddLogColors.calendarIcon,
                          label: _dateTimeLabel(_selectedDate),
                          onTap: _pickDateTime,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _InputBox(
                          icon: CupertinoIcons.text_quote,
                          iconColor: _AddLogColors.impressionIcon,
                          hint: 'コメント（任意）',
                          controller: _memoController,
                          maxLines: 3,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _FriendSelectCard(
                        search: _InputBox(
                          icon: CupertinoIcons.search,
                          iconColor: _AddLogColors.searchIcon,
                          hint: '誰と？（任意）',
                          controller: _friendSearchController,
                          maxLines: 1,
                          borderless: true,
                          onChanged: (value) =>
                              setState(() => _friendSearchQuery = value),
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
                            error: (error, stackTrace) => const _ErrorBox(
                              message: '友達を読み込めませんでした',
                              compact: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _InputBox(
                        icon: CupertinoIcons.location_solid,
                        iconColor: _AddLogColors.placeIcon,
                        hint: 'どこで？（任意）',
                        controller: _placeController,
                        maxLines: 1,
                        onChanged: (_) => setState(() {}),
                        suffix: _PlaceSearchButton(onTap: _openPlaceSearch),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: _SaveButton(
                    label: _hasPhoto ? '飲みログを投稿する' : '写真を撮る',
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
        builder: (_) => const NomoCameraScreen(returnPhoto: true),
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
    if (!_hasPhoto) {
      final hasCapturedPhoto = await _openNomoCamera();
      if (hasCapturedPhoto && mounted) {
        NomoToast.show(context, '投稿プレビューを確認してください');
      }
      return;
    }
    setState(() => _isSaving = true);
    final selectedFriends = friends
        .where((friend) => _selectedFriendIds.contains(friend.id))
        .toList(growable: false);
    try {
      final photoPath = await _photoPathForSave();
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
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      NomoToast.show(context, '飲みログを保存できませんでした: $error');
    }
  }

  Future<String> _photoPathForSave() async {
    final path = _photoPath;
    if (path == null || path.isEmpty) {
      throw StateError('写真を追加してください。');
    }
    if (!await nomoIsSquareOrLandscapePhoto(path)) {
      throw StateError('正方形または横長の写真のみ投稿できます。');
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

  static String _dateTimeLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}年${date.month}月${date.day}日（${_weekday(date)}） $hour:$minute';
  }

  static String _weekday(DateTime date) =>
      const ['月', '火', '水', '木', '金', '土', '日'][date.weekday - 1];
}

String _previewUserName(String? name) {
  final normalized = name?.trim() ?? '';
  return normalized.isEmpty ? 'あなた' : normalized;
}

String _previewCaptionHint({required String place}) {
  final placeName = place.trim();
  if (placeName.isNotEmpty) return placeName;
  return 'コメントを入力';
}

class _PhotoCapturePrompt extends StatelessWidget {
  const _PhotoCapturePrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: _DarkShell(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Row(
        children: [
          const NomoPopIcon(
            icon: CupertinoIcons.camera_fill,
            color: _AddLogColors.lime,
            size: 38,
            iconSize: 22,
            shadow: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '写真を追加',
                  style: TextStyle(
                    color: _AddLogColors.primaryTextFor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '撮影後に投稿プレビューを確認できます',
                  style: TextStyle(
                    color: _AddLogColors.secondaryTextFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          NomoGeneratedIcon(
            CupertinoIcons.chevron_right,
            color: _AddLogColors.secondaryTextFor(context),
            size: 22,
          ),
        ],
      ),
    ),
  );
}

class _PostPreviewCard extends StatelessWidget {
  const _PostPreviewCard({
    required this.path,
    required this.userName,
    required this.avatar,
    required this.memoController,
    required this.place,
    required this.date,
    required this.friends,
    required this.onEditDateTime,
    required this.onMemoChanged,
    required this.onRetake,
  });

  final String path;
  final String userName;
  final NomoAvatar avatar;
  final TextEditingController memoController;
  final String place;
  final DateTime date;
  final List<NomoFriend> friends;
  final VoidCallback onEditDateTime;
  final ValueChanged<String> onMemoChanged;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final captionHint = _previewCaptionHint(place: place);
    final isWhite = _AddLogColors.isWhite(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text(
                '投稿プレビュー',
                style: TextStyle(
                  color: _AddLogColors.primaryTextFor(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _MiniActionButton(
                icon: CupertinoIcons.camera_rotate_fill,
                label: '撮り直す',
                onTap: onRetake,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isWhite ? .12 : .36),
                blurRadius: 26,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PhotoPreviewImage(
                  path: path,
                  fallbackAspectRatio: 4 / 5,
                  fit: BoxFit.cover,
                  expand: true,
                ),
                const _FeedSizedPreviewScrim(),
                Positioned(
                  left: 14,
                  top: 14,
                  right: 14,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _AddLogColors.lime.withValues(alpha: .28),
                          shape: BoxShape.circle,
                        ),
                        child: NomoAvatarView(avatar: avatar, size: 40),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                                letterSpacing: -.25,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            _PreviewTimeEditor(
                              label: _previewFeedTime(date),
                              onTap: onEditDateTime,
                            ),
                          ],
                        ),
                      ),
                      NomoGeneratedIcon(
                        CupertinoIcons.ellipsis,
                        color: Colors.white.withValues(alpha: .96),
                        size: 28,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PreviewCaptionField(
                        controller: memoController,
                        hint: captionHint,
                        onChanged: onMemoChanged,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (friends.isNotEmpty)
                            _PreviewFriendsPill(friends: friends),
                          const Spacer(),
                          const _PreviewOverlayAction(
                            icon: CupertinoIcons.heart,
                            label: '0',
                          ),
                          const SizedBox(width: 13),
                          const _PreviewOverlayAction(
                            icon: CupertinoIcons.paperplane,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedSizedPreviewScrim extends StatelessWidget {
  const _FeedSizedPreviewScrim();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xB2000000),
          Color(0x1A000000),
          Color(0x00000000),
          Color(0xE6000000),
        ],
        stops: [0, .23, .50, 1],
      ),
    ),
  );
}

class _PreviewTimeEditor extends StatelessWidget {
  const _PreviewTimeEditor({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '日時を編集',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, right: 10, bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .78),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                height: 1,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.pencil,
              size: 10,
              color: Colors.white.withValues(alpha: .74),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PreviewCaptionField extends StatelessWidget {
  const _PreviewCaptionField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.newline,
    minLines: 1,
    maxLines: 3,
    cursorColor: _AddLogColors.lime,
    decoration: InputDecoration(
      isDense: true,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      fillColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: .72),
        fontSize: 21,
        fontWeight: FontWeight.w900,
        height: 1.12,
        letterSpacing: -.55,
        shadows: const [
          Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
    ),
    style: const TextStyle(
      color: Colors.white,
      fontSize: 21,
      fontWeight: FontWeight.w900,
      height: 1.12,
      letterSpacing: -.55,
      shadows: [
        Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 3)),
      ],
    ),
  );
}

class _PreviewOverlayAction extends StatelessWidget {
  const _PreviewOverlayAction({required this.icon, this.label = ''});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      NomoPopIcon(icon: icon, color: Colors.white, size: 26, showBubble: false),
      if (label.isNotEmpty) ...[
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _PreviewFriendsPill extends StatelessWidget {
  const _PreviewFriendsPill({required this.friends});

  final List<NomoFriend> friends;

  @override
  Widget build(BuildContext context) {
    final visible = friends.take(3).toList(growable: false);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28.0 + (visible.length - 1) * 18.0,
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var index = 0; index < visible.length; index++)
                  Positioned(
                    left: index * 18,
                    child: Container(
                      width: 28,
                      height: 28,
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: visible[index].accentColor.withValues(
                          alpha: .34,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .82),
                          width: 1,
                        ),
                      ),
                      child: NomoAvatarView(
                        avatar:
                            visible[index].avatar ?? NomoAvatar.defaultAvatar,
                        size: 28,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'with',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .92),
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _previewFeedTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
  if (diff.inHours < 24) return '${diff.inHours}時間前';
  return '${diff.inDays}日前';
}

class _PhotoPreviewImage extends StatelessWidget {
  const _PhotoPreviewImage({
    required this.path,
    required this.fallbackAspectRatio,
    required this.fit,
    this.expand = false,
  });

  final String path;
  final double fallbackAspectRatio;
  final BoxFit fit;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final image = Image.file(
      File(path),
      width: double.infinity,
      height: expand ? double.infinity : null,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) =>
          _PhotoMissingPlaceholder(expand: expand),
    );
    if (expand) return image;

    return FutureBuilder<NomoPhotoDimensions>(
      future: nomoReadPhotoDimensions(path),
      builder: (context, snapshot) {
        final dimensions = snapshot.data;
        final aspectRatio = dimensions == null
            ? fallbackAspectRatio
            : _safePhotoAspectRatio(dimensions);
        return AspectRatio(aspectRatio: aspectRatio, child: image);
      },
    );
  }
}

double _safePhotoAspectRatio(NomoPhotoDimensions dimensions) {
  if (dimensions.height <= 0 || dimensions.width <= 0) return 1;
  final aspectRatio = dimensions.width / dimensions.height;
  if (aspectRatio < 1) return 1;
  if (aspectRatio > 1.8) return 1.8;
  return aspectRatio;
}

class _PhotoMissingPlaceholder extends StatelessWidget {
  const _PhotoMissingPlaceholder({required this.expand});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .24)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NomoGeneratedIcon(
              CupertinoIcons.photo,
              color: _AddLogColors.secondaryTextFor(context),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              '写真を表示できません',
              style: TextStyle(
                color: _AddLogColors.secondaryTextFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
    if (expand) return SizedBox.expand(child: child);
    return AspectRatio(aspectRatio: 1, child: child);
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _AddLogColors.lime.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _AddLogColors.lime.withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NomoGeneratedIcon(icon, color: _AddLogColors.lime, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _AddLogColors.lime,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final titleColor = _AddLogColors.primaryTextFor(context);
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _AddLogColors.surfaceFor(context),
              shape: BoxShape.circle,
              border: Border.all(color: _AddLogColors.lineFor(context)),
            ),
            child: Center(
              child: NomoGeneratedIcon(
                CupertinoIcons.chevron_left,
                color: titleColor,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '飲みログ作成',
          style: TextStyle(
            color: titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _PlaceSearchButton extends StatelessWidget {
  const _PlaceSearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _AddLogColors.placeIcon.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _AddLogColors.placeIcon.withValues(alpha: .30),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NomoGeneratedIcon(
            CupertinoIcons.location_fill,
            color: _AddLogColors.placeIcon,
            size: 14,
          ),
          SizedBox(width: 5),
          Text(
            '探す',
            style: TextStyle(
              color: _AddLogColors.placeIcon,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlaceSearchScreen extends StatefulWidget {
  const _PlaceSearchScreen({required this.initialQuery});

  final String initialQuery;

  @override
  State<_PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<_PlaceSearchScreen> {
  final _service = const NomoPlaceSearchService();
  late final TextEditingController _queryController;
  Timer? _debounce;
  List<NomoPlaceSearchResult> _places = const [];
  String? _errorMessage;
  bool _isLoading = false;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery.trim());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search(_queryController.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _scheduleSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), () => _search(query));
  }

  Future<void> _search(String query) async {
    final generation = ++_searchGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final places = await _service.searchNearby(query: query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _places = const [];
        _isLoading = false;
        _errorMessage = _placeSearchErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: _PlaceSearchHeader(
                  onClose: () => Navigator.of(context).maybePop(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _PlaceSearchInput(
                  controller: _queryController,
                  isLoading: _isLoading,
                  onChanged: _scheduleSearch,
                  onSubmitted: _search,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _PlaceSearchQuickChips(
                  onSelected: (query) {
                    _queryController.text = query;
                    _queryController.selection = TextSelection.collapsed(
                      offset: query.length,
                    );
                    _search(query);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _places.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_errorMessage != null) {
      return _PlaceSearchMessage(
        icon: CupertinoIcons.location_slash_fill,
        title: 'お店を検索できませんでした',
        message: _errorMessage!,
        actionLabel: 'もう一度探す',
        onAction: () => _search(_queryController.text),
      );
    }
    if (_places.isEmpty) {
      return const _PlaceSearchMessage(
        icon: CupertinoIcons.map_fill,
        title: '近くのお店が見つかりません',
        message: '店名や「居酒屋」「バー」などで検索してみてください。',
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      itemCount: _places.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _PlaceSearchTile(
        place: _places[index],
        onTap: () => Navigator.of(context).pop(_places[index]),
      ),
    );
  }
}

class _PlaceSearchHeader extends StatelessWidget {
  const _PlaceSearchHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final titleColor = _AddLogColors.primaryTextFor(context);
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _AddLogColors.surfaceFor(context),
              shape: BoxShape.circle,
              border: Border.all(color: _AddLogColors.lineFor(context)),
            ),
            child: Center(
              child: NomoGeneratedIcon(
                CupertinoIcons.chevron_left,
                color: titleColor,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '場所を検索',
          style: TextStyle(
            color: titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
      ],
    );
  }
}

class _PlaceSearchInput extends StatelessWidget {
  const _PlaceSearchInput({
    required this.controller,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => _DarkShell(
    padding: const EdgeInsets.fromLTRB(15, 12, 12, 12),
    child: Row(
      children: [
        const NomoPopIcon(
          icon: CupertinoIcons.search,
          color: _AddLogColors.placeIcon,
          size: 32,
          iconSize: 18,
          shadow: false,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              counterText: '',
              hintText: '店名・居酒屋・バーなど',
              hintStyle: TextStyle(
                color: _AddLogColors.secondaryTextFor(context),
                fontWeight: FontWeight.w800,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              color: _AddLogColors.primaryTextFor(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (isLoading)
          const CupertinoActivityIndicator(radius: 10)
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSubmitted(controller.text),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: NomoGeneratedIcon(
                CupertinoIcons.arrow_clockwise,
                color: _AddLogColors.placeIcon,
                size: 20,
              ),
            ),
          ),
      ],
    ),
  );
}

class _PlaceSearchQuickChips extends StatelessWidget {
  const _PlaceSearchQuickChips({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const queries = ['居酒屋', 'バー', '焼き鳥', 'レストラン'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final query in queries) ...[
            GestureDetector(
              onTap: () => onSelected(query),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _AddLogColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _AddLogColors.lineFor(context)),
                ),
                child: Text(
                  query,
                  style: TextStyle(
                    color: _AddLogColors.primaryTextFor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PlaceSearchTile extends StatelessWidget {
  const _PlaceSearchTile({required this.place, required this.onTap});

  final NomoPlaceSearchResult place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (place.subtitle.isNotEmpty) place.subtitle,
      _formatPlaceDistance(place.distanceMeters),
    ];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _DarkShell(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        child: Row(
          children: [
            const NomoPopIcon(
              icon: CupertinoIcons.location_solid,
              color: _AddLogColors.placeIcon,
              size: 40,
              iconSize: 22,
              shadow: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _AddLogColors.primaryTextFor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleParts.join(' ・ '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _AddLogColors.secondaryTextFor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            NomoGeneratedIcon(
              CupertinoIcons.chevron_right,
              color: _AddLogColors.secondaryTextFor(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceSearchMessage extends StatelessWidget {
  const _PlaceSearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 44, 28, 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NomoPopIcon(
          icon: icon,
          color: _AddLogColors.placeIcon,
          size: 62,
          iconSize: 34,
          shadow: false,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _AddLogColors.primaryTextFor(context),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _AddLogColors.secondaryTextFor(context),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.45,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _AddLogColors.placeIcon.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _AddLogColors.placeIcon.withValues(alpha: .30),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: _AddLogColors.placeIcon,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

String _formatPlaceDistance(double meters) {
  if (meters <= 0) return '現在地周辺';
  if (meters < 1000) return '${meters.round()}m';
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)}km';
}

String _placeSearchErrorMessage(Object error) {
  if (error is PlatformException) {
    return switch (error.code) {
      'permission_denied' => '位置情報の利用が許可されていません。設定アプリでNomoの位置情報を許可してください。',
      'location_unavailable' => '現在地を取得できませんでした。少し移動するか、時間をおいてもう一度試してください。',
      'not_available' => 'この端末では現在地からのお店検索を利用できません。',
      _ => error.message ?? '位置情報からお店を検索できませんでした。',
    };
  }
  return '位置情報からお店を検索できませんでした。';
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.hint,
    required this.controller,
    required this.maxLines,
    this.icon,
    this.iconColor = _AddLogColors.lime,
    this.suffix,
    this.borderless = false,
    this.onChanged,
  });

  final IconData? icon;
  final Color iconColor;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final Widget? suffix;
  final bool borderless;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final primaryText = _AddLogColors.primaryTextFor(context);
    final secondaryText = _AddLogColors.secondaryTextFor(context);
    return _DarkShell(
      borderless: borderless,
      padding: EdgeInsets.symmetric(
        horizontal: borderless ? 0 : 16,
        vertical: borderless ? 0 : 13,
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            NomoPopIcon(
              icon: icon!,
              color: iconColor,
              size: 34,
              iconSize: 19,
              shadow: false,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                fillColor: Colors.transparent,
                counterText: '',
                hintText: hint,
                hintStyle: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w800,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ?suffix,
        ],
      ),
    );
  }
}

class _FriendSelectCard extends StatelessWidget {
  const _FriendSelectCard({required this.search, required this.chips});

  final Widget search;
  final Widget chips;

  @override
  Widget build(BuildContext context) => _DarkShell(
    padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
    child: Column(children: [search, const SizedBox(height: 14), chips]),
  );
}

class _FriendChips extends StatelessWidget {
  const _FriendChips({
    required this.friends,
    required this.selectedIds,
    required this.onChanged,
    required this.emptyMessage,
  });

  final List<NomoFriend> friends;
  final Set<String> selectedIds;
  final ValueChanged<String> onChanged;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return _DarkShell(
        child: Center(
          child: Text(
            emptyMessage,
            style: TextStyle(
              color: _AddLogColors.mutedTextFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final friend in friends) ...[
            _FriendChip(
              friend: friend,
              selected: selectedIds.contains(friend.id),
              onTap: () => onChanged(friend.id),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _FriendChip extends StatelessWidget {
  const _FriendChip({
    required this.friend,
    required this.selected,
    required this.onTap,
  });

  final NomoFriend friend;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(10, 8, 9, 8),
      decoration: BoxDecoration(
        color: _AddLogColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? _AddLogColors.friendRemoveIcon
              : _AddLogColors.lineFor(context),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: friend.accentColor.withValues(alpha: .24),
              shape: BoxShape.circle,
            ),
            child: NomoAvatarView(
              avatar: friend.avatar ?? NomoAvatar.defaultAvatar,
              size: 34,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            friend.name,
            style: TextStyle(
              color: _AddLogColors.primaryTextFor(context),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          NomoPopIcon(
            icon: selected ? CupertinoIcons.xmark : CupertinoIcons.plus,
            color: selected
                ? _AddLogColors.friendRemoveIcon
                : _AddLogColors.friendAddIcon,
            size: 26,
            iconSize: 15,
            shadow: false,
          ),
        ],
      ),
    ),
  );
}

class _DateTimeBox extends StatelessWidget {
  const _DateTimeBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: _DarkShell(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      child: Row(
        children: [
          NomoPopIcon(
            icon: icon,
            color: iconColor,
            size: 32,
            iconSize: 18,
            shadow: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _AddLogColors.primaryTextFor(context),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DarkShell extends StatelessWidget {
  const _DarkShell({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    this.borderless = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool borderless;

  @override
  Widget build(BuildContext context) {
    if (borderless) return Padding(padding: padding, child: child);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _AddLogColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AddLogColors.lineFor(context)),
        boxShadow: _AddLogColors.isWhite(context)
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .035),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.isSaving,
    required this.onPressed,
  });

  final String label;
  final bool isSaving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Nomo3DButton(
    label: label,
    isLoading: isSaving,
    enabled: onPressed != null,
    onTap: onPressed,
    height: 56,
    radius: 22,
    color: const Color(0xFF35DCC4),
    shadowColor: const Color(0xFF35DCC4),
    fontSize: 15,
    useGradient: false,
  );
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => _DarkShell(
    padding: EdgeInsets.all(compact ? 10 : 16),
    child: Center(
      child: CupertinoActivityIndicator(
        color: _AddLogColors.primaryTextFor(context),
      ),
    ),
  );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, this.compact = false});

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) => _DarkShell(
    padding: EdgeInsets.all(compact ? 10 : 16),
    child: Text(
      message,
      style: TextStyle(
        color: _AddLogColors.mutedTextFor(context),
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _AddLogColors {
  const _AddLogColors._();

  static const lightText = Color(0xFF101820);
  static const lightSubText = Color(0xFF72808D);
  static const lightMuted = Color(0xFF8A96A3);
  static const lightLine = Color(0xFFE0E7EF);
  static const surface = Color(0xFF14212B);
  static const muted = Color(0xFF99A3AE);
  static const lime = Color(0xFFB8FF00);
  static const placeIcon = Color(0xFF7DF1FF);
  static const searchIcon = Color(0xFFFFD166);
  static const clearIcon = Color(0xFFFF8AB3);
  static const calendarIcon = Color(0xFF9F7BFF);
  static const impressionIcon = Color(0xFFFF8AB3);
  static const friendAddIcon = Color(0xFF4CD964);
  static const friendRemoveIcon = Color(0xFFFF5F8F);
  static const line = Color(0xFF243542);

  static bool isWhite(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static Color pageBackgroundFor(BuildContext context) => isWhite(context)
      ? const Color(0xFFF7F9FC)
      : AppColors.darkBackgroundBottom;

  static BoxDecoration pageDecorationFor(BuildContext context) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isWhite(context)
          ? const [Colors.white, Color(0xFFF7F9FC)]
          : AppColors.darkBackgroundGradient,
    ),
  );

  static Color surfaceFor(BuildContext context) =>
      isWhite(context) ? Colors.white : surface;

  static Color lineFor(BuildContext context) =>
      isWhite(context) ? lightLine : line;

  static Color primaryTextFor(BuildContext context) =>
      isWhite(context) ? lightText : Colors.white;

  static Color secondaryTextFor(BuildContext context) =>
      isWhite(context) ? lightSubText : Colors.white.withValues(alpha: .56);

  static Color mutedTextFor(BuildContext context) =>
      isWhite(context) ? lightMuted : muted;
}
