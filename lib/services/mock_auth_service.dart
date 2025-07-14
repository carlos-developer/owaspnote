import 'dart:async';
import 'package:owaspnote/models/user.dart';
import 'package:owaspnote/security/security_config.dart';

/// Mock Authentication Service para tests de integración
/// Almacena usuarios en memoria para permitir flujo completo de registro/login
class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  // Base de datos en memoria
  final Map<String, _MockUser> _users = {};
  String? _currentUserId;
  
  // Usuario actual
  User? get currentUser {
    if (_currentUserId == null) return null;
    final mockUser = _users[_currentUserId!];
    if (mockUser == null) return null;
    return User(
      id: mockUser.id,
      username: mockUser.username,
      email: mockUser.email,
      createdAt: DateTime.now(),
      permissions: ['read', 'write'], // Permisos básicos para usuario mock
    );
  }

  // Registro de usuario
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    // Simular delay de red
    await Future.delayed(const Duration(seconds: 1));

    // Validar si el usuario ya existe
    if (_users.values.any((u) => u.username == username || u.email == email)) {
      throw Exception('Username or email already exists');
    }

    // Validar contraseña fuerte
    if (!SecurityConfig.isPasswordStrong(password)) {
      throw Exception('Password does not meet security requirements');
    }

    // Crear usuario
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final salt = SecurityConfig.generateSalt();
    final hashedPassword = SecurityConfig.hashPassword(password, salt);
    
    final mockUser = _MockUser(
      id: userId,
      username: username,
      email: email,
      passwordHash: hashedPassword,
      salt: salt,
    );

    _users[userId] = mockUser;
    _currentUserId = userId;

    return User(
      id: userId,
      username: username,
      email: email,
      createdAt: DateTime.now(),
      permissions: ['read', 'write'], // Permisos básicos para nuevo usuario
    );
  }

  // Login
  Future<User> login({
    required String username,
    required String password,
  }) async {
    // Simular delay de red
    await Future.delayed(const Duration(seconds: 1));

    // Buscar usuario
    final mockUser = _users.values.firstWhere(
      (u) => u.username == username,
      orElse: () => throw Exception('Invalid username or password'),
    );

    // Verificar contraseña
    final inputHash = SecurityConfig.hashPassword(password, mockUser.salt);
    if (inputHash != mockUser.passwordHash) {
      throw Exception('Invalid username or password');
    }

    _currentUserId = mockUser.id;

    return User(
      id: mockUser.id,
      username: mockUser.username,
      email: mockUser.email,
      createdAt: DateTime.now(),
      permissions: ['read', 'write'], // Permisos básicos para usuario mock
    );
  }

  // Logout
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUserId = null;
  }

  // Verificar si está autenticado
  bool isAuthenticated() {
    return _currentUserId != null;
  }

  // Limpiar todos los datos (para tests)
  void clearAllData() {
    _users.clear();
    _currentUserId = null;
  }
}

// Clase interna para almacenar datos de usuario
class _MockUser {
  final String id;
  final String username;
  final String email;
  final String passwordHash;
  final String salt;

  _MockUser({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.salt,
  });
}