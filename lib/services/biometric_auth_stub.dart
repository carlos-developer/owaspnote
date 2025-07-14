/// Stub implementation for platforms that don't support biometric authentication
class BiometricAuth {
  static Future<bool> canCheckBiometrics() async => false;
  
  static Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
    bool stickyAuth = true,
  }) async => true; // Always allow on web for development
}