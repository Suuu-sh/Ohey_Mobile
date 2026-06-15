import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/ohey_api_paths.dart';
import '../../../core/contracts/ohey_api_values.dart';
import '../../../core/data/backend_api_client.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(backendApiClientProvider));
});

class AdminRepository {
  const AdminRepository(this._client);

  final BackendApiClient _client;

  Future<void> checkAccess() async {
    await _client.get(OheyApiPaths.adminMe);
  }

  Future<List<AdminUserProfile>> listUsers() async {
    final rows = await _client.getRows(
      OheyApiPaths.adminUsers,
      query: {'date': _todayIsoDate()},
    );
    return rows.map(AdminUserProfile.fromJson).toList(growable: false);
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String userId,
    required String displayName,
    required String status,
    required bool isPlus,
  }) async {
    await _client.post(OheyApiPaths.adminUsers, {
      'email': email,
      'password': password,
      'user_id': userId,
      'display_name': displayName,
      'status': status,
      'status_date': _todayIsoDate(),
      'is_plus': isPlus,
    });
  }

  Future<void> updateUser({
    required String id,
    String? email,
    String? password,
    required String userId,
    required String displayName,
    required String status,
    required bool isPlus,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'display_name': displayName,
      'status': status,
      'status_date': _todayIsoDate(),
      'is_plus': isPlus,
    };
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }
    if (password != null && password.trim().isNotEmpty) {
      body['password'] = password.trim();
    }
    await _client.patch(OheyApiPaths.adminUser(id), body);
  }

  Future<void> deleteUser(String id) async {
    await _client.delete(OheyApiPaths.adminUser(id));
  }

  Future<List<AdminYurubo>> listYurubos({
    String status = OheyStatusKeys.open,
  }) async {
    final rows = await _client.getRows(
      OheyApiPaths.adminYurubos,
      query: {'status': status},
    );
    return rows.map(AdminYurubo.fromJson).toList(growable: false);
  }

  Future<void> createYurubo({
    required String ownerUserId,
    required String title,
    required String body,
    required String placeText,
    required String timeLabel,
    required String startsAt,
    required String status,
    required String visibility,
  }) async {
    final bodyMap = {
      'owner_user_id': ownerUserId,
      'title': title,
      'body': body,
      'category': OheyCategoryKeys.other,
      'place_text': placeText,
      'time_label': timeLabel,
      'starts_at': startsAt,
      'status': status,
      'visibility': visibility,
    };
    await _client.post(OheyApiPaths.adminYurubos, bodyMap);
  }

  Future<void> updateYurubo({
    required String id,
    required String ownerUserId,
    required String title,
    required String body,
    required String placeText,
    required String timeLabel,
    required String startsAt,
    required String status,
    required String visibility,
  }) async {
    final bodyMap = {
      'owner_user_id': ownerUserId,
      'title': title,
      'body': body,
      'place_text': placeText,
      'time_label': timeLabel,
      'starts_at': startsAt,
      'status': status,
      'visibility': visibility,
    };
    await _client.patch(OheyApiPaths.adminYurubo(id), bodyMap);
  }

  Future<void> deleteYurubo(String id) async {
    await _client.delete(OheyApiPaths.adminYurubo(id));
  }

  Future<AdminNotificationResult> createSystemNotification({
    required String title,
    required String message,
    required bool sendToAll,
    required List<String> recipientUserIds,
    String? systemKey,
  }) async {
    final row = await _client.postRow(OheyApiPaths.adminNotifications, {
      'title': title,
      'message': message,
      'send_to_all': sendToAll,
      'recipient_user_ids': recipientUserIds,
      if (systemKey != null && systemKey.trim().isNotEmpty)
        'system_key': systemKey.trim(),
    });
    return AdminNotificationResult.fromJson(row);
  }

  Future<List<AdminNotificationOutboxItem>> listNotificationOutbox({
    String status = OheyStatusKeys.failed,
  }) async {
    final rows = await _client.getRows(
      OheyApiPaths.adminNotificationOutbox,
      query: {'status': status},
    );
    return rows
        .map(AdminNotificationOutboxItem.fromJson)
        .toList(growable: false);
  }

  Future<AdminNotificationOutboxProcessResult> processNotificationOutbox({
    int limit = 50,
  }) async {
    final row = BackendApiClient.mapFrom(
      await _client.postNoBody(
        OheyApiPaths.adminNotificationOutboxProcess,
        query: {'limit': limit.clamp(1, 100).toString()},
      ),
    );
    return AdminNotificationOutboxProcessResult.fromJson(row);
  }
}

String _todayIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

class AdminUserProfile {
  const AdminUserProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.status,
    required this.isPlus,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String status;
  final bool isPlus;
  final DateTime? createdAt;

  factory AdminUserProfile.fromJson(Map<String, dynamic> json) {
    return AdminUserProfile(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Ohey user',
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String? ?? OheyStatusKeys.unselected,
      isPlus: json['is_plus'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class AdminYurubo {
  const AdminYurubo({
    required this.id,
    required this.ownerUserId,
    required this.ownerDisplayName,
    required this.ownerHandle,
    required this.title,
    required this.body,
    required this.category,
    required this.placeText,
    required this.timeLabel,
    required this.status,
    required this.visibility,
    required this.reactionCount,
    this.startsAt,
    this.createdAt,
  });

  final String id;
  final String ownerUserId;
  final String ownerDisplayName;
  final String ownerHandle;
  final String title;
  final String body;
  final String category;
  final String placeText;
  final String timeLabel;
  final String status;
  final String visibility;
  final int reactionCount;
  final DateTime? startsAt;
  final DateTime? createdAt;

  factory AdminYurubo.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] is Map
        ? Map<String, dynamic>.from(json['owner'] as Map)
        : const <String, dynamic>{};
    return AdminYurubo(
      id: json['id'] as String? ?? '',
      ownerUserId: json['owner_user_id'] as String? ?? '',
      ownerDisplayName: owner['display_name'] as String? ?? 'Ohey user',
      ownerHandle: owner['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: json['category'] as String? ?? OheyCategoryKeys.other,
      placeText: json['place_text'] as String? ?? '',
      timeLabel: json['time_label'] as String? ?? '',
      status: json['status'] as String? ?? OheyStatusKeys.open,
      visibility: json['visibility'] as String? ?? OheyVisibilityKeys.friends,
      reactionCount: _intFromJson(json['reaction_count']),
      startsAt: _dateFromJson(json['starts_at']),
      createdAt: _dateFromJson(json['created_at']),
    );
  }
}

class AdminNotificationResult {
  const AdminNotificationResult({
    required this.recipientCount,
    required this.createdCount,
  });

  final int recipientCount;
  final int createdCount;

  factory AdminNotificationResult.fromJson(Map<String, dynamic> json) {
    return AdminNotificationResult(
      recipientCount: (json['recipient_count'] as num?)?.toInt() ?? 0,
      createdCount: (json['created_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminNotificationOutboxItem {
  const AdminNotificationOutboxItem({
    required this.id,
    required this.eventKind,
    required this.aggregateType,
    required this.aggregateId,
    required this.actorUserId,
    required this.recipientUserId,
    required this.status,
    required this.attempts,
    required this.payload,
    this.lastError,
    this.nextAttemptAt,
    this.processedAt,
    this.createdAt,
  });

  final String id;
  final String eventKind;
  final String aggregateType;
  final String aggregateId;
  final String actorUserId;
  final String recipientUserId;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime? nextAttemptAt;
  final DateTime? processedAt;
  final DateTime? createdAt;
  final Map<String, dynamic> payload;

  factory AdminNotificationOutboxItem.fromJson(Map<String, dynamic> json) {
    return AdminNotificationOutboxItem(
      id: json['id'] as String? ?? '',
      eventKind: json['event_kind'] as String? ?? '',
      aggregateType: json['aggregate_type'] as String? ?? '',
      aggregateId: json['aggregate_id'] as String? ?? '',
      actorUserId: json['actor_user_id'] as String? ?? '',
      recipientUserId: json['recipient_user_id'] as String? ?? '',
      status: json['status'] as String? ?? OheyStatusKeys.pending,
      attempts: _intFromJson(json['attempts']),
      lastError: json['last_error'] as String?,
      nextAttemptAt: _dateFromJson(json['next_attempt_at']),
      processedAt: _dateFromJson(json['processed_at']),
      createdAt: _dateFromJson(json['created_at']),
      payload: _mapFromJson(json['payload']),
    );
  }
}

class AdminNotificationOutboxProcessResult {
  const AdminNotificationOutboxProcessResult({
    required this.processedCount,
    required this.failedCount,
    required this.skippedCount,
  });

  final int processedCount;
  final int failedCount;
  final int skippedCount;

  factory AdminNotificationOutboxProcessResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminNotificationOutboxProcessResult(
      processedCount: _intFromJson(json['processed_count']),
      failedCount: _intFromJson(json['failed_count']),
      skippedCount: _intFromJson(json['skipped_count']),
    );
  }
}

int _intFromJson(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _dateFromJson(dynamic value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

Map<String, dynamic> _mapFromJson(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}
