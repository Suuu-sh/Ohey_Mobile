import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/core/data/nomo_last_account_store.dart';
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

  testWidgets('first demo exits to account choice screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: NomoApp()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('スキップ'));
    await tester.tap(find.text('スキップ'));
    await tester.pumpAndSettle();

    expect(find.text('すでにアカウントをお持ち\nですか？'), findsOneWidget);
    expect(find.text('ログイン'), findsOneWidget);
    expect(find.text('Nomoは初めてですか？'), findsOneWidget);
    expect(find.text('スタート'), findsOneWidget);
  });

  testWidgets('signed out returning users land on the login page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      NomoLastAccountStore.onboardingSeenKey: true,
      NomoLastAccountStore.nameKey: 'Suu',
      NomoLastAccountStore.emailKey: 'yisshiki39@gmail.com',
    });

    await tester.pumpWidget(const ProviderScope(child: NomoApp()));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('再ログイン'), findsOneWidget);
    expect(find.text('Suu'), findsOneWidget);
    expect(find.text('yisshiki39@gmail.com'), findsOneWidget);
    expect(find.text('別のアカウントを追加'), findsOneWidget);
    expect(find.text('アカウント管理'), findsOneWidget);

    await tester.tap(find.text('別のアカウントを追加'));
    await tester.pumpAndSettle();

    expect(find.text('Eメール/電話番号/ユーザー名'), findsOneWidget);
    expect(find.text('パスワード'), findsOneWidget);
    expect(find.text('パスワードをお忘れですか？'), findsOneWidget);
    expect(find.text('GOOGLEでログイン'), findsOneWidget);
    expect(find.text('FACEBOOKでログイン'), findsOneWidget);
    expect(find.text('APPLEでログイン'), findsOneWidget);
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
