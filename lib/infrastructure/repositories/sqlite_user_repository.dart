import 'package:sqflite/sqflite.dart';
import '../../domain/user/user_aggregate.dart';
import '../../domain/user/user_repository.dart';
import '../../domain/user/user_id.dart';
import '../../domain/user/email.dart';
import '../../domain/user/username.dart';
import '../../domain/user/password.dart';
import 'dart:convert';

class SqliteUserRepository implements UserRepository {
  final Database database;

  SqliteUserRepository({required this.database});

  @override
  Future<User?> findById(UserId id) async {
    final maps = await database.query(
      'users',
      where: 'id = ?',
      whereArgs: [id.value],
    );

    if (maps.isEmpty) return null;

    return await _mapToUserWithRoles(maps.first);
  }

  @override
  Future<List<User>> findAll() async {
    final maps = await database.query('users');
    final users = <User>[];
    for (final map in maps) {
      users.add(await _mapToUserWithRoles(map));
    }
    return users;
  }

  @override
  Future<void> save(User entity) async {
    final map = _userToMap(entity);
    
    await database.insert(
      'users',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _saveRoles(entity);
  }

  @override
  Future<void> delete(User entity) async {
    await database.delete(
      'users',
      where: 'id = ?',
      whereArgs: [entity.id.value],
    );
  }

  @override
  Future<User?> findByEmail(String email) async {
    final maps = await database.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (maps.isEmpty) return null;

    return await _mapToUserWithRoles(maps.first);
  }

  @override
  Future<User?> findByUsername(String username) async {
    final maps = await database.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.toLowerCase()],
    );

    if (maps.isEmpty) return null;

    return await _mapToUserWithRoles(maps.first);
  }

  @override
  Future<bool> existsWithEmail(String email) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE email = ?',
      [email.toLowerCase()],
    );
    return (result.first['count'] as int) > 0;
  }

  @override
  Future<bool> existsWithUsername(String username) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE username = ?',
      [username.toLowerCase()],
    );
    return (result.first['count'] as int) > 0;
  }

  @override
  Future<List<User>> findByRole(String role) async {
    final maps = await database.rawQuery('''
      SELECT u.* FROM users u
      INNER JOIN user_roles ur ON u.id = ur.user_id
      WHERE ur.role = ?
    ''', [role]);

    final users = <User>[];
    for (final map in maps) {
      users.add(await _mapToUserWithRoles(map));
    }
    return users;
  }

  @override
  Future<List<User>> findLockedUsers() async {
    final maps = await database.query(
      'users',
      where: 'is_locked = ?',
      whereArgs: [1],
    );

    final users = <User>[];
    for (final map in maps) {
      users.add(await _mapToUserWithRoles(map));
    }
    return users;
  }

  @override
  Future<List<User>> findUsersWithExpiredPasswords() async {
    final ninetyDaysAgo = DateTime.now().subtract(Duration(days: 90));
    final maps = await database.query(
      'users',
      where: 'password_changed_at < ?',
      whereArgs: [ninetyDaysAgo.toIso8601String()],
    );

    final users = <User>[];
    for (final map in maps) {
      users.add(await _mapToUserWithRoles(map));
    }
    return users;
  }

  @override
  Future<int> countActiveUsers() async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE is_locked = 0 AND is_email_verified = 1',
    );
    return result.first['count'] as int;
  }

  Future<void> _saveRoles(User user) async {
    await database.delete(
      'user_roles',
      where: 'user_id = ?',
      whereArgs: [user.id.value],
    );

    for (final role in user.roles) {
      await database.insert('user_roles', {
        'user_id': user.id.value,
        'role': role,
      });
    }
  }

  Future<User> _mapToUserWithRoles(Map<String, dynamic> map) async {
    final rolesMaps = await database.query(
      'user_roles',
      where: 'user_id = ?',
      whereArgs: [map['id']],
    );
    
    final roles = rolesMaps
        .map((m) => m['role'] as String)
        .toSet();

    return _mapToUser(map, roles);
  }

  User _mapToUser(Map<String, dynamic> map, Set<String> roles) {
    return User(
      id: UserId(map['id'] as String),
      email: Email(map['email'] as String),
      username: Username(map['username'] as String),
      hashedPassword: HashedPassword(map['hashed_password'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      lastLoginAt: DateTime.parse(map['last_login_at'] as String),
      passwordChangedAt: DateTime.parse(map['password_changed_at'] as String),
      isEmailVerified: map['is_email_verified'] == 1,
      isLocked: map['is_locked'] == 1,
      failedLoginAttempts: map['failed_login_attempts'] as int,
      lockedUntil: map['locked_until'] != null 
          ? DateTime.parse(map['locked_until'] as String)
          : null,
      isTwoFactorEnabled: map['is_two_factor_enabled'] == 1,
      twoFactorSecret: map['two_factor_secret'] as String?,
      roles: roles.isEmpty ? {'user'} : roles,
      metadata: map['metadata'] != null 
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : {},
    );
  }

  Map<String, dynamic> _userToMap(User user) {
    return {
      'id': user.id.value,
      'email': user.email.value,
      'username': user.username.value,
      'hashed_password': user.hashedPassword.value,
      'created_at': user.createdAt.toIso8601String(),
      'last_login_at': user.lastLoginAt.toIso8601String(),
      'password_changed_at': user.passwordChangedAt.toIso8601String(),
      'is_email_verified': user.isEmailVerified ? 1 : 0,
      'is_locked': user.isLocked ? 1 : 0,
      'failed_login_attempts': user.failedLoginAttempts,
      'locked_until': user.lockedUntil?.toIso8601String(),
      'is_two_factor_enabled': user.isTwoFactorEnabled ? 1 : 0,
      'two_factor_secret': user.twoFactorSecret,
      'metadata': jsonEncode(user.metadata),
    };
  }
}