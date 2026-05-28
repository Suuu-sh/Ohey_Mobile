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

final adminDrinkLogsProvider = FutureProvider.autoDispose<List<AdminDrinkLog>>((
  ref,
) async {
  return ref.watch(adminControllerProvider).listDrinkLogs();
});

final adminDrinkLogReportsProvider =
    FutureProvider.autoDispose<List<AdminDrinkLogReport>>((ref) async {
      return ref.watch(adminControllerProvider).listDrinkLogReports();
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

  Future<List<AdminDrinkLog>> listDrinkLogs() => _repository.listDrinkLogs();

  Future<List<AdminDrinkLogReport>> listDrinkLogReports() {
    return _repository.listDrinkLogReports();
  }

  Future<void> updateDrinkLogReport({
    required String id,
    required String status,
    String? moderationNote,
  }) {
    return _repository.updateDrinkLogReport(
      id: id,
      status: status,
      moderationNote: moderationNote,
    );
  }

  Future<String?> displayPhotoUrl(String path) =>
      _repository.displayPhotoUrl(path);

  Future<void> createDrinkLog({
    String? ownerUserId,
    required String placeName,
    required String memo,
    required String linkUrl,
    required String photoPath,
    required bool isOfficial,
  }) {
    return _repository.createDrinkLog(
      ownerUserId: ownerUserId,
      placeName: placeName,
      memo: memo,
      linkUrl: linkUrl,
      photoPath: photoPath,
      isOfficial: isOfficial,
    );
  }

  Future<void> updateDrinkLog({
    required String id,
    String? ownerUserId,
    required String placeName,
    required String memo,
    required String linkUrl,
    required String photoPath,
    required bool isOfficial,
  }) {
    return _repository.updateDrinkLog(
      id: id,
      ownerUserId: ownerUserId,
      placeName: placeName,
      memo: memo,
      linkUrl: linkUrl,
      photoPath: photoPath,
      isOfficial: isOfficial,
    );
  }

  Future<void> deleteDrinkLog(String id) => _repository.deleteDrinkLog(id);

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
