enum NomoFriendRequestStatus { pending, accepted, rejected, cancelled }

NomoFriendRequestStatus nomoFriendRequestStatusFromKey(String? key) {
  return switch (key) {
    'accepted' => NomoFriendRequestStatus.accepted,
    'rejected' => NomoFriendRequestStatus.rejected,
    'cancelled' => NomoFriendRequestStatus.cancelled,
    _ => NomoFriendRequestStatus.pending,
  };
}

extension NomoFriendRequestStatusX on NomoFriendRequestStatus {
  String get key => switch (this) {
    NomoFriendRequestStatus.pending => 'pending',
    NomoFriendRequestStatus.accepted => 'accepted',
    NomoFriendRequestStatus.rejected => 'rejected',
    NomoFriendRequestStatus.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    NomoFriendRequestStatus.pending => '承認待ち',
    NomoFriendRequestStatus.accepted => '承認済み',
    NomoFriendRequestStatus.rejected => '見送り済み',
    NomoFriendRequestStatus.cancelled => '取り消し済み',
  };

  String get actionLabel => switch (this) {
    NomoFriendRequestStatus.pending => 'タップして承認',
    NomoFriendRequestStatus.accepted => label,
    NomoFriendRequestStatus.rejected => label,
    NomoFriendRequestStatus.cancelled => label,
  };

  bool get isPending => this == NomoFriendRequestStatus.pending;
}
