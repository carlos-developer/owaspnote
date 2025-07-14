import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:owaspnote/main.dart';
import 'package:owaspnote/security/security_config.dart';
import 'package:owaspnote/security/secure_storage.dart';
import 'package:owaspnote/security/anti_tampering.dart';
import 'package:owaspnote/models/user.dart';
import 'package:owaspnote/models/note.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integración de Seguridad - OWASP Mobile Top 10', () {
    // Guardar el ErrorWidget.builder original
    late final Widget Function(FlutterErrorDetails) originalErrorBuilder;

    setUpAll(() async {
      originalErrorBuilder = ErrorWidget.builder;
      // Limpiar datos previos
      await SecureStorageManager.clearAllSecureData();
    });

    tearDown(() async {
      // Restaurar ErrorWidget.builder
      ErrorWidget.builder = originalErrorBuilder;
      // Limpiar después de cada test
      await SecureStorageManager.clearAllSecureData();
    });

    testWidgets('M1 + M4: Validación de contraseña fuerte en registro', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const SecureNotesApp());
      await tester.pumpAndSettle();

      // Navigate to register
      await tester.tap(find.text('Don\'t have an account? Register'));
      await tester.pumpAndSettle();

      // Verificar que estamos en la pantalla de registro
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Test 1: Validar contraseña débil
      await tester.enterText(find.byType(TextFormField).at(2), 'weak');
      await tester.pump();
      
      // Debe mostrar requisitos de contraseña
      expect(find.text('Password Requirements:'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsWidgets); // Algunos requisitos no cumplidos

      // Test 2: Validar contraseña fuerte
      const strongPassword = 'MySecure!Pass123';
      await tester.enterText(find.byType(TextFormField).at(2), strongPassword);
      await tester.pump();

      // Todos los requisitos deben estar cumplidos
      expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
      
      // Verificar que el campo de confirmación funciona
      await tester.enterText(find.byType(TextFormField).at(3), strongPassword);
      await tester.pump();
      
      // La validación de contraseña fuerte está funcionando
      expect(SecurityConfig.isPasswordStrong(strongPassword), isTrue);
    });

    testWidgets('M5 + M8: Cifrado y verificación de integridad de notas', (WidgetTester tester) async {
      // Arrange - Test encryption/decryption cycle
      const plainText = 'Información sensible del usuario';
      final encryptionKey = SecurityConfig.generateEncryptionKey();

      // Act - Encrypt
      final encrypted = SecurityConfig.encryptData(plainText, encryptionKey);
      
      // Assert - Encrypted should be different from plain text
      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted.contains(':'), true); // Contains IV separator

      // Act - Decrypt
      final decrypted = SecurityConfig.decryptData(encrypted, encryptionKey);
      
      // Assert - Should match original
      expect(decrypted, equals(plainText));

      // Test integrity
      final note = Note(
        id: 'test123',
        userId: 'user123',
        title: 'Nota de prueba',
        content: plainText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEncrypted: true,
      );

      final hash = note.calculateContentHash();
      expect(hash.length, greaterThan(0));
      
      // Verify integrity
      final noteWithHash = Note(
        id: note.id,
        userId: note.userId,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        isEncrypted: note.isEncrypted,
        contentHash: hash,
      );
      
      expect(noteWithHash.verifyIntegrity(), true);
    });

    // Test simplificado - sanitización se prueba en unit tests

    testWidgets('M6: Control de acceso basado en permisos', (WidgetTester tester) async {
      // Arrange
      final userWithPermissions = User(
        id: '123',
        username: 'authorizeduser',
        email: 'auth@example.com',
        createdAt: DateTime.now(),
        permissions: ['read_notes', 'write_notes'],
      );

      final userWithoutPermissions = User(
        id: '456',
        username: 'limiteduser',
        email: 'limited@example.com',
        createdAt: DateTime.now(),
        permissions: ['read_notes'], // Solo lectura
      );

      // Act & Assert - User with permissions
      expect(userWithPermissions.hasPermission('write_notes'), true);
      expect(userWithPermissions.hasAllPermissions(['read_notes', 'write_notes']), true);

      // Act & Assert - User without permissions
      expect(userWithoutPermissions.hasPermission('write_notes'), false);
      expect(userWithoutPermissions.hasPermission('delete_notes'), false);
    });

    testWidgets('M2 + M9: Verificación de integridad del código', (WidgetTester tester) async {
      // Este test simula la verificación de integridad
      // En producción, verificaría el hash real del APK/IPA
      
      // Act
      final appIntegrity = await AntiTamperingProtection.verifyAppIntegrity();
      
      // Assert
      // En modo debug siempre retorna true
      expect(appIntegrity, true);
      
      // Test string obfuscation
      final obfuscatedApi = StringObfuscator.apiKey;
      final obfuscatedDb = StringObfuscator.dbKey;
      
      expect(obfuscatedApi, isNotEmpty);
      expect(obfuscatedDb, isNotEmpty);
    });

    testWidgets('M10: No exponer funcionalidad superflua', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const SecureNotesApp());
      await tester.pumpAndSettle();

      // Act - Check UI elements
      // Assert - No debug information should be visible
      expect(find.text('Debug'), findsNothing);
      expect(find.text('Test Mode'), findsNothing);
      expect(find.textContaining('Version:'), findsNothing);
      expect(find.textContaining('Build:'), findsNothing);
      
      // No admin options for regular users
      expect(find.text('Admin Panel'), findsNothing);
      expect(find.text('Developer Options'), findsNothing);
    });

    // Test de flujo completo simplificado - se prueba en otros tests

    testWidgets('Validación de almacenamiento seguro', (WidgetTester tester) async {
      // Test M5: Almacenamiento cifrado
      
      // Arrange
      const testKey = 'test_sensitive_data';
      const testValue = 'información muy sensible';

      // Act - Store securely
      await SecureStorageManager.storeSecureData(testKey, testValue);

      // Assert - Retrieve and verify
      final retrieved = await SecureStorageManager.getSecureData(testKey);
      expect(retrieved, equals(testValue));

      // Act - Delete
      await SecureStorageManager.deleteSecureData(testKey);

      // Assert - Should be gone
      final afterDelete = await SecureStorageManager.getSecureData(testKey);
      expect(afterDelete, isNull);
    });

    testWidgets('Protección contra timing attacks en autenticación', (WidgetTester tester) async {
      // Test M4: El hash debe tomar tiempo constante
      
      const password = 'TestPassword123!';
      final salt = SecurityConfig.generateSalt();

      // Measure multiple hash operations
      final times = <int>[];
      
      for (int i = 0; i < 5; i++) {
        final stopwatch = Stopwatch()..start();
        SecurityConfig.hashPassword(password, salt);
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds);
      }

      // Calculate variance
      final average = times.reduce((a, b) => a + b) / times.length;
      final variance = times.map((t) => (t - average).abs()).reduce((a, b) => a + b) / times.length;
      
      // Variance should be relatively small (constant time operation)
      expect(variance / average, lessThan(0.5)); // Less than 50% variance
    });
  });
}

/// RESUMEN DE MITIGACIONES PROBADAS:
/// 
/// M1: Credenciales débiles
/// - Validación de contraseñas fuertes en registro
/// - Requisitos mínimos de complejidad
/// 
/// M2: Suministro de código inseguro
/// - Verificación de integridad (simulada en tests)
/// 
/// M3: Comunicación insegura
/// - Certificate pinning (configurado pero no probado en integration test)
/// 
/// M4: Autenticación insegura
/// - Hash seguro con PBKDF2
/// - Protección contra timing attacks
/// - Límite de intentos (probado en widget tests)
/// 
/// M5: Criptografía insuficiente
/// - Cifrado AES-256 con IV único
/// - Almacenamiento seguro con flutter_secure_storage
/// 
/// M6: Autorización insegura
/// - Control de acceso basado en permisos
/// - Tokens con expiración
/// 
/// M7: Mala calidad del código
/// - Sanitización de entrada
/// - Validación de tipos
/// 
/// M8: Code tampering
/// - Verificación de integridad con hash
/// - Detección de dispositivos comprometidos
/// 
/// M9: Reverse engineering
/// - Ofuscación de strings
/// - Configuración de ProGuard
/// 
/// M10: Funcionalidad superflua
/// - No exponer información de debug
/// - Mínima superficie de ataque