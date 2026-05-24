import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nomo_avatar.dart';
import '../models/nomo_gender.dart';
import '../models/nomo_user.dart';
import 'backend_api_client.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(backendApiClientProvider));
});

class UserRepository {
  const UserRepository(this._client);

  final BackendApiClient _client;

  String? get currentUserId => _client.currentUserId;

  Future<NomoUser?> fetchCurrentUserProfile() async {
    final authUserId = currentUserId;
    if (authUserId == null || authUserId.isEmpty) return null;

    Map<String, dynamic> row;
    try {
      row = await _client.getRow('/v1/me/profile');
    } on BackendApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }

    final statusRows = await _client.getRows(
      '/v1/daily-status',
      query: {'date': _todayIsoDate()},
    );
    final statusRow = statusRows.isEmpty ? null : statusRows.first;

    return _userFromProfileRow(row, authUserId, statusRow: statusRow);
  }

  Future<String?> latestDisplayName(String? fallback) async {
    final authUserId = currentUserId;
    if (authUserId == null || authUserId.isEmpty) return fallback;

    try {
      final row = await _client.getRow('/v1/me/profile');
      final displayName = (row['display_name'] as String?)?.trim();
      if (displayName != null && displayName.isNotEmpty) return displayName;
    } catch (_) {
      // Re-login can still proceed even if refreshing the cached label fails.
    }
    return fallback;
  }

  Future<void> createProfile({
    required String name,
    required String userId,
    required NomoGender gender,
    NomoAvatar? avatar,
  }) async {
    await _client.put(
      '/v1/me/profile',
      createProfilePayload(
        name: name,
        userId: userId,
        gender: gender,
        avatar: avatar,
      ),
    );
  }

  Future<void> updateProfile({
    required String name,
    required String userId,
    NomoAvatar? avatar,
  }) async {
    await _client.patch(
      '/v1/me/profile',
      updateProfilePayload(name: name, userId: userId, avatar: avatar),
    );
  }

  Future<void> updateDailyStatus(NomoDailyStatus status) async {
    await _client.put('/v1/daily-status', {
      'status_date': _todayIsoDate(),
      'status': status.key,
    });
  }

  NomoUser _userFromProfileRow(
    Map<String, dynamic> row,
    String authUserId, {
    Map<String, dynamic>? statusRow,
  }) {
    return NomoUser(
      name: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? row['display_name'] as String
          : 'mi-mu',
      userId: (row['user_id'] as String?) ?? defaultNomoUserId(authUserId),
      gender: nomoGenderFromKey(row['gender'] as String?),
      avatar: NomoAvatar.decode(row['avatar_url'] as String?),
      dailyStatus: nomoDailyStatusFromKey(statusRow?['status'] as String?),
      isPlus: (row['is_plus'] as bool?) ?? false,
    );
  }
}

bool isValidNomoUserId(String userId) =>
    RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(userId);

String defaultNomoUserId(String authUserId) {
  final compact = authUserId.replaceAll('-', '');
  return 'nomo_${compact.substring(0, compact.length < 12 ? compact.length : 12)}';
}

String _todayIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> createProfilePayload({
  required String name,
  required String userId,
  required NomoGender gender,
  NomoAvatar? avatar,
}) {
  return {
    'user_id': userId,
    'display_name': name,
    'gender': gender.key,
    'character_key': 'avatar',
    'avatar_url': avatar?.encode() ?? '',
  };
}

Map<String, dynamic> updateProfilePayload({
  required String name,
  required String userId,
  NomoAvatar? avatar,
}) {
  return {
    'user_id': userId,
    'display_name': name,
    'character_key': 'avatar',
    'avatar_url': avatar?.encode() ?? '',
  };
}
