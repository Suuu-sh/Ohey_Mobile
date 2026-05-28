import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return BackendNotificationRepository(ref.watch(backendApiClientProvider));
});

class TomoNotification {
  const TomoNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isUnread,
    this.actorUserId,
    this.memoryId,
    this.friendRequestId,
    this.friendRequestStatus,
    this.inviteId,
    this.inviteStatus,
    this.notificationDate,
    this.systemKey,
  });

  final String id;
  final String kind;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isUnread;
  final String? actorUserId;
  final String? memoryId;
  final String? friendRequestId;
  final String? friendRequestStatus;
  final String? inviteId;
  final String? inviteStatus;
  final DateTime? notificationDate;
  final String? systemKey;

  String get displayTitle => _tomolaNotificationText(title);
  String get displayMessage => _tomolaNotificationText(message);

  TomoNotification markRead() => TomoNotification(
    id: id,
    kind: kind,
    title: title,
    message: message,
    createdAt: createdAt,
    isUnread: false,
    actorUserId: actorUserId,
    memoryId: memoryId,
    friendRequestId: friendRequestId,
    friendRequestStatus: friendRequestStatus,
    inviteId: inviteId,
    inviteStatus: inviteStatus,
    notificationDate: notificationDate,
    systemKey: systemKey,
  );

  factory TomoNotification.fromJson(Map<String, dynamic> json) {
    final createdAtText = json['created_at'] as String?;
    final friendRequest = json['friend_request'];
    final friendRequestMap = friendRequest is Map
        ? Map<String, dynamic>.from(friendRequest)
        : null;
    final invite = json['invite'];
    final inviteMap = invite is Map ? Map<String, dynamic>.from(invite) : null;
    return TomoNotification(
      id: json['id'] as String,
      kind: (json['kind'] as String?) ?? 'memory_like',
      title: (json['title'] as String?) ?? 'お知らせ',
      message: (json['message'] as String?) ?? '',
      createdAt: createdAtText == null
          ? DateTime.now()
          : DateTime.parse(createdAtText).toLocal(),
      isUnread: json['read_at'] == null,
      actorUserId: json['actor_user_id'] as String?,
      memoryId: json['memory_id'] as String?,
      friendRequestId: json['friend_request_id'] as String?,
      friendRequestStatus: friendRequestMap?['status'] as String?,
      inviteId: json['invite_id'] as String?,
      inviteStatus: inviteMap?['status'] as String?,
      notificationDate: _dateOnly(json['notification_date'] as String?),
      systemKey: json['system_key'] as String?,
    );
  }
}

abstract interface class NotificationRepository {
  Future<List<TomoNotification>> fetchNotifications();
  Future<void> markAllRead();
  Future<void> updateFriendRequest({
    required String friendRequestId,
    required String status,
  });
  Future<void> updateInvite({required String inviteId, required String status});
}

class BackendNotificationRepository implements NotificationRepository {
  const BackendNotificationRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<List<TomoNotification>> fetchNotifications() async {
    final rows = await _client.getRows(
      '/v1/notifications',
      query: {'date': _todayIsoDate()},
    );
    return rows.map(TomoNotification.fromJson).toList(growable: false);
  }

  @override
  Future<void> markAllRead() async {
    await _client.patch('/v1/notifications/read-all', const {});
  }

  @override
  Future<void> updateFriendRequest({
    required String friendRequestId,
    required String status,
  }) async {
    await _client.patch('/v1/friend-requests/$friendRequestId', {
      'status': status,
    });
  }

  @override
  Future<void> updateInvite({
    required String inviteId,
    required String status,
  }) async {
    await _client.patch('/v1/invites/$inviteId', {'status': status});
  }
}

DateTime? _dateOnly(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String _todayIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

String _tomolaNotificationText(String value) {
  return value
      .replaceAll('飲みログ', '思い出')
      .replaceAll('飲みとも', 'フレンズ')
      .replaceAll('飲み友', 'フレンズ')
      .replaceAll('飲み会', '集まり')
      .replaceAll('今日遊べる', '今日遊べる')
      .replaceAll('休肝日', 'おやすみ')
      .replaceAll('ノンアル', '軽め')
      .replaceAll('今日会わない？', '今日会わない？')
      .replaceAll('お誘い', 'お誘い')
      .replaceAll('乾杯', '思い出');
}
