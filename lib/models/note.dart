import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Modelo de nota con validaciones de seguridad
class Note {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEncrypted;
  final String? contentHash; // Para verificar integridad
  
  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isEncrypted = false,
    this.contentHash,
  });
  
  /// MITIGACIÓN M7: Mala calidad del código
  /// Validación estricta y sanitización de datos
  factory Note.fromJson(Map<String, dynamic> json) {
    // Validaciones de tipo y null safety
    if (json['id'] == null || json['id'] is! String) {
      throw FormatException('Invalid note ID');
    }
    
    if (json['userId'] == null || json['userId'] is! String) {
      throw FormatException('Invalid user ID');
    }
    
    if (json['title'] == null || json['title'] is! String) {
      throw FormatException('Invalid title');
    }
    
    if (json['content'] == null || json['content'] is! String) {
      throw FormatException('Invalid content');
    }
    
    final note = Note(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: _sanitizeText(json['title'] as String, maxLength: 100),
      content: _sanitizeText(json['content'] as String, maxLength: 10000),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isEncrypted: json['isEncrypted'] ?? false,
      contentHash: json['contentHash'] as String?,
    );
    
    // Verifica integridad si existe hash
    if (note.contentHash != null && !note.verifyIntegrity()) {
      throw SecurityException('Note integrity check failed');
    }
    
    return note;
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isEncrypted': isEncrypted,
    'contentHash': contentHash ?? calculateContentHash(),
  };
  
  /// Sanitiza texto para prevenir XSS y otros ataques
  static String _sanitizeText(String text, {required int maxLength}) {
    final sanitized = text
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), '') // Elimina todos los tags HTML
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*='), '') // Elimina event handlers
        .trim();
    
    return sanitized.length > maxLength 
        ? sanitized.substring(0, maxLength) 
        : sanitized;
  }
  
  /// Calcula hash del contenido para verificar integridad
  /// MITIGACIÓN M8: Code tampering
  String calculateContentHash() {
    final data = '$id$userId$title$content${createdAt.toIso8601String()}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Verifica la integridad de la nota
  bool verifyIntegrity() {
    if (contentHash == null) return true;
    return contentHash == calculateContentHash();
  }
  
  /// Crea una copia de la nota con contenido actualizado
  Note copyWith({
    String? title,
    String? content,
    bool? isEncrypted,
  }) {
    return Note(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isEncrypted: isEncrypted ?? this.isEncrypted,
      contentHash: null, // Se recalculará
    );
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}