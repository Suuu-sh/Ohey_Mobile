part of 'friends_screen.dart';

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.status,
    required this.onFavoriteToggle,
    required this.onInvite,
  });

  final NomoFriend friend;
  final _FriendStatus status;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) => NomoFriendUserBlock(
    friend: friend,
    statusLabel: status.label,
    statusReason: status.reason,
    statusColor: _friendInviteButtonColor(status),
    statusEnabled: status.enabled,
    fallbackAvatar: _fallbackAvatarForFriend(friend),
    showFavorite: true,
    showInvite: true,
    onFavoriteToggle: onFavoriteToggle,
    onInvite: onInvite,
  );
}
