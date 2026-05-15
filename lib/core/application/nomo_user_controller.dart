import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/nomo_user.dart';
import '../models/nomo_avatar.dart';

final nomoUserProvider = NotifierProvider<NomoUserController, NomoUser?>(
  NomoUserController.new,
);

class NomoUserController extends Notifier<NomoUser?> {
  @override
  NomoUser? build() => null;

  Future<bool> loadFromSupabaseProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final row = await supabase
        .from('profiles')
        .select('user_id,display_name,character_key,avatar_url,is_plus')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return false;

    final statusRow = await supabase
        .from('daily_statuses')
        .select('status')
        .eq('user_id', user.id)
        .eq('status_date', _todayIsoDate())
        .maybeSingle();

    state = NomoUser(
      name: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? row['display_name'] as String
          : 'mi-mu',
      userId: (row['user_id'] as String?) ?? _defaultUserId(user.id),
      avatar: NomoAvatar.decode(row['avatar_url'] as String?),
      dailyStatus: nomoDailyStatusFromKey(statusRow?['status'] as String?),
      isPlus: (row['is_plus'] as bool?) ?? false,
    );
    return true;
  }

  Future<void> createUser({required String name, NomoAvatar? avatar}) async {
    final supabase = Supabase.instance.client;
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw StateError('Login is required before creating a Nomo user.');
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    final existing = await supabase
        .from('profiles')
        .select('user_id')
        .eq('id', authUser.id)
        .maybeSingle();

    await supabase
        .from('profiles')
        .upsert(
          {
            'id': authUser.id,
            'user_id': existing?['user_id'] ?? _defaultUserId(authUser.id),
            'display_name': trimmed,
            'character_key': 'avatar',
            'avatar_url': avatar?.encode(),
          }..removeWhere((_, value) => value == null),
        );

    state = NomoUser(
      name: trimmed,
      avatar: avatar,
      userId: (existing?['user_id'] as String?) ?? _defaultUserId(authUser.id),
    );
  }

  Future<void> updateProfile({required String name, NomoAvatar? avatar}) async {
    final supabase = Supabase.instance.client;
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw StateError('Login is required before updating a Nomo user.');
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }

    await supabase
        .from('profiles')
        .update({
          'display_name': trimmed,
          'character_key': 'avatar',
          'avatar_url': avatar?.encode(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', authUser.id);

    state =
        (state ??
                NomoUser(
                  name: trimmed,
                  avatar: avatar,
                  userId: _defaultUserId(authUser.id),
                ))
            .copyWith(name: trimmed, avatar: avatar);
  }

  Future<void> updateDailyStatus(NomoDailyStatus status) async {
    final supabase = Supabase.instance.client;
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw StateError('Login is required before updating daily status.');
    }

    final payload = {
      'user_id': authUser.id,
      'status_date': _todayIsoDate(),
      'status': status.key,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await supabase.from('daily_statuses').upsert(payload);
    } on PostgrestException catch (error) {
      if (error.code != '23514') rethrow;
      await supabase.from('daily_statuses').upsert({
        ...payload,
        'status': status.legacyCompatibleKey,
      });
    }

    state =
        (state ?? NomoUser(name: 'mi-mu', userId: _defaultUserId(authUser.id)))
            .copyWith(dailyStatus: status);
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    } finally {
      // ローカルセッション削除が例外になっても、UI上は必ず未ログイン状態へ戻す。
      state = null;
    }
  }
}

String _todayIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _defaultUserId(String authUserId) {
  final compact = authUserId.replaceAll('-', '');
  return 'nomo_${compact.substring(0, compact.length < 12 ? compact.length : 12)}';
}
