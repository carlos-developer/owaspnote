import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../security/security_config.dart';

/// Pantalla de registro con validaciones de seguridad
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Estado de validación de contraseña
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigits = false;
  bool _hasSpecialChars = false;

  @override
  void initState() {
    super.initState();
    // Listener para validación en tiempo real
    _passwordController.addListener(_validatePasswordStrength);
  }
  
  /// Valida la fortaleza de la contraseña en tiempo real
  /// MITIGACIÓN M1: Credenciales débiles
  void _validatePasswordStrength() {
    final password = _passwordController.text;
    
    setState(() {
      _hasMinLength = password.length >= SecurityConfig.minPasswordLength;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasDigits = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }
  
  /// Widget para mostrar requisito de contraseña
  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isMet ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await AuthService.initialize();
      
      await AuthService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        // Muestra mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Vuelve a la pantalla de login
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError(e.toString());
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
        title: const Text('Create Account'),
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
                      Icons.person_add_outlined,
                      size: 80,
                      color: Colors.blue,
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
                      maxLength: 50,
                      inputFormatters: [
                        // MITIGACIÓN M7: Mala calidad del código
                        // Previene caracteres peligrosos
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9._-]'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value)) {
                          return 'Username can only contain letters, numbers, dots, underscores and hyphens';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Campo de email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [
                        // Limita longitud para prevenir DoS
                        LengthLimitingTextInputFormatter(100),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        // Validación estricta de email
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address';
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        // MITIGACIÓN M1: Credenciales débiles
                        if (!SecurityConfig.isPasswordStrong(value)) {
                          return 'Password does not meet security requirements';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    
                    // Indicadores de fortaleza de contraseña
                    if (_passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Password Requirements:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPasswordRequirement(
                                'At least ${SecurityConfig.minPasswordLength} characters',
                                _hasMinLength,
                              ),
                              _buildPasswordRequirement(
                                'Contains uppercase letter',
                                _hasUpperCase,
                              ),
                              _buildPasswordRequirement(
                                'Contains lowercase letter',
                                _hasLowerCase,
                              ),
                              _buildPasswordRequirement(
                                'Contains number',
                                _hasDigits,
                              ),
                              _buildPasswordRequirement(
                                'Contains special character',
                                _hasSpecialChars,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Campo de confirmación de contraseña
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword 
                              ? Icons.visibility 
                              : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Botón de registro
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
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
                              'Register',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Aviso de privacidad
                    const Text(
                      'By registering, you agree that your data will be '
                      'encrypted and stored securely. We take your privacy seriously.',
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
    _passwordController.removeListener(_validatePasswordStrength);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M1: Permitir contraseñas débiles como "password123"
/// - M7: No validar formato de email (permitir inyecciones)
/// - M7: No limitar longitud de campos (DoS)
/// - M10: Recopilar información innecesaria del usuario
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - Burp Suite: Para fuzzing de campos de entrada
/// - SQLMap: Para probar inyecciones SQL
/// - OWASP ZAP: Para validación de entrada
/// - Postman: Para bypass de validaciones del cliente