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

    await tester.tap(find.text('スキップ'));
    await tester.pumpAndSettle();

    expect(find.text('すでにアカウントをお持ち\nですか？'), findsOneWidget);
    expect(find.text('ログイン'), findsOneWidget);
    expect(find.text('Nomoは初めてですか'), findsOneWidget);
    expect(find.text('サインアップ'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);

    await tester.tap(find.text('サインアップ'));
    await tester.pumpAndSettle();

    expect(find.text('メールアドレスを入力して\nください'), findsOneWidget);
    expect(find.text('次へ'), findsOneWidget);
    expect(find.text('GOOGLEで登録'), findsOneWidget);
    expect(find.text('FACEBOOKで登録'), findsNothing);
    expect(find.text('APPLEで登録'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'yaujt@gmail.com');
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    expect(find.text('パスワードを入力してください'), findsOneWidget);
    expect(find.text('アカウントを登録（無料）'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
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
    expect(find.byType(SingleChildScrollView), findsNothing);

    await tester.tap(find.text('別のアカウントを追加'));
    await tester.pumpAndSettle();

    expect(find.text('すでにアカウントをお持ち\nですか？'), findsOneWidget);
    expect(find.text('ログイン'), findsOneWidget);
    expect(find.text('Nomoは初めてですか'), findsOneWidget);
    expect(find.text('サインアップ'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);

    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();

    expect(find.text('Eメール/電話番号/ユーザー名'), findsOneWidget);
    expect(find.text('パスワード'), findsOneWidget);
    expect(find.text('パスワードをお忘れですか？'), findsOneWidget);
    expect(find.text('GOOGLEでログイン'), findsOneWidget);
    expect(find.text('FACEBOOKでログイン'), findsNothing);
    expect(find.text('APPLEでログイン'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  test('last account store keeps the latest three unique accounts', () async {
    SharedPreferences.setMockInitialValues({});

    await NomoLastAccountStore.save(
      name: 'One',
      email: 'one@example.com',
      avatar: null,
    );
    await NomoLastAccountStore.save(
      name: 'Two',
      email: 'two@example.com',
      avatar: null,
    );
    await NomoLastAccountStore.save(
      name: 'Three',
      email: 'three@example.com',
      avatar: null,
    );
    await NomoLastAccountStore.save(
      name: 'Four',
      email: 'four@example.com',
      avatar: null,
    );

    var accounts = await NomoLastAccountStore.loadAccounts();
    expect(accounts.map((account) => account.email), [
      'four@example.com',
      'three@example.com',
      'two@example.com',
    ]);

    await NomoLastAccountStore.save(
      name: 'Two Updated',
      email: 'TWO@example.com',
      avatar: null,
    );

    accounts = await NomoLastAccountStore.loadAccounts();
    expect(accounts.map((account) => account.email), [
      'TWO@example.com',
      'four@example.com',
      'three@example.com',
    ]);
    expect(accounts.first.name, 'Two Updated');
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
