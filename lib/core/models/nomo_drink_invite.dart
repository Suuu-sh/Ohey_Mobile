import 'nomo_friend.dart';

enum NomoDrinkInviteStatus { pending, accepted, rejected, cancelled }

class NomoDrinkInvite {
  const NomoDrinkInvite({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.inviteDate,
    required this.status,
    required this.fromUser,
    required this.toUser,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final DateTime inviteDate;
  final NomoDrinkInviteStatus status;
  final NomoFriend fromUser;
  final NomoFriend toUser;

  NomoFriend otherUser(String currentUserId) =>
      fromUserId == currentUserId ? toUser : fromUser;
}

NomoDrinkInviteStatus nomoDrinkInviteStatusFromKey(String? key) {
  return switch (key) {
    'accepted' => NomoDrinkInviteStatus.accepted,
    'rejected' => NomoDrinkInviteStatus.rejected,
    'cancelled' => NomoDrinkInviteStatus.cancelled,
    _ => NomoDrinkInviteStatus.pending,
  };
}

extension NomoDrinkInviteStatusX on NomoDrinkInviteStatus {
  String get key => switch (this) {
    NomoDrinkInviteStatus.pending => 'pending',
    NomoDrinkInviteStatus.accepted => 'accepted',
    NomoDrinkInviteStatus.rejected => 'rejected',
    NomoDrinkInviteStatus.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    NomoDrinkInviteStatus.pending => '返信待ち',
    NomoDrinkInviteStatus.accepted => '予定あり',
    NomoDrinkInviteStatus.rejected => '見送り済み',
    NomoDrinkInviteStatus.cancelled => '取り消し済み',
  };

  String get actionLabel => switch (this) {
    NomoDrinkInviteStatus.pending => 'タップして返信',
    NomoDrinkInviteStatus.accepted => label,
    NomoDrinkInviteStatus.rejected => label,
    NomoDrinkInviteStatus.cancelled => label,
  };

  bool get isPending => this == NomoDrinkInviteStatus.pending;
}
