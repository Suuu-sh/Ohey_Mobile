import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/main.dart';
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

  testWidgets('Nomo home renders the redesigned core experience', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: NomoApp()));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('公式'), findsOneWidget);
    expect(find.text('フォロー中'), findsOneWidget);
    expect(find.text('フィード'), findsWidgets);
    expect(find.text('マイページ'), findsOneWidget);
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
