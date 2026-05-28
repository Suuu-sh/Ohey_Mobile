import 'nomo_friend.dart';

enum NomoInviteStatus { pending, accepted, rejected, cancelled }

class NomoInvite {
  const NomoInvite({
    required this.id,
    required this.inviterUserId,
    required this.inviteeUserId,
    required this.scheduledDate,
    required this.status,
    required this.inviter,
    required this.invitee,
  });

  final String id;
  final String inviterUserId;
  final String inviteeUserId;
  final DateTime scheduledDate;
  final NomoInviteStatus status;
  final NomoFriend inviter;
  final NomoFriend invitee;

  NomoFriend otherUser(String currentUserId) =>
      inviterUserId == currentUserId ? invitee : inviter;
}

NomoInviteStatus nomoInviteStatusFromKey(String? key) {
  return switch (key) {
    'accepted' => NomoInviteStatus.accepted,
    'rejected' => NomoInviteStatus.rejected,
    'cancelled' => NomoInviteStatus.cancelled,
    _ => NomoInviteStatus.pending,
  };
}

extension NomoInviteStatusX on NomoInviteStatus {
  String get key => switch (this) {
    NomoInviteStatus.pending => 'pending',
    NomoInviteStatus.accepted => 'accepted',
    NomoInviteStatus.rejected => 'rejected',
    NomoInviteStatus.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    NomoInviteStatus.pending => '返信待ち',
    NomoInviteStatus.accepted => '予定あり',
    NomoInviteStatus.rejected => '見送り済み',
    NomoInviteStatus.cancelled => '取り消し済み',
  };

  String get actionLabel => switch (this) {
    NomoInviteStatus.pending => 'タップして返信',
    NomoInviteStatus.accepted => label,
    NomoInviteStatus.rejected => label,
    NomoInviteStatus.cancelled => label,
  };

  bool get isPending => this == NomoInviteStatus.pending;
}
