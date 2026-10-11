import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/application/ohey_user_controller.dart';
import 'package:ohey/core/data/auth_repository.dart';
import 'package:ohey/core/services/ohey_plus_service.dart';
import 'package:ohey/core/services/ohey_push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'signOut revokes the Clerk session instead of only suspending it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final authRepository = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          oheyPlusServiceProvider.overrideWithValue(_FakeOheyPlusService()),
          oheyPushNotificationServiceProvider.overrideWithValue(
            _FakePushNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(oheyUserProvider.notifier).signOut();

      expect(authRepository.signOutCalls, 1);
      expect(authRepository.suspendCurrentSessionCalls, 0);
      expect(container.read(oheyUserProvider), isNull);
    },
  );
}

class _FakeAuthRepository extends Fake implements AuthRepository {
  var signOutCalls = 0;
  var suspendCurrentSessionCalls = 0;

  @override
  String? get currentEmail => null;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }

  @override
  Future<void> suspendCurrentSessionLocally() async {
    suspendCurrentSessionCalls += 1;
  }
}

class _FakeOheyPlusService extends Fake implements OheyPlusService {
  @override
  Future<void> logOutIfConfigured() async {}
}

class _FakePushNotificationService extends Fake
    implements OheyPushNotificationService {
  @override
  Future<void> unregisterCurrentToken() async {}
}
