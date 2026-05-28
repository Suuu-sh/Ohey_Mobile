enum TomoFriendRequestStatus { pending, accepted, rejected, cancelled }

TomoFriendRequestStatus tomoFriendRequestStatusFromKey(String? key) {
  return switch (key) {
    'accepted' => TomoFriendRequestStatus.accepted,
    'rejected' => TomoFriendRequestStatus.rejected,
    'cancelled' => TomoFriendRequestStatus.cancelled,
    _ => TomoFriendRequestStatus.pending,
  };
}

extension TomoFriendRequestStatusX on TomoFriendRequestStatus {
  String get key => switch (this) {
    TomoFriendRequestStatus.pending => 'pending',
    TomoFriendRequestStatus.accepted => 'accepted',
    TomoFriendRequestStatus.rejected => 'rejected',
    TomoFriendRequestStatus.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    TomoFriendRequestStatus.pending => '承認待ち',
    TomoFriendRequestStatus.accepted => '承認済み',
    TomoFriendRequestStatus.rejected => '見送り済み',
    TomoFriendRequestStatus.cancelled => '取り消し済み',
  };

  String get actionLabel => switch (this) {
    TomoFriendRequestStatus.pending => 'タップして承認',
    TomoFriendRequestStatus.accepted => label,
    TomoFriendRequestStatus.rejected => label,
    TomoFriendRequestStatus.cancelled => label,
  };

  bool get isPending => this == TomoFriendRequestStatus.pending;
}
