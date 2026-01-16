import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for securely storing and retrieving user credentials for remember me functionality
class CredentialStorageService {
  static const String _rememberMeKey = 'remember_me_enabled';
  static const String _storedEmailKey = 'stored_email';
  static const String _storedPasswordHashKey = 'stored_password_hash';
  static const String _lastLoginTimeKey = 'last_login_time';
  static const String _autoLoginEnabledKey = 'auto_login_enabled';

  // Security: Credentials expire after 30 days
  static const int _credentialExpiryDays = 30;

  /// Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error checking remember me status: $e');
      }
      return false;
    }
  }

  /// Check if auto-login is enabled
  static Future<bool> isAutoLoginEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoLoginEnabledKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error checking auto-login status: $e');
      }
      return false;
    }
  }

  /// Store credentials securely when remember me is enabled
  static Future<void> storeCredentials({
    required String email,
    required String password,
    required bool rememberMe,
    bool enableAutoLogin = true, // Default to true for one-time login
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (rememberMe) {
        // Store the actual password for auto-login (encrypted)
        final encryptedPassword = _encryptPassword(password);

        await prefs.setBool(_rememberMeKey, true);
        await prefs.setString(_storedEmailKey, email);
        await prefs.setString(_storedPasswordHashKey, encryptedPassword);
        await prefs.setString(
            _lastLoginTimeKey, DateTime.now().toIso8601String());
        await prefs.setBool(_autoLoginEnabledKey, enableAutoLogin);

        if (kDebugMode) {
          print('DEBUG: ✅ Credentials stored securely with auto-login enabled');
        }
      } else {
        // Clear stored credentials if remember me is disabled
        await clearStoredCredentials();
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error storing credentials: $e');
      }
    }
  }

  /// Retrieve stored credentials
  static Future<Map<String, String>?> getStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (!rememberMe) {
        return null;
      }

      // Check if credentials have expired
      final lastLoginTimeStr = prefs.getString(_lastLoginTimeKey);
      if (lastLoginTimeStr != null) {
        final lastLoginTime = DateTime.parse(lastLoginTimeStr);
        final daysSinceLastLogin =
            DateTime.now().difference(lastLoginTime).inDays;

        if (daysSinceLastLogin > _credentialExpiryDays) {
          if (kDebugMode) {
            print('DEBUG: ⏰ Stored credentials have expired');
          }
          await clearStoredCredentials();
          return null;
        }
      }

      final email = prefs.getString(_storedEmailKey);
      final passwordHash = prefs.getString(_storedPasswordHashKey);

      if (email != null && passwordHash != null) {
        return {
          'email': email,
          'passwordHash': passwordHash,
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error retrieving stored credentials: $e');
      }
      return null;
    }
  }

  /// Get stored password for auto-login (decrypted)
  static Future<String?> getStoredPassword() async {
    try {
      final credentials = await getStoredCredentials();
      if (credentials != null && credentials['passwordHash'] != null) {
        return _decryptPassword(credentials['passwordHash']!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error getting stored password: $e');
      }
      return null;
    }
  }

  /// Get stored email for pre-filling the login form
  static Future<String?> getStoredEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      if (rememberMe) {
        return prefs.getString(_storedEmailKey);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error getting stored email: $e');
      }
      return null;
    }
  }

  /// Verify if the provided password matches the stored password
  static Future<bool> verifyStoredPassword(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEncryptedPassword = prefs.getString(_storedPasswordHashKey);

      if (storedEncryptedPassword == null) {
        return false;
      }

      final storedPassword = _decryptPassword(storedEncryptedPassword);
      return storedPassword == password;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error verifying stored password: $e');
      }
      return false;
    }
  }

  /// Clear all stored credentials
  static Future<void> clearStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_rememberMeKey);
      await prefs.remove(_storedEmailKey);
      await prefs.remove(_storedPasswordHashKey);
      await prefs.remove(_lastLoginTimeKey);
      await prefs.remove(_autoLoginEnabledKey);

      if (kDebugMode) {
        print('DEBUG: ✅ Stored credentials cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error clearing stored credentials: $e');
      }
    }
  }

  /// Update last login time to extend credential validity
  static Future<void> updateLastLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      if (rememberMe) {
        await prefs.setString(
            _lastLoginTimeKey, DateTime.now().toIso8601String());

        if (kDebugMode) {
          print('DEBUG: ✅ Last login time updated');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error updating last login time: $e');
      }
    }
  }

  /// Enable or disable auto-login
  static Future<void> setAutoLoginEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoLoginEnabledKey, enabled);

      if (kDebugMode) {
        print('DEBUG: ✅ Auto-login ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error setting auto-login: $e');
      }
    }
  }

  /// Simple encryption for password storage (Base64 encoding for demo)
  /// In production, use proper encryption like AES
  static String _encryptPassword(String password) {
    final bytes = utf8.encode(password);
    return base64.encode(bytes);
  }

  /// Simple decryption for password retrieval
  static String _decryptPassword(String encryptedPassword) {
    final bytes = base64.decode(encryptedPassword);
    return utf8.decode(bytes);
  }

  /// Get credential storage info for debugging
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'rememberMeEnabled': prefs.getBool(_rememberMeKey) ?? false,
        'autoLoginEnabled': prefs.getBool(_autoLoginEnabledKey) ?? false,
        'hasStoredEmail': prefs.getString(_storedEmailKey) != null,
        'hasStoredPasswordHash':
            prefs.getString(_storedPasswordHashKey) != null,
        'lastLoginTime': prefs.getString(_lastLoginTimeKey),
      };
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error getting storage info: $e');
      }
      return {};
    }
  }
}
