part of 'add_log_screen.dart';

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
                  '写真を追加（任意）',
                  style: TextStyle(
                    color: _AddLogColors.primaryTextFor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '写真なしでも保存できます。撮る場合はこちら',
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
    required this.friendEditor,
    required this.placeEditor,
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
  final Widget friendEditor;
  final Widget placeEditor;
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
              _PreviewInlineEditors(
                friendEditor: friendEditor,
                placeEditor: placeEditor,
                isWhite: isWhite,
              ),
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
    const bandHeight = 52.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final top = constraints.maxHeight > bandHeight
            ? (constraints.maxHeight - bandHeight) / 2
            : 0.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: top,
              height: bandHeight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                color: Colors.black.withValues(alpha: .46),
                alignment: Alignment.center,
                child: TextField(
                  controller: controller,
                  maxLength: _drinkLogCommentMaxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  onChanged: onChanged,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: _AddLogColors.lime,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                    hintText: hint,
                    hintStyle: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(
                          color: Colors.white.withValues(alpha: .76),
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: -.65,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                  ),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -.65,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
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
              if (friends.isNotEmpty) ...[
                const SizedBox(width: 10),
                _PreviewFriendsPill(friends: friends, isWhite: isWhite),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewInlineEditors extends StatelessWidget {
  const _PreviewInlineEditors({
    required this.friendEditor,
    required this.placeEditor,
    required this.isWhite,
  });

  final Widget friendEditor;
  final Widget placeEditor;
  final bool isWhite;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: isWhite
              ? const Color(0xFFE3EAF3)
              : Colors.white.withValues(alpha: .08),
          width: .8,
        ),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [friendEditor, const SizedBox(height: 10), placeEditor],
      ),
    ),
  );
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

class _DrinkLogSuccessSheet extends StatefulWidget {
  const _DrinkLogSuccessSheet({
    required this.friends,
    required this.monthlyCount,
    required this.isPrivateRecord,
  });

  final List<NomoFriend> friends;
  final int monthlyCount;
  final bool isPrivateRecord;

  @override
  State<_DrinkLogSuccessSheet> createState() => _DrinkLogSuccessSheetState();
}

class _DrinkLogSuccessSheetState extends State<_DrinkLogSuccessSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _friendSummary {
    if (widget.isPrivateRecord) {
      if (widget.friends.isEmpty) return 'フィードには投稿せず、カレンダーで確認できます';
      final first = widget.friends.first.name;
      final others = widget.friends.length - 1;
      if (others <= 0) return '$firstとの記録はカレンダーで確認できます';
      return '$firstほか$others人との記録はカレンダーで確認できます';
    }
    if (widget.friends.isEmpty) return '自分だけの思い出に追加しました';
    final first = widget.friends.first.name;
    final others = widget.friends.length - 1;
    if (others <= 0) return '$firstとの思い出に追加しました';
    return '$firstほか$others人との思い出に追加しました';
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final background = isWhite ? Colors.white : const Color(0xFF071320);
    final ink = isWhite ? const Color(0xFF17212B) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF667381)
        : Colors.white.withValues(alpha: .64);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: isWhite
                ? const Color(0xFFDCE4EC)
                : Colors.white.withValues(alpha: .12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAction.withValues(alpha: .20),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale =
                    .78 + Curves.elasticOut.transform(_controller.value) * .22;
                return Transform.scale(scale: scale, child: child);
              },
              child: NomoPopIcon(
                icon: CupertinoIcons.checkmark_alt,
                color: widget.isPrivateRecord
                    ? AppColors.success
                    : AppColors.primaryAction,
                size: 70,
                iconSize: 38,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.isPrivateRecord ? '記録しました！' : '飲みログを残しました！',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isPrivateRecord
                  ? 'カレンダーに追加しました'
                  : '今月${widget.monthlyCount}回目の飲みログです',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.isPrivateRecord
                    ? AppColors.success
                    : AppColors.primaryAction,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _friendSummary,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: sub,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Nomo3DButton.secondary(
                    label: '閉じる',
                    onTap: () => Navigator.of(context).pop(false),
                    height: 48,
                    radius: 22,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Nomo3DButton(
                    label: widget.isPrivateRecord ? 'カレンダーへ' : 'フィードへ',
                    icon: widget.isPrivateRecord
                        ? CupertinoIcons.calendar_today
                        : CupertinoIcons.house_fill,
                    onTap: () =>
                        Navigator.of(context).pop(widget.isPrivateRecord),
                    height: 48,
                    radius: 22,
                    color: widget.isPrivateRecord
                        ? AppColors.success
                        : AppColors.primaryAction,
                    shadowColor: widget.isPrivateRecord
                        ? AppColors.successShadow
                        : AppColors.primaryActionShadow,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
