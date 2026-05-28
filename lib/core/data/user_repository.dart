import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tomo_avatar.dart';
import '../models/tomo_gender.dart';
import '../models/tomo_user.dart';
import 'backend_api_client.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(backendApiClientProvider));
});

class UserRepository {
  const UserRepository(this._client);

  final BackendApiClient _client;

  String? get currentUserId => _client.currentUserId;

  Future<TomoUser?> fetchCurrentUserProfile() async {
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
      query: {'date': _isoDate(DateTime.now())},
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
    required TomoGender gender,
    TomoAvatar? avatar,
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
    TomoAvatar? avatar,
  }) async {
    await _client.patch(
      '/v1/me/profile',
      updateProfilePayload(name: name, userId: userId, avatar: avatar),
    );
  }

  Future<void> deleteAccount() async {
    await _client.delete('/v1/me/account');
  }

  Future<TomoDailyStatus> fetchDailyStatus(DateTime date) async {
    final rows = await _client.getRows(
      '/v1/daily-status',
      query: {'date': _isoDate(date)},
    );
    if (rows.isEmpty) return TomoDailyStatus.unselected;
    return tomoDailyStatusFromKey(rows.first['status'] as String?);
  }

  Future<Map<String, TomoDailyStatus>> fetchDailyStatusesForMonth(
    DateTime month,
  ) async {
    final rows = await _client.getRows(
      '/v1/daily-statuses/month',
      query: {'month': _isoMonth(month)},
    );
    return {
      for (final row in rows)
        if (row['status_date'] is String)
          row['status_date'] as String: tomoDailyStatusFromKey(
            row['status'] as String?,
          ),
    };
  }

  Future<void> updateDailyStatus(
    TomoDailyStatus status, {
    DateTime? date,
  }) async {
    await _client.put('/v1/daily-status', {
      'status_date': _isoDate(date ?? DateTime.now()),
      'status': status.key,
    });
  }

  TomoUser _userFromProfileRow(
    Map<String, dynamic> row,
    String authUserId, {
    Map<String, dynamic>? statusRow,
  }) {
    return TomoUser(
      name: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? row['display_name'] as String
          : 'mi-mu',
      userId: (row['user_id'] as String?) ?? defaultTomoUserId(authUserId),
      gender: tomoGenderFromKey(row['gender'] as String?),
      avatar: TomoAvatar.decode(row['avatar_url'] as String?),
      dailyStatus: tomoDailyStatusFromKey(statusRow?['status'] as String?),
      isPlus: (row['is_plus'] as bool?) ?? false,
    );
  }
}

bool isValidTomoUserId(String userId) =>
    RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(userId);

String defaultTomoUserId(String authUserId) {
  final compact = authUserId.replaceAll('-', '');
  return 'tomo_${compact.substring(0, compact.length < 12 ? compact.length : 12)}';
}

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _isoMonth(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';
}

Map<String, dynamic> createProfilePayload({
  required String name,
  required String userId,
  required TomoGender gender,
  TomoAvatar? avatar,
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
  TomoAvatar? avatar,
}) {
  return {
    'user_id': userId,
    'display_name': name,
    'character_key': 'avatar',
    'avatar_url': avatar?.encode() ?? '',
  };
}
