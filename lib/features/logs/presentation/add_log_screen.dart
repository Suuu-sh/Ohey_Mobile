import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../camera/presentation/nomo_camera_screen.dart';
import '../application/drink_log_controller.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key});

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
  String? _photoFilterName;
  bool _isSaving = false;

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
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * .86;

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
                color: _AddLogColors.panel,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _AddLogColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .24),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
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
                            hint: 'コメント（15文字以内）',
                            controller: _memoController,
                            maxLines: 1,
                            showCounter: true,
                            maxLength: 15,
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
                          const SizedBox(height: 14),
                          _PhotoPickerCard(
                            photoPath: _photoPath,
                            filterName: _photoFilterName,
                            onCamera: _openNomoCamera,
                            onGallery: _pickPhotoFromGallery,
                            onRemove: () => setState(() {
                              _photoPath = null;
                              _photoFilterName = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SaveButton(
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

  Future<void> _openNomoCamera() async {
    final result = await Navigator.of(context).push<NomoCameraResult>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NomoCameraScreen(returnPhoto: true),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _photoPath = result.path;
      _photoFilterName = result.filterName;
    });
  }

  Future<void> _pickPhotoFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _photoPath = picked.path;
      _photoFilterName = 'Album';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
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

  Future<String?> _photoPathForSave() async {
    final path = _photoPath;
    if (path == null || path.isEmpty) return null;

    final impression = _memoController.text.trim();
    if (impression.isEmpty) return path;
    return _writeImpressionOnPhoto(path, impression);
  }

  Future<String> _writeImpressionOnPhoto(String path, String impression) async {
    final source = File(path);
    final bytes = await source.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width.toDouble();
    final height = image.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final imageRect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawImageRect(image, imageRect, imageRect, Paint());

    final safePadding = (width * .055).clamp(28.0, 72.0).toDouble();
    final fontSize = (width * .060).clamp(34.0, 70.0).toDouble();
    final textPainter = TextPainter(
      text: TextSpan(
        text: impression,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1.12,
          letterSpacing: -1.0,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: .55),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: width - safePadding * 2);

    final top = safePadding * .62;
    final backgroundHeight = textPainter.height + safePadding * .78;
    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        safePadding * .55,
        top,
        width - safePadding * 1.1,
        backgroundHeight,
      ),
      Radius.circular(safePadding * .45),
    );
    canvas.drawRRect(
      backgroundRect,
      Paint()..color = Colors.black.withValues(alpha: .38),
    );
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        top + (backgroundHeight - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final output = await picture.toImage(image.width, image.height);
    final byteData = await output.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('写真に感想を書き込めませんでした。');
    }

    final outputPath =
        '${source.parent.path}/nomo_impression_${DateTime.now().microsecondsSinceEpoch}.png';
    await File(outputPath).writeAsBytes(byteData.buffer.asUint8List());
    image.dispose();
    output.dispose();
    picture.dispose();
    return outputPath;
  }

  static String _dateLabel(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日（${_weekday(date)}）';

  static String _weekday(DateTime date) =>
      const ['月', '火', '水', '木', '金', '土', '日'][date.weekday - 1];
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text(
        '飲みログ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
        ),
      ),
      const Spacer(),
      IconButton(
        onPressed: onClose,
        icon: const NomoGeneratedIcon(
          CupertinoIcons.xmark,
          color: Colors.white,
          size: 28,
        ),
      ),
    ],
  );
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.hint,
    required this.controller,
    required this.maxLines,
    this.icon,
    this.iconColor = _AddLogColors.lime,
    this.suffix,
    this.showCounter = false,
    this.maxLength = 100,
    this.borderless = false,
    this.onChanged,
  });

  final IconData? icon;
  final Color iconColor;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final Widget? suffix;
  final bool showCounter;
  final int maxLength;
  final bool borderless;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => _DarkShell(
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
            maxLength: showCounter ? maxLength : null,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              counterText: '',
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: .45),
                fontWeight: FontWeight.w800,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (showCounter)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 48),
            child: Text(
              '${controller.text.length}/$maxLength',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .38),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ?suffix,
      ],
    ),
  );
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
              color: _AddLogColors.muted,
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
        color: _AddLogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? _AddLogColors.friendRemoveIcon
              : Colors.white.withValues(alpha: .06),
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
            style: const TextStyle(
              color: Colors.white,
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
                color: Colors.white,
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

class _PhotoPickerCard extends StatelessWidget {
  const _PhotoPickerCard({
    required this.photoPath,
    required this.filterName,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final String? photoPath;
  final String? filterName;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    return _DarkShell(
      padding: const EdgeInsets.all(12),
      child: path == null || path.isEmpty
          ? Row(
              children: [
                Expanded(
                  child: _PhotoActionButton(
                    icon: CupertinoIcons.camera_fill,
                    label: 'カメラ（任意）',
                    subtitle: '感想を画像に重ねられます',
                    color: _AddLogColors.cameraIcon,
                    onTap: onCamera,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PhotoActionButton(
                    icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                    label: '写真を選ぶ',
                    subtitle: '任意・1枚まで',
                    color: _AddLogColors.photoIcon,
                    onTap: onGallery,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(path),
                    width: 82,
                    height: 62,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '写真を追加済み',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        filterName == null
                            ? 'Nomo Photo'
                            : '$filterName filter',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .50),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const NomoGeneratedIcon(
                    CupertinoIcons.xmark_circle_fill,
                    color: _AddLogColors.clearIcon,
                  ),
                ),
              ],
            ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        children: [
          NomoPopIcon(
            icon: icon,
            color: color,
            size: 36,
            iconSize: 20,
            shadow: false,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .42),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ],
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
        color: _AddLogColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AddLogColors.line),
      ),
      child: child,
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Nomo3DButton(
    label: '飲みログを残す',
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
    child: const Center(child: CupertinoActivityIndicator(color: Colors.white)),
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
      style: const TextStyle(
        color: _AddLogColors.muted,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _AddLogColors {
  const _AddLogColors._();

  static const panel = Color(0xFF08131A);
  static const surface = Color(0xFF14212B);
  static const muted = Color(0xFF99A3AE);
  static const lime = Color(0xFFB8FF00);
  static const placeIcon = Color(0xFF7DF1FF);
  static const searchIcon = Color(0xFFFFD166);
  static const clearIcon = Color(0xFFFF8AB3);
  static const calendarIcon = Color(0xFF9F7BFF);
  static const cameraIcon = Color(0xFF35DCC4);
  static const photoIcon = Color(0xFFFFD166);
  static const impressionIcon = Color(0xFFFF8AB3);
  static const friendAddIcon = Color(0xFF4CD964);
  static const friendRemoveIcon = Color(0xFFFF5F8F);
  static const line = Color(0xFF243542);
}
