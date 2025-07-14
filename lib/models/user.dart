/// Modelo de usuario con validaciones de seguridad
class User {
  final String id;
  final String username;
  final String email;
  final DateTime createdAt;
  final List<String> permissions;
  
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    required this.permissions,
  });
  
  /// MITIGACIÓN M7: Mala calidad del código
  /// Validación estricta de datos de entrada
  factory User.fromJson(Map<String, dynamic> json) {
    // Validación de tipos y valores
    if (json['id'] == null || json['id'] is! String) {
      throw FormatException('Invalid user ID');
    }
    
    if (json['username'] == null || json['username'] is! String) {
      throw FormatException('Invalid username');
    }
    
    if (json['email'] == null || json['email'] is! String) {
      throw FormatException('Invalid email');
    }
    
    // Validación de formato de email
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*(\+[\w-]+)?@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(json['email'])) {
      throw FormatException('Invalid email format');
    }
    
    return User(
      id: json['id'] as String,
      username: _sanitizeUsername(json['username'] as String),
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      permissions: List<String>.unmodifiable(json['permissions'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    'permissions': permissions,
  };
  
  /// Sanitiza el nombre de usuario para evitar inyecciones
  static String _sanitizeUsername(String username) {
    // Remove dangerous characters
    final sanitized = username
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('&', '')
        .trim();
    return sanitized.substring(0, sanitized.length > 50 ? 50 : sanitized.length);
  }
  
  /// Verifica si el usuario tiene un permiso específico
  /// MITIGACIÓN M6: Autorización insegura
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
  
  /// Verifica múltiples permisos
  bool hasAllPermissions(List<String> requiredPermissions) {
    return requiredPermissions.every((perm) => permissions.contains(perm));
  }
  
  bool hasAnyPermission(List<String> requiredPermissions) {
    return requiredPermissions.any((perm) => permissions.contains(perm));
  }
}