import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Security service for handling app security features
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool _isInitialized = false;
  static bool _isJailbroken = false;
  static String? _deviceId;
  static bool _isScreenRecordingActive = false;
  static bool _isScreenshotPrevented = false;

  /// Initialize security service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check device security
      await _checkDeviceSecurity();

      // Get device ID
      await _getDeviceId();

      // Check for jailbreak/root
      await _checkJailbreakRoot();

      _isInitialized = true;
      debugPrint('SecurityService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SecurityService: $e');
    }
  }

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access the app',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
      return false;
    }
  }

  /// Check device security status
  static Future<void> _checkDeviceSecurity() async {
    try {
      // Check if device has screen lock
      final hasScreenLock = await _localAuth.isDeviceSupported();
      debugPrint('Device has screen lock: $hasScreenLock');
    } catch (e) {
      debugPrint('Error checking device security: $e');
    }
  }

  /// Get unique device ID
  static Future<void> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
      }

      debugPrint('Device ID: $_deviceId');
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
  }

  /// Check for jailbreak/root
  static Future<void> _checkJailbreakRoot() async {
    try {
      if (Platform.isAndroid) {
        _isJailbroken = await _checkAndroidRoot();
      } else if (Platform.isIOS) {
        _isJailbroken = await _checkIOSJailbreak();
      }

      debugPrint('Device is jailbroken/rooted: $_isJailbroken');
    } catch (e) {
      debugPrint('Error checking jailbreak/root: $e');
    }
  }

  /// Check Android root
  static Future<bool> _checkAndroidRoot() async {
    try {
      // Check for common root files
      final rootFiles = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
      ];

      for (final file in rootFiles) {
        if (await File(file).exists()) {
          return true;
        }
      }

      // Check for root management apps would require additional platform channel implementation
      // For now, return false
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check iOS jailbreak
  static Future<bool> _checkIOSJailbreak() async {
    try {
      // Check for common jailbreak files
      final jailbreakFiles = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
      ];

      for (final file in jailbreakFiles) {
        if (await File(file).exists()) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Generate secure hash
  static String generateSecureHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validate app integrity
  static Future<bool> validateAppIntegrity() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      // Check if app is signed properly
      // This is a basic check - in production, you'd want more sophisticated validation
      final isValid =
          packageInfo.packageName.isNotEmpty && packageInfo.version.isNotEmpty;

      debugPrint('App integrity valid: $isValid');
      return isValid;
    } catch (e) {
      debugPrint('Error validating app integrity: $e');
      return false;
    }
  }

  /// Check if device is secure
  static bool get isDeviceSecure => !_isJailbroken;

  /// Get device ID
  static String? get deviceId => _deviceId;

  /// Check if running on emulator
  static Future<bool> isRunningOnEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.isPhysicalDevice == false;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.isPhysicalDevice == false;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking emulator: $e');
      return false;
    }
  }

  /// Prevent screenshots (Android and iOS)
  static Future<void> preventScreenshots(bool prevent) async {
    try {
      const platform = MethodChannel('security/screenshots');
      await platform.invokeMethod('preventScreenshots', prevent);

      if (kDebugMode) {
        print(
            'DEBUG: ${prevent ? "Enabled" : "Disabled"} screenshot prevention on ${Platform.operatingSystem}');
      }
    } catch (e) {
      debugPrint('Error preventing screenshots: $e');
      if (kDebugMode) {
        print('DEBUG: ❌ Screenshot prevention failed: $e');
      }
    }
  }

  /// Test if screenshot protection is active (Android only)
  static Future<bool> testScreenshotProtection() async {
    if (!Platform.isAndroid) return false;

    try {
      const platform = MethodChannel('security/screenshots');
      final bool isProtected =
          await platform.invokeMethod('testScreenshotProtection');

      if (kDebugMode) {
        print('DEBUG: 🧪 Screenshot protection test result: $isProtected');
      }

      return isProtected;
    } catch (e) {
      debugPrint('Error testing screenshot protection: $e');
      return false;
    }
  }

  /// Clear app data on security breach
  static Future<void> clearAppDataOnBreach() async {
    try {
      // Clear sensitive data from storage
      // This would typically involve clearing SharedPreferences,
      // secure storage, and any cached data
      debugPrint('Clearing app data due to security breach');
    } catch (e) {
      debugPrint('Error clearing app data: $e');
    }
  }

  /// Log security event
  static void logSecurityEvent(String event, [Map<String, dynamic>? data]) {
    debugPrint('Security Event: $event');
    if (data != null) {
      debugPrint('Data: $data');
    }

    // In production, you'd want to send this to your security monitoring system
  }

  /// Check app permissions
  static Future<Map<String, bool>> checkAppPermissions() async {
    try {
      // This would require platform-specific implementation
      // For now, return empty map
      return {};
    } catch (e) {
      debugPrint('Error checking app permissions: $e');
      return {};
    }
  }

  /// Validate network security
  static bool validateNetworkSecurity(String url) {
    try {
      final uri = Uri.parse(url);

      // Ensure HTTPS is used
      if (uri.scheme != 'https') {
        logSecurityEvent('Insecure network request', {'url': url});
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error validating network security: $e');
      return false;
    }
  }

  /// Enable comprehensive screen protection (screenshots + screen recording)
  static Future<void> enableScreenProtection() async {
    try {
      await preventScreenshots(true);
      await preventScreenRecording(true);
      _isScreenshotPrevented = true;

      if (kDebugMode) {
        print('DEBUG: ✅ Screen protection enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error enabling screen protection: $e');
      }
    }
  }

  /// Disable comprehensive screen protection
  static Future<void> disableScreenProtection() async {
    try {
      await preventScreenshots(false);
      await preventScreenRecording(false);
      _isScreenshotPrevented = false;

      if (kDebugMode) {
        print('DEBUG: ✅ Screen protection disabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error disabling screen protection: $e');
      }
    }
  }

  /// Prevent screen recording (iOS and Android)
  static Future<void> preventScreenRecording(bool prevent) async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('security/screen_recording');
        await platform.invokeMethod('preventScreenRecording', prevent);
      } else if (Platform.isIOS) {
        const platform = MethodChannel('security/screen_recording');
        await platform.invokeMethod('preventScreenRecording', prevent);
      }

      if (kDebugMode) {
        print(
            'DEBUG: ${prevent ? "Enabled" : "Disabled"} screen recording prevention');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error preventing screen recording: $e');
      }
    }
  }

  /// Check if screen recording is active (iOS only)
  static Future<bool> isScreenRecordingActive() async {
    try {
      if (Platform.isIOS) {
        const platform = MethodChannel('security/screen_recording');
        final result = await platform.invokeMethod('isScreenRecordingActive');
        _isScreenRecordingActive = result ?? false;

        if (_isScreenRecordingActive) {
          await _logSecurityBreach('screen_recording_detected');
        }

        return _isScreenRecordingActive;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error checking screen recording: $e');
      }
      return false;
    }
  }

  /// Monitor screen recording status (iOS)
  static Future<void> startScreenRecordingMonitoring() async {
    if (!Platform.isIOS) return;

    try {
      const platform = MethodChannel('security/screen_recording');
      await platform.invokeMethod('startMonitoring');

      // Set up listener for screen recording events
      platform.setMethodCallHandler((call) async {
        if (call.method == 'screenRecordingStatusChanged') {
          final isRecording = call.arguments['isRecording'] ?? false;
          _isScreenRecordingActive = isRecording;

          if (isRecording) {
            await _handleScreenRecordingDetected();
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error starting screen recording monitoring: $e');
      }
    }
  }

  /// Handle screen recording detection
  static Future<void> _handleScreenRecordingDetected() async {
    try {
      await _logSecurityBreach('screen_recording_detected');

      // Optionally blur the screen or show warning
      const platform = MethodChannel('security/screen_recording');
      await platform.invokeMethod('showRecordingWarning');

      if (kDebugMode) {
        print('DEBUG: ⚠️ Screen recording detected!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error handling screen recording detection: $e');
      }
    }
  }

  /// Log security breach to Firestore
  static Future<void> _logSecurityBreach(String breachType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('mobile_users').doc(user.uid).update({
        'securityEvents': FieldValue.arrayUnion([
          {
            'type': breachType,
            'timestamp': FieldValue.serverTimestamp(),
            'deviceId': _deviceId,
            'details': 'Security breach detected',
          }
        ]),
      });
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error logging security breach: $e');
      }
    }
  }

  /// Get screen protection status
  static bool get isScreenProtectionEnabled => _isScreenshotPrevented;

  /// Get screen recording status
  static bool get isScreenRecordingDetected => _isScreenRecordingActive;
}
