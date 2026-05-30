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
              titleColor: isWhite ? const Color(0xFF1B2633) : Colors.white,
              messageColor: isWhite
                  ? const Color(0xFF6D7784)
                  : Colors.white.withValues(alpha: .58),
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
              titleColor: isWhite ? const Color(0xFF1B2633) : Colors.white,
              messageColor: isWhite
                  ? const Color(0xFF6D7784)
                  : Colors.white.withValues(alpha: .58),
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
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 6,
            child: _LoadingMascotBubble(
              size: 82,
              color: const Color(0xFF34E1C3),
              borderColor: isWhite ? Colors.white : _FriendsColors.bg,
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
              color: const Color(0xFF7C5CFF),
              borderColor: isWhite ? Colors.white : _FriendsColors.bg,
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
              color: isWhite ? const Color(0xFF1B2633) : Colors.white,
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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                  const Color(0xFFFF6B8A).withValues(alpha: .20),
                  _FriendsColors.lime.withValues(alpha: .07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          _LoadingMascotBubble(
            size: 88,
            color: const Color(0xFFFF8AB1),
            borderColor: isWhite ? Colors.white : _FriendsColors.bg,
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
                color: const Color(0xFFFF6B8A),
                border: Border.all(
                  color: isWhite ? Colors.white : _FriendsColors.bg,
                  width: 4,
                ),
              ),
              child: const Center(
                child: OheyGeneratedIcon(
                  CupertinoIcons.exclamationmark,
                  color: Colors.white,
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
    isWhite ? Colors.white : AppColors.darkBackgroundBottom;

Color _friendBlockFrameColor(_FriendStatus status) =>
    _friendInviteButtonColor(status);

Color _friendStatusPillColor(_FriendStatus status) =>
    _friendInviteButtonColor(status);

Color _friendInviteButtonColor(_FriendStatus status) {
  if (!status.enabled) return _FriendsColors.disabledButton;
  if (status.buttonColor == _FriendsColors.statusGreen) {
    return _FriendsColors.lime;
  }
  return status.buttonColor;
}

Color _friendInviteButtonShadowColor(_FriendStatus status) {
  if (!status.enabled) return _FriendsColors.disabledButtonShadow;
  final color = _friendInviteButtonColor(status);
  if (color == _FriendsColors.lime) return _FriendsColors.limeShadow;
  return Color.lerp(color, Colors.black, .32)!;
}

Color _friendInviteButtonForegroundColor(_FriendStatus status) => status.enabled
    ? _FriendsColors.limeForeground
    : _FriendsColors.disabledButtonForeground;

double _friendInviteCardGlowAlpha({
  required bool isWhite,
  required _FriendStatus status,
}) {
  if (!status.enabled) return isWhite ? .03 : .05;
  return isWhite ? .075 : .15;
}

double _friendBlockBorderAlpha({
  required bool isWhite,
  required _FriendStatus status,
}) {
  if (!status.enabled) return isWhite ? .20 : .24;
  return isWhite ? .34 : .42;
}

_FriendStatus _statusForFriend(OheyFriend friend, int _) =>
    _friendStatusForDailyStatus(oheyDailyStatusFromKey(friend.statusKey));

_FriendStatus _friendStatusForDailyStatus(OheyDailyStatus status) {
  return _FriendStatus(
    label: status.label,
    enabled: status.isAvailable,
    reason: status.description,
    buttonColor: switch (status) {
      OheyDailyStatus.available => _FriendsColors.statusPink,
      OheyDailyStatus.maybeAvailable => _FriendsColors.statusBlue,
      OheyDailyStatus.dependsOnTime => _FriendsColors.statusPurple,
      OheyDailyStatus.hasPlans => _FriendsColors.statusBlocked,
      OheyDailyStatus.unselected => _FriendsColors.statusGreen,
    },
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
  static const lime = Color(0xFFB8FF00);
  static const limeShadow = Color(0xFF6FB600);
  static const limeForeground = Color(0xFF071320);
  static const muted = Color(0xFF8792A3);
  static const statusPink = Color(0xFFFF5EA8);
  static const statusBlue = Color(0xFF20B9FF);
  static const statusPurple = Color(0xFF8A62FF);
  static const statusGreen = Color(0xFF9AF21A);
  static const statusBlocked = Color(0xFF2B3644);
  static const disabledButton = Color(0xFF2B3441);
  static const disabledButtonShadow = Color(0xFF111923);
  static const disabledButtonForeground = Color(0xFF738092);
  static const invitedButton = Color(0xFF3C4652);
  static const invitedButtonShadow = Color(0xFF1A222C);
  static const invitedButtonForeground = Color(0xFFC3CAD3);
}
