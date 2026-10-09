import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/data/auth_repository.dart';
import 'package:ohey/features/onboarding/presentation/create_user_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {
  _FakeAuthRepository(this._signInWithOAuth);

  final Future<OAuthSignInResult> Function(OAuthProvider provider)
  _signInWithOAuth;

  @override
  bool get isSignedIn => false;

  @override
  Future<OAuthSignInResult> signInWithOAuth(OAuthProvider provider) =>
      _signInWithOAuth(provider);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Apple OAuth timeout error is cleared when login can be retried',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      final attempts = <Completer<OAuthSignInResult>>[
        Completer<OAuthSignInResult>(),
        Completer<OAuthSignInResult>(),
      ];
      final providers = <OAuthProvider>[];
      var attemptIndex = 0;
      final repository = _FakeAuthRepository((provider) {
        providers.add(provider);
        return attempts[attemptIndex++].future;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(
            home: CreateUserDialog(startAtLogin: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final appleLoginButton = find.text('APPLEでログイン');
      expect(appleLoginButton, findsOneWidget);

      await tester.tap(appleLoginButton);
      await tester.pump();
      expect(providers, [OAuthProvider.apple]);

      attempts.first.completeError(
        const AuthException('Apple認証がタイムアウトしました。もう一度試してね。'),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      const timeoutMessage = 'Apple認証がタイムアウトしました。もう一度試してね。';
      expect(find.text(timeoutMessage), findsOneWidget);
      expect(appleLoginButton, findsOneWidget);

      await tester.tap(appleLoginButton);
      await tester.pump();
      expect(providers, [OAuthProvider.apple, OAuthProvider.apple]);
      expect(find.text(timeoutMessage), findsNothing);

      attempts[1].complete(OAuthSignInResult.cancelled);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(timeoutMessage), findsNothing);
      expect(appleLoginButton, findsOneWidget);
    },
  );
}
