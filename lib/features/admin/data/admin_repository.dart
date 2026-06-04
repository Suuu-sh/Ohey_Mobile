import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/ohey_api_paths.dart';
import '../../../core/contracts/ohey_api_values.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/models/ohey_moderation_status.dart';

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
    required String gender,
    required String status,
    required bool isPlus,
  }) async {
    await _client.post(OheyApiPaths.adminUsers, {
      'email': email,
      'password': password,
      'user_id': userId,
      'display_name': displayName,
      'gender': gender,
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

  Future<List<AdminMemory>> listMemorys() async {
    final rows = await _client.getRows(OheyApiPaths.adminMemories);
    return rows.map(AdminMemory.fromJson).toList(growable: false);
  }

  Future<List<AdminMemoryReport>> listMemoryReports({
    String status = OheyStatusKeys.pending,
  }) async {
    final rows = await _client.getRows(
      OheyApiPaths.adminMemoryReports,
      query: {'status': status},
    );
    return rows.map(AdminMemoryReport.fromJson).toList(growable: false);
  }

  Future<void> updateMemoryReport({
    required String id,
    required OheyModerationStatus status,
    String? moderationNote,
  }) async {
    await _client.patch(OheyApiPaths.adminMemoryReport(id), {
      'status': status.key,
      'moderation_note': moderationNote?.trim() ?? '',
    });
  }

  Future<void> createMemory({
    String? ownerUserId,
    required String placeName,
    required String memo,
    required String linkUrl,
    required bool isOfficial,
  }) async {
    final body = <String, dynamic>{
      'happened_at': DateTime.now().toUtc().toIso8601String(),
      'place_name': placeName,
      'memo': memo,
      'link_url': linkUrl,
      'is_official': isOfficial,
    };
    if (ownerUserId != null && ownerUserId.trim().isNotEmpty) {
      body['owner_user_id'] = ownerUserId.trim();
    }
    await _client.post(OheyApiPaths.adminMemories, body);
  }

  Future<void> updateMemory({
    required String id,
    String? ownerUserId,
    required String placeName,
    required String memo,
    required String linkUrl,
    required bool isOfficial,
  }) async {
    final body = <String, dynamic>{
      'place_name': placeName,
      'memo': memo,
      'link_url': linkUrl,
      'is_official': isOfficial,
    };
    if (ownerUserId != null && ownerUserId.trim().isNotEmpty) {
      body['owner_user_id'] = ownerUserId.trim();
    }
    await _client.patch(OheyApiPaths.adminMemory(id), body);
  }

  Future<void> deleteMemory(String id) async {
    await _client.delete(OheyApiPaths.adminMemory(id));
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
    required this.gender,
    required this.status,
    required this.isPlus,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String gender;
  final String status;
  final bool isPlus;
  final DateTime? createdAt;

  factory AdminUserProfile.fromJson(Map<String, dynamic> json) {
    return AdminUserProfile(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Ohey user',
      avatarUrl: json['avatar_url'] as String?,
      gender: json['gender'] as String? ?? 'unspecified',
      status: json['status'] as String? ?? OheyStatusKeys.unselected,
      isPlus: json['is_plus'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class AdminMemory {
  const AdminMemory({
    required this.id,
    required this.ownerUserId,
    required this.ownerDisplayName,
    required this.ownerHandle,
    required this.happenedAt,
    required this.placeName,
    required this.memo,
    required this.linkUrl,
    required this.isOfficial,
  });

  final String id;
  final String ownerUserId;
  final String ownerDisplayName;
  final String ownerHandle;
  final DateTime happenedAt;
  final String placeName;
  final String memo;
  final String linkUrl;
  final bool isOfficial;

  factory AdminMemory.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] is Map
        ? Map<String, dynamic>.from(json['owner'] as Map)
        : const <String, dynamic>{};
    return AdminMemory(
      id: json['id'] as String? ?? '',
      ownerUserId: json['owner_user_id'] as String? ?? '',
      ownerDisplayName: owner['display_name'] as String? ?? 'Ohey user',
      ownerHandle: owner['user_id'] as String? ?? '',
      happenedAt:
          DateTime.tryParse(json['happened_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      placeName: json['place_name'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      linkUrl: json['link_url'] as String? ?? '',
      isOfficial: json['is_official'] as bool? ?? false,
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

class AdminMemoryReport {
  const AdminMemoryReport({
    required this.id,
    required this.memoryId,
    required this.reason,
    required this.status,
    required this.reporterDisplayName,
    required this.reporterHandle,
    required this.ownerDisplayName,
    required this.ownerHandle,
    required this.memo,
    required this.isOfficial,
    this.createdAt,
    this.reviewedAt,
    this.moderationNote,
  });

  final String id;
  final String memoryId;
  final String reason;
  final String status;
  final String reporterDisplayName;
  final String reporterHandle;
  final String ownerDisplayName;
  final String ownerHandle;
  final String memo;
  final bool isOfficial;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? moderationNote;

  factory AdminMemoryReport.fromJson(Map<String, dynamic> json) {
    final memory = json['memory'] is Map
        ? Map<String, dynamic>.from(json['memory'] as Map)
        : const <String, dynamic>{};
    final owner = memory['owner'] is Map
        ? Map<String, dynamic>.from(memory['owner'] as Map)
        : const <String, dynamic>{};
    final reporter = json['reporter'] is Map
        ? Map<String, dynamic>.from(json['reporter'] as Map)
        : const <String, dynamic>{};
    return AdminMemoryReport(
      id: json['id'] as String? ?? '',
      memoryId: json['memory_id'] as String? ?? '',
      reason: json['reason'] as String? ?? OheyReportReasonKeys.other,
      status: json['status'] as String? ?? oheyModerationPendingKey,
      reporterDisplayName: reporter['display_name'] as String? ?? 'Reporter',
      reporterHandle: reporter['user_id'] as String? ?? '',
      ownerDisplayName: owner['display_name'] as String? ?? 'Ohey user',
      ownerHandle: owner['user_id'] as String? ?? '',
      memo: memory['memo'] as String? ?? '',
      isOfficial: memory['is_official'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
      moderationNote: json['moderation_note'] as String?,
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
