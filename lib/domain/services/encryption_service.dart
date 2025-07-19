abstract class EncryptionService {
  Future<String> encrypt(String plainText, String key);
  Future<String> decrypt(String encryptedText, String key);
  String generateKey();
}