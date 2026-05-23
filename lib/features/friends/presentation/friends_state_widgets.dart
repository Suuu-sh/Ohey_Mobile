part of 'friends_screen.dart';

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(color: Colors.white),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .64),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontWeight: FontWeight.w700,
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
