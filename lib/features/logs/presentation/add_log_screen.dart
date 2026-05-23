import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
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
    final isWhite = _AddLogColors.isWhite(context);
    final surfaceColor = isWhite ? Colors.white : AppColors.darkBackground;
    final borderColor = isWhite
        ? const Color(0xFFE3EAF3)
        : Colors.white.withValues(alpha: .08);
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
            color: surfaceColor,
            border: Border.symmetric(
              horizontal: BorderSide(color: borderColor, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isWhite ? .08 : .18),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _PreviewAuthorBar(
                userName: userName,
                avatar: avatar,
                isWhite: isWhite,
                metadata: _previewMetadata(date: date, place: place),
                onEditDateTime: onEditDateTime,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: borderColor, width: .8),
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _PhotoPreviewImage(
                          path: path,
                          fallbackAspectRatio: 1,
                          fit: BoxFit.cover,
                          expand: true,
                        ),
                        _PreviewPhotoCaptionEditor(
                          controller: memoController,
                          hint: _previewCaptionHint(place: place),
                          onChanged: onMemoChanged,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _PreviewFooter(friends: friends, isWhite: isWhite),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewAuthorBar extends StatelessWidget {
  const _PreviewAuthorBar({
    required this.userName,
    required this.avatar,
    required this.isWhite,
    required this.metadata,
    required this.onEditDateTime,
  });

  final String userName;
  final NomoAvatar avatar;
  final bool isWhite;
  final String metadata;
  final VoidCallback onEditDateTime;

  @override
  Widget build(BuildContext context) {
    final primaryText = isWhite ? const Color(0xFF17202B) : Colors.white;
    final secondaryText = isWhite
        ? const Color(0xFF778393)
        : Colors.white.withValues(alpha: .62);
    final iconColor = isWhite
        ? const Color(0xFF1E2733)
        : Colors.white.withValues(alpha: .92);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _AddLogColors.lime.withValues(alpha: .34),
                  _AddLogColors.lime.withValues(alpha: .09),
                ],
              ),
            ),
            child: NomoAvatarView(avatar: avatar, size: 38.5),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: primaryText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -.25,
                  ),
                ),
                const SizedBox(height: 3),
                _PreviewTimeEditor(
                  label: metadata,
                  color: secondaryText,
                  onTap: onEditDateTime,
                ),
              ],
            ),
          ),
          NomoGeneratedIcon(
            CupertinoIcons.ellipsis,
            color: iconColor,
            size: 27,
          ),
        ],
      ),
    );
  }
}

class _PreviewTimeEditor extends StatelessWidget {
  const _PreviewTimeEditor({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.pencil, size: 10, color: color),
          ],
        ),
      ),
    ),
  );
}

class _PreviewPhotoCaptionEditor extends StatelessWidget {
  const _PreviewPhotoCaptionEditor({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final lineTop = constraints.maxHeight * .52;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: lineTop,
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .78),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .44),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              top: math.max(14.0, lineTop - 55),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 2,
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
                  hintStyle: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(
                        color: Colors.white.withValues(alpha: .76),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.04,
                        letterSpacing: -.7,
                        shadows: const [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.04,
                  letterSpacing: -.7,
                  shadows: const [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PreviewFooter extends StatelessWidget {
  const _PreviewFooter({required this.friends, required this.isWhite});

  final List<NomoFriend> friends;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final primaryText = isWhite ? const Color(0xFF17202B) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (friends.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerRight,
              child: _PreviewFriendsPill(friends: friends, isWhite: isWhite),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PreviewFooterAction(
                          icon: CupertinoIcons.heart,
                          color: primaryText,
                        ),
                        const SizedBox(width: 18),
                        _PreviewFooterAction(
                          customIcon: _PreviewShareIcon(
                            color: primaryText,
                            size: 27,
                          ),
                          color: primaryText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '0件のいいね',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewFooterAction extends StatelessWidget {
  const _PreviewFooterAction({this.icon, this.customIcon, required this.color});

  final IconData? icon;
  final Widget? customIcon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child:
        customIcon ??
        NomoPopIcon(
          icon: icon ?? CupertinoIcons.circle,
          color: color,
          size: 29,
          showBubble: false,
        ),
  );
}

class _PreviewShareIcon extends StatelessWidget {
  const _PreviewShareIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _PreviewShareIconPainter(color)),
  );
}

class _PreviewShareIconPainter extends CustomPainter {
  const _PreviewShareIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * .105;

    final tray = Path()
      ..moveTo(w * .22, h * .62)
      ..lineTo(w * .22, h * .76)
      ..quadraticBezierTo(w * .22, h * .86, w * .32, h * .86)
      ..lineTo(w * .68, h * .86)
      ..quadraticBezierTo(w * .78, h * .86, w * .78, h * .76)
      ..lineTo(w * .78, h * .62);
    canvas.drawPath(tray, stroke);

    canvas.drawLine(Offset(w * .50, h * .66), Offset(w * .50, h * .16), stroke);
    canvas.drawLine(Offset(w * .34, h * .31), Offset(w * .50, h * .16), stroke);
    canvas.drawLine(Offset(w * .66, h * .31), Offset(w * .50, h * .16), stroke);
  }

  @override
  bool shouldRepaint(covariant _PreviewShareIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PreviewFriendsPill extends StatelessWidget {
  const _PreviewFriendsPill({required this.friends, required this.isWhite});

  final List<NomoFriend> friends;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final textColor = isWhite ? const Color(0xFF344152) : Colors.white;
    final borderColor = isWhite
        ? const Color(0xFFE0E7EF)
        : Colors.white.withValues(alpha: .13);
    final backgroundColor = isWhite
        ? const Color(0xFFF4F7FA)
        : Colors.white.withValues(alpha: .07);
    final label = friends.length == 1
        ? '${friends.first.name}と一緒'
        : '${friends.first.name}ほか${friends.length - 1}人と一緒';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 182),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PreviewFriendAvatarStack(friends: friends),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewFriendAvatarStack extends StatelessWidget {
  const _PreviewFriendAvatarStack({required this.friends});

  final List<NomoFriend> friends;

  @override
  Widget build(BuildContext context) {
    final visible = friends.take(3).toList(growable: false);
    return SizedBox(
      width: 24.0 + (visible.length - 1) * 15.0,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * 15,
              child: Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(1.4),
                decoration: BoxDecoration(
                  color: visible[index].accentColor.withValues(alpha: .34),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .78),
                    width: 1,
                  ),
                ),
                child: NomoAvatarView(
                  avatar: visible[index].avatar ?? NomoAvatar.defaultAvatar,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _previewMetadata({required DateTime date, required String place}) {
  final trimmedPlace = place.trim();
  final time = _previewFeedTime(date);
  return trimmedPlace.isEmpty ? time : '$time ・ $trimmedPlace';
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
