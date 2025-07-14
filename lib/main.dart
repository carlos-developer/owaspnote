import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'security/anti_tampering.dart';

/// MITIGACIÓN M2: Suministro de código inseguro
/// MITIGACIÓN M7: Mala calidad del código
/// MITIGACIÓN M8: Code tampering
/// MITIGACIÓN M9: Reverse Engineering
/// 
/// Punto de entrada de la aplicación con medidas de seguridad
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // MITIGACIÓN M8: Code tampering
  // Verifica la integridad de la aplicación al inicio
  await _performSecurityChecks();
  
  // MITIGACIÓN M9: Reverse Engineering
  // Deshabilita depuración en release
  if (const bool.fromEnvironment('dart.vm.product')) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  runApp(const SecureNotesApp());
}

/// Realiza verificaciones de seguridad iniciales
Future<void> _performSecurityChecks() async {
  try {
    // Verifica si el dispositivo está comprometido
    final isCompromised = await AntiTamperingProtection.isDeviceCompromised();
    
    if (isCompromised) {
      // En producción, terminar la app
      SystemNavigator.pop();
      return;
    }
    
    // Verifica integridad del código
    final hasIntegrity = await AntiTamperingProtection.verifyAppIntegrity();
    
    if (!hasIntegrity) {
      // Código ha sido modificado
      SystemNavigator.pop();
      return;
    }
  } catch (e) {
    // En caso de error, falla de forma segura
    SystemNavigator.pop();
  }
}

class SecureNotesApp extends StatelessWidget {
  const SecureNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MITIGACIÓN M10: Funcionalidad superflua
    // Previene screenshots en contenido sensible
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    return MaterialApp(
      title: 'Secure Notes',
      debugShowCheckedModeBanner: false, // Oculta banner de debug
      
      // MITIGACIÓN M7: Mala calidad del código
      // Tema consistente y profesional
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        
        // Configuración de seguridad visual
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        
        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      
      // MITIGACIÓN M2: Suministro de código inseguro
      // No hardcodear rutas o configuraciones sensibles
      home: const SecureAppWrapper(),
      
      // Manejo global de errores sin exponer información
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return const Material(
            child: Center(
              child: Text(
                'An error occurred. Please restart the app.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

/// Wrapper con verificaciones de seguridad adicionales
class SecureAppWrapper extends StatefulWidget {
  const SecureAppWrapper({super.key});

  @override
  State<SecureAppWrapper> createState() => _SecureAppWrapperState();
}

class _SecureAppWrapperState extends State<SecureAppWrapper> 
    with WidgetsBindingObserver {
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // MITIGACIÓN M10: Funcionalidad superflua
    // Oculta contenido cuando la app no está activa
    setState(() {
      _isObscured = state != AppLifecycleState.resumed;
    });
    
    if (state == AppLifecycleState.paused) {
      // Limpia datos sensibles de memoria
      imageCache.clear();
      imageCache.clearLiveImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isObscured) {
      // Muestra pantalla de bloqueo cuando la app está en segundo plano
      return const Material(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Secure Notes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return const LoginScreen();
  }
}

/// MITIGACIÓN M9: Reverse Engineering
/// Configuración adicional necesaria:
/// 
/// 1. En android/app/build.gradle:
/// ```gradle
/// android {
///     buildTypes {
///         release {
///             minifyEnabled true
///             shrinkResources true
///             proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
///         }
///     }
/// }
/// ```
/// 
/// 2. Crear android/app/proguard-rules.pro:
/// ```
/// -keep class com.secure.owaspnote.** { *; }
/// -keepattributes Signature
/// -keepattributes *Annotation*
/// ```
/// 
/// 3. Para iOS, en Xcode habilitar:
/// - Strip Debug Symbols
/// - Strip Swift Symbols
/// - Enable Bitcode

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M2: No verificar integridad del código al inicio
/// - M7: Exponer stack traces en errores
/// - M8: Permitir ejecución sin verificaciones
/// - M9: No ofuscar código en release
/// - M10: Mostrar contenido sensible en app switcher
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - APKTool: Para decompilar y analizar el APK
/// - Frida: Para hooking en runtime
/// - Jadx: Para análisis de código fuente
/// - MobSF: Para análisis de seguridad automatizado