import 'package:local_auth/local_auth.dart';

/// Mobile implementation for biometric authentication
class BiometricAuth {
  static final _localAuth = LocalAuthentication();
  
  static Future<bool> canCheckBiometrics() async {
    return await _localAuth.canCheckBiometrics;
  }
  
  static Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
    bool stickyAuth = true,
  }) async {
    return await _localAuth.authenticate(
      localizedReason: localizedReason,
      options: AuthenticationOptions(
        biometricOnly: biometricOnly,
        stickyAuth: stickyAuth,
      ),
    );
  }
}