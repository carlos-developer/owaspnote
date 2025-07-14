// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:owaspnote/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    // Save the original error widget builder
    final originalErrorWidgetBuilder = ErrorWidget.builder;
    
    try {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const SecureNotesApp());

      // Verify that login screen is shown
      expect(find.text('Secure Notes'), findsWidgets); // May appear in AppBar and as title
      expect(find.text('Login'), findsOneWidget);
    } finally {
      // Restore the original error widget builder
      ErrorWidget.builder = originalErrorWidgetBuilder;
    }
  });
}
