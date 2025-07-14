import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:owaspnote/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    // Guardar el ErrorWidget.builder original
    late final Widget Function(FlutterErrorDetails) originalErrorBuilder;

    setUpAll(() {
      originalErrorBuilder = ErrorWidget.builder;
    });

    tearDown(() {
      // Restaurar ErrorWidget.builder después de cada test
      ErrorWidget.builder = originalErrorBuilder;
    });

    testWidgets('App should start and display login screen', (tester) async {
      // Start the app
      await tester.pumpWidget(const SecureNotesApp());
      await tester.pumpAndSettle();

      // Verify login screen is displayed
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });
  });
}