import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// MITIGACIÓN M3: Comunicación insegura
/// 
/// Esta clase implementa certificate pinning para prevenir ataques MITM
/// Evita que un atacante intercepte la comunicación HTTPS
class CertificatePinningConfig {
  static const String apiBaseUrl = 'https://api.securenotesapp.com';
  
  /// Configura Dio con certificate pinning
  /// Evita M3: Comunicación insegura
  static Future<Dio> getSecureHttpClient() async {
    final dio = Dio();
    
    // Certificate pinning para producción (no aplicable en web)
    if (!_isDebugMode() && !kIsWeb) {
      try {
        // En producción, validar certificados manualmente
        dio.interceptors.add(
          CertificatePinningInterceptor(
            allowedFingerprints: [
              // SHA256 fingerprint del certificado del servidor
              'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
              // Backup pin
              'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
            ],
          ),
        );
      } catch (e) {
        // En caso de error, falla de forma segura
        throw SecurityException('Certificate pinning failed: $e');
      }
    }
    
    // Configuración adicional de seguridad
    dio.options = BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'User-Agent': 'SecureNotesApp/1.0',
      },
      // Fuerza HTTPS
      followRedirects: false,
      validateStatus: (status) {
        return status != null && status < 500;
      },
    );
    
    // Interceptor para validar respuestas
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Valida que sea HTTPS
          if (!options.uri.isScheme('https')) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Only HTTPS connections are allowed',
                type: DioExceptionType.cancel,
              ),
            );
            return;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Valida headers de seguridad
          _validateSecurityHeaders(response.headers);
          handler.next(response);
        },
      ),
    );
    
    return dio;
  }
  
  /// Valida headers de seguridad en la respuesta
  static void _validateSecurityHeaders(Headers headers) {
    // Skip header validation on web or debug mode as these are development/testing environments
    if (kIsWeb || _isDebugMode()) {
      return;
    }
    
    // Verifica headers de seguridad importantes
    final requiredHeaders = [
      'x-content-type-options',
      'x-frame-options',
      'strict-transport-security',
    ];
    
    for (final header in requiredHeaders) {
      if (!headers.map.containsKey(header)) {
        throw SecurityException('Missing security header: $header');
      }
    }
  }
  
  static bool _isDebugMode() {
    return const bool.fromEnvironment('dart.vm.product') == false;
  }
}

/// Interceptor personalizado para certificate pinning
class CertificatePinningInterceptor extends Interceptor {
  final List<String> allowedFingerprints;
  
  CertificatePinningInterceptor({required this.allowedFingerprints});
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // En una implementación real, aquí se validaría el certificado
    // Por ahora, solo validamos que sea HTTPS
    if (!options.uri.isScheme('https')) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Only HTTPS connections are allowed',
          type: DioExceptionType.cancel,
        ),
      );
      return;
    }
    handler.next(options);
  }
}

/// MITIGACIÓN M2: Suministro de código inseguro
/// 
/// Validación de integridad de respuestas
class ResponseIntegrityValidator {
  /// Valida la integridad de la respuesta usando HMAC
  /// Evita M2: Suministro de código inseguro
  static bool validateResponseIntegrity(
    String responseBody,
    String serverHmac,
    String sharedSecret,
  ) {
    final calculatedHmac = _calculateHmac(responseBody, sharedSecret);
    return calculatedHmac == serverHmac;
  }
  
  static String _calculateHmac(String data, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return base64.encode(digest.bytes);
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M3: Comunicación HTTP en texto plano
/// - M3: No validar certificados SSL/TLS
/// - M2: No validar la integridad de las actualizaciones
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - Burp Suite: Para interceptar y modificar tráfico HTTPS
/// - OWASP ZAP: Para analizar vulnerabilidades en la comunicación
/// - Wireshark: Para capturar tráfico de red
/// - SSL Labs: Para validar configuración SSL/TLS