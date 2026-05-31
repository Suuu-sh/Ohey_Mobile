part of 'add_memory_screen.dart';

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.hint,
    required this.controller,
    required this.maxLines,
    this.maxLength,
    this.icon,
    this.iconColor = _AddMemoryColors.lime,
    this.suffix,
    this.borderless = false,
    this.onChanged,
  });

  final IconData? icon;
  final Color iconColor;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final int? maxLength;
  final Widget? suffix;
  final bool borderless;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final primaryText = _AddMemoryColors.primaryTextFor(context);
    final secondaryText = _AddMemoryColors.secondaryTextFor(context);
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
            OheyPopIcon(
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
              maxLength: maxLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                fillColor: AppColors.transparent,
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

  final List<OheyFriend> friends;
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
              color: _AddMemoryColors.mutedTextFor(context),
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

  final OheyFriend friend;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(10, 8, 9, 8),
      decoration: BoxDecoration(
        color: _AddMemoryColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? _AddMemoryColors.friendRemoveIcon
              : _AddMemoryColors.lineFor(context),
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
            child: OheyAvatarView(
              avatar: friend.avatar ?? OheyAvatar.defaultAvatar,
              size: 34,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            friend.name,
            style: TextStyle(
              color: _AddMemoryColors.primaryTextFor(context),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          OheyPopIcon(
            icon: selected ? CupertinoIcons.xmark : CupertinoIcons.plus,
            color: selected
                ? _AddMemoryColors.friendRemoveIcon
                : _AddMemoryColors.friendAddIcon,
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
          OheyPopIcon(
            icon: icon,
            color: iconColor,
            size: 32,
            iconSize: 18,
            shadow: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '日程を決める',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AddMemoryColors.primaryTextFor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AddMemoryColors.secondaryTextFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OheyGeneratedIcon(
            CupertinoIcons.chevron_right,
            color: _AddMemoryColors.secondaryTextFor(context),
            size: 20,
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
        color: _AddMemoryColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AddMemoryColors.lineFor(context)),
        boxShadow: _AddMemoryColors.isWhite(context)
            ? [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: .035),
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
  Widget build(BuildContext context) => Ohey3DButton(
    label: label,
    isLoading: isSaving,
    enabled: onPressed != null,
    onTap: onPressed,
    height: 56,
    radius: 22,
    color: AppColors.primaryAction,
    shadowColor: AppColors.primaryActionShadow,
    fontSize: 15,
    useGradient: false,
  );
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) =>
      OheyStateView.loading(message: '読み込み中...', compact: compact);
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, this.compact = false});

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) =>
      OheyStateView.error(message: message, compact: compact);
}

class _AddMemoryColors {
  const _AddMemoryColors._();

  static const lightText = AppColors.cFF101820;
  static const lightSubText = AppColors.cFF72808D;
  static const lightMuted = AppColors.cFF8A96A3;
  static const lightLine = AppColors.cFFE0E7EF;
  static const surface = AppColors.cFF14212B;
  static const muted = AppColors.cFF99A3AE;
  static const lime = AppColors.cFFB8FF00;
  static const placeIcon = AppColors.cFF7DF1FF;
  static const searchIcon = AppColors.cFFFFD166;
  static const clearIcon = AppColors.cFFFF8AB3;
  static const calendarIcon = AppColors.cFF9F7BFF;
  static const impressionIcon = AppColors.cFFFF8AB3;
  static const friendAddIcon = AppColors.cFF4CD964;
  static const friendRemoveIcon = AppColors.cFFFF5F8F;
  static const line = AppColors.cFF243542;

  static bool isWhite(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static Color pageBackgroundFor(BuildContext context) =>
      isWhite(context) ? AppColors.cFFF7F9FC : AppColors.darkBackgroundBottom;

  static BoxDecoration pageDecorationFor(BuildContext context) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isWhite(context)
          ? const [AppColors.white, AppColors.cFFF7F9FC]
          : AppColors.darkBackgroundGradient,
    ),
  );

  static Color surfaceFor(BuildContext context) =>
      isWhite(context) ? AppColors.white : surface;

  static Color lineFor(BuildContext context) =>
      isWhite(context) ? lightLine : line;

  static Color primaryTextFor(BuildContext context) =>
      isWhite(context) ? lightText : AppColors.white;

  static Color secondaryTextFor(BuildContext context) =>
      isWhite(context) ? lightSubText : AppColors.white.withValues(alpha: .56);

  static Color mutedTextFor(BuildContext context) =>
      isWhite(context) ? lightMuted : muted;
}
