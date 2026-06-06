import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/models/ohey_moderation_status.dart';
import '../data/admin_repository.dart';

final adminControllerProvider = Provider<AdminController>((ref) {
  return AdminController(ref.watch(adminRepositoryProvider));
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

final adminYurubosProvider = FutureProvider.autoDispose
    .family<List<AdminYurubo>, String>((ref, status) async {
      return ref.watch(adminControllerProvider).listYurubos(status);
    });

final adminMemorysProvider = FutureProvider.autoDispose<List<AdminMemory>>((
  ref,
) async {
  return ref.watch(adminControllerProvider).listMemorys();
});

final adminMemoryReportsProvider = FutureProvider.autoDispose
    .family<List<AdminMemoryReport>, String>((ref, status) async {
      return ref.watch(adminControllerProvider).listMemoryReports(status);
    });

final adminNotificationOutboxProvider = FutureProvider.autoDispose
    .family<List<AdminNotificationOutboxItem>, String>((ref, status) async {
      return ref.watch(adminControllerProvider).listNotificationOutbox(status);
    });

class AdminController {
  const AdminController(this._repository);

  final AdminRepository _repository;

  Future<void> checkAccess() => _repository.checkAccess();

  Future<List<AdminUserProfile>> listUsers() => _repository.listUsers();

  Future<void> createUser({
    required String email,
    required String password,
    required String userId,
    required String displayName,
    required String status,
    required bool isPlus,
  }) {
    return _repository.createUser(
      email: email,
      password: password,
      userId: userId,
      displayName: displayName,
      status: status,
      isPlus: isPlus,
    );
  }

  Future<void> updateUser({
    required String id,
    String? email,
    String? password,
    required String userId,
    required String displayName,
    required String status,
    required bool isPlus,
  }) {
    return _repository.updateUser(
      id: id,
      email: email,
      password: password,
      userId: userId,
      displayName: displayName,
      status: status,
      isPlus: isPlus,
    );
  }

  Future<void> deleteUser(String id) => _repository.deleteUser(id);

  Future<List<AdminYurubo>> listYurubos(String status) {
    return _repository.listYurubos(status: status);
  }

  Future<void> createYurubo({
    required String ownerUserId,
    required String title,
    required String body,
    required String placeText,
    required String timeLabel,
    required String startsAt,
    required String status,
    required String visibility,
  }) {
    return _repository.createYurubo(
      ownerUserId: ownerUserId,
      title: title,
      body: body,
      placeText: placeText,
      timeLabel: timeLabel,
      startsAt: startsAt,
      status: status,
      visibility: visibility,
    );
  }

  Future<void> updateYurubo({
    required String id,
    required String ownerUserId,
    required String title,
    required String body,
    required String placeText,
    required String timeLabel,
    required String startsAt,
    required String status,
    required String visibility,
  }) {
    return _repository.updateYurubo(
      id: id,
      ownerUserId: ownerUserId,
      title: title,
      body: body,
      placeText: placeText,
      timeLabel: timeLabel,
      startsAt: startsAt,
      status: status,
      visibility: visibility,
    );
  }

  Future<void> deleteYurubo(String id) => _repository.deleteYurubo(id);

  Future<List<AdminMemory>> listMemorys() => _repository.listMemorys();

  Future<List<AdminMemoryReport>> listMemoryReports(String status) {
    return _repository.listMemoryReports(status: status);
  }

  Future<void> updateMemoryReport({
    required String id,
    required OheyModerationStatus status,
    String? moderationNote,
  }) {
    return _repository.updateMemoryReport(
      id: id,
      status: status,
      moderationNote: moderationNote,
    );
  }

  Future<void> createMemory({
    String? ownerUserId,
    required String placeName,
    required String memo,
    required String linkUrl,
    required bool isOfficial,
  }) {
    return _repository.createMemory(
      ownerUserId: ownerUserId,
      placeName: placeName,
      memo: memo,
      linkUrl: linkUrl,
      isOfficial: isOfficial,
    );
  }

  Future<void> updateMemory({
    required String id,
    String? ownerUserId,
    required String placeName,
    required String memo,
    required String linkUrl,
    required bool isOfficial,
  }) {
    return _repository.updateMemory(
      id: id,
      ownerUserId: ownerUserId,
      placeName: placeName,
      memo: memo,
      linkUrl: linkUrl,
      isOfficial: isOfficial,
    );
  }

  Future<void> deleteMemory(String id) => _repository.deleteMemory(id);

  Future<AdminNotificationResult> createSystemNotification({
    required String title,
    required String message,
    required bool sendToAll,
    required List<String> recipientUserIds,
    String? systemKey,
  }) {
    return _repository.createSystemNotification(
      title: title,
      message: message,
      sendToAll: sendToAll,
      recipientUserIds: recipientUserIds,
      systemKey: systemKey,
    );
  }

  Future<List<AdminNotificationOutboxItem>> listNotificationOutbox(
    String status,
  ) {
    return _repository.listNotificationOutbox(status: status);
  }

  Future<AdminNotificationOutboxProcessResult> processNotificationOutbox({
    int limit = 50,
  }) {
    return _repository.processNotificationOutbox(limit: limit);
  }
}
