import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';

final adminControllerProvider = Provider<AdminController>((ref) {
  return AdminController(ref.watch(backendApiClientProvider));
});

final adminAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    await ref.watch(adminControllerProvider).checkAccess();
    return true;
  } on BackendApiException catch (error) {
    if (error.statusCode == 403) {
      return false;
    }
    rethrow;
  }
});

final adminUsersProvider = FutureProvider.autoDispose<List<AdminUserProfile>>((
  ref,
) async {
  return ref.watch(adminControllerProvider).listUsers();
});

final adminDrinkLogsProvider = FutureProvider.autoDispose<List<AdminDrinkLog>>((
  ref,
) async {
  return ref.watch(adminControllerProvider).listDrinkLogs();
});

class AdminController {
  const AdminController(this._client);

  final BackendApiClient _client;

  Future<void> checkAccess() async {
    await _client.get('/v1/admin/me');
  }

  Future<List<AdminUserProfile>> listUsers() async {
    final data = await _client.get('/v1/admin/users');
    return (data as List<dynamic>)
        .map(
          (item) => AdminUserProfile.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String userId,
    required String displayName,
    required bool isPlus,
  }) async {
    await _client.post('/v1/admin/users', {
      'email': email,
      'password': password,
      'user_id': userId,
      'display_name': displayName,
      'is_plus': isPlus,
    });
  }

  Future<void> updateUser({
    required String id,
    String? email,
    String? password,
    required String userId,
    required String displayName,
    required bool isPlus,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'display_name': displayName,
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
    final data = await _client.get('/v1/admin/drink-logs');
    return (data as List<dynamic>)
        .map((item) => AdminDrinkLog.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<void> createDrinkLog({
    String? ownerUserId,
    required String placeName,
    required String memo,
    required String linkUrl,
    required bool isOfficial,
  }) async {
    final body = <String, dynamic>{
      'drank_at': DateTime.now().toUtc().toIso8601String(),
      'place_name': placeName,
      'memo': memo,
      'link_url': linkUrl,
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
    await _client.patch('/v1/admin/drink-logs/$id', body);
  }

  Future<void> deleteDrinkLog(String id) async {
    await _client.delete('/v1/admin/drink-logs/$id');
  }
}

class AdminUserProfile {
  const AdminUserProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.isPlus,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final bool isPlus;
  final DateTime? createdAt;

  factory AdminUserProfile.fromJson(Map<String, dynamic> json) {
    return AdminUserProfile(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Nomo user',
      avatarUrl: json['avatar_url'] as String?,
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
      isOfficial: json['is_official'] as bool? ?? false,
    );
  }
}
