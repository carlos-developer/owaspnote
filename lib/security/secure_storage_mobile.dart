import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Mobile implementation for secure storage
class SecureStorageImpl {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'secure_prefs',
      preferencesKeyPrefix: 'secure_',
    ),
    iOptions: IOSOptions(
      // Los datos solo son accesibles cuando el dispositivo está desbloqueado
    ),
  );
  
  static Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }
  
  static Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }
  
  static Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }
  
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
  
  static Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}