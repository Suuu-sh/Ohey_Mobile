import '../contracts/ohey_api_values.dart';

enum OheyFriendRequestStatus { pending, accepted, rejected, cancelled }

const oheyFriendRequestResponseStatuses = <OheyFriendRequestStatus>[
  OheyFriendRequestStatus.accepted,
  OheyFriendRequestStatus.rejected,
];

OheyFriendRequestStatus oheyFriendRequestStatusFromKey(String? key) {
  return switch (key) {
    OheyStatusKeys.accepted => OheyFriendRequestStatus.accepted,
    OheyStatusKeys.rejected => OheyFriendRequestStatus.rejected,
    OheyStatusKeys.cancelled => OheyFriendRequestStatus.cancelled,
    _ => OheyFriendRequestStatus.pending,
  };
}

extension OheyFriendRequestStatusX on OheyFriendRequestStatus {
  String get key => switch (this) {
    OheyFriendRequestStatus.pending => OheyStatusKeys.pending,
    OheyFriendRequestStatus.accepted => OheyStatusKeys.accepted,
    OheyFriendRequestStatus.rejected => OheyStatusKeys.rejected,
    OheyFriendRequestStatus.cancelled => OheyStatusKeys.cancelled,
  };

  String get label => switch (this) {
    OheyFriendRequestStatus.pending => '承認待ち',
    OheyFriendRequestStatus.accepted => '承認済み',
    OheyFriendRequestStatus.rejected => '見送り済み',
    OheyFriendRequestStatus.cancelled => '取り消し済み',
  };

  String get actionLabel => switch (this) {
    OheyFriendRequestStatus.pending => '確認する',
    OheyFriendRequestStatus.accepted => label,
    OheyFriendRequestStatus.rejected => label,
    OheyFriendRequestStatus.cancelled => label,
  };

  bool get isPending => this == OheyFriendRequestStatus.pending;

  bool get isAccepted => this == OheyFriendRequestStatus.accepted;

  bool get isResponseAction => oheyFriendRequestResponseStatuses.contains(this);

  String get responseToastMessage => switch (this) {
    OheyFriendRequestStatus.accepted => 'フレンズ申請を承認しました',
    OheyFriendRequestStatus.rejected => '申請を見送りました',
    OheyFriendRequestStatus.cancelled => '申請を取り消しました',
    OheyFriendRequestStatus.pending => label,
  };
}
