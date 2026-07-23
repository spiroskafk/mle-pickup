// Smoke test: the app boots and, with no authenticated user, shows the
// sign-in screen. Firebase isn't initialized in the test harness, so we build
// the SignInScreen directly rather than MleApp (which calls Firebase).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mle/services/auth_service.dart';
import 'package:mle/screens/sign_in_screen.dart';

void main() {
  testWidgets('Sign-in screen renders its core controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<AuthService>(
        create: (_) => AuthService(),
        child: const MaterialApp(home: SignInScreen()),
      ),
    );

    expect(find.text('MLE'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
