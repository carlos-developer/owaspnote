import 'dart:io';
import 'package:crypto/crypto.dart';
// import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Mobile implementation for jailbreak/root detection
class PlatformChecker {
  static Future<bool> isJailbroken() async {
    // Manual jailbreak/root detection
    if (Platform.isAndroid) {
      return _checkAndroidRoot();
    } else if (Platform.isIOS) {
      return _checkIOSJailbreak();
    }
    return false;
  }
  
  static Future<bool> isDeveloperMode() async {
    // Check for developer mode indicators
    try {
      // Check if running in debug mode
      if (Platform.executable.contains('flutter_tester')) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> checkStoreInstallation() async {
    // En producción, verificar si viene de tienda oficial
    if (Platform.isIOS) {
      // Verificar receipt de App Store
      return true; // Por ahora, siempre true
    } else if (Platform.isAndroid) {
      // Verificar Google Play signature
      return true; // Por ahora, siempre true
    }
    return false;
  }
  
  static bool isDebuggerAttached() {
    // Detecta si hay un debugger conectado
    return Platform.executable.contains('flutter_tester');
  }
  
  static Future<bool> checkForProxy() async {
    try {
      // Verifica configuración de proxy del sistema
      final proxyEnv = Platform.environment['HTTP_PROXY'] ?? 
                       Platform.environment['HTTPS_PROXY'];
      return proxyEnv != null && proxyEnv.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  static Future<String> calculateAppHash() async {
    try {
      final appPath = Platform.resolvedExecutable;
      final appFile = File(appPath);
      final bytes = await appFile.readAsBytes();
      return sha256.convert(bytes).toString();
    } catch (e) {
      return '';
    }
  }
  
  /// Check for Android root
  static bool _checkAndroidRoot() {
    // Check for common root indicators
    final rootPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su'
    ];
    
    for (final path in rootPaths) {
      if (File(path).existsSync()) {
        return true;
      }
    }
    
    // Check for root apps (future implementation)
    // final rootApps = [
    //   'com.koushikdutta.superuser',
    //   'com.thirdparty.superuser',
    //   'eu.chainfire.supersu',
    //   'com.noshufou.android.su',
    //   'com.zachspong.temprootremovejb',
    //   'com.ramdroid.appquarantine',
    // ];
    
    // Check build tags
    try {
      final buildTags = Platform.environment['ANDROID_BUILD_TAGS'] ?? '';
      if (buildTags.contains('test-keys')) {
        return true;
      }
    } catch (e) {
      // Ignore
    }
    
    return false;
  }
  
  /// Check for iOS jailbreak
  static bool _checkIOSJailbreak() {
    // Check for common jailbreak paths
    final jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/Applications/FakeCarrier.app',
      '/Applications/Icy.app',
      '/Applications/IntelliScreen.app',
      '/Applications/SBSettings.app',
    ];
    
    for (final path in jailbreakPaths) {
      if (File(path).existsSync()) {
        return true;
      }
    }
    
    // Check if we can write to system directories
    try {
      const testPath = '/private/test_jb.txt';
      File(testPath).writeAsStringSync('test');
      File(testPath).deleteSync();
      return true; // If we can write, it's jailbroken
    } catch (e) {
      // Expected - not jailbroken
    }
    
    return false;
  }
}