import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
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

final adminMemorysProvider = FutureProvider.autoDispose<List<AdminMemory>>((
  ref,
) async {
  return ref.watch(adminControllerProvider).listMemorys();
});

final adminMemoryReportsProvider =
    FutureProvider.autoDispose<List<AdminMemoryReport>>((ref) async {
      return ref.watch(adminControllerProvider).listMemoryReports();
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
    required String gender,
    required String status,
    required bool isPlus,
  }) {
    return _repository.createUser(
      email: email,
      password: password,
      userId: userId,
      displayName: displayName,
      gender: gender,
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

  Future<List<AdminMemory>> listMemorys() => _repository.listMemorys();

  Future<List<AdminMemoryReport>> listMemoryReports() {
    return _repository.listMemoryReports();
  }

  Future<void> updateMemoryReport({
    required String id,
    required String status,
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
}
