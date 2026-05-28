import 'ohey_friend.dart';

enum OheyInviteStatus { pending, accepted, rejected, cancelled }

class OheyInvite {
  const OheyInvite({
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
  final OheyInviteStatus status;
  final OheyFriend inviter;
  final OheyFriend invitee;

  OheyFriend otherUser(String currentUserId) =>
      inviterUserId == currentUserId ? invitee : inviter;
}

OheyInviteStatus oheyInviteStatusFromKey(String? key) {
  return switch (key) {
    'accepted' => OheyInviteStatus.accepted,
    'rejected' => OheyInviteStatus.rejected,
    'cancelled' => OheyInviteStatus.cancelled,
    _ => OheyInviteStatus.pending,
  };
}

extension OheyInviteStatusX on OheyInviteStatus {
  String get key => switch (this) {
    OheyInviteStatus.pending => 'pending',
    OheyInviteStatus.accepted => 'accepted',
    OheyInviteStatus.rejected => 'rejected',
    OheyInviteStatus.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    OheyInviteStatus.pending => '返信待ち',
    OheyInviteStatus.accepted => '予定あり',
    OheyInviteStatus.rejected => '見送り済み',
    OheyInviteStatus.cancelled => '取り消し済み',
  };

  String get actionLabel => switch (this) {
    OheyInviteStatus.pending => 'タップして返信',
    OheyInviteStatus.accepted => label,
    OheyInviteStatus.rejected => label,
    OheyInviteStatus.cancelled => label,
  };

  bool get isPending => this == OheyInviteStatus.pending;
}
