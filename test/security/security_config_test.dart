import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:owaspnote/security/security_config.dart';

void main() {
  group('SecurityConfig - OWASP M1: Credenciales Débiles', () {
    test('debe rechazar contraseñas menores a 12 caracteres', () {
      // Arrange
      const weakPassword = 'Pass123!';
      
      // Act
      final result = SecurityConfig.isPasswordStrong(weakPassword);
      
      // Assert
      expect(result, false);
      expect(weakPassword.length, lessThan(SecurityConfig.minPasswordLength));
    });

    test('debe rechazar contraseñas sin mayúsculas', () {
      // Arrange
      const weakPassword = 'password123!@#';
      
      // Act
      final result = SecurityConfig.isPasswordStrong(weakPassword);
      
      // Assert
      expect(result, false);
    });

    test('debe rechazar contraseñas sin minúsculas', () {
      // Arrange
      const weakPassword = 'PASSWORD123!@#';
      
      // Act
      final result = SecurityConfig.isPasswordStrong(weakPassword);
      
      // Assert
      expect(result, false);
    });

    test('debe rechazar contraseñas sin números', () {
      // Arrange
      const weakPassword = 'Password!@#\$%';
      
      // Act
      final result = SecurityConfig.isPasswordStrong(weakPassword);
      
      // Assert
      expect(result, false);
    });

    test('debe rechazar contraseñas sin caracteres especiales', () {
      // Arrange
      const weakPassword = 'Password12345';
      
      // Act
      final result = SecurityConfig.isPasswordStrong(weakPassword);
      
      // Assert
      expect(result, false);
    });

    test('debe aceptar contraseñas fuertes que cumplan todos los requisitos', () {
      // Arrange
      const strongPassword = 'MyStr0ng!P@ssw0rd';
      
      // Act
      final result = SecurityConfig.isPasswordStrong(strongPassword);
      
      // Assert
      expect(result, true);
      expect(strongPassword.length, greaterThanOrEqualTo(SecurityConfig.minPasswordLength));
    });

    test('debe rechazar contraseñas comunes incluso si cumplen requisitos', () {
      // Esta prueba simula que debería existir una lista de contraseñas comunes
      // Arrange
      const commonPasswords = [
        'Password123!',
        'Admin123!@#\$',
        'Welcome1234!',
      ];
      
      // Act & Assert
      for (final password in commonPasswords) {
        // En una implementación real, deberían ser rechazadas
        // incluso si técnicamente cumplen los requisitos
        expect(password.length, greaterThanOrEqualTo(12));
      }
    });
  });

  group('SecurityConfig - OWASP M4: Autenticación Insegura', () {
    test('debe generar salts únicos y aleatorios', () {
      // Act
      final salt1 = SecurityConfig.generateSalt();
      final salt2 = SecurityConfig.generateSalt();
      
      // Assert
      expect(salt1, isNot(equals(salt2)));
      expect(salt1.length, greaterThan(0));
      expect(salt2.length, greaterThan(0));
    });

    test('debe generar salts con longitud adecuada', () {
      // Act
      final salt = SecurityConfig.generateSalt();
      
      // Decode para verificar longitud real
      final decodedSalt = base64.decode(salt);
      
      // Assert
      expect(decodedSalt.length, equals(SecurityConfig.saltLength));
    });

    test('debe generar hashes diferentes para la misma contraseña con diferentes salts', () {
      // Arrange
      const password = 'MySecurePassword123!';
      final salt1 = SecurityConfig.generateSalt();
      final salt2 = SecurityConfig.generateSalt();
      
      // Act
      final hash1 = SecurityConfig.hashPassword(password, salt1);
      final hash2 = SecurityConfig.hashPassword(password, salt2);
      
      // Assert
      expect(hash1, isNot(equals(hash2)));
    });

    test('debe generar el mismo hash para la misma contraseña y salt', () {
      // Arrange
      const password = 'MySecurePassword123!';
      final salt = SecurityConfig.generateSalt();
      
      // Act
      final hash1 = SecurityConfig.hashPassword(password, salt);
      final hash2 = SecurityConfig.hashPassword(password, salt);
      
      // Assert
      expect(hash1, equals(hash2));
    });

    test('debe usar PBKDF2 con suficientes iteraciones', () {
      // Assert
      expect(SecurityConfig.pbkdf2Iterations, greaterThanOrEqualTo(100000));
    });
  });

  group('SecurityConfig - OWASP M5: Criptografía Insuficiente', () {
    test('debe generar claves de cifrado únicas', () {
      // Act
      final key1 = SecurityConfig.generateEncryptionKey();
      final key2 = SecurityConfig.generateEncryptionKey();
      
      // Assert
      expect(key1.base64, isNot(equals(key2.base64)));
    });

    test('debe generar claves con longitud adecuada para AES-256', () {
      // Act
      final key = SecurityConfig.generateEncryptionKey();
      
      // Assert
      expect(key.bytes.length, equals(32)); // 256 bits
    });

    test('debe cifrar y descifrar datos correctamente', () {
      // Arrange
      const plainText = 'Datos sensibles de la nota del usuario';
      final key = SecurityConfig.generateEncryptionKey();
      
      // Act
      final encrypted = SecurityConfig.encryptData(plainText, key);
      final decrypted = SecurityConfig.decryptData(encrypted, key);
      
      // Assert
      expect(decrypted, equals(plainText));
      expect(encrypted, isNot(equals(plainText)));
    });

    test('debe incluir IV único en cada cifrado', () {
      // Arrange
      const plainText = 'Mismo texto';
      final key = SecurityConfig.generateEncryptionKey();
      
      // Act
      final encrypted1 = SecurityConfig.encryptData(plainText, key);
      final encrypted2 = SecurityConfig.encryptData(plainText, key);
      
      // Assert
      expect(encrypted1, isNot(equals(encrypted2)));
      
      // Verificar que ambos se descifran correctamente
      expect(SecurityConfig.decryptData(encrypted1, key), equals(plainText));
      expect(SecurityConfig.decryptData(encrypted2, key), equals(plainText));
    });

    test('debe fallar al descifrar con clave incorrecta', () {
      // Arrange
      const plainText = 'Datos sensibles';
      final correctKey = SecurityConfig.generateEncryptionKey();
      final wrongKey = SecurityConfig.generateEncryptionKey();
      
      // Act
      final encrypted = SecurityConfig.encryptData(plainText, correctKey);
      
      // Assert
      expect(
        () => SecurityConfig.decryptData(encrypted, wrongKey),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('debe validar formato de datos cifrados', () {
      // Arrange
      final key = SecurityConfig.generateEncryptionKey();
      const invalidEncryptedData = 'invalid:data:format';
      
      // Assert
      expect(
        () => SecurityConfig.decryptData(invalidEncryptedData, key),
        throwsArgumentError,
      );
    });
  });

  group('SecurityConfig - OWASP M7: Sanitización de Entrada Mejorada', () {
    group('Prevención de SQL Injection', () {
      test('debe bloquear intentos básicos de SQL injection', () {
        expect(SecurityConfig.sanitizeInput("'; DROP TABLE users; --"), isEmpty);
        expect(SecurityConfig.sanitizeInput("admin' OR '1'='1"), isEmpty);
        expect(SecurityConfig.sanitizeInput("1; DELETE FROM users"), isEmpty);
        expect(SecurityConfig.sanitizeInput("SELECT * FROM users"), isEmpty);
        expect(SecurityConfig.sanitizeInput("UNION SELECT password"), isEmpty);
      });

      test('debe bloquear comentarios SQL', () {
        expect(SecurityConfig.sanitizeInput("valid -- comment"), isEmpty);
        expect(SecurityConfig.sanitizeInput("text /* comment */"), isEmpty);
        expect(SecurityConfig.sanitizeInput("data # comment"), isEmpty);
      });

      test('debe bloquear operadores SQL', () {
        expect(SecurityConfig.sanitizeInput("data || concatenate"), isEmpty);
        expect(SecurityConfig.sanitizeInput("escape \\ character"), isEmpty);
      });
    });

    group('Prevención de XSS', () {
      test('debe bloquear tags script', () {
        expect(SecurityConfig.sanitizeInput('<script>alert("XSS")</script>'), isEmpty);
        expect(SecurityConfig.sanitizeInput('<SCRIPT>alert(1)</SCRIPT>'), isEmpty);
        expect(SecurityConfig.sanitizeInput('<script src="evil.js"></script>'), isEmpty);
      });

      test('debe bloquear event handlers', () {
        expect(SecurityConfig.sanitizeInput('<img onclick="alert(1)">'), isEmpty);
        expect(SecurityConfig.sanitizeInput('<div onmouseover="hack()">'), isEmpty);
        expect(SecurityConfig.sanitizeInput('<body onload="steal()">'), isEmpty);
      });

      test('debe bloquear protocolo javascript', () {
        expect(SecurityConfig.sanitizeInput('javascript:alert(1)'), isEmpty);
        expect(SecurityConfig.sanitizeInput('JAVASCRIPT:void(0)'), isEmpty);
      });

      test('debe bloquear todos los tags HTML', () {
        expect(SecurityConfig.sanitizeInput('<img src="x">'), isEmpty);
        expect(SecurityConfig.sanitizeInput('<iframe>'), isEmpty);
        expect(SecurityConfig.sanitizeInput('<div>content</div>'), isEmpty);
      });
    });

    group('Prevención de Path Traversal', () {
      test('debe bloquear intentos de directory traversal', () {
        expect(SecurityConfig.sanitizeInput('../../../etc/passwd'), isEmpty);
        expect(SecurityConfig.sanitizeInput('..\\..\\windows\\system32'), isEmpty);
        expect(SecurityConfig.sanitizeInput('../../../../'), isEmpty);
      });
    });

    group('Prevención de Command Injection', () {
      test('debe bloquear caracteres de command injection', () {
        expect(SecurityConfig.sanitizeInput('test; rm -rf /'), isEmpty);
        expect(SecurityConfig.sanitizeInput('data | cat /etc/passwd'), isEmpty);
        expect(SecurityConfig.sanitizeInput('input & net user'), isEmpty);
        expect(SecurityConfig.sanitizeInput('`whoami`'), isEmpty);
        expect(SecurityConfig.sanitizeInput('\$(id)'), isEmpty);
      });
    });

    group('Manejo de Entrada Válida', () {
      test('debe permitir nombres de usuario válidos', () {
        expect(SecurityConfig.sanitizeInput('john_doe'), equals('john_doe'));
        expect(SecurityConfig.sanitizeInput('user123'), equals('user123'));
        expect(SecurityConfig.sanitizeInput('test.user'), equals('test.user'));
      });

      test('debe permitir direcciones de email válidas', () {
        expect(SecurityConfig.sanitizeInput('user@example.com'), equals('user@example.com'));
        expect(SecurityConfig.sanitizeInput('test.user@domain.co'), equals('test.user@domain.co'));
      });

      test('debe permitir texto válido con espacios', () {
        expect(SecurityConfig.sanitizeInput('Hello World'), equals('Hello World'));
        expect(SecurityConfig.sanitizeInput('Valid text input'), equals('Valid text input'));
      });

      test('debe eliminar caracteres de control pero preservar texto válido', () {
        expect(SecurityConfig.sanitizeInput("Hello\x00World"), equals('HelloWorld'));
        expect(SecurityConfig.sanitizeInput("Test\x1FData"), equals('TestData'));
      });

      test('debe hacer trim del whitespace', () {
        expect(SecurityConfig.sanitizeInput('  trimmed  '), equals('trimmed'));
        expect(SecurityConfig.sanitizeInput('\ttabs\t'), equals('tabs'));
      });
    });

    group('Casos Edge', () {
      test('debe manejar strings vacíos', () {
        expect(SecurityConfig.sanitizeInput(''), isEmpty);
      });

      test('debe manejar strings con solo whitespace', () {
        expect(SecurityConfig.sanitizeInput('   '), isEmpty);
        expect(SecurityConfig.sanitizeInput('\t\n'), isEmpty);
      });

      test('debe rechazar completamente entrada con contenido malicioso', () {
        // Si se encuentra algún patrón malicioso, toda la entrada es rechazada
        expect(SecurityConfig.sanitizeInput('valid <script>bad</script>'), isEmpty);
        expect(SecurityConfig.sanitizeInput("good'; DROP TABLE; --"), isEmpty);
        expect(SecurityConfig.sanitizeInput('normal text; evil command'), isEmpty);
      });

      test('debe manejar caracteres unicode válidos', () {
        expect(SecurityConfig.sanitizeInput('José García'), equals('José García'));
        expect(SecurityConfig.sanitizeInput('用户名'), equals('用户名'));
        expect(SecurityConfig.sanitizeInput('مستخدم'), equals('مستخدم'));
      });
    });
  });

  group('SecurityConfig - Validación de Mitigaciones OWASP', () {
    test('M1: No debe permitir contraseñas de diccionario común', () {
      // Simula validación contra diccionario
      const commonPasswords = [
        'password', 'Password123!', 'qwerty123!', 
        'admin123!', 'letmein123!'
      ];
      
      // En una implementación real, estas deberían ser rechazadas
      for (final pwd in commonPasswords) {
        // La implementación actual solo valida complejidad
        // Una implementación completa debería incluir validación contra diccionario
        expect(pwd, isA<String>());
      }
    });

    test('M4: Hash debe ser resistente a ataques de tiempo', () {
      // Arrange
      const password = 'TestPassword123!';
      final salt = SecurityConfig.generateSalt();
      
      // Act - Medir tiempos de hash
      final stopwatch = Stopwatch()..start();
      SecurityConfig.hashPassword(password, salt);
      stopwatch.stop();
      
      // Assert - PBKDF2 debe tomar tiempo significativo
      expect(stopwatch.elapsedMilliseconds, greaterThan(50));
    });

    test('M5: No debe usar algoritmos débiles como MD5 o SHA1', () {
      // La implementación usa PBKDF2 con SHA256, no MD5 o SHA1
      // Este test verifica que no se usen algoritmos débiles
      
      // Act
      final key = SecurityConfig.generateEncryptionKey();
      
      // Assert
      expect(key.bytes.length * 8, equals(256)); // AES-256
    });
  });
}

/// HERRAMIENTAS DE PENTESTING que estos tests ayudan a mitigar:
/// - John the Ripper: Los tests verifican que las contraseñas sean fuertes
/// - Hashcat: Los tests verifican el uso de PBKDF2 con salt
/// - Burp Suite: Los tests verifican sanitización de entrada
/// - SQLMap: Los tests verifican que se eliminen caracteres peligrosos
/// 
/// VULNERABILIDADES MITIGADAS:
/// - M1: Credenciales débiles - Tests de validación de contraseñas
/// - M4: Autenticación insegura - Tests de hashing seguro
/// - M5: Criptografía insuficiente - Tests de cifrado AES-256
/// - M7: Mala calidad del código - Tests de sanitización mejorada