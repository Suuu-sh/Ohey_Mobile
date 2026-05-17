import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'http://localhost',
      anonKey: 'test_publishable_key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _MemoryAsyncStorage(),
      ),
    );
  });

  testWidgets('signed out returning users land on the login page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'nomo_onboarding_seen': true});

    await tester.pumpWidget(const ProviderScope(child: NomoApp()));
    await tester.pumpAndSettle();

    expect(find.text('おかえりログイン'), findsOneWidget);
    expect(find.text('また乾杯を記録しよう'), findsOneWidget);
    expect(find.text('飲みログ'), findsOneWidget);
    expect(find.text('ログイン'), findsOneWidget);
  });
}

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  const _MemoryAsyncStorage();

  static final Map<String, String> _values = {};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}
