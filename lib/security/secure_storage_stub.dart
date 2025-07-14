
/// Web implementation for secure storage using localStorage
class SecureStorageImpl {
  // Simple in-memory storage for web development
  static final Map<String, String> _storage = {};
  
  static Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }
  
  static Future<String?> read({required String key}) async {
    return _storage[key];
  }
  
  static Future<void> delete({required String key}) async {
    _storage.remove(key);
  }
  
  static Future<void> deleteAll() async {
    _storage.clear();
  }
  
  static Future<Map<String, String>> readAll() async {
    return Map<String, String>.from(_storage);
  }
}