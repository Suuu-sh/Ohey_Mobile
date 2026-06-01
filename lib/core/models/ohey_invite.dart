import 'ohey_friend.dart';

enum OheyInviteStatus { pending, accepted, rejected, cancelled }

class OheyInvite {
  const OheyInvite({
    required this.id,
    required this.inviterUserId,
    required this.inviteeUserId,
    required this.scheduledDate,
    this.activityLabel,
    required this.status,
    required this.inviter,
    required this.invitee,
  });

  final String id;
  final String inviterUserId;
  final String inviteeUserId;
  final DateTime scheduledDate;
  final String? activityLabel;
  final OheyInviteStatus status;
  final OheyFriend inviter;
  final OheyFriend invitee;

  OheyFriend otherUser(String currentUserId) =>
      inviterUserId == currentUserId ? invitee : inviter;

  String dateLabel({DateTime? now}) {
    final base = now ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final date = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    if (date == today) return '今日';
    return '${date.month}/${date.day}';
  }

  String get cleanActivityLabel => activityLabel?.trim() ?? '';

  String summary({DateTime? now}) {
    final activity = cleanActivityLabel;
    if (activity.isEmpty) return '${dateLabel(now: now)}のお誘い';
    return '${dateLabel(now: now)}に「$activity」';
  }
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
    OheyInviteStatus.pending => '確認する',
    OheyInviteStatus.accepted => label,
    OheyInviteStatus.rejected => label,
    OheyInviteStatus.cancelled => label,
  };

  bool get isPending => this == OheyInviteStatus.pending;
}
