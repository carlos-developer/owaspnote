/// Stub implementation for platforms that don't support jailbreak detection
class PlatformChecker {
  static Future<bool> isJailbroken() async => false;
  static Future<bool> isDeveloperMode() async => false;
  static Future<bool> checkStoreInstallation() async => true;
  static bool isDebuggerAttached() => false;
  static Future<bool> checkForProxy() async => false;
  static Future<String> calculateAppHash() async => 'web_hash';
}