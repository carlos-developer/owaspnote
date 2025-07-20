import 'dart:async';
import 'package:owaspnote/models/user.dart';
import 'package:owaspnote/security/security_config.dart';
import 'local_storage_service.dart';

/// Mock Authentication Service para tests de integración y modo local
/// Almacena usuarios localmente para permitir flujo completo offline
class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal() {
    _loadUsersFromStorage();
  }

  // Base de datos en memoria (cache)
  final Map<String, _MockUser> _users = {};
  String? _currentUserId;
  
  /// Carga usuarios desde almacenamiento local al iniciar
  Future<void> _loadUsersFromStorage() async {
    // Cargar usuario actual si existe
    final currentUser = await LocalStorageService.getCurrentUser();
    if (currentUser != null) {
      _currentUserId = currentUser.id;
    }
  }
  
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
    await Future.delayed(const Duration(milliseconds: 500));

    // Validar si el usuario ya existe en almacenamiento local
    if (await LocalStorageService.userExists(username)) {
      throw Exception('Username already exists');
    }
    
    if (await LocalStorageService.emailExists(email)) {
      throw Exception('Email already registered');
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

    // Guardar en memoria y almacenamiento local
    _users[userId] = mockUser;
    _currentUserId = userId;
    
    // Persistir en almacenamiento local
    await LocalStorageService.saveUser({
      'id': userId,
      'username': username,
      'email': email,
      'passwordHash': hashedPassword,
      'salt': salt,
      'createdAt': DateTime.now().toIso8601String(),
    });
    
    final user = User(
      id: userId,
      username: username,
      email: email,
      createdAt: DateTime.now(),
      permissions: ['read', 'write'],
    );
    
    // Guardar como usuario actual
    await LocalStorageService.setCurrentUser(user);

    return user;
  }

  // Login
  Future<User> login({
    required String username,
    required String password,
  }) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 500));

    // Buscar usuario en almacenamiento local
    final userData = await LocalStorageService.getUser(username);
    if (userData == null) {
      throw Exception('Invalid username or password');
    }

    // Verificar contraseña
    final inputHash = SecurityConfig.hashPassword(password, userData['salt']);
    if (inputHash != userData['passwordHash']) {
      throw Exception('Invalid username or password');
    }

    _currentUserId = userData['id'];
    
    final user = User(
      id: userData['id'],
      username: userData['username'],
      email: userData['email'],
      createdAt: DateTime.parse(userData['createdAt'] ?? DateTime.now().toIso8601String()),
      permissions: ['read', 'write'],
    );
    
    // Guardar como usuario actual
    await LocalStorageService.setCurrentUser(user);

    return user;
  }

  // Logout
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUserId = null;
    await LocalStorageService.setCurrentUser(null);
  }

  // Verificar si está autenticado
  bool isAuthenticated() {
    return _currentUserId != null;
  }
  
  // Verificar autenticación asíncrona (desde almacenamiento)
  Future<bool> isAuthenticatedAsync() async {
    final currentUser = await LocalStorageService.getCurrentUser();
    return currentUser != null;
  }

  // Limpiar todos los datos (para tests)
  void clearAllData() {
    _users.clear();
    _currentUserId = null;
    // No limpiamos el almacenamiento local aquí para mantener persistencia
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