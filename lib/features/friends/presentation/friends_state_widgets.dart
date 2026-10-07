part of 'friends_screen.dart';

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 168),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: OheyEmptyState(
              visual: const _FriendsLoadingVisual(),
              title: 'フレンズを読み込み中...',
              message: 'かわいいフレンズたちを呼んでいます',
              titleColor: isWhite ? AppColors.cFF1A272D : AppColors.white,
              messageColor: isWhite
                  ? AppColors.cFF777777
                  : AppColors.white.withValues(alpha: .58),
              padding: EdgeInsets.zero,
              spacing: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 168),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: OheyEmptyState(
              visual: const _FriendsErrorVisual(),
              title: title,
              message: message,
              titleColor: isWhite ? AppColors.cFF1A272D : AppColors.white,
              messageColor: isWhite
                  ? AppColors.cFF777777
                  : AppColors.white.withValues(alpha: .58),
              padding: EdgeInsets.zero,
              spacing: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendsLoadingVisual extends StatelessWidget {
  const _FriendsLoadingVisual();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      width: 156,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _FriendsColors.lime.withValues(alpha: .24),
                  _FriendsColors.lime.withValues(alpha: .06),
                  AppColors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 6,
            child: _LoadingMascotBubble(
              size: 82,
              color: AppColors.cFF3DDCB6,
              borderColor: isWhite ? AppColors.white : _FriendsColors.bg,
              avatar: const OheyAvatar(
                skin: 5,
                hair: 1,
                shirt: 8,
                eyes: 2,
                mouth: 0,
                accessory: 1,
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 18,
            child: _LoadingMascotBubble(
              size: 66,
              color: AppColors.cFFCE82FF,
              borderColor: isWhite ? AppColors.white : _FriendsColors.bg,
              avatar: const OheyAvatar(
                skin: 0,
                hair: 3,
                shirt: 4,
                eyes: 1,
                mouth: 1,
                accessory: 0,
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 14,
            child: CupertinoActivityIndicator(
              radius: 12,
              color: isWhite ? AppColors.cFF1A272D : AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingMascotBubble extends StatelessWidget {
  const _LoadingMascotBubble({
    required this.size,
    required this.color,
    required this.borderColor,
    required this.avatar,
  });

  final double size;
  final Color color;
  final Color borderColor;
  final OheyAvatar avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: borderColor, width: 5),
      ),
      child: ClipOval(
        child: Container(
          color: color,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, size * .08),
            child: OheyAvatarView(
              avatar: avatar,
              size: size * .9,
              showBody: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendsErrorVisual extends StatelessWidget {
  const _FriendsErrorVisual();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      width: 150,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.cFFFF86C8.withValues(alpha: .20),
                  _FriendsColors.lime.withValues(alpha: .07),
                  AppColors.transparent,
                ],
              ),
            ),
          ),
          _LoadingMascotBubble(
            size: 88,
            color: AppColors.cFFFF86C8,
            borderColor: isWhite ? AppColors.white : _FriendsColors.bg,
            avatar: const OheyAvatar(
              skin: 1,
              hair: 4,
              shirt: 6,
              eyes: 1,
              mouth: 2,
              accessory: 0,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cFFFF86C8,
                border: Border.all(
                  color: isWhite ? AppColors.white : _FriendsColors.bg,
                  width: 4,
                ),
              ),
              child: const Center(
                child: OheyGeneratedIcon(
                  CupertinoIcons.exclamationmark,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendStatus {
  const _FriendStatus({
    required this.label,
    required this.enabled,
    required this.reason,
    required this.buttonColor,
  });

  final String label;
  final bool enabled;
  final String reason;
  final Color buttonColor;
}

Color _friendBlockSurfaceColor({required bool isWhite}) =>
    isWhite ? AppColors.white : AppColors.darkBackgroundBottom;

Color _friendBlockFrameColor(_FriendStatus status) =>
    AppColors.chunkyBorderLight;

Color _friendStatusPillColor(_FriendStatus status) => status.buttonColor;

Color _friendInviteButtonColor(_FriendStatus status, {bool isWhite = true}) =>
    status.enabled
    ? _FriendsColors.lime
    : _FriendsColors.disabledButton(isWhite);

Color _friendInviteButtonShadowColor(
  _FriendStatus status, {
  bool isWhite = true,
}) {
  if (!status.enabled) return _FriendsColors.disabledButtonShadow(isWhite);
  return _FriendsColors.limeShadow;
}

Color _friendInviteButtonForegroundColor(
  _FriendStatus status, {
  bool isWhite = true,
}) => status.enabled
    ? _FriendsColors.limeForeground
    : _FriendsColors.disabledButtonForeground(isWhite);

_FriendStatus _statusForFriend(OheyFriend friend, int _) =>
    _friendStatusForDailyStatus(oheyDailyStatusFromKey(friend.statusKey));

_FriendStatus _friendStatusForDailyStatus(OheyDailyStatus status) {
  return _FriendStatus(
    label: status.label,
    enabled: status.isAvailable,
    reason: status.description,
    buttonColor: oheyDailyStatusBlockAccent(status),
  );
}

OheyAvatar _fallbackAvatarForFriend(OheyFriend friend) {
  final hash = friend.id.hashCode.abs();
  return OheyAvatar(
    skin: hash % OheyAvatar.skinColors.length,
    hair: (hash ~/ 3) % OheyAvatar.hairStyles.length,
    shirt: (hash ~/ 5) % OheyAvatar.shirtColors.length,
    eyes: (hash ~/ 7) % OheyAvatar.eyeStyles.length,
    mouth: (hash ~/ 11) % OheyAvatar.mouthStyles.length,
    accessory: (hash ~/ 13) % OheyAvatar.accessoryStyles.length,
  );
}

class _FriendsColors {
  const _FriendsColors._();

  static const bg = AppColors.darkBackgroundBottom;
  static const lime = AppColors.brand;
  static const limeShadow = AppColors.brandLip;
  static const limeForeground = AppColors.white;
  static const muted = AppColors.cFFAFAFAF;
  static Color disabledButton(bool isWhite) =>
      isWhite ? AppColors.cFFE5E5E5 : AppColors.cFF2B3A41;
  static Color disabledButtonShadow(bool isWhite) =>
      isWhite ? AppColors.cFFCDCDCD : AppColors.cFF131F24;
  static Color disabledButtonForeground(bool isWhite) =>
      isWhite ? AppColors.cFFAFAFAF : AppColors.cFF777777;
  static Color invitedButton(bool isWhite) =>
      isWhite ? AppColors.cFFF7F7F7 : AppColors.cFF37464F;
  static Color invitedButtonShadow(bool isWhite) =>
      isWhite ? AppColors.cFFE5E5E5 : AppColors.cFF1A272D;
  static Color invitedButtonForeground(bool isWhite) =>
      isWhite ? AppColors.cFF777777 : AppColors.cFFCDCDCD;
}
