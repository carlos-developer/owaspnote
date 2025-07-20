import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../security/secure_storage.dart';
import '../models/user.dart';

/// Servicio de almacenamiento local para modo offline
/// Permite persistencia de datos de usuario de forma segura
class LocalStorageService {
  static const String _userStorageKey = 'local_users';
  static const String _currentUserKey = 'current_user';
  static const String _localModeKey = 'local_mode_enabled';
  
  /// Guarda la preferencia de modo local
  static Future<void> setLocalModeEnabled(bool enabled) async {
    await SecureStorageManager.storeSecureData(_localModeKey, enabled.toString());
  }
  
  /// Obtiene la preferencia de modo local
  static Future<bool> getLocalModeEnabled() async {
    final value = await SecureStorageManager.getSecureData(_localModeKey);
    return value == 'true';
  }
  
  /// Guarda un usuario en almacenamiento local
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    try {
      // Obtener usuarios existentes
      final existingUsers = await _getAllUsers();
      
      // Agregar o actualizar usuario
      existingUsers[userData['username']] = userData;
      
      // Guardar de vuelta
      final jsonString = jsonEncode(existingUsers);
      await SecureStorageManager.storeSecureData(_userStorageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving user: $e');
      rethrow;
    }
  }
  
  /// Obtiene un usuario por username
  static Future<Map<String, dynamic>?> getUser(String username) async {
    try {
      final users = await _getAllUsers();
      return users[username];
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }
  
  /// Obtiene todos los usuarios almacenados
  static Future<Map<String, dynamic>> _getAllUsers() async {
    try {
      final jsonString = await SecureStorageManager.getSecureData(_userStorageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return {};
    }
  }
  
  /// Guarda el usuario actual
  static Future<void> setCurrentUser(User? user) async {
    if (user == null) {
      await SecureStorageManager.deleteSecureData(_currentUserKey);
    } else {
      await SecureStorageManager.storeSecureData(_currentUserKey, jsonEncode(user.toJson()));
    }
  }
  
  /// Obtiene el usuario actual
  static Future<User?> getCurrentUser() async {
    try {
      final jsonString = await SecureStorageManager.getSecureData(_currentUserKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      final userData = jsonDecode(jsonString);
      return User.fromJson(userData);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }
  
  /// Limpia todos los datos locales
  static Future<void> clearAllData() async {
    await SecureStorageManager.deleteSecureData(_userStorageKey);
    await SecureStorageManager.deleteSecureData(_currentUserKey);
    await SecureStorageManager.deleteSecureData(_localModeKey);
  }
  
  /// Verifica si existe un usuario
  static Future<bool> userExists(String username) async {
    final users = await _getAllUsers();
    return users.containsKey(username);
  }
  
  /// Verifica si un email ya está registrado
  static Future<bool> emailExists(String email) async {
    final users = await _getAllUsers();
    return users.values.any((user) => user['email'] == email);
  }
}