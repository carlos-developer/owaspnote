import 'package:flutter_test/flutter_test.dart';
import 'package:owaspnote/models/note.dart';

void main() {
  group('Note Model - OWASP M7: Mala Calidad del Código', () {
    test('debe sanitizar título eliminando scripts maliciosos', () {
      // Arrange
      final json = {
        'id': 'note123',
        'userId': 'user123',
        'title': '<script>alert("XSS")</script>Mi Nota',
        'content': 'Contenido de la nota',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isEncrypted': false,
      };
      
      // Act
      final note = Note.fromJson(json);
      
      // Assert
      expect(note.title, equals('Mi Nota'));
      expect(note.title.contains('<script>'), false);
      expect(note.title.contains('alert'), false);
    });

    test('debe sanitizar contenido eliminando tags HTML', () {
      // Arrange
      final dangerousContent = '''
        <div onclick="evil()">
          <script>steal_data()</script>
          <img src="x" onerror="alert('XSS')">
          Contenido real de la nota
        </div>
      ''';
      
      final json = {
        'id': 'note123',
        'userId': 'user123',
        'title': 'Nota',
        'content': dangerousContent,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isEncrypted': false,
      };
      
      // Act
      final note = Note.fromJson(json);
      
      // Assert
      expect(note.content.contains('<script>'), false);
      expect(note.content.contains('<div'), false);
      expect(note.content.contains('onclick'), false);
      expect(note.content.contains('onerror'), false);
      expect(note.content.contains('Contenido real de la nota'), true);
    });

    test('debe limitar longitud del título a 100 caracteres', () {
      // Arrange
      final longTitle = 'a' * 200;
      final json = {
        'id': 'note123',
        'userId': 'user123',
        'title': longTitle,
        'content': 'Contenido',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isEncrypted': false,
      };
      
      // Act
      final note = Note.fromJson(json);
      
      // Assert
      expect(note.title.length, equals(100));
    });

    test('debe limitar longitud del contenido a 10000 caracteres', () {
      // Arrange
      final longContent = 'a' * 15000;
      final json = {
        'id': 'note123',
        'userId': 'user123',
        'title': 'Nota',
        'content': longContent,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isEncrypted': false,
      };
      
      // Act
      final note = Note.fromJson(json);
      
      // Assert
      expect(note.content.length, equals(10000));
    });

    test('debe validar tipos de datos correctamente', () {
      // Arrange
      final invalidJsons = [
        {
          // ID inválido
          'id': null,
          'userId': 'user123',
          'title': 'Nota',
          'content': 'Contenido',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          // userId no es string
          'id': 'note123',
          'userId': 123,
          'title': 'Nota',
          'content': 'Contenido',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];
      
      // Act & Assert
      for (final json in invalidJsons) {
        expect(
          () => Note.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      }
    });

    test('debe prevenir inyección JavaScript en contenido', () {
      // Arrange
      final jsInjection = '''
        javascript:alert('XSS')
        <a href="javascript:void(0)">Click</a>
        onmouseover="malicious()"
      ''';
      
      final json = {
        'id': 'note123',
        'userId': 'user123',
        'title': 'Nota',
        'content': jsInjection,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isEncrypted': false,
      };
      
      // Act
      final note = Note.fromJson(json);
      
      // Assert
      expect(note.content.contains('javascript:'), false);
      expect(note.content.contains('onmouseover'), false);
    });
  });

  group('Note Model - OWASP M8: Code Tampering', () {
    test('debe calcular hash de contenido correctamente', () {
      // Arrange
      final note = Note(
        id: 'note123',
        userId: 'user123',
        title: 'Mi Nota',
        content: 'Contenido importante',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEncrypted: false,
      );
      
      // Act
      final hash1 = note.calculateContentHash();
      final hash2 = note.calculateContentHash();
      
      // Assert
      expect(hash1, equals(hash2));
      expect(hash1.length, greaterThan(0));
    });

    test('debe detectar modificación de contenido', () {
      // Arrange
      final originalNote = Note(
        id: 'note123',
        userId: 'user123',
        title: 'Mi Nota',
        content: 'Contenido original',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEncrypted: false,
      );
      
      final originalHash = originalNote.calculateContentHash();
      
      // Crear nota con contenido modificado
      final modifiedNote = Note(
        id: 'note123',
        userId: 'user123',
        title: 'Mi Nota',
        content: 'Contenido MODIFICADO', // Contenido alterado
        createdAt: originalNote.createdAt,
        updatedAt: originalNote.updatedAt,
        isEncrypted: false,
        contentHash: originalHash,
      );
      
      // Act & Assert
      expect(modifiedNote.verifyIntegrity(), false);
    });

    test('debe verificar integridad correctamente con hash válido', () {
      // Arrange
      final note = Note(
        id: 'note123',
        userId: 'user123',
        title: 'Mi Nota',
        content: 'Contenido',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEncrypted: false,
      );
      
      final hash = note.calculateContentHash();
      
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
      
      // Act & Assert
      expect(noteWithHash.verifyIntegrity(), true);
    });

    test('debe fallar verificación si se modifica título', () {
      // Arrange
      final originalNote = Note(
        id: 'note123',
        userId: 'user123',
        title: 'Título Original',
        content: 'Contenido',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEncrypted: false,
      );
      
      final hash = originalNote.calculateContentHash();
      
      // Modificar título
      final tamperedNote = Note(
        id: originalNote.id,
        userId: originalNote.userId,
        title: 'Título MODIFICADO',
        content: originalNote.content,
        createdAt: originalNote.createdAt,
        updatedAt: originalNote.updatedAt,
        isEncrypted: originalNote.isEncrypted,
        contentHash: hash,
      );
      
      // Act & Assert
      expect(tamperedNote.verifyIntegrity(), false);
    });

    test('debe lanzar excepción al deserializar nota con integridad comprometida', () {
      // Arrange
      final json = {
        'id': 'note123',
        'userId': 'user123',
        'title': 'Nota',
        'content': 'Contenido',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isEncrypted': false,
        'contentHash': 'INVALID_HASH_12345',
      };
      
      // Act & Assert
      expect(
        () => Note.fromJson(json),
        throwsA(isA<SecurityException>()),
      );
    });
  });

  group('Note Model - OWASP M5: Criptografía Insuficiente', () {
    test('debe marcar correctamente notas cifradas', () {
      // Arrange
      final json = {
        'id': 'note123',
        'userId': 'user123',
        'title': 'Nota Cifrada',
        'content': 'BASE64_ENCRYPTED_CONTENT==',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isEncrypted': true,
      };
      
      // Act
      final note = Note.fromJson(json);
      
      // Assert
      expect(note.isEncrypted, true);
    });

    test('debe preservar estado de cifrado al copiar', () {
      // Arrange
      final encryptedNote = Note(
        id: 'note123',
        userId: 'user123',
        title: 'Nota',
        content: 'ENCRYPTED_CONTENT',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEncrypted: true,
      );
      
      // Act
      final copiedNote = encryptedNote.copyWith(
        title: 'Nuevo Título',
      );
      
      // Assert
      expect(copiedNote.isEncrypted, true);
      expect(copiedNote.title, equals('Nuevo Título'));
      expect(copiedNote.content, equals(encryptedNote.content));
    });

    test('debe actualizar timestamp al copiar con cambios', () {
      // Arrange
      final originalTime = DateTime.now().subtract(Duration(hours: 1));
      final note = Note(
        id: 'note123',
        userId: 'user123',
        title: 'Nota',
        content: 'Contenido',
        createdAt: originalTime,
        updatedAt: originalTime,
        isEncrypted: false,
      );
      
      // Act
      final updatedNote = note.copyWith(content: 'Nuevo contenido');
      
      // Assert
      expect(updatedNote.updatedAt.isAfter(originalTime), true);
      expect(updatedNote.createdAt, equals(originalTime));
    });

    test('debe invalidar hash al copiar con cambios', () {
      // Arrange
      final note = Note(
        id: 'note123',
        userId: 'user123',
        title: 'Nota',
        content: 'Contenido',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEncrypted: false,
        contentHash: 'SOME_HASH',
      );
      
      // Act
      final updatedNote = note.copyWith(content: 'Nuevo contenido');
      
      // Assert
      expect(updatedNote.contentHash, isNull);
    });
  });

  group('Note Model - Serialización segura', () {
    test('debe serializar correctamente a JSON', () {
      // Arrange
      final now = DateTime.now();
      final note = Note(
        id: 'note123',
        userId: 'user123',
        title: 'Mi Nota',
        content: 'Contenido de prueba',
        createdAt: now,
        updatedAt: now,
        isEncrypted: true,
      );
      
      // Act
      final json = note.toJson();
      
      // Assert
      expect(json['id'], equals('note123'));
      expect(json['userId'], equals('user123'));
      expect(json['title'], equals('Mi Nota'));
      expect(json['content'], equals('Contenido de prueba'));
      expect(json['isEncrypted'], equals(true));
      expect(json['contentHash'], isNotNull);
    });

    test('debe incluir hash al serializar', () {
      // Arrange
      final note = Note(
        id: 'note123',
        userId: 'user123',
        title: 'Nota',
        content: 'Contenido',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEncrypted: false,
      );
      
      // Act
      final json = note.toJson();
      
      // Assert
      expect(json['contentHash'], equals(note.calculateContentHash()));
    });
  });
}

/// VULNERABILIDADES MITIGADAS:
/// - M5: Criptografía insuficiente - Tests de manejo de notas cifradas
/// - M7: Mala calidad del código - Tests de sanitización y validación
/// - M8: Code tampering - Tests de integridad con hash
/// 
/// HERRAMIENTAS DE PENTESTING MITIGADAS:
/// - Burp Suite: Prevención de XSS mediante sanitización
/// - SQLMap: Prevención de inyección mediante validación
/// - Tampering tools: Detección de modificaciones con hash