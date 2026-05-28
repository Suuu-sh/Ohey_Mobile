import 'tomo_friend.dart';

enum TomoInviteStatus { pending, accepted, rejected, cancelled }

class TomoInvite {
  const TomoInvite({
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
  final TomoInviteStatus status;
  final TomoFriend inviter;
  final TomoFriend invitee;

  TomoFriend otherUser(String currentUserId) =>
      inviterUserId == currentUserId ? invitee : inviter;
}

TomoInviteStatus tomoInviteStatusFromKey(String? key) {
  return switch (key) {
    'accepted' => TomoInviteStatus.accepted,
    'rejected' => TomoInviteStatus.rejected,
    'cancelled' => TomoInviteStatus.cancelled,
    _ => TomoInviteStatus.pending,
  };
}

extension TomoInviteStatusX on TomoInviteStatus {
  String get key => switch (this) {
    TomoInviteStatus.pending => 'pending',
    TomoInviteStatus.accepted => 'accepted',
    TomoInviteStatus.rejected => 'rejected',
    TomoInviteStatus.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    TomoInviteStatus.pending => '返信待ち',
    TomoInviteStatus.accepted => '予定あり',
    TomoInviteStatus.rejected => '見送り済み',
    TomoInviteStatus.cancelled => '取り消し済み',
  };

  String get actionLabel => switch (this) {
    TomoInviteStatus.pending => 'タップして返信',
    TomoInviteStatus.accepted => label,
    TomoInviteStatus.rejected => label,
    TomoInviteStatus.cancelled => label,
  };

  bool get isPending => this == TomoInviteStatus.pending;
}
