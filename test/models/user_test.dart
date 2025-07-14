import 'package:flutter_test/flutter_test.dart';
import 'package:owaspnote/models/user.dart';

void main() {
  group('User Model - OWASP M7: Mala Calidad del Código', () {
    test('debe validar y sanitizar nombre de usuario correctamente', () {
      // Arrange
      final json = {
        'id': '123',
        'username': 'user<script>alert("xss")</script>name',
        'email': 'test@example.com',
        'createdAt': DateTime.now().toIso8601String(),
        'permissions': ['read_notes', 'write_notes'],
      };
      
      // Act
      final user = User.fromJson(json);
      
      // Assert
      // La sanitización elimina caracteres peligrosos individuales, no tags completos
      expect(user.username, equals('userscriptalert(xss)/scriptname'));
      expect(user.username.contains('<'), false);
      expect(user.username.contains('>'), false);
      expect(user.username.contains('"'), false);
    });

    test('debe rechazar JSON con campos faltantes', () {
      // Arrange
      final invalidJson = {
        'id': '123',
        // Falta username
        'email': 'test@example.com',
        'createdAt': DateTime.now().toIso8601String(),
        'permissions': [],
      };
      
      // Act & Assert
      expect(
        () => User.fromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('debe rechazar JSON con tipos incorrectos', () {
      // Arrange
      final invalidJson = {
        'id': 123, // Debe ser String
        'username': 'testuser',
        'email': 'test@example.com',
        'createdAt': DateTime.now().toIso8601String(),
        'permissions': [],
      };
      
      // Act & Assert
      expect(
        () => User.fromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('debe validar formato de email correctamente', () {
      // Arrange
      final invalidEmails = [
        'notanemail',
        '@example.com',
        'user@',
        'user@.com',
        'user..@example.com',
      ];
      
      // Act & Assert
      for (final email in invalidEmails) {
        final json = {
          'id': '123',
          'username': 'testuser',
          'email': email,
          'createdAt': DateTime.now().toIso8601String(),
          'permissions': [],
        };
        
        expect(
          () => User.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      }
    });

    test('debe aceptar emails válidos', () {
      // Arrange
      final validEmails = [
        'user@example.com',
        'user.name@example.com',
        'user+tag@example.co.uk',
        'user123@test-domain.org',
      ];
      
      // Act & Assert
      for (final email in validEmails) {
        final json = {
          'id': '123',
          'username': 'testuser',
          'email': email,
          'createdAt': DateTime.now().toIso8601String(),
          'permissions': [],
        };
        
        final user = User.fromJson(json);
        expect(user.email, equals(email));
      }
    });

    test('debe limitar longitud del nombre de usuario a 50 caracteres', () {
      // Arrange
      final longUsername = 'a' * 100;
      final json = {
        'id': '123',
        'username': longUsername,
        'email': 'test@example.com',
        'createdAt': DateTime.now().toIso8601String(),
        'permissions': [],
      };
      
      // Act
      final user = User.fromJson(json);
      
      // Assert
      expect(user.username.length, equals(50));
    });

    test('debe eliminar caracteres peligrosos del nombre de usuario', () {
      // Arrange
      final dangerousUsernames = {
        'user<name': 'username',
        'user>name': 'username',
        'user"name': 'username',
        "user'name": 'username',
        'user&name': 'username',
        'user<>&"\' name': 'user name',
      };
      
      // Act & Assert
      dangerousUsernames.forEach((input, expected) {
        final json = {
          'id': '123',
          'username': input,
          'email': 'test@example.com',
          'createdAt': DateTime.now().toIso8601String(),
          'permissions': [],
        };
        
        final user = User.fromJson(json);
        expect(user.username, equals(expected));
      });
    });

    test('debe serializar correctamente a JSON', () {
      // Arrange
      final user = User(
        id: '123',
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        permissions: ['read_notes', 'write_notes'],
      );
      
      // Act
      final json = user.toJson();
      
      // Assert
      expect(json['id'], equals('123'));
      expect(json['username'], equals('testuser'));
      expect(json['email'], equals('test@example.com'));
      expect(json['permissions'], equals(['read_notes', 'write_notes']));
      expect(json['createdAt'], isA<String>());
    });
  });

  group('User Model - OWASP M6: Autorización Insegura', () {
    test('debe verificar permisos individuales correctamente', () {
      // Arrange
      final user = User(
        id: '123',
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        permissions: ['read_notes', 'write_notes'],
      );
      
      // Act & Assert
      expect(user.hasPermission('read_notes'), true);
      expect(user.hasPermission('write_notes'), true);
      expect(user.hasPermission('delete_notes'), false);
      expect(user.hasPermission('admin'), false);
    });

    test('debe verificar múltiples permisos con hasAllPermissions', () {
      // Arrange
      final user = User(
        id: '123',
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        permissions: ['read_notes', 'write_notes'],
      );
      
      // Act & Assert
      expect(
        user.hasAllPermissions(['read_notes', 'write_notes']),
        true,
      );
      expect(
        user.hasAllPermissions(['read_notes', 'write_notes', 'delete_notes']),
        false,
      );
    });

    test('debe verificar al menos un permiso con hasAnyPermission', () {
      // Arrange
      final user = User(
        id: '123',
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        permissions: ['read_notes'],
      );
      
      // Act & Assert
      expect(
        user.hasAnyPermission(['read_notes', 'write_notes']),
        true,
      );
      expect(
        user.hasAnyPermission(['delete_notes', 'admin']),
        false,
      );
    });

    test('debe manejar lista de permisos vacía', () {
      // Arrange
      final user = User(
        id: '123',
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        permissions: [],
      );
      
      // Act & Assert
      expect(user.hasPermission('read_notes'), false);
      expect(user.hasAllPermissions(['read_notes']), false);
      expect(user.hasAnyPermission(['read_notes']), false);
    });

    test('debe prevenir escalación de privilegios', () {
      // Arrange
      final json = {
        'id': '123',
        'username': 'testuser',
        'email': 'test@example.com',
        'createdAt': DateTime.now().toIso8601String(),
        'permissions': ['read_notes'],
      };
      
      // Act
      final user = User.fromJson(json);
      
      // Intentar agregar permisos no debe ser posible
      // ya que la lista es inmutable
      expect(() {
        user.permissions.add('admin');
      }, throwsUnsupportedError);
    });
  });

  group('User Model - OWASP M10: Funcionalidad Superflua', () {
    test('no debe incluir información sensible innecesaria', () {
      // Arrange
      final json = {
        'id': '123',
        'username': 'testuser',
        'email': 'test@example.com',
        'createdAt': DateTime.now().toIso8601String(),
        'permissions': ['read_notes'],
        // Estos campos no deberían ser procesados
        'password': 'should_not_be_included',
        'creditCard': '1234-5678-9012-3456',
        'ssn': '123-45-6789',
      };
      
      // Act
      final user = User.fromJson(json);
      final serialized = user.toJson();
      
      // Assert
      expect(serialized.containsKey('password'), false);
      expect(serialized.containsKey('creditCard'), false);
      expect(serialized.containsKey('ssn'), false);
    });

    test('debe incluir solo campos necesarios en serialización', () {
      // Arrange
      final user = User(
        id: '123',
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        permissions: ['read_notes'],
      );
      
      // Act
      final json = user.toJson();
      
      // Assert
      expect(json.keys.length, equals(5)); // Solo 5 campos
      expect(json.keys, containsAll(['id', 'username', 'email', 'createdAt', 'permissions']));
    });
  });
}

/// VULNERABILIDADES MITIGADAS:
/// - M6: Autorización insegura - Tests de permisos y control de acceso
/// - M7: Mala calidad del código - Tests de validación y sanitización
/// - M10: Funcionalidad superflua - Tests que verifican no exponer datos innecesarios
/// 
/// HERRAMIENTAS DE PENTESTING MITIGADAS:
/// - Burp Suite: Los tests verifican sanitización contra XSS
/// - SQLMap: Los tests verifican eliminación de caracteres peligrosos
/// - OWASP ZAP: Los tests verifican validación de entrada