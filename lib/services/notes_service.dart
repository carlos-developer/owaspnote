import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import '../models/note.dart';
import '../models/user.dart';
import '../security/security_config.dart';
import '../security/certificate_pinning.dart';
import '../security/secure_storage.dart';

/// Servicio para gestión segura de notas
class NotesService {
  static Dio? _dio;
  static late encrypt_pkg.Key _encryptionKey;
  
  /// Inicializa el servicio
  static Future<void> initialize() async {
    _dio = await CertificatePinningConfig.getSecureHttpClient();
    
    // Obtiene o genera clave de cifrado
    final storedKey = await SecureStorageManager.getSecureData('encryption_key');
    if (storedKey != null) {
      _encryptionKey = encrypt_pkg.Key.fromBase64(storedKey);
    } else {
      _encryptionKey = SecurityConfig.generateEncryptionKey();
      await SecureStorageManager.storeSecureData(
        'encryption_key',
        _encryptionKey.base64,
      );
    }
  }
  
  /// Obtiene las notas del usuario con verificación de permisos
  /// MITIGACIÓN M6: Autorización insegura
  static Future<List<Note>> getUserNotes(User currentUser) async {
    // Verifica permisos del usuario
    if (!currentUser.hasPermission('read_notes')) {
      throw AuthorizationException('User does not have permission to read notes');
    }
    
    final token = await SessionManager.getValidAuthToken();
    if (token == null) {
      throw AuthException('Session expired');
    }
    
    try {
      final response = await _dio!.get(
        '/notes',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-User-Id': currentUser.id,
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> notesJson = response.data['notes'];
        final notes = notesJson.map((json) {
          final note = Note.fromJson(json);
          
          // Descifra notas cifradas
          if (note.isEncrypted) {
            return _decryptNote(note);
          }
          return note;
        }).toList();
        
        return notes;
      } else {
        throw ServiceException('Failed to fetch notes');
      }
    } catch (e) {
      throw ServiceException('Error fetching notes: ${e.toString()}');
    }
  }
  
  /// Crea una nueva nota con cifrado
  /// MITIGACIÓN M5: Criptografía insuficiente
  static Future<Note> createNote({
    required User currentUser,
    required String title,
    required String content,
    bool encrypt = true,
  }) async {
    // Verifica permisos
    if (!currentUser.hasPermission('create_notes')) {
      throw AuthorizationException('User does not have permission to create notes');
    }
    
    final token = await SessionManager.getValidAuthToken();
    if (token == null) {
      throw AuthException('Session expired');
    }
    
    // Sanitiza entrada
    final sanitizedTitle = SecurityConfig.sanitizeInput(title);
    final sanitizedContent = SecurityConfig.sanitizeInput(content);
    
    String finalContent = sanitizedContent;
    bool isEncrypted = false;
    
    // Cifra contenido sensible
    if (encrypt && sanitizedContent.isNotEmpty) {
      finalContent = SecurityConfig.encryptData(sanitizedContent, _encryptionKey);
      isEncrypted = true;
    }
    
    try {
      final noteData = {
        'title': sanitizedTitle,
        'content': finalContent,
        'isEncrypted': isEncrypted,
        'userId': currentUser.id,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Calcula hash para integridad
      final tempNote = Note(
        id: 'temp',
        userId: currentUser.id,
        title: sanitizedTitle,
        content: sanitizedContent, // Usa contenido sin cifrar para hash
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      noteData['contentHash'] = tempNote.calculateContentHash();
      
      final response = await _dio!.post(
        '/notes',
        data: noteData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-User-Id': currentUser.id,
          },
        ),
      );
      
      if (response.statusCode == 201) {
        final note = Note.fromJson(response.data['note']);
        return note;
      } else {
        throw ServiceException('Failed to create note');
      }
    } catch (e) {
      throw ServiceException('Error creating note: ${e.toString()}');
    }
  }
  
  /// Actualiza una nota existente
  /// MITIGACIÓN M6: Autorización insegura
  static Future<Note> updateNote({
    required User currentUser,
    required String noteId,
    required String title,
    required String content,
    bool encrypt = true,
  }) async {
    // Verifica permisos
    if (!currentUser.hasPermission('update_notes')) {
      throw AuthorizationException('User does not have permission to update notes');
    }
    
    final token = await SessionManager.getValidAuthToken();
    if (token == null) {
      throw AuthException('Session expired');
    }
    
    // Primero verifica que el usuario sea dueño de la nota
    final existingNote = await _getNoteById(noteId, currentUser);
    if (existingNote.userId != currentUser.id) {
      throw AuthorizationException('Cannot update notes from other users');
    }
    
    // Proceso similar a createNote...
    final sanitizedTitle = SecurityConfig.sanitizeInput(title);
    final sanitizedContent = SecurityConfig.sanitizeInput(content);
    
    String finalContent = sanitizedContent;
    bool isEncrypted = false;
    
    if (encrypt && sanitizedContent.isNotEmpty) {
      finalContent = SecurityConfig.encryptData(sanitizedContent, _encryptionKey);
      isEncrypted = true;
    }
    
    try {
      final response = await _dio!.put(
        '/notes/$noteId',
        data: {
          'title': sanitizedTitle,
          'content': finalContent,
          'isEncrypted': isEncrypted,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-User-Id': currentUser.id,
          },
        ),
      );
      
      if (response.statusCode == 200) {
        return Note.fromJson(response.data['note']);
      } else {
        throw ServiceException('Failed to update note');
      }
    } catch (e) {
      throw ServiceException('Error updating note: ${e.toString()}');
    }
  }
  
  /// Elimina una nota
  /// MITIGACIÓN M6: Autorización insegura
  static Future<void> deleteNote({
    required User currentUser,
    required String noteId,
  }) async {
    // Verifica permisos
    if (!currentUser.hasPermission('delete_notes')) {
      throw AuthorizationException('User does not have permission to delete notes');
    }
    
    final token = await SessionManager.getValidAuthToken();
    if (token == null) {
      throw AuthException('Session expired');
    }
    
    // Verifica propiedad de la nota
    final existingNote = await _getNoteById(noteId, currentUser);
    if (existingNote.userId != currentUser.id) {
      throw AuthorizationException('Cannot delete notes from other users');
    }
    
    try {
      final response = await _dio!.delete(
        '/notes/$noteId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-User-Id': currentUser.id,
          },
        ),
      );
      
      if (response.statusCode != 204) {
        throw ServiceException('Failed to delete note');
      }
    } catch (e) {
      throw ServiceException('Error deleting note: ${e.toString()}');
    }
  }
  
  /// Obtiene una nota por ID
  static Future<Note> _getNoteById(String noteId, User currentUser) async {
    final token = await SessionManager.getValidAuthToken();
    if (token == null) {
      throw AuthException('Session expired');
    }
    
    final response = await _dio!.get(
      '/notes/$noteId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'X-User-Id': currentUser.id,
        },
      ),
    );
    
    if (response.statusCode == 200) {
      return Note.fromJson(response.data['note']);
    } else {
      throw ServiceException('Note not found');
    }
  }
  
  /// Descifra una nota
  static Note _decryptNote(Note encryptedNote) {
    try {
      final decryptedContent = SecurityConfig.decryptData(
        encryptedNote.content,
        _encryptionKey,
      );
      
      return encryptedNote.copyWith(
        content: decryptedContent,
        isEncrypted: false,
      );
    } catch (e) {
      throw ServiceException('Failed to decrypt note');
    }
  }
}

class ServiceException implements Exception {
  final String message;
  ServiceException(this.message);
  
  @override
  String toString() => message;
}

class AuthorizationException implements Exception {
  final String message;
  AuthorizationException(this.message);
  
  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M5: Almacenar notas en texto plano
/// - M6: No verificar permisos antes de operaciones CRUD
/// - M6: Permitir acceso a notas de otros usuarios
/// - M7: No sanitizar entrada de usuario
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - SQLMap: Para inyección SQL en endpoints
/// - Burp Suite: Para manipular requests y bypass autorización
/// - OWASP ZAP: Para fuzzing de parámetros
/// - Postman: Para probar diferentes escenarios de autorización