import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:pointycastle/export.dart';

/// MITIGACIÓN M1: Credenciales débiles
/// MITIGACIÓN M4: Autenticación insegura
/// MITIGACIÓN M5: Criptografía insuficiente
/// 
/// Esta clase implementa configuraciones de seguridad robustas para evitar:
/// - M1: Uso de credenciales débiles mediante validación de contraseñas fuertes
/// - M4: Autenticación insegura mediante hashing seguro y salt
/// - M5: Criptografía insuficiente mediante AES-256 y claves seguras
class SecurityConfig {
  static const int minPasswordLength = 12;
  static const int saltLength = 32;
  static const int keyLength = 32;
  static const int pbkdf2Iterations = 100000;
  
  /// Valida la fortaleza de la contraseña
  /// Evita M1: Credenciales débiles
  static bool isPasswordStrong(String password) {
    if (password.length < minPasswordLength) return false;
    
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasUpperCase && hasLowerCase && hasDigits && hasSpecialChars;
  }
  
  /// Genera un salt aleatorio criptográficamente seguro
  /// Evita M4: Autenticación insegura
  static String generateSalt() {
    final random = Random.secure();
    final salt = List<int>.generate(saltLength, (i) => random.nextInt(256));
    return base64.encode(salt);
  }
  
  /// Hash de contraseña usando PBKDF2
  /// Evita M4: Autenticación insegura
  static String hashPassword(String password, String salt) {
    final saltBytes = base64.decode(salt);
    final passwordBytes = utf8.encode(password);
    
    // Usar PBKDF2 con HMAC-SHA256
    final params = Pbkdf2Parameters(
      Uint8List.fromList(saltBytes),
      pbkdf2Iterations,
      32, // 256 bits
    );
    
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(params);
    
    final key = Uint8List(32);
    pbkdf2.deriveKey(passwordBytes, 0, key, 0);
    
    return base64.encode(key);
  }
  
  /// Genera una clave de cifrado segura
  /// Evita M5: Criptografía insuficiente
  static encrypt_pkg.Key generateEncryptionKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(keyLength, (i) => random.nextInt(256));
    return encrypt_pkg.Key.fromBase64(base64.encode(keyBytes));
  }
  
  /// Cifra datos sensibles usando AES-256
  /// Evita M5: Criptografía insuficiente
  static String encryptData(String plainText, encrypt_pkg.Key key) {
    final iv = encrypt_pkg.IV.fromSecureRandom(16);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Incluye el IV con el texto cifrado
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }
  
  /// Descifra datos usando AES-256
  /// Evita M5: Criptografía insuficiente
  static String decryptData(String encryptedData, encrypt_pkg.Key key) {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid encrypted data format');
    }
    
    final iv = encrypt_pkg.IV.fromBase64(parts[0]);
    final encrypted = encrypt_pkg.Encrypted.fromBase64(parts[1]);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc));
    
    return encrypter.decrypt(encrypted, iv: iv);
  }
  
  /// Validación de entrada para prevenir inyecciones
  /// Evita M7: Mala calidad del código
  static String sanitizeInput(String input) {
    // Primero, detectamos patrones maliciosos comunes
    final dangerousPatterns = [
      // SQL Injection patterns
      RegExp(r"('|(--|#)|(/\*)|(\*/)|(\|\|)|(\\))", caseSensitive: false),
      RegExp(r'(DROP|DELETE|INSERT|UPDATE|SELECT|UNION|WHERE|FROM)\s', caseSensitive: false),
      RegExp(r'(;|--)', caseSensitive: false),
      
      // XSS patterns
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // onclick, onload, etc.
      RegExp(r'<[^>]*>', caseSensitive: false), // Any HTML tags
      
      // Path traversal
      RegExp(r'\.\./', caseSensitive: false),
      RegExp(r'\.\.\\', caseSensitive: false),
      
      // Command injection
      RegExp(r'[;&|`$]', caseSensitive: false),
    ];
    
    // Si detectamos algún patrón peligroso, rechazamos completamente la entrada
    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        // En producción, podríamos loggear este intento
        return ''; // Retornamos string vacío para inputs maliciosos
      }
    }
    
    // Si pasa las validaciones, aplicamos sanitización adicional
    return input
        .replaceAll(RegExp(r'[<>]'), '') // Elimina < y > restantes
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '') // Elimina caracteres de control
        .trim();
  }
}

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M1: Permitir contraseñas como "123456" o "password"
/// - M4: Almacenar contraseñas en texto plano o con MD5/SHA1
/// - M5: Usar cifrado débil como DES o claves hardcodeadas
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - Hydra/Medusa: Para ataques de fuerza bruta contra credenciales débiles
/// - John the Ripper: Para crackear hashes débiles
/// - MobSF: Para analizar la implementación de criptografía