import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/user_repository.dart';
import '../data/nomo_last_account_store.dart';
import '../data/supabase_client_provider.dart';
import '../models/nomo_avatar.dart';
import '../models/nomo_gender.dart';
import '../models/nomo_user.dart';
import '../services/nomo_push_notification_service.dart';

final nomoUserProvider = NotifierProvider<NomoUserController, NomoUser?>(
  NomoUserController.new,
);

class NomoUserController extends Notifier<NomoUser?> {
  @override
  NomoUser? build() => null;

  Future<bool> loadFromBackendProfile() async {
    final user = await ref
        .read(userRepositoryProvider)
        .fetchCurrentUserProfile();
    if (user == null) return false;
    state = user;
    return true;
  }

  Future<String?> latestDisplayName(String? fallback) {
    return ref.read(userRepositoryProvider).latestDisplayName(fallback);
  }

  Future<void> createUser({
    required String name,
    required String userId,
    required NomoGender gender,
    NomoAvatar? avatar,
  }) async {
    final repository = ref.read(userRepositoryProvider);
    final authUserId = repository.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before creating a Nomo user.');
    }

    final trimmed = name.trim();
    final normalizedUserId = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    if (!isValidNomoUserId(normalizedUserId)) {
      throw ArgumentError.value(
        userId,
        'userId',
        'User ID must be 3-24 letters, numbers, or underscores.',
      );
    }
    final profileAvatar = avatar;
    await repository.createProfile(
      name: trimmed,
      userId: normalizedUserId,
      gender: gender,
      avatar: profileAvatar,
    );

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
    final repository = ref.read(userRepositoryProvider);
    final authUserId = repository.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before updating a Nomo user.');
    }

    final trimmed = name.trim();
    final normalizedUserId = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    if (!isValidNomoUserId(normalizedUserId)) {
      throw ArgumentError.value(
        userId,
        'userId',
        'User ID must be 3-24 letters, numbers, or underscores.',
      );
    }
    final profileAvatar = avatar;
    await repository.updateProfile(
      name: trimmed,
      userId: normalizedUserId,
      avatar: profileAvatar,
    );

    state =
        (state ??
                NomoUser(
                  name: trimmed,
                  avatar: profileAvatar,
                  userId: defaultNomoUserId(authUserId),
                ))
            .copyWith(
              name: trimmed,
              userId: normalizedUserId,
              avatar: profileAvatar,
            );
  }

  Future<void> updateDailyStatus(
    NomoDailyStatus status, {
    DateTime? date,
  }) async {
    final repository = ref.read(userRepositoryProvider);
    final authUserId = repository.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before updating daily status.');
    }

    await repository.updateDailyStatus(status, date: date);

    if (date == null || _isSameLocalDate(date, DateTime.now())) {
      state =
          (state ??
                  NomoUser(
                    name: 'mi-mu',
                    userId: defaultNomoUserId(authUserId),
                  ))
              .copyWith(dailyStatus: status);
    }
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
      await ref
          .read(nomoPushNotificationServiceProvider)
          .unregisterCurrentToken();
      await supabase.auth.signOut(scope: SignOutScope.local);
    } finally {
      // ローカルセッション削除が例外になっても、UI上は必ず未ログイン状態へ戻す。
      state = null;
    }
  }
}

bool _isSameLocalDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
