import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/backend_api_client.dart';
import '../data/nomo_last_account_store.dart';
import '../data/supabase_client_provider.dart';
import '../models/nomo_avatar.dart';
import '../models/nomo_gender.dart';
import '../models/nomo_user.dart';

final nomoUserProvider = NotifierProvider<NomoUserController, NomoUser?>(
  NomoUserController.new,
);

class NomoUserController extends Notifier<NomoUser?> {
  @override
  NomoUser? build() => null;

  Future<bool> loadFromBackendProfile() async {
    final client = ref.read(backendApiClientProvider);
    final userId = client.currentUserId;
    if (userId == null || userId.isEmpty) return false;

    Map<String, dynamic> row;
    try {
      row = _asMap(await client.get('/v1/me/profile'));
    } on BackendApiException catch (error) {
      if (error.statusCode == 404) return false;
      rethrow;
    }

    final statusRow = _firstMapOrNull(
      await client.get('/v1/daily-status', query: {'date': _todayIsoDate()}),
    );

    state = NomoUser(
      name: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? row['display_name'] as String
          : 'mi-mu',
      userId: (row['user_id'] as String?) ?? _defaultUserId(userId),
      gender: nomoGenderFromKey(row['gender'] as String?),
      avatar: NomoAvatar.decode(row['avatar_url'] as String?),
      dailyStatus: nomoDailyStatusFromKey(statusRow?['status'] as String?),
      isPlus: (row['is_plus'] as bool?) ?? false,
    );
    return true;
  }

  Future<void> createUser({
    required String name,
    required String userId,
    required NomoGender gender,
    NomoAvatar? avatar,
  }) async {
    final client = ref.read(backendApiClientProvider);
    final authUserId = client.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before creating a Nomo user.');
    }

    final trimmed = name.trim();
    final normalizedUserId = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    if (!_isValidUserId(normalizedUserId)) {
      throw ArgumentError.value(
        userId,
        'userId',
        'User ID must be 3-24 letters, numbers, or underscores.',
      );
    }
    final profileAvatar = avatar;
    await client.put('/v1/me/profile', {
      'user_id': normalizedUserId,
      'display_name': trimmed,
      'gender': gender.key,
      'character_key': 'avatar',
      'avatar_url': profileAvatar?.encode() ?? '',
    });

    state = NomoUser(
      name: trimmed,
      avatar: profileAvatar,
      userId: normalizedUserId,
      gender: gender,
    );
  }

  Future<void> updateProfile({
    required String name,
    required String userId,
    NomoAvatar? avatar,
  }) async {
    final client = ref.read(backendApiClientProvider);
    final authUserId = client.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before updating a Nomo user.');
    }

    final trimmed = name.trim();
    final normalizedUserId = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    if (!_isValidUserId(normalizedUserId)) {
      throw ArgumentError.value(
        userId,
        'userId',
        'User ID must be 3-24 letters, numbers, or underscores.',
      );
    }
    final profileAvatar = avatar;
    await client.patch('/v1/me/profile', {
      'user_id': normalizedUserId,
      'display_name': trimmed,
      'character_key': 'avatar',
      'avatar_url': profileAvatar?.encode() ?? '',
    });

    state =
        (state ??
                NomoUser(
                  name: trimmed,
                  avatar: profileAvatar,
                  userId: _defaultUserId(authUserId),
                ))
            .copyWith(
              name: trimmed,
              userId: normalizedUserId,
              avatar: profileAvatar,
            );
  }

  Future<void> updateDailyStatus(NomoDailyStatus status) async {
    final client = ref.read(backendApiClientProvider);
    final authUserId = client.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before updating daily status.');
    }

    await client.put('/v1/daily-status', {
      'status_date': _todayIsoDate(),
      'status': status.key,
    });

    state =
        (state ?? NomoUser(name: 'mi-mu', userId: _defaultUserId(authUserId)))
            .copyWith(dailyStatus: status);
  }

  Future<void> signOut() async {
    final currentUser = state;
    final supabase = ref.read(supabaseClientProvider);
    final currentAuthUser = supabase.auth.currentUser;
    try {
      try {
        await NomoLastAccountStore.save(
          name: currentUser?.name,
          email: currentAuthUser?.email,
          avatar: currentUser?.avatar,
        );
      } catch (_) {
        // 保存に失敗してもログアウト自体は止めない。
      }
      await supabase.auth.signOut(scope: SignOutScope.local);
    } finally {
      // ローカルセッション削除が例外になっても、UI上は必ず未ログイン状態へ戻す。
      state = null;
    }
  }
}

bool _isValidUserId(String userId) =>
    RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(userId);

String _todayIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _defaultUserId(String authUserId) {
  final compact = authUserId.replaceAll('-', '');
  return 'nomo_${compact.substring(0, compact.length < 12 ? compact.length : 12)}';
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List && value.isNotEmpty && value.first is Map) {
    return Map<String, dynamic>.from(value.first as Map);
  }
  throw const FormatException('プロフィールデータの形式が不正です。');
}

Map<String, dynamic>? _firstMapOrNull(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List && value.isNotEmpty && value.first is Map) {
    return Map<String, dynamic>.from(value.first as Map);
  }
  return null;
}
