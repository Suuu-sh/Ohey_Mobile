import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../data/ohey_last_account_store.dart';
import '../models/ohey_avatar.dart';
import '../models/ohey_user.dart';
import '../services/ohey_plus_service.dart';
import '../services/ohey_push_notification_service.dart';

final oheyUserProvider = NotifierProvider<OheyUserController, OheyUser?>(
  OheyUserController.new,
);

class OheyUserController extends Notifier<OheyUser?> {
  @override
  OheyUser? build() => null;

  Future<bool> loadFromBackendProfile() async {
    final user = await ref
        .read(userRepositoryProvider)
        .fetchCurrentUserProfile();
    if (user == null) return false;
    await _activateUser(user);
    return true;
  }

  Future<void> ensureProfileForAuthenticatedUser() async {
    final loaded = await loadFromBackendProfile();
    if (loaded) return;

    final repository = ref.read(userRepositoryProvider);
    final authUserId = repository.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before creating a Ohey user.');
    }
    final name = _defaultDisplayName();
    final userId = defaultOheyUserId(authUserId);

    await repository.createProfile(name: name, userId: userId);

    final created = await repository.fetchCurrentUserProfile();
    await _activateUser(created ?? OheyUser(name: name, userId: userId));
  }

  Future<void> _activateUser(OheyUser user) async {
    state = user;
    await ref.read(oheyPlusServiceProvider).configureForCurrentUser();
    ref.invalidate(oheyPlusCustomerInfoProvider);
  }

  Future<String?> latestDisplayName(String? fallback) {
    return ref.read(userRepositoryProvider).latestDisplayName(fallback);
  }

  Future<void> useLocallyCreatedUser({
    required String name,
    required String userId,
    OheyAvatar? avatar,
  }) async {
    final trimmed = name.trim();
    final normalizedUserId = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    if (!isValidOheyUserId(normalizedUserId)) {
      throw ArgumentError.value(
        userId,
        'userId',
        'User ID must be 3-24 letters, numbers, or underscores.',
      );
    }
    await _activateUser(
      OheyUser(name: trimmed, avatar: avatar, userId: normalizedUserId),
    );
  }

  Future<void> createUser({
    required String name,
    required String userId,
    OheyAvatar? avatar,
  }) async {
    final repository = ref.read(userRepositoryProvider);
    final authUserId = repository.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before creating a Ohey user.');
    }

    final trimmed = name.trim();
    final normalizedUserId = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    if (!isValidOheyUserId(normalizedUserId)) {
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
      avatar: profileAvatar,
    );

    await _activateUser(
      OheyUser(name: trimmed, avatar: profileAvatar, userId: normalizedUserId),
    );
  }

  Future<void> updateProfile({
    required String name,
    required String userId,
    OheyAvatar? avatar,
  }) async {
    final repository = ref.read(userRepositoryProvider);
    final authUserId = repository.currentUserId;
    if (authUserId == null || authUserId.isEmpty) {
      throw StateError('Login is required before updating a Ohey user.');
    }

    final trimmed = name.trim();
    final normalizedUserId = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    if (!isValidOheyUserId(normalizedUserId)) {
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
                OheyUser(
                  name: trimmed,
                  avatar: profileAvatar,
                  userId: defaultOheyUserId(authUserId),
                ))
            .copyWith(
              name: trimmed,
              userId: normalizedUserId,
              avatar: profileAvatar,
            );
  }

  Future<void> updateDailyStatus(
    OheyDailyStatus status, {
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
                  OheyUser(
                    name: 'mi-mu',
                    userId: defaultOheyUserId(authUserId),
                  ))
              .copyWith(dailyStatus: status);
    }
  }

  Future<void> signOut() async {
    final currentUser = state;
    final authRepository = ref.read(authRepositoryProvider);
    final currentEmail = authRepository.currentEmail;
    try {
      try {
        await OheyLastAccountStore.save(
          name: currentUser?.name,
          email: currentEmail,
          avatar: currentUser?.avatar,
        );
      } catch (_) {
        // 保存に失敗してもログアウト自体は止めない。
      }
      await ref
          .read(oheyPushNotificationServiceProvider)
          .unregisterCurrentToken();
      await ref.read(oheyPlusServiceProvider).logOutIfConfigured();
      await authRepository.signOut();
    } finally {
      // ローカルセッション削除が例外になっても、UI上は必ず未ログイン状態へ戻す。
      state = null;
    }
  }

  Future<void> deleteAccount() async {
    final authRepository = ref.read(authRepositoryProvider);
    final currentEmail = authRepository.currentEmail;
    try {
      try {
        await ref
            .read(oheyPushNotificationServiceProvider)
            .unregisterCurrentToken();
      } catch (_) {
        // Push token cleanup should not block account deletion.
      }
      await ref.read(userRepositoryProvider).deleteAccount();
      try {
        final email = currentEmail;
        if (email != null && email.trim().isNotEmpty) {
          await OheyLastAccountStore.remove(email);
        }
      } catch (_) {
        // A stale quick-login cache is less important than finishing deletion.
      }
      try {
        await authRepository.signOut();
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

String _defaultDisplayName() => 'Ohey user';
