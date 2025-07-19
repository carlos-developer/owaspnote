import 'dart:async';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../security/security_config.dart';
import '../security/certificate_pinning.dart';
import '../security/secure_storage.dart';
import '../security/anti_tampering.dart';
import 'mock_auth_service.dart';

// Conditional imports for biometric auth
import 'biometric_auth_stub.dart'
    if (dart.library.io) 'biometric_auth_mobile.dart';

/// Servicio de autenticación con múltiples capas de seguridad
class AuthService {
  static Dio? _dio;
  static Timer? _sessionTimer;
  static bool _useMockService = false;
  static final MockAuthService _mockService = MockAuthService();
  
  /// Habilita el modo mock para tests
  static void enableMockMode() {
    _useMockService = true;
  }
  
  /// Deshabilita el modo mock
  static void disableMockMode() {
    _useMockService = false;
    _mockService.clearAllData();
  }
  
  /// Verifica si el modo mock está habilitado
  static bool isMockModeEnabled() {
    return _useMockService;
  }
  
  /// Inicializa el servicio con verificaciones de seguridad
  static Future<void> initialize() async {
    if (_useMockService) {
      // En modo mock, no hacer verificaciones de seguridad
      // [AuthService] Modo mock activo - usando almacenamiento local
      return;
    }
    
    // MITIGACIÓN M8: Code tampering
    final isCompromised = await AntiTamperingProtection.isDeviceCompromised();
    if (isCompromised) {
      throw SecurityException('Device security compromised');
    }
    
    // MITIGACIÓN M3: Comunicación insegura
    _dio = await CertificatePinningConfig.getSecureHttpClient();
  }
  
  /// Registro de usuario con validaciones de seguridad
  /// MITIGACIÓN M1: Credenciales débiles
  /// MITIGACIÓN M4: Autenticación insegura
  static Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    // Si estamos en modo mock, usar el servicio mock
    if (_useMockService) {
      return await _mockService.register(
        username: username,
        email: email,
        password: password,
      );
    }
    
    // Validación de contraseña fuerte
    if (!SecurityConfig.isPasswordStrong(password)) {
      throw AuthException(
        'Password must be at least 12 characters with uppercase, lowercase, numbers, and special characters',
      );
    }
    
    // Sanitización de entrada
    final sanitizedUsername = SecurityConfig.sanitizeInput(username);
    final sanitizedEmail = SecurityConfig.sanitizeInput(email);
    
    // Genera salt y hashea la contraseña
    final salt = SecurityConfig.generateSalt();
    final passwordHash = SecurityConfig.hashPassword(password, salt);
    
    try {
      final response = await _dio!.post(
        '/auth/register',
        data: {
          'username': sanitizedUsername,
          'email': sanitizedEmail,
          'passwordHash': passwordHash,
          'salt': salt,
          'clientVersion': '1.0.0',
        },
      );
      
      if (response.statusCode == 201) {
        final user = User.fromJson(response.data['user']);
        final token = response.data['token'] as String;
        final refreshToken = response.data['refreshToken'] as String;
        
        // Almacena tokens de forma segura
        await SessionManager.storeAuthToken(token, refreshToken);
        await SessionManager.storeSessionData(user.toJson());
        
        // Inicia monitor de sesión
        _startSessionMonitor();
        
        return user;
      } else {
        throw AuthException('Registration failed');
      }
    } catch (e) {
      throw AuthException('Registration error: ${e.toString()}');
    }
  }
  
  /// Login con múltiples factores de autenticación
  /// MITIGACIÓN M4: Autenticación insegura
  static Future<User> login({
    required String username,
    required String password,
    bool requireBiometric = true,
  }) async {
    // Si estamos en modo mock, usar el servicio mock
    if (_useMockService) {
      final user = await _mockService.login(
        username: username,
        password: password,
      );
      // Iniciar sesión
      await _startSession(user);
      return user;
    }
    
    // Verificación biométrica si está disponible
    if (requireBiometric) {
      final canCheckBiometrics = await BiometricAuth.canCheckBiometrics();
      if (canCheckBiometrics) {
        final didAuthenticate = await BiometricAuth.authenticate(
          localizedReason: 'Authenticate to access your notes',
          biometricOnly: true,
          stickyAuth: true,
        );
        
        if (!didAuthenticate) {
          throw AuthException('Biometric authentication failed');
        }
      }
    }
    
    // Sanitización de entrada
    final sanitizedUsername = SecurityConfig.sanitizeInput(username);
    
    try {
      // Primera fase: obtener salt del servidor
      final saltResponse = await _dio!.post(
        '/auth/salt',
        data: {'username': sanitizedUsername},
      );
      
      final salt = saltResponse.data['salt'] as String;
      final passwordHash = SecurityConfig.hashPassword(password, salt);
      
      // Segunda fase: autenticación
      final response = await _dio!.post(
        '/auth/login',
        data: {
          'username': sanitizedUsername,
          'passwordHash': passwordHash,
          'deviceId': await _getDeviceId(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data['user']);
        final token = response.data['token'] as String;
        final refreshToken = response.data['refreshToken'] as String;
        
        // Almacena tokens de forma segura
        await SessionManager.storeAuthToken(token, refreshToken);
        await SessionManager.storeSessionData(user.toJson());
        
        // Inicia monitor de sesión
        _startSessionMonitor();
        
        return user;
      } else {
        throw AuthException('Invalid credentials');
      }
    } catch (e) {
      // Manejo seguro de errores sin exponer detalles
      throw AuthException('Authentication failed');
    }
  }
  
  /// Cierra sesión de forma segura
  static Future<void> logout() async {
    // Si estamos en modo mock, usar el servicio mock
    if (_useMockService) {
      await _mockService.logout();
      _stopSession();
      return;
    }
    
    try {
      final token = await SessionManager.getValidAuthToken();
      if (token != null) {
        // Notifica al servidor
        await _dio!.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      // Continúa con el logout local aunque falle el servidor
    } finally {
      // Limpia datos locales
      await SessionManager.clearSession();
      _sessionTimer?.cancel();
    }
  }
  
  /// Monitor de sesión para expiración automática
  /// MITIGACIÓN M6: Autorización insegura
  static void _startSessionMonitor() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) async {
        final token = await SessionManager.getValidAuthToken();
        if (token == null) {
          // Sesión expirada, forzar logout
          await logout();
        }
      },
    );
  }
  
  /// Obtiene ID único del dispositivo
  static Future<String> _getDeviceId() async {
    // Implementación simplificada - usar plugin para ID real
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Inicia una sesión para el usuario en modo mock
  static Future<void> _startSession(User user) async {
    if (_useMockService) {
      // En modo mock, solo simular el inicio de sesión
      await Future.delayed(const Duration(milliseconds: 100));
      _startSessionMonitor();
    }
  }
  
  /// Detiene la sesión actual
  static void _stopSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }
  
  /// Verifica si hay una sesión activa
  static Future<bool> isAuthenticated() async {
    // Si estamos en modo mock, usar el servicio mock
    if (_useMockService) {
      return _mockService.isAuthenticated();
    }
    
    final token = await SessionManager.getValidAuthToken();
    return token != null;
  }
  
  /// Refresca el token de autenticación
  static Future<void> refreshToken() async {
    // Implementación de refresh token
    // Similar al login pero usando refresh token
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M1: Permitir contraseñas débiles como "123456"
/// - M4: Login sin verificación adicional (solo usuario/contraseña)
/// - M4: No implementar límite de intentos de login
/// - M6: Tokens sin expiración o renovación
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - Burp Suite: Para analizar peticiones de autenticación
/// - THC-Hydra: Para ataques de fuerza bruta
/// - OWASP ZAP: Para testing de autenticación
/// - Postman: Para probar endpoints de API