import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../security/anti_tampering.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// Pantalla de login con medidas de seguridad
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _loginAttempts = 0;
  DateTime? _lastAttemptTime;
  bool _useLocalMode = false; // Para activar/desactivar modo local
  
  // MITIGACIÓN M4: Autenticación insegura - límite de intentos
  static const int maxLoginAttempts = 3;
  static const int lockoutDurationMinutes = 15;

  @override
  void initState() {
    super.initState();
    _checkDeviceSecurity();
    // En modo debug, verificar si el modo local estaba activo
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      _useLocalMode = AuthService.isMockModeEnabled();
    }
  }
  
  /// Verifica la seguridad del dispositivo
  /// MITIGACIÓN M8: Code tampering
  Future<void> _checkDeviceSecurity() async {
    final isCompromised = await AntiTamperingProtection.isDeviceCompromised();
    if (isCompromised && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Security Warning'),
          content: const Text(
            'This device appears to be compromised. '
            'For your security, the app cannot run on rooted or jailbroken devices.',
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Exit'),
            ),
          ],
        ),
      );
    }
  }
  
  /// Verifica si el usuario está bloqueado por intentos fallidos
  bool _isUserLockedOut() {
    if (_lastAttemptTime == null) return false;
    
    final timeSinceLastAttempt = DateTime.now().difference(_lastAttemptTime!);
    return _loginAttempts >= maxLoginAttempts && 
           timeSinceLastAttempt.inMinutes < lockoutDurationMinutes;
  }
  
  /// Calcula tiempo restante de bloqueo
  int _getRemainingLockoutMinutes() {
    if (_lastAttemptTime == null) return 0;
    
    final elapsed = DateTime.now().difference(_lastAttemptTime!).inMinutes;
    return lockoutDurationMinutes - elapsed;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Verifica bloqueo por intentos fallidos
    if (_isUserLockedOut()) {
      _showError(
        'Too many failed attempts. Please try again in '
        '${_getRemainingLockoutMinutes()} minutes.',
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await AuthService.initialize();
      
      final user = await AuthService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        requireBiometric: true,
      );
      
      // Reset intentos en login exitoso
      _loginAttempts = 0;
      _lastAttemptTime = null;
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: user),
          ),
        );
      }
    } catch (e) {
      // Incrementa intentos fallidos
      setState(() {
        _loginAttempts++;
        _lastAttemptTime = DateTime.now();
      });
      
      // Mensaje genérico para no revelar información
      _showError('Invalid credentials');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Notes'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 40),
              Text(
                'Secure Notes',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
                    
                    // Campo de usuario
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      // MITIGACIÓN M7: Mala calidad del código
                      // Limita longitud de entrada
                      maxLength: 50,
                      inputFormatters: [
                        // Solo permite caracteres alfanuméricos y algunos especiales
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9._@-]'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Campo de contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword 
                              ? Icons.visibility 
                              : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      // No muestra requisitos de contraseña en login
                      // para no dar pistas a atacantes
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Botón de login
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Link a registro
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                      child: const Text('Don\'t have an account? Register'),
                    ),
                    
                    // Switch para modo local (solo en debug)
                    if (const bool.fromEnvironment('dart.vm.product') == false) ...[                    
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _useLocalMode ? Colors.orange.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _useLocalMode ? Colors.orange : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.developer_mode,
                              color: _useLocalMode ? Colors.orange : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Modo Local (Debug)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _useLocalMode ? Colors.orange.shade800 : Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    _useLocalMode 
                                      ? 'Usando almacenamiento local' 
                                      : 'Usando servidor remoto',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _useLocalMode ? Colors.orange.shade600 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _useLocalMode,
                              onChanged: _isLoading ? null : (value) {
                                setState(() {
                                  _useLocalMode = value;
                                  if (value) {
                                    AuthService.enableMockMode();
                                  } else {
                                    AuthService.disableMockMode();
                                  }
                                });
                                
                                // Mostrar mensaje informativo
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      value 
                                        ? 'Modo local activado - Los datos se guardarán temporalmente'
                                        : 'Modo remoto activado - Los datos se guardarán en el servidor',
                                    ),
                                    backgroundColor: value ? Colors.orange : Colors.blue,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                              activeColor: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Mensaje de seguridad
                    const SizedBox(height: 20),
                    const Text(
                      'This app uses biometric authentication and '
                      'encrypts all your data for maximum security.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M4: No limitar intentos de login (fuerza bruta)
/// - M4: Mostrar mensajes específicos como "Usuario no existe"
/// - M7: No validar/sanitizar entrada del usuario
/// - M8: Permitir ejecución en dispositivos comprometidos
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - Hydra: Para ataques de fuerza bruta
/// - Burp Suite: Para analizar respuestas de login
/// - ADB: Para bypass de verificaciones del cliente
/// - Frida: Para hooking de funciones de validación