import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/user_repository.dart';
import '../data/tomo_last_account_store.dart';
import '../data/supabase_client_provider.dart';
import '../models/tomo_avatar.dart';
import '../models/tomo_gender.dart';
import '../models/tomo_user.dart';
import '../services/tomo_push_notification_service.dart';

final tomoUserProvider = NotifierProvider<TomoUserController, TomoUser?>(
  TomoUserController.new,
);

class TomoUserController extends Notifier<TomoUser?> {
  @override
  TomoUser? build() => null;

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
    required TomoGender gender,
    TomoAvatar? avatar,
  }) async {
    final repository = ref.read(userRepositoryProvider);
    final authUserId = repository.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before creating a Tomo user.');
    }

    final trimmed = name.trim();
    final normalizedUserId = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    if (!isValidTomoUserId(normalizedUserId)) {
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

    state = TomoUser(
      name: trimmed,
      avatar: profileAvatar,
      userId: normalizedUserId,
      gender: gender,
    );
  }

  Future<void> updateProfile({
    required String name,
    required String userId,
    TomoAvatar? avatar,
  }) async {
    final repository = ref.read(userRepositoryProvider);
    final authUserId = repository.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before updating a Tomo user.');
    }

    final trimmed = name.trim();
    final normalizedUserId = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    if (!isValidTomoUserId(normalizedUserId)) {
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
                TomoUser(
                  name: trimmed,
                  avatar: profileAvatar,
                  userId: defaultTomoUserId(authUserId),
                ))
            .copyWith(
              name: trimmed,
              userId: normalizedUserId,
              avatar: profileAvatar,
            );
  }

  Future<void> updateDailyStatus(
    TomoDailyStatus status, {
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
                  TomoUser(
                    name: 'mi-mu',
                    userId: defaultTomoUserId(authUserId),
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
        await TomoLastAccountStore.save(
          name: currentUser?.name,
          email: currentAuthUser?.email,
          avatar: currentUser?.avatar,
        );
      } catch (_) {
        // 保存に失敗してもログアウト自体は止めない。
      }
      await ref
          .read(tomoPushNotificationServiceProvider)
          .unregisterCurrentToken();
      await supabase.auth.signOut(scope: SignOutScope.local);
    } finally {
      // ローカルセッション削除が例外になっても、UI上は必ず未ログイン状態へ戻す。
      state = null;
    }
  }

  Future<void> deleteAccount() async {
    final supabase = ref.read(supabaseClientProvider);
    final currentAuthUser = supabase.auth.currentUser;
    try {
      try {
        await ref
            .read(tomoPushNotificationServiceProvider)
            .unregisterCurrentToken();
      } catch (_) {
        // Push token cleanup should not block account deletion.
      }
      await ref.read(userRepositoryProvider).deleteAccount();
      try {
        final email = currentAuthUser?.email;
        if (email != null && email.trim().isNotEmpty) {
          await TomoLastAccountStore.remove(email);
        }
      } catch (_) {
        // A stale quick-login cache is less important than finishing deletion.
      }
      try {
        await supabase.auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        // The auth user may already be deleted server-side.
      }
    } finally {
      state = null;
    }
  }
}

bool _isSameLocalDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
