import 'package:bictree_assessment/features/auth/presentation/login_screen.dart';
import 'package:bictree_assessment/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fakes.dart';

Widget _app(FakeAuthRepository repo) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      splashMinDurationProvider.overrideWithValue(Duration.zero),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => const LoginScreen())],
      ),
    ),
  );
}

Finder get _loginButton => find.widgetWithText(FilledButton, 'Log In');

void main() {
  Future<void> pumpLogin(WidgetTester tester, FakeAuthRepository repo) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
  }

  testWidgets('shows validation messages for empty fields', (tester) async {
    final repo = FakeAuthRepository();
    await pumpLogin(tester, repo);

    await tester.tap(_loginButton);
    await tester.pump();

    expect(find.text('Please enter your username or email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    expect(repo.loginCalls, 0);
  });

  testWidgets('rejects a password that is too short', (tester) async {
    final repo = FakeAuthRepository();
    await pumpLogin(tester, repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'emilys');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(_loginButton);
    await tester.pump();

    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(repo.loginCalls, 0);
  });

  testWidgets('a valid form calls the repository once', (tester) async {
    final repo = FakeAuthRepository();
    await pumpLogin(tester, repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'emilys');
    await tester.enterText(find.byType(TextFormField).at(1), 'emilyspass');
    await tester.tap(_loginButton);
    await tester.pumpAndSettle();

    expect(repo.loginCalls, 1);
    expect(repo.lastUsername, 'emilys');
  });
}
