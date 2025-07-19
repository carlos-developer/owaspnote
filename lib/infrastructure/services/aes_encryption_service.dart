import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import '../../domain/services/encryption_service.dart';

class AesEncryptionService implements EncryptionService {
  @override
  Future<String> encrypt(String plainText, String key) async {
    try {
      final keyBytes = _padKey(key);
      final encrypter = Encrypter(AES(Key(Uint8List.fromList(keyBytes))));
      final iv = IV.fromSecureRandom(16);
      
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      return '${base64.encode(iv.bytes)}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  @override
  Future<String> decrypt(String encryptedText, String key) async {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted text format');
      }

      final ivBytes = base64.decode(parts[0]);
      final encryptedData = parts[1];

      final keyBytes = _padKey(key);
      final encrypter = Encrypter(AES(Key(Uint8List.fromList(keyBytes))));
      final iv = IV(ivBytes);

      final decrypted = encrypter.decrypt64(encryptedData, iv: iv);
      
      return decrypted;
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  @override
  String generateKey() {
    final key = List<int>.generate(32, (i) => 
      DateTime.now().millisecondsSinceEpoch + i);
    return base64.encode(key);
  }

  List<int> _padKey(String key) {
    final keyBytes = utf8.encode(key);
    if (keyBytes.length >= 32) {
      return keyBytes.take(32).toList();
    }
    
    final padded = List<int>.filled(32, 0);
    for (int i = 0; i < keyBytes.length; i++) {
      padded[i] = keyBytes[i];
    }
    return padded;
  }
}