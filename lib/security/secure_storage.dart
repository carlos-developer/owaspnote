import 'dart:convert';
import 'package:crypto/crypto.dart';

// Conditional imports
import 'secure_storage_stub.dart'
    if (dart.library.io) 'secure_storage_mobile.dart';

/// MITIGACIÓN M5: Criptografía insuficiente
/// MITIGACIÓN M6: Autorización insegura
/// 
/// Manejo seguro de almacenamiento local con cifrado
class SecureStorageManager {
  
  /// Almacena datos sensibles de forma segura
  /// Evita M5: Criptografía insuficiente
  static Future<void> storeSecureData(String key, String value) async {
    try {
      // Validación de entrada
      if (key.isEmpty || value.isEmpty) {
        throw ArgumentError('Key and value cannot be empty');
      }
      
      // Añade metadata de seguridad
      final metadata = {
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      final jsonData = jsonEncode(metadata);
      await SecureStorageImpl.write(key: key, value: jsonData);
    } catch (e) {
      throw StorageException('Failed to store secure data: $e');
    }
  }
  
  /// Recupera datos sensibles de forma segura
  /// Evita M5: Criptografía insuficiente
  static Future<String?> getSecureData(String key) async {
    try {
      final jsonData = await SecureStorageImpl.read(key: key);
      if (jsonData == null) return null;
      
      final metadata = jsonDecode(jsonData) as Map<String, dynamic>;
      
      // Valida la versión
      if (metadata['version'] != '1.0') {
        throw StorageException('Unsupported data version');
      }
      
      return metadata['value'] as String;
    } catch (e) {
      throw StorageException('Failed to retrieve secure data: $e');
    }
  }
  
  /// Elimina datos sensibles de forma segura
  static Future<void> deleteSecureData(String key) async {
    await SecureStorageImpl.delete(key: key);
  }
  
  /// Limpia todos los datos almacenados
  static Future<void> clearAllSecureData() async {
    await SecureStorageImpl.deleteAll();
  }
}

/// MITIGACIÓN M6: Autorización insegura
/// 
/// Gestión segura de tokens y sesiones
class SessionManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _sessionKey = 'session_data';
  static const int tokenExpiryMinutes = 15;
  
  /// Almacena token de autenticación con expiración
  /// Evita M6: Autorización insegura
  static Future<void> storeAuthToken(String token, String refreshToken) async {
    final tokenData = {
      'token': token,
      'refreshToken': refreshToken,
      'expiresAt': DateTime.now()
          .add(Duration(minutes: tokenExpiryMinutes))
          .toIso8601String(),
      'tokenHash': _hashToken(token),
    };
    
    await SecureStorageManager.storeSecureData(
      _tokenKey,
      jsonEncode(tokenData),
    );
  }
  
  /// Valida y recupera el token si no ha expirado
  /// Evita M6: Autorización insegura
  static Future<String?> getValidAuthToken() async {
    try {
      final data = await SecureStorageManager.getSecureData(_tokenKey);
      if (data == null) return null;
      
      final tokenData = jsonDecode(data) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(tokenData['expiresAt'] as String);
      
      // Verifica expiración
      if (DateTime.now().isAfter(expiresAt)) {
        await clearSession();
        return null;
      }
      
      final token = tokenData['token'] as String;
      final storedHash = tokenData['tokenHash'] as String;
      
      // Verifica integridad del token
      if (_hashToken(token) != storedHash) {
        await clearSession();
        throw SecurityException('Token integrity check failed');
      }
      
      return token;
    } catch (e) {
      await clearSession();
      return null;
    }
  }
  
  /// Limpia la sesión del usuario
  static Future<void> clearSession() async {
    await SecureStorageManager.deleteSecureData(_tokenKey);
    await SecureStorageManager.deleteSecureData(_refreshTokenKey);
    await SecureStorageManager.deleteSecureData(_sessionKey);
  }
  
  /// Hash del token para verificar integridad
  static String _hashToken(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Almacena datos de sesión del usuario
  /// Evita M10: Funcionalidad superflua
  static Future<void> storeSessionData(Map<String, dynamic> userData) async {
    // Solo almacena datos necesarios, no información superflua
    final minimalData = {
      'userId': userData['userId'],
      'username': userData['username'],
      'permissions': userData['permissions'],
      // NO almacenar: contraseñas, datos bancarios, información personal sensible
    };
    
    await SecureStorageManager.storeSecureData(
      _sessionKey,
      jsonEncode(minimalData),
    );
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  
  @override
  String toString() => 'StorageException: $message';
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M5: Almacenar datos en SharedPreferences sin cifrar
/// - M6: Tokens sin expiración o validación
/// - M10: Almacenar datos innecesarios del usuario
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - ADB: Para examinar SharedPreferences no cifradas
/// - Device File Explorer: Para acceder a archivos de la app
/// - Objection: Para runtime manipulation
/// - Root Explorer: Para acceder a datos en dispositivos rooteados