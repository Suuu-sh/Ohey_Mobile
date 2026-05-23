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
      padding: const EdgeInsets.only(bottom: 116),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: NomoEmptyState(
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
      padding: const EdgeInsets.only(bottom: 116),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: NomoEmptyState(
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
              avatar: const NomoAvatar(
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
              avatar: const NomoAvatar(
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
  final NomoAvatar avatar;

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
            child: NomoAvatarView(
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
            avatar: const NomoAvatar(
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
                child: NomoGeneratedIcon(
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
  });

  final String label;
  final bool enabled;
  final String reason;
}

_FriendStatus _statusForFriend(NomoFriend friend, int _) {
  switch (friend.statusKey) {
    case 'can_drink_today':
      return const _FriendStatus(
        label: '今日飲める',
        enabled: true,
        reason: '今夜誘いやすい状態です',
      );
    case 'non_alcohol':
      return const _FriendStatus(
        label: 'ノンアルなら',
        enabled: true,
        reason: 'ノンアル参加なら誘えます',
      );
    case 'liver_rest':
      return const _FriendStatus(
        label: '休肝日',
        enabled: false,
        reason: '今日は飲みを控えたい日です',
      );
    case 'has_plans':
      return const _FriendStatus(
        label: '予定あり',
        enabled: false,
        reason: '今日は予定が入っています',
      );
    case 'unselected' || 'unset' || null || '':
      return const _FriendStatus(
        label: '未設定',
        enabled: true,
        reason: '未設定だけど誘えます',
      );
  }

  return const _FriendStatus(label: '未設定', enabled: true, reason: '未設定だけど誘えます');
}

Color _accentForFriend(NomoFriend friend) {
  return switch (friend.palette) {
    NomiTomoPalette.peach => const Color(0xFFFFB03B),
    NomiTomoPalette.sky => const Color(0xFF18AFFF),
    NomiTomoPalette.lemon => _FriendsColors.lime,
    NomiTomoPalette.lavender => const Color(0xFFA855F7),
    NomiTomoPalette.mint => const Color(0xFF46E68A),
    NomiTomoPalette.blush => const Color(0xFFFF4B9A),
  };
}

NomoAvatar _fallbackAvatarForFriend(NomoFriend friend) {
  final hash = friend.id.hashCode.abs();
  return NomoAvatar(
    skin: hash % NomoAvatar.skinColors.length,
    hair: (hash ~/ 3) % NomoAvatar.hairStyles.length,
    shirt: (hash ~/ 5) % NomoAvatar.shirtColors.length,
    eyes: (hash ~/ 7) % NomoAvatar.eyeStyles.length,
    mouth: (hash ~/ 11) % NomoAvatar.mouthStyles.length,
    accessory: (hash ~/ 13) % NomoAvatar.accessoryStyles.length,
  );
}

class _FriendsColors {
  const _FriendsColors._();

  static const bg = AppColors.darkBackgroundBottom;
  static const block = Color(0xFF101B28);
  static const lime = Color(0xFFB8FF00);
  static const muted = Color(0xFF8792A3);
}
