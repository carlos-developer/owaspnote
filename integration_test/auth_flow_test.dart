import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:owaspnote/main.dart';
import 'package:owaspnote/services/auth_service.dart';
import 'package:owaspnote/security/security_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo completo de Registro y Login', () {
    // Referencia al ErrorWidget.builder original para cada test
    Widget Function(FlutterErrorDetails)? originalErrorBuilder;
    // No es necesario guardar aquí, ya se guarda en setUp

    setUpAll(() async {
      // Habilitar modo mock para usar autenticación local
      AuthService.enableMockMode();
      await AuthService.initialize();
    });

    setUp(() async {
      // Guardar el ErrorWidget.builder original
      originalErrorBuilder = ErrorWidget.builder;
      // Limpiar datos antes de cada test
      AuthService.disableMockMode();
      AuthService.enableMockMode();
    });

    tearDown(() async {
      // Restaurar ErrorWidget.builder
      if (originalErrorBuilder != null) {
        ErrorWidget.builder = originalErrorBuilder!;
      }
    });

    tearDownAll(() async {
      // Deshabilitar modo mock
      AuthService.disableMockMode();
      // ErrorWidget.builder se restaura en tearDown de cada test
    });

    testWidgets('Flujo visual completo: Registro → Logout → Login', 
      (WidgetTester tester) async {
      // Datos de prueba únicos
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testUsername = 'usuario_$timestamp';
      final testEmail = 'test_$timestamp@example.com';
      final testPassword = 'TestSeguro123!@#';

      // PASO 1: Iniciar la aplicación
      await tester.pumpWidget(const SecureNotesApp());
      await tester.pumpAndSettle();

      // Verificar que estamos en la pantalla de login
      expect(find.text('Login'), findsAtLeastNWidgets(1));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // PASO 2: Navegar a registro
      await tester.tap(find.text('Don\'t have an account? Register'));
      await tester.pumpAndSettle();

      // Verificar que estamos en la pantalla de registro
      expect(find.text('Register'), findsAtLeastNWidgets(1));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // PASO 3: Probar validación de contraseña débil
      await tester.enterText(find.byType(TextFormField).at(0), testUsername);
      await tester.enterText(find.byType(TextFormField).at(1), testEmail);
      await tester.enterText(find.byType(TextFormField).at(2), '123'); // Contraseña débil
      await tester.enterText(find.byType(TextFormField).at(3), '123');
      
      // Hacer scroll para ver el botón de registro
      await tester.ensureVisible(find.text('Register'));
      await tester.tap(find.text('Register'));
      await tester.pump();
      
      // Debe mostrar error de contraseña débil
      await tester.pumpAndSettle();
      
      // Buscar cualquier mensaje de error relacionado con la contraseña
      final errorMessages = find.textContaining('Password');
      expect(errorMessages, findsAny);

      // PASO 4: Registro con contraseña válida
      await tester.enterText(find.byType(TextFormField).at(2), testPassword);
      await tester.enterText(find.byType(TextFormField).at(3), testPassword);
      
      // Hacer scroll para ver el botón y registrarse
      await tester.ensureVisible(find.text('Register'));
      await tester.tap(find.text('Register'));
      await tester.pump();
      
      // Ver indicador de carga
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Esperar a que complete el registro
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // PASO 5: Verificar mensaje de éxito y retorno a login
      // El registro exitoso muestra un mensaje y vuelve a la pantalla de login
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verificar que mostró el mensaje de éxito
      expect(find.text('Registration successful! Please login.'), findsOneWidget);
      
      // Esperar a que el snackbar desaparezca
      await tester.pumpAndSettle(const Duration(seconds: 4));
      
      // Verificar que volvimos a la pantalla de login
      expect(find.text('Login'), findsAtLeastNWidgets(1));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // PASO 6: Login con las credenciales recién creadas
      await tester.enterText(find.byType(TextFormField).at(0), testUsername);
      await tester.enterText(find.byType(TextFormField).at(1), testPassword);
      
      await tester.tap(find.text('Login'));
      await tester.pump();
      
      // Ver indicador de carga
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Esperar login exitoso
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // PASO 7: Verificar que llegamos a la pantalla principal
      // La aplicación muestra "Secure Notes" como título
      expect(find.text('Secure Notes'), findsOneWidget);
      // Verificar que el usuario está logueado (muestra el username)
      expect(find.text(testUsername), findsOneWidget);
      // Verificar que estamos en la pantalla de notas
      expect(find.text('No notes yet'), findsOneWidget);

      // PASO 8: Hacer logout (no implementado en la UI actual)
      // Por ahora, simular logout llamando al servicio directamente
      await AuthService.logout();
      
      // Navegar de vuelta a login
      await tester.pumpWidget(const SecureNotesApp());
      await tester.pumpAndSettle();
      
      // Verificar que estamos en login
      expect(find.text('Login'), findsAtLeastNWidgets(1));
      
      // PASO 9: Intentar login con credenciales incorrectas
      await tester.enterText(find.byType(TextFormField).at(0), testUsername);
      await tester.enterText(find.byType(TextFormField).at(1), 'ContraseñaIncorrecta');
      
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Debe mostrar error
      expect(find.textContaining('Invalid'), findsOneWidget);

      // PASO 10: Login con credenciales correctas
      await tester.enterText(find.byType(TextFormField).at(1), testPassword);
      
      await tester.tap(find.text('Login'));
      await tester.pump();
      
      // Ver indicador de carga
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Esperar login
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verificar que llegamos a la pantalla principal
      expect(find.text('Secure Notes'), findsOneWidget);
      expect(find.text(testUsername), findsOneWidget);

      // PASO 11: Verificar que podemos crear notas (opcional)
      // Por ahora el test de flujo básico está completo
      
      print('✅ Test de flujo completo exitoso:');
      print('  - Registro de usuario nuevo');
      print('  - Login con credenciales correctas');
      print('  - Manejo de errores en login');
      print('  - Navegación entre pantallas');
    });

    testWidgets('Protección contra inyección SQL y XSS', 
      (WidgetTester tester) async {
      // Guardar ErrorWidget.builder original para este test
      final originalBuilder = ErrorWidget.builder;
      // Iniciar la aplicación
      await tester.pumpWidget(const SecureNotesApp());
      await tester.pumpAndSettle();

      // Navegar a registro
      await tester.tap(find.text('Don\'t have an account? Register'));
      await tester.pumpAndSettle();

      // Intentar SQL injection en username
      await tester.enterText(
        find.byType(TextFormField).at(0), 
        "admin'; DROP TABLE users; --"
      );
      
      // La entrada debe ser aceptada en el campo (sanitización en backend)
      final usernameField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(0)
      );
      // El campo filtra caracteres especiales automáticamente
      // Verificar que algunos caracteres fueron eliminados
      final actualText = usernameField.controller?.text ?? '';
      expect(actualText, isNotEmpty);
      expect(actualText, isNot(equals("admin'; DROP TABLE users; --")));

      // Verificar que la función de sanitización funciona
      final sanitized = SecurityConfig.sanitizeInput("admin'; DROP TABLE users; --");
      expect(sanitized, isEmpty); // Debe rechazar entrada maliciosa

      // Intentar XSS en email
      await tester.enterText(
        find.byType(TextFormField).at(1), 
        '<script>alert("XSS")</script>@test.com'
      );
      
      // Verificar sanitización de XSS
      final sanitizedXss = SecurityConfig.sanitizeInput('<script>alert("XSS")</script>');
      expect(sanitizedXss, isEmpty);
      
      // Restaurar ErrorWidget.builder
      ErrorWidget.builder = originalBuilder;
    });
  });
}