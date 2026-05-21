import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../../core/utils/nomo_photo_orientation.dart';
import '../../camera/presentation/nomo_camera_screen.dart';
import '../application/drink_log_controller.dart';

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
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * .86;
    final isWhite = _AddLogColors.isWhite(context);
    final selectedFriends =
        friendsAsync.asData?.value
            .where((friend) => _selectedFriendIds.contains(friend.id))
            .toList(growable: false) ??
        const <NomoFriend>[];

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardBottom),
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                color: _AddLogColors.panelFor(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _AddLogColors.lineFor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isWhite ? .10 : .24),
                    blurRadius: isWhite ? 24 : 30,
                    offset: Offset(0, isWhite ? 12 : 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onClose: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_hasPhoto) ...[
                            _CapturedPhotoPanel(
                              path: _photoPath!,
                              onRetake: _openNomoCamera,
                            ),
                            const SizedBox(height: 14),
                            _PostPreviewCard(
                              path: _photoPath!,
                              userName: _previewUserName(user?.name),
                              avatar: user?.avatar ?? NomoAvatar.defaultAvatar,
                              memo: _memoController.text,
                              place: _placeController.text,
                              date: _selectedDate,
                              friends: selectedFriends,
                            ),
                            const SizedBox(height: 14),
                          ] else ...[
                            _PhotoCapturePrompt(onTap: _openNomoCamera),
                            const SizedBox(height: 14),
                          ],
                          _DateTimeBox(
                            icon: CupertinoIcons.calendar,
                            iconColor: _AddLogColors.calendarIcon,
                            label: _dateLabel(_selectedDate),
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 14),
                          _InputBox(
                            icon: CupertinoIcons.text_quote,
                            iconColor: _AddLogColors.impressionIcon,
                            hint: 'コメント（任意）',
                            controller: _memoController,
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),
                          _FriendSelectCard(
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
                                  emptyMessage:
                                      _friendSearchQuery.trim().isEmpty
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
                          const SizedBox(height: 14),
                          _InputBox(
                            icon: CupertinoIcons.location_solid,
                            iconColor: _AddLogColors.placeIcon,
                            hint: 'どこで？（任意）',
                            controller: _placeController,
                            maxLines: 1,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SaveButton(
                    label: _hasPhoto ? '飲みログを投稿する' : '写真を撮る',
                    isSaving: _isSaving,
                    onPressed: () => _save(
                      friendsAsync.asData?.value ?? const <NomoFriend>[],
                    ),
                  ),
                ],
              ),
            ),
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

  Future<void> _pickDate() async {
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
    setState(
      () =>
          _selectedDate = DateTime(picked.year, picked.month, picked.day, 0, 0),
    );
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

  static String _dateLabel(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日（${_weekday(date)}）';

  static String _weekday(DateTime date) =>
      const ['月', '火', '水', '木', '金', '土', '日'][date.weekday - 1];
}

String _previewUserName(String? name) {
  final normalized = name?.trim() ?? '';
  return normalized.isEmpty ? 'あなた' : normalized;
}

String _previewCaption({
  required String memo,
  required String place,
  required List<NomoFriend> friends,
}) {
  final body = memo.trim();
  if (body.isNotEmpty) return body;
  final placeName = place.trim();
  if (placeName.isNotEmpty) return '$placeNameで飲みログ';
  if (friends.isNotEmpty) {
    return '${friends.first.name}${friends.length > 1 ? 'たち' : ''}と飲みログ';
  }
  return '今日の飲みログ';
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

class _CapturedPhotoPanel extends StatelessWidget {
  const _CapturedPhotoPanel({required this.path, required this.onRetake});

  final String path;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) => _DarkShell(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '撮った写真',
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
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: _PhotoPreviewImage(
            path: path,
            fallbackAspectRatio: 1,
            fit: BoxFit.cover,
          ),
        ),
      ],
    ),
  );
}

class _PostPreviewCard extends StatelessWidget {
  const _PostPreviewCard({
    required this.path,
    required this.userName,
    required this.avatar,
    required this.memo,
    required this.place,
    required this.date,
    required this.friends,
  });

  final String path;
  final String userName;
  final NomoAvatar avatar;
  final String memo;
  final String place;
  final DateTime date;
  final List<NomoFriend> friends;

  @override
  Widget build(BuildContext context) {
    final caption = _previewCaption(memo: memo, place: place, friends: friends);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '投稿プレビュー',
            style: TextStyle(
              color: _AddLogColors.primaryTextFor(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 330,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: .10),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _PhotoPreviewImage(
                path: path,
                fallbackAspectRatio: 4 / 5,
                fit: BoxFit.cover,
                expand: true,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .42),
                      Colors.transparent,
                      Colors.black.withValues(alpha: .76),
                    ],
                    stops: const [0, .45, 1],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                right: 14,
                child: Row(
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
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '投稿プレビュー',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .72),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const NomoGeneratedIcon(
                      CupertinoIcons.ellipsis,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _PreviewMetaPill(
                          icon: CupertinoIcons.calendar,
                          label: _AddLogScreenState._dateLabel(date),
                        ),
                        if (place.trim().isNotEmpty)
                          _PreviewMetaPill(
                            icon: CupertinoIcons.location_solid,
                            label: place.trim(),
                          ),
                        _PreviewMetaPill(
                          icon: CupertinoIcons.person_2_fill,
                          label: friends.isEmpty
                              ? 'ひとり飲み'
                              : friends.map((friend) => friend.name).join('、'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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

class _PreviewMetaPill extends StatelessWidget {
  const _PreviewMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 250),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .42),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NomoGeneratedIcon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
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
        Text(
          '飲みログ',
          style: TextStyle(
            color: titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onClose,
          icon: NomoGeneratedIcon(
            CupertinoIcons.xmark,
            color: titleColor,
            size: 28,
          ),
        ),
      ],
    );
  }
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
  static const panel = Color(0xFF08131A);
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

  static Color panelFor(BuildContext context) =>
      isWhite(context) ? Colors.white : panel;

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
