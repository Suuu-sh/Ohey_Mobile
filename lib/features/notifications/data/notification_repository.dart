import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return BackendNotificationRepository(ref.watch(backendApiClientProvider));
});

class NomoNotification {
  const NomoNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isUnread,
    this.actorUserId,
    this.drinkLogId,
  });

  final String id;
  final String kind;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isUnread;
  final String? actorUserId;
  final String? drinkLogId;

  factory NomoNotification.fromJson(Map<String, dynamic> json) {
    final createdAtText = json['created_at'] as String?;
    return NomoNotification(
      id: json['id'] as String,
      kind: (json['kind'] as String?) ?? 'drink_log_like',
      title: (json['title'] as String?) ?? 'お知らせ',
      message: (json['message'] as String?) ?? '',
      createdAt: createdAtText == null
          ? DateTime.now()
          : DateTime.parse(createdAtText).toLocal(),
      isUnread: json['read_at'] == null,
      actorUserId: json['actor_user_id'] as String?,
      drinkLogId: json['drink_log_id'] as String?,
    );
  }
}

abstract interface class NotificationRepository {
  Future<List<NomoNotification>> fetchNotifications();
  Future<void> markAllRead();
}

class BackendNotificationRepository implements NotificationRepository {
  const BackendNotificationRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<List<NomoNotification>> fetchNotifications() async {
    final response = await _client.get('/v1/notifications');
    final rows = (response as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    return rows.map(NomoNotification.fromJson).toList(growable: false);
  }

  @override
  Future<void> markAllRead() async {
    await _client.patch('/v1/notifications/read-all', const {});
  }
}
