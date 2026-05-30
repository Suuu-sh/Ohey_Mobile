enum OheyFriendRequestStatus { pending, accepted, rejected, cancelled }

OheyFriendRequestStatus oheyFriendRequestStatusFromKey(String? key) {
  return switch (key) {
    'accepted' => OheyFriendRequestStatus.accepted,
    'rejected' => OheyFriendRequestStatus.rejected,
    'cancelled' => OheyFriendRequestStatus.cancelled,
    _ => OheyFriendRequestStatus.pending,
  };
}

extension OheyFriendRequestStatusX on OheyFriendRequestStatus {
  String get key => switch (this) {
    OheyFriendRequestStatus.pending => 'pending',
    OheyFriendRequestStatus.accepted => 'accepted',
    OheyFriendRequestStatus.rejected => 'rejected',
    OheyFriendRequestStatus.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    OheyFriendRequestStatus.pending => '承認待ち',
    OheyFriendRequestStatus.accepted => '承認済み',
    OheyFriendRequestStatus.rejected => '見送り済み',
    OheyFriendRequestStatus.cancelled => '取り消し済み',
  };

  String get actionLabel => switch (this) {
    OheyFriendRequestStatus.pending => 'タップして承認',
    OheyFriendRequestStatus.accepted => label,
    OheyFriendRequestStatus.rejected => label,
    OheyFriendRequestStatus.cancelled => label,
  };

  bool get isPending => this == OheyFriendRequestStatus.pending;
}
