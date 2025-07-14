import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Conditional imports
import 'anti_tampering_stub.dart'
    if (dart.library.io) 'anti_tampering_mobile.dart';

/// MITIGACIÓN M8: Manipulación del código (Code tampering)
/// MITIGACIÓN M9: Ingeniería inversa (Reverse Engineering)
/// 
/// Esta clase implementa protecciones contra modificación del código
/// y técnicas anti-ingeniería inversa
class AntiTamperingProtection {
  // Hash del APK/IPA original para validación de integridad
  static const String expectedAppHash = 'YOUR_APP_HASH_HERE';
  
  /// Detecta si el dispositivo está rooteado/jailbroken
  /// Evita M8: Code tampering en dispositivos comprometidos
  static Future<bool> isDeviceCompromised() async {
    // En Flutter Web, permitir ejecución normal
    if (kIsWeb) {
      return false;
    }
    
    // En modo debug, permitir ejecución para pruebas
    if (kDebugMode) {
      print('[AntiTampering] Running in debug mode - security checks bypassed for testing');
      return false;
    }
    
    try {
      // Detección de jailbreak/root
      final isJailbroken = await PlatformChecker.isJailbroken();
      final isDeveloperMode = await PlatformChecker.isDeveloperMode();
      
      // Verificaciones adicionales
      final hasStoreInstallation = await _checkStoreInstallation();
      final hasDebugger = _isDebuggerAttached();
      final hasProxy = await _checkForProxy();
      
      return isJailbroken || isDeveloperMode || !hasStoreInstallation || hasDebugger || hasProxy;
    } catch (e) {
      // En modo debug, permitir ejecución
      if (kDebugMode) {
        return false;
      }
      // En caso de error en producción, asume que está comprometido
      return true;
    }
  }
  
  /// Verifica la integridad del código de la aplicación
  /// Evita M8: Code tampering
  static Future<bool> verifyAppIntegrity() async {
    if (kDebugMode || kIsWeb) return true; // Skip en modo debug o web
    
    try {
      // Calcula el hash del ejecutable actual
      final currentHash = await PlatformChecker.calculateAppHash();
      
      // Compara con el hash esperado
      return currentHash == expectedAppHash;
    } catch (e) {
      return false;
    }
  }
  
  /// Detecta si hay un debugger conectado
  /// Evita M9: Reverse Engineering
  static bool _isDebuggerAttached() {
    // En producción, esta verificación es más compleja
    // Aquí se muestra una implementación básica
    assert(() {
      // En modo debug, siempre hay un debugger
      return true;
    }());
    
    // Verificaciones adicionales para producción
    return false;
  }
  
  /// Verifica si la app fue instalada desde una tienda oficial
  /// Evita M8: Code tampering
  static Future<bool> _checkStoreInstallation() async {
    if (kIsWeb) {
      // En web, siempre es "oficial"
      return true;
    }
    
    if (!kIsWeb) {
      // Verifica el instalador del paquete
      try {
        const platform = MethodChannel('com.secure.owaspnote/security');
        final String? installer = await platform.invokeMethod('getInstaller');
        
        // Lista de tiendas oficiales
        const officialStores = [
          'com.android.vending', // Google Play Store
          'com.amazon.venezia', // Amazon App Store
        ];
        
        return installer != null && officialStores.contains(installer);
      } catch (e) {
        return false;
      }
    }
    
    return false;
  }
  
  /// Detecta si hay un proxy configurado
  /// Evita M3: Comunicación insegura
  static Future<bool> _checkForProxy() async {
    if (kIsWeb) {
      // En web, el navegador maneja los proxies
      return false;
    }
    
    try {
      return await PlatformChecker.checkForProxy();
    } catch (e) {
      return true; // Asume proxy si hay error
    }
  }
}

/// MITIGACIÓN M9: Ingeniería inversa
/// 
/// Ofuscación de strings sensibles
class StringObfuscator {
  /// Ofusca strings sensibles en tiempo de compilación
  /// Evita M9: Reverse Engineering
  static String deobfuscate(List<int> obfuscated) {
    // XOR simple para el ejemplo - usar técnicas más complejas en producción
    const key = 0x42;
    return String.fromCharCodes(
      obfuscated.map((c) => c ^ key),
    );
  }
  
  /// Strings críticos ofuscados
  static final apiKey = deobfuscate([0x03, 0x0F, 0x0B]); // "API"
  static final dbKey = deobfuscate([0x06, 0x04, 0x1B]); // "DB"
}

/// MITIGACIÓN M7: Mala calidad del código
/// 
/// Manejo seguro de errores sin exponer información sensible
class SecureErrorHandler {
  /// Maneja errores sin exponer detalles internos
  /// Evita M7: Mala calidad del código
  static String sanitizeError(dynamic error) {
    // En producción, registra el error completo internamente
    _logSecurely(error);
    
    // Retorna mensaje genérico al usuario
    if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    } else if (error is AuthException) {
      return 'Authentication failed. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again later.';
    }
  }
  
  static void _logSecurely(dynamic error) {
    if (kDebugMode) {
      print('Error: $error');
    } else {
      // En producción, enviar a servicio de logging seguro
      // sin exponer información sensible
    }
  }
}

class NetworkException implements Exception {}
class AuthException implements Exception {}

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M8: Permitir ejecución en dispositivos rooteados
/// - M8: No verificar integridad del código
/// - M9: Strings hardcodeados visibles en el binario
/// - M7: Mensajes de error que exponen stack traces
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - Frida: Para hooking dinámico y bypass de protecciones
/// - APKTool: Para decompilar y modificar APKs
/// - IDA Pro: Para análisis estático del binario
/// - MobSF: Para análisis de seguridad automatizado
/// - Jadx: Para decompilar código Java/Kotlin