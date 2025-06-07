// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:go_cloud_backend/main.dart';
import 'package:go_cloud_backend/screens/login_screen.dart';
import 'package:go_cloud_backend/services/auth_service.dart';

void main() {
  testWidgets('LoginScreen displays all required elements', (WidgetTester tester) async {
    // Build the LoginScreen directly
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<AuthService>(
          create: (_) => AuthService(),
          child: const LoginScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify login screen elements are present
    expect(find.text('Go Cloud Frontend'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Don\'t have an account? Register'), findsOneWidget);
  });

  testWidgets('Email field accepts input', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<AuthService>(
          create: (_) => AuthService(),
          child: const LoginScreen(),
        ),
      ),
    );

    await tester.pump();

    // Find the email field by looking for the field with "Email" hint
    final emailField = find.byKey(const Key('email_field'));
    
    if (emailField.evaluate().isEmpty) {
      // If key not found, find by type and check if it's the first field
      final textFields = find.byType(TextFormField);
      expect(textFields, findsAtLeastNWidgets(2)); // Should have email and password fields
      
      await tester.tap(textFields.first);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.pump();
      
      // Verify the text was entered
      expect(find.text('test@example.com'), findsOneWidget);
    }
  });

  testWidgets('App can be initialized', (WidgetTester tester) async {
    // Test that the full app can be built without crashing
    await tester.pumpWidget(const MyApp());    await tester.pump();
    
    // Just verify it doesn't crash and shows some content
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });
}
