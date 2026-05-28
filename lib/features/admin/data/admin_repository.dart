import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/data/supabase_client_provider.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    ref.watch(backendApiClientProvider),
    ref.watch(supabaseClientProvider),
  );
});

class AdminRepository {
  const AdminRepository(this._client, this._supabase);

  static const _photoBucket = 'nomo-photos';

  final BackendApiClient _client;
  final SupabaseClient _supabase;

  Future<void> checkAccess() async {
    await _client.get('/v1/admin/me');
  }

  Future<List<AdminUserProfile>> listUsers() async {
    final rows = await _client.getRows(
      '/v1/admin/users',
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
    await _client.post('/v1/admin/users', {
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
    await _client.patch('/v1/admin/users/$id', body);
  }

  Future<void> deleteUser(String id) async {
    await _client.delete('/v1/admin/users/$id');
  }

  Future<List<AdminDrinkLog>> listDrinkLogs() async {
    final rows = await _client.getRows('/v1/admin/drink-logs');
    return rows.map(AdminDrinkLog.fromJson).toList(growable: false);
  }

  Future<List<AdminDrinkLogReport>> listDrinkLogReports({
    String status = 'pending',
  }) async {
    final rows = await _client.getRows(
      '/v1/admin/drink-log-reports',
      query: {'status': status},
    );
    return rows.map(AdminDrinkLogReport.fromJson).toList(growable: false);
  }

  Future<void> updateDrinkLogReport({
    required String id,
    required String status,
    String? moderationNote,
  }) async {
    await _client.patch('/v1/admin/drink-log-reports/$id', {
      'status': status,
      'moderation_note': moderationNote?.trim() ?? '',
    });
  }

  Future<String?> displayPhotoUrl(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) return null;
    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('assets/') ||
        normalized.startsWith('/')) {
      return normalized;
    }
    final row = await _client.postRow('/v1/media/display-url', {
      'path': normalized,
    });
    return row['signed_url'] as String?;
  }

  Future<void> createDrinkLog({
    String? ownerUserId,
    required String placeName,
    required String memo,
    required String linkUrl,
    required String photoPath,
    required bool isOfficial,
  }) async {
    final uploadedPhotoPath = await _uploadLocalPhotoIfNeeded(
      photoPath,
      isOfficial: isOfficial,
    );
    final body = <String, dynamic>{
      'drank_at': DateTime.now().toUtc().toIso8601String(),
      'place_name': placeName,
      'memo': memo,
      'link_url': linkUrl,
      'photo_path': uploadedPhotoPath ?? '',
      'is_official': isOfficial,
    };
    if (ownerUserId != null && ownerUserId.trim().isNotEmpty) {
      body['owner_user_id'] = ownerUserId.trim();
    }
    await _client.post('/v1/admin/drink-logs', body);
  }

  Future<void> updateDrinkLog({
    required String id,
    String? ownerUserId,
    required String placeName,
    required String memo,
    required String linkUrl,
    required String photoPath,
    required bool isOfficial,
  }) async {
    final uploadedPhotoPath = await _uploadLocalPhotoIfNeeded(
      photoPath,
      isOfficial: isOfficial,
    );
    final body = <String, dynamic>{
      'place_name': placeName,
      'memo': memo,
      'link_url': linkUrl,
      'photo_path': uploadedPhotoPath ?? '',
      'is_official': isOfficial,
    };
    if (ownerUserId != null && ownerUserId.trim().isNotEmpty) {
      body['owner_user_id'] = ownerUserId.trim();
    }
    await _client.patch('/v1/admin/drink-logs/$id', body);
  }

  Future<String?> _uploadLocalPhotoIfNeeded(
    String? path, {
    required bool isOfficial,
  }) async {
    final normalized = path?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (!normalized.startsWith('/')) return normalized;

    final file = File(normalized);
    if (!await file.exists()) return normalized;

    final userId = _client.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('写真をアップロードするにはログインが必要です。');
    }

    final extension = _safeExtension(normalized);
    final folder = isOfficial ? 'admin/official_posts' : 'admin/drink_logs';
    final storagePath =
        '$folder/$userId/${DateTime.now().toUtc().microsecondsSinceEpoch}$extension';

    await _supabase.storage
        .from(_photoBucket)
        .upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            cacheControl: '3600',
            contentType: _contentTypeForExtension(extension),
            upsert: false,
          ),
        );
    return storagePath;
  }

  String _safeExtension(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '.jpg';
    final extension = name.substring(dot).toLowerCase();
    return switch (extension) {
      '.jpg' || '.jpeg' || '.png' || '.heic' || '.webp' => extension,
      _ => '.jpg',
    };
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      '.png' => 'image/png',
      '.heic' => 'image/heic',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<void> deleteDrinkLog(String id) async {
    await _client.delete('/v1/admin/drink-logs/$id');
  }

  Future<AdminNotificationResult> createSystemNotification({
    required String title,
    required String message,
    required bool sendToAll,
    required List<String> recipientUserIds,
    String? systemKey,
  }) async {
    final row = await _client.postRow('/v1/admin/notifications', {
      'title': title,
      'message': message,
      'send_to_all': sendToAll,
      'recipient_user_ids': recipientUserIds,
      if (systemKey != null && systemKey.trim().isNotEmpty)
        'system_key': systemKey.trim(),
    });
    return AdminNotificationResult.fromJson(row);
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
      displayName: json['display_name'] as String? ?? 'Nomo user',
      avatarUrl: json['avatar_url'] as String?,
      gender: json['gender'] as String? ?? 'unspecified',
      status: json['status'] as String? ?? 'unselected',
      isPlus: json['is_plus'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class AdminDrinkLog {
  const AdminDrinkLog({
    required this.id,
    required this.ownerUserId,
    required this.ownerDisplayName,
    required this.ownerHandle,
    required this.drankAt,
    required this.placeName,
    required this.memo,
    required this.linkUrl,
    required this.photoPath,
    required this.isOfficial,
  });

  final String id;
  final String ownerUserId;
  final String ownerDisplayName;
  final String ownerHandle;
  final DateTime drankAt;
  final String placeName;
  final String memo;
  final String linkUrl;
  final String photoPath;
  final bool isOfficial;

  factory AdminDrinkLog.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] is Map
        ? Map<String, dynamic>.from(json['owner'] as Map)
        : const <String, dynamic>{};
    return AdminDrinkLog(
      id: json['id'] as String? ?? '',
      ownerUserId: json['owner_user_id'] as String? ?? '',
      ownerDisplayName: owner['display_name'] as String? ?? 'Nomo user',
      ownerHandle: owner['user_id'] as String? ?? '',
      drankAt:
          DateTime.tryParse(json['drank_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      placeName: json['place_name'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      linkUrl: json['link_url'] as String? ?? '',
      photoPath: json['photo_path'] as String? ?? '',
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

class AdminDrinkLogReport {
  const AdminDrinkLogReport({
    required this.id,
    required this.drinkLogId,
    required this.reason,
    required this.status,
    required this.reporterDisplayName,
    required this.reporterHandle,
    required this.ownerDisplayName,
    required this.ownerHandle,
    required this.memo,
    required this.photoPath,
    required this.isOfficial,
    this.createdAt,
    this.reviewedAt,
    this.moderationNote,
  });

  final String id;
  final String drinkLogId;
  final String reason;
  final String status;
  final String reporterDisplayName;
  final String reporterHandle;
  final String ownerDisplayName;
  final String ownerHandle;
  final String memo;
  final String photoPath;
  final bool isOfficial;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? moderationNote;

  factory AdminDrinkLogReport.fromJson(Map<String, dynamic> json) {
    final drinkLog = json['drink_log'] is Map
        ? Map<String, dynamic>.from(json['drink_log'] as Map)
        : const <String, dynamic>{};
    final owner = drinkLog['owner'] is Map
        ? Map<String, dynamic>.from(drinkLog['owner'] as Map)
        : const <String, dynamic>{};
    final reporter = json['reporter'] is Map
        ? Map<String, dynamic>.from(json['reporter'] as Map)
        : const <String, dynamic>{};
    return AdminDrinkLogReport(
      id: json['id'] as String? ?? '',
      drinkLogId: json['drink_log_id'] as String? ?? '',
      reason: json['reason'] as String? ?? 'other',
      status: json['status'] as String? ?? 'pending',
      reporterDisplayName: reporter['display_name'] as String? ?? 'Reporter',
      reporterHandle: reporter['user_id'] as String? ?? '',
      ownerDisplayName: owner['display_name'] as String? ?? 'Nomo user',
      ownerHandle: owner['user_id'] as String? ?? '',
      memo: drinkLog['memo'] as String? ?? '',
      photoPath: drinkLog['photo_path'] as String? ?? '',
      isOfficial: drinkLog['is_official'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
      moderationNote: json['moderation_note'] as String?,
    );
  }
}
