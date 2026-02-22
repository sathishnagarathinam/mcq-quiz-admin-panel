import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'demo_account_service.dart';

/// Device Authentication Service
/// Handles device binding and validation for secure user authentication
class DeviceAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static String? _cachedDeviceId;
  static Map<String, dynamic>? _cachedDeviceInfo;
  static String? _cachedPersistentDeviceId;

  /// Get base device identifier (hardware-based with enhanced uniqueness)
  static Future<String> _getBaseDeviceId() async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔍 Getting enhanced base device ID...');
      }

      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        // Create a more robust device identifier by combining multiple factors
        final components = [
          androidInfo.id.isNotEmpty && androidInfo.id != 'unknown'
              ? androidInfo.id
              : null,
          androidInfo.fingerprint,
          androidInfo.brand,
          androidInfo.model,
          androidInfo.manufacturer,
          androidInfo.product,
          androidInfo.device,
          androidInfo.hardware,
          androidInfo.version.release,
          androidInfo.version.sdkInt.toString(),
        ]
            .where((component) => component != null && component.isNotEmpty)
            .toList();

        // Create a unique hash from all available components
        final combinedString = components.join('_');
        deviceId = sha256.convert(utf8.encode(combinedString)).toString();

        if (kDebugMode) {
          print('DEBUG: 📱 Android device components: ${components.length}');
          print(
              'DEBUG: 🔑 Generated device ID: ${deviceId.substring(0, 8)}...');
        }
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;

        // Create a more robust device identifier by combining multiple factors
        final components = [
          iosInfo.identifierForVendor?.isNotEmpty == true
              ? iosInfo.identifierForVendor
              : null,
          iosInfo.name,
          iosInfo.model,
          iosInfo.localizedModel,
          iosInfo.systemName,
          iosInfo.systemVersion,
          iosInfo.utsname.machine,
          iosInfo.utsname.sysname,
          iosInfo.utsname.release,
        ]
            .where((component) => component != null && component.isNotEmpty)
            .toList();

        // Create a unique hash from all available components
        final combinedString = components.join('_');
        deviceId = sha256.convert(utf8.encode(combinedString)).toString();

        if (kDebugMode) {
          print('DEBUG: 📱 iOS device components: ${components.length}');
          print(
              'DEBUG: 🔑 Generated device ID: ${deviceId.substring(0, 8)}...');
        }
      } else {
        throw UnsupportedError('Platform not supported');
      }

      return deviceId;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error getting base device ID: $e');
      }
      throw Exception('Failed to get base device ID: $e');
    }
  }

  /// Get or create a persistent unique device identifier (OPTIMIZED)
  /// This uses multiple storage layers for maximum persistence across app reinstalls
  /// STRICT ONE-USER-PER-DEVICE POLICY: Device ID must remain same across updates/reinstalls
  static Future<String> _getPersistentDeviceId() async {
    if (_cachedPersistentDeviceId != null) return _cachedPersistentDeviceId!;

    // First try to validate and recover existing device ID with timeout
    try {
      final recoveredId = await _validateAndRecoverDeviceId()
          .timeout(const Duration(seconds: 8));
      if (recoveredId.isNotEmpty) {
        _cachedPersistentDeviceId = recoveredId;
        return recoveredId;
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'DEBUG: ⚠️ Device ID recovery failed/timed out, generating new: $e');
      }
    }

    try {
      const String secureKey = 'secure_persistent_device_id';
      const String prefsKey = 'persistent_device_id';
      const String hardwareKey = 'hardware_device_signature';

      // Layer 1: Try to get from secure storage (survives app reinstalls) with timeout
      String? secureStoredId = await _secureStorage
          .read(key: secureKey)
          .timeout(const Duration(seconds: 5));

      // Layer 2: Try to get from shared preferences (faster access) with timeout
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      String? prefsStoredId = prefs.getString(prefsKey);

      // Layer 3: Try device-specific backup storage (ultra-persistent) with timeout
      final deviceSpecificKey = await _getDeviceSpecificStorageKey()
          .timeout(const Duration(seconds: 5));
      String? backupStoredId = await _secureStorage
          .read(key: 'backup_device_id_$deviceSpecificKey')
          .timeout(const Duration(seconds: 5));

      // Layer 4: Generate hardware-based signature for validation
      final baseDeviceId = await _getBaseDeviceId();
      String? hardwareSignature = await _secureStorage.read(key: hardwareKey);

      // If we have a secure stored ID and it matches our hardware, use it
      if (secureStoredId != null && secureStoredId.isNotEmpty) {
        // Validate against hardware signature if available
        if (hardwareSignature != null) {
          final currentHardwareHash =
              sha256.convert(utf8.encode(baseDeviceId)).toString();
          if (hardwareSignature == currentHardwareHash) {
            _cachedPersistentDeviceId = secureStoredId;
            // Sync to shared preferences for faster future access
            await prefs.setString(prefsKey, secureStoredId);
            if (kDebugMode) {
              print(
                  'DEBUG: 📱 Retrieved secure persistent device ID: ${secureStoredId.substring(0, 8)}...');
            }
            return secureStoredId;
          }
        } else {
          // No hardware signature stored yet, but we have secure ID - use it and create signature
          _cachedPersistentDeviceId = secureStoredId;
          await prefs.setString(prefsKey, secureStoredId);
          await _secureStorage.write(
              key: hardwareKey,
              value: sha256.convert(utf8.encode(baseDeviceId)).toString());
          if (kDebugMode) {
            print(
                'DEBUG: 📱 Retrieved secure device ID and created hardware signature: ${secureStoredId.substring(0, 8)}...');
          }
          return secureStoredId;
        }
      }

      // If we have a preferences stored ID, migrate it to secure storage
      if (prefsStoredId != null && prefsStoredId.isNotEmpty) {
        await _secureStorage.write(key: secureKey, value: prefsStoredId);
        await _secureStorage.write(
            key: hardwareKey,
            value: sha256.convert(utf8.encode(baseDeviceId)).toString());
        // Also store in backup location for ultra-persistence
        await _secureStorage.write(
            key: 'backup_device_id_$deviceSpecificKey', value: prefsStoredId);
        _cachedPersistentDeviceId = prefsStoredId;
        if (kDebugMode) {
          print(
              'DEBUG: 📱 Migrated device ID to secure storage: ${prefsStoredId.substring(0, 8)}...');
        }
        return prefsStoredId;
      }

      // If we have a backup stored ID, restore it to primary storage
      if (backupStoredId != null && backupStoredId.isNotEmpty) {
        await _secureStorage.write(key: secureKey, value: backupStoredId);
        await _secureStorage.write(
            key: hardwareKey,
            value: sha256.convert(utf8.encode(baseDeviceId)).toString());
        await prefs.setString(prefsKey, backupStoredId);
        _cachedPersistentDeviceId = backupStoredId;
        if (kDebugMode) {
          print(
              'DEBUG: 🔄 Restored device ID from backup storage: ${backupStoredId.substring(0, 8)}...');
        }
        return backupStoredId;
      }

      // Generate a new ultra-persistent device ID using stable hardware characteristics
      // This ensures the device ID remains the same across app updates and reinstalls
      final persistentId = await _createUltraPersistentDeviceId()
          .timeout(const Duration(seconds: 8));

      // Store in all layers for maximum persistence with timeouts
      await Future.wait([
        _secureStorage
            .write(key: secureKey, value: persistentId)
            .timeout(const Duration(seconds: 3)),
        _secureStorage
            .write(
                key: hardwareKey,
                value: sha256.convert(utf8.encode(baseDeviceId)).toString())
            .timeout(const Duration(seconds: 3)),
        _secureStorage
            .write(
                key: 'backup_device_id_$deviceSpecificKey', value: persistentId)
            .timeout(const Duration(seconds: 3)),
        prefs.setString(prefsKey, persistentId),
      ]).timeout(const Duration(seconds: 10));
      _cachedPersistentDeviceId = persistentId;

      if (kDebugMode) {
        print(
            'DEBUG: 🆕 Generated new multi-layer persistent device ID: ${persistentId.substring(0, 8)}...');
      }

      return persistentId;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error getting persistent device ID: $e');
      }
      throw Exception('Failed to get persistent device ID: $e');
    }
  }

  /// Debug method to check current device ID status and migration state
  static Future<Map<String, dynamic>> getDeviceIdDebugInfo() async {
    try {
      final currentDeviceId = await _getPersistentDeviceId();
      final legacyDeviceId = await _generateLegacyDeviceId();
      final baseDeviceId = await _getBaseDeviceId();
      final deviceSpecificKey = await _getDeviceSpecificStorageKey();

      final prefs = await SharedPreferences.getInstance();
      final prefsDeviceId = prefs.getString('persistent_device_id');

      final secureDeviceId =
          await _secureStorage.read(key: 'secure_persistent_device_id');
      final backupDeviceId =
          await _secureStorage.read(key: 'backup_device_id_$deviceSpecificKey');

      return {
        'currentDeviceId': currentDeviceId,
        'legacyDeviceId': legacyDeviceId,
        'baseDeviceId': baseDeviceId,
        'deviceSpecificKey': deviceSpecificKey,
        'prefsDeviceId': prefsDeviceId,
        'secureDeviceId': secureDeviceId,
        'backupDeviceId': backupDeviceId,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Clear the persistent device ID (for testing or device reset scenarios)
  /// WARNING: This will break device binding and allow new user registration
  static Future<void> clearPersistentDeviceId() async {
    try {
      // Clear from all storage layers
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('persistent_device_id');
      await _secureStorage.delete(key: 'secure_persistent_device_id');
      await _secureStorage.delete(key: 'hardware_device_signature');

      // Also clear any device-specific backup keys
      final deviceSpecificKey = await _getDeviceSpecificStorageKey();
      await _secureStorage.delete(key: 'backup_device_id_$deviceSpecificKey');

      _cachedPersistentDeviceId = null;

      if (kDebugMode) {
        print(
            'DEBUG: 🗑️ Cleared persistent device ID from all storage layers');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error clearing persistent device ID: $e');
      }
    }
  }

  /// Clear cached device ID only (for testing device ID consistency)
  static void clearCachedDeviceId() {
    _cachedPersistentDeviceId = null;
    if (kDebugMode) {
      print('DEBUG: 🧹 Cleared cached device ID');
    }
  }

  /// Get a device-specific storage key that's based on hardware characteristics
  /// This key should remain stable across app reinstalls for the same device
  static Future<String> _getDeviceSpecificStorageKey() async {
    try {
      final baseDeviceId = await _getBaseDeviceId();
      final deviceInfo = await getDeviceInfo();

      // Create a stable key based on hardware that doesn't change
      String stableKey = '';

      if (Platform.isAndroid) {
        final androidInfo = deviceInfo['android'] as Map<String, dynamic>?;
        if (androidInfo != null) {
          // Use the most stable identifiers for the key
          stableKey =
              '${androidInfo['brand']}_${androidInfo['model']}_${androidInfo['manufacturer']}'
                  .replaceAll(' ', '_')
                  .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
        }
      } else if (Platform.isIOS) {
        final iosInfo = deviceInfo['ios'] as Map<String, dynamic>?;
        if (iosInfo != null) {
          stableKey = '${iosInfo['model']}_${iosInfo['systemName']}'
              .replaceAll(' ', '_')
              .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
        }
      }

      // Fallback to a hash of the base device ID
      if (stableKey.isEmpty) {
        stableKey = sha256
            .convert(utf8.encode(baseDeviceId))
            .toString()
            .substring(0, 16);
      }

      return stableKey;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error creating device-specific storage key: $e');
      }
      // Fallback to a generic key
      return 'default_device_key';
    }
  }

  /// Validate and recover device ID in case of hardware signature mismatch
  /// This handles cases where OS updates might change some hardware identifiers
  static Future<String> _validateAndRecoverDeviceId() async {
    try {
      const String secureKey = 'secure_persistent_device_id';
      const String hardwareKey = 'hardware_device_signature';

      String? secureStoredId = await _secureStorage.read(key: secureKey);
      String? storedHardwareSignature =
          await _secureStorage.read(key: hardwareKey);

      if (secureStoredId == null || storedHardwareSignature == null) {
        // No stored data, generate new
        return await _getPersistentDeviceId();
      }

      final currentBaseDeviceId = await _getBaseDeviceId();
      final currentHardwareHash =
          sha256.convert(utf8.encode(currentBaseDeviceId)).toString();

      // If hardware signature matches, device ID is still valid
      if (storedHardwareSignature == currentHardwareHash) {
        return secureStoredId;
      }

      // Hardware signature mismatch - this could be due to OS update
      // Check if the core hardware identifiers are still similar
      if (await _isHardwareStillSimilar(
          storedHardwareSignature, currentHardwareHash)) {
        // Update hardware signature but keep the same device ID
        await _secureStorage.write(
            key: hardwareKey, value: currentHardwareHash);
        if (kDebugMode) {
          print(
              'DEBUG: 🔄 Updated hardware signature due to minor hardware changes');
        }
        return secureStoredId;
      }

      // Major hardware change detected - this might be a different device
      if (kDebugMode) {
        print(
            'DEBUG: ⚠️ Major hardware change detected - generating new device ID');
      }

      // Clear old data and generate new device ID
      await clearPersistentDeviceId();
      return await _getPersistentDeviceId();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error validating device ID: $e');
      }
      // Fallback to generating new device ID
      return await _getPersistentDeviceId();
    }
  }

  /// Check if hardware is still similar (handles minor OS update changes)
  static Future<bool> _isHardwareStillSimilar(
      String oldSignature, String newSignature) async {
    // For now, we'll be conservative and consider any change as significant
    // In the future, this could be enhanced to compare individual hardware components
    // and allow minor changes while detecting major hardware swaps
    return oldSignature == newSignature;
  }

  /// Validate device match with migration support for old device ID formats
  /// This ensures existing users can still sign in after the ultra-persistent update
  static Future<bool> _validateDeviceMatch(
      String currentDeviceId,
      String registeredDeviceId,
      String userId,
      String userEmail,
      String phoneNumber) async {
    try {
      // Direct match - new ultra-persistent device ID
      if (currentDeviceId == registeredDeviceId) {
        if (kDebugMode) {
          print('DEBUG: ✅ Direct device ID match (ultra-persistent)');
        }
        return true;
      }

      // Migration support: Check if registered device ID was created with old method
      // Generate old-style device ID for comparison
      final oldStyleDeviceId = await _generateLegacyDeviceId();

      if (oldStyleDeviceId == registeredDeviceId) {
        if (kDebugMode) {
          print(
              'DEBUG: 🔄 Legacy device ID match - migrating to ultra-persistent');
        }

        // Migrate user to new ultra-persistent device ID
        await _migrateUserToUltraPersistentDeviceId(
            userId, currentDeviceId, userEmail, phoneNumber);
        return true;
      }

      // Check if the base hardware characteristics match (for partial migrations)
      final currentBaseDeviceId = await _getBaseDeviceId();
      if (registeredDeviceId.contains(currentBaseDeviceId)) {
        if (kDebugMode) {
          print(
              'DEBUG: 🔄 Base device ID match - migrating to ultra-persistent');
        }

        // Migrate user to new ultra-persistent device ID
        await _migrateUserToUltraPersistentDeviceId(
            userId, currentDeviceId, userEmail, phoneNumber);
        return true;
      }

      if (kDebugMode) {
        print('DEBUG: ❌ No device ID match found');
        print('DEBUG: Current: ${currentDeviceId.substring(0, 8)}...');
        print('DEBUG: Registered: ${registeredDeviceId.substring(0, 8)}...');
        print('DEBUG: Legacy: ${oldStyleDeviceId.substring(0, 8)}...');
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error validating device match: $e');
      }
      return false;
    }
  }

  /// Generate legacy device ID using the old method for migration support
  static Future<String> _generateLegacyDeviceId() async {
    try {
      final baseDeviceId = await _getBaseDeviceId();

      // This recreates the old device ID generation logic
      // Check if there's an old device ID in shared preferences
      final prefs = await SharedPreferences.getInstance();
      final oldStoredId = prefs.getString('persistent_device_id');

      if (oldStoredId != null && oldStoredId.isNotEmpty) {
        return oldStoredId;
      }

      // If no old stored ID, return the base device ID as fallback
      return baseDeviceId;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error generating legacy device ID: $e');
      }
      return await _getBaseDeviceId();
    }
  }

  /// Migrate user to ultra-persistent device ID in Firestore
  static Future<void> _migrateUserToUltraPersistentDeviceId(String userId,
      String newDeviceId, String userEmail, String phoneNumber) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔄 Migrating user $userId to ultra-persistent device ID');
      }

      // Create enhanced device ID with user data
      final enhancedDeviceId =
          await getEnhancedDeviceId(userId, userEmail, phoneNumber);

      // Update user document in Firestore
      await _firestore.collection('mobile_users').doc(userId).update({
        'registeredDeviceId': enhancedDeviceId,
        'deviceInfo': await getDeviceInfo(),
        'lastDeviceUpdate': FieldValue.serverTimestamp(),
        'migrationStatus': 'ultra_persistent_migrated',
      });

      // Log the migration event
      await _logSecurityEvent(userId, 'device_id_migration', {
        'newDeviceId': newDeviceId,
        'enhancedDeviceId': enhancedDeviceId,
        'details': 'Successfully migrated to ultra-persistent device ID',
      });

      if (kDebugMode) {
        print(
            'DEBUG: ✅ Successfully migrated user to ultra-persistent device ID');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'DEBUG: ❌ Error migrating user to ultra-persistent device ID: $e');
      }
      throw Exception('Failed to migrate device ID: $e');
    }
  }

  /// Create ultra-persistent device fingerprint using multiple hardware characteristics
  /// This method creates a device ID that should remain stable across app updates/reinstalls
  /// CRITICAL: This ensures STRICT ONE-USER-PER-DEVICE policy enforcement
  static Future<String> _createUltraPersistentDeviceId() async {
    try {
      final baseDeviceId = await _getBaseDeviceId();

      // Create multiple entropy sources for maximum uniqueness and persistence
      final deviceInfo = await getDeviceInfo();

      // Extract stable hardware characteristics that don't change with OS updates
      String stableHardwareId = '';

      if (Platform.isAndroid) {
        final androidInfo = deviceInfo['android'] as Map<String, dynamic>?;
        if (androidInfo != null) {
          // Use most stable Android identifiers
          final stableComponents = [
            androidInfo['brand'] ?? '', // Device brand (Samsung, Google, etc.)
            androidInfo['manufacturer'] ?? '', // Manufacturer
            androidInfo['model'] ?? '', // Device model
            androidInfo['product'] ?? '', // Product name
            androidInfo['device'] ?? '', // Device name
            androidInfo['hardware'] ?? '', // Hardware platform
            androidInfo['board'] ?? '', // Board name
            androidInfo['bootloader'] ?? '', // Bootloader version
            androidInfo['display'] ?? '', // Display ID
          ];
          stableHardwareId =
              stableComponents.where((c) => c.isNotEmpty).join(':');
        }
      } else if (Platform.isIOS) {
        final iosInfo = deviceInfo['ios'] as Map<String, dynamic>?;
        if (iosInfo != null) {
          // Use most stable iOS identifiers
          final stableComponents = [
            iosInfo['model'] ?? '', // Device model
            iosInfo['localizedModel'] ?? '', // Localized model
            iosInfo['name'] ?? '', // Device name
            iosInfo['systemName'] ?? '', // System name (iOS)
            iosInfo['utsname.machine'] ?? '', // Machine identifier
          ];
          stableHardwareId =
              stableComponents.where((c) => c.isNotEmpty).join(':');
        }
      }

      // Combine base device ID with stable hardware characteristics
      final combinedId =
          '$baseDeviceId:$stableHardwareId:${Platform.operatingSystem}';

      // Create SHA-256 hash for consistent length and security
      final ultraPersistentId =
          sha256.convert(utf8.encode(combinedId)).toString();

      if (kDebugMode) {
        print(
            'DEBUG: 🔒 Created ultra-persistent device ID: ${ultraPersistentId.substring(0, 8)}...');
        print(
            'DEBUG: 📱 Stable hardware components: ${stableHardwareId.length} chars');
      }

      return ultraPersistentId;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error creating ultra-persistent device ID: $e');
      }
      // Fallback to base device ID
      return await _getBaseDeviceId();
    }
  }

  /// Get unique device identifier (for backward compatibility)
  /// @deprecated Use getUserSpecificDeviceId instead for new implementations
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final baseDeviceId = await _getBaseDeviceId();
    _cachedDeviceId = baseDeviceId;
    return baseDeviceId;
  }

  /// Get enhanced device identifier that includes user data for uniqueness
  /// This ensures proper device binding validation while maintaining one-user-per-device policy
  static Future<String> getEnhancedDeviceId(
      String userId, String userEmail, String phoneNumber) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔑 Generating enhanced device ID for user: $userId');
      }

      // Get persistent device identifier (more reliable than base device ID)
      final persistentDeviceId = await _getPersistentDeviceId();

      // For strict one-user-per-device policy, we use the persistent device ID
      // and enhance it with a hash of user data for validation purposes
      final userDataHash = sha256
          .convert(utf8.encode('${userId}_${userEmail}_$phoneNumber'))
          .toString();

      // Store both the device ID and user data hash for validation
      // This allows us to verify the correct user is accessing the device
      final enhancedDeviceId = '$persistentDeviceId:$userDataHash';

      if (kDebugMode) {
        print(
            'DEBUG: ✅ Enhanced device ID generated: ${persistentDeviceId.substring(0, 8)}...');
      }

      return enhancedDeviceId;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error generating enhanced device ID: $e');
      }
      throw Exception('Failed to generate enhanced device ID: $e');
    }
  }

  /// Extract base device ID from enhanced device ID
  static String extractBaseDeviceId(String enhancedDeviceId) {
    if (enhancedDeviceId.contains(':')) {
      return enhancedDeviceId.split(':')[0];
    }
    return enhancedDeviceId; // Fallback for old format
  }

  /// Extract user data hash from enhanced device ID
  static String? extractUserDataHash(String enhancedDeviceId) {
    if (enhancedDeviceId.contains(':')) {
      return enhancedDeviceId.split(':')[1];
    }
    return null; // Old format doesn't have user data hash
  }

  /// Get comprehensive device information
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) return _cachedDeviceInfo!;

    try {
      Map<String, dynamic> deviceInfo = {};

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceInfo = {
          'platform': 'android',
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'product': androidInfo.product,
          'device': androidInfo.device,
          'androidId': androidInfo.id,
          'fingerprint': androidInfo.fingerprint,
          'hardware': androidInfo.hardware,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'systemVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceInfo = {
          'platform': 'ios',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'localizedModel': iosInfo.localizedModel,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          'utsname': {
            'machine': iosInfo.utsname.machine,
            'sysname': iosInfo.utsname.sysname,
            'release': iosInfo.utsname.release,
          },
        };
      }

      // Add timestamp
      deviceInfo['registeredAt'] = DateTime.now().toIso8601String();

      _cachedDeviceInfo = deviceInfo;
      return deviceInfo;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error getting device info: $e');
      }
      throw Exception('Failed to get device info: $e');
    }
  }

  /// Check if user has a registered device
  static Future<bool> hasRegisteredDevice(String userId) async {
    try {
      final userDoc =
          await _firestore.collection('mobile_users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      return userData['isDeviceBound'] == true &&
          userData['registeredDeviceId'] != null &&
          userData['registeredDeviceId'].toString().isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error checking registered device: $e');
      }
      return false;
    }
  }

  /// Bind device to user account (first login)
  static Future<bool> bindDeviceToUser(String userId) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔗 Binding device to user: $userId');
      }

      // Get user data to create user-specific device ID
      final userDoc =
          await _firestore.collection('mobile_users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final userEmail = userData['email'] ?? '';
      final phoneNumber = userData['phoneNumber'] ?? '';

      // Bypass device binding for demo account
      if (DemoAccountService.shouldBypassEmailVerification(userEmail)) {
        if (kDebugMode) {
          print('DEBUG: 🎯 Bypassing device binding for demo account');
        }

        // Just mark as device bound without actual binding for demo account
        await _firestore.collection('mobile_users').doc(userId).update({
          'isDeviceBound': true,
          'registeredDeviceId': 'demo_device_bypass',
          'deviceInfo': {'demo': true, 'type': 'demo_account'},
          'deviceRegisteredAt': FieldValue.serverTimestamp(),
        });

        return true;
      }

      // Get persistent device ID to check for existing bindings
      final persistentDeviceId = await _getPersistentDeviceId();
      final deviceInfo = await getDeviceInfo();

      // Check if device is already bound to ANY user (strict one-user-per-device policy)
      final existingBinding =
          await _checkDeviceAlreadyBound(persistentDeviceId, userId);
      if (existingBinding != null) {
        // Log the unauthorized attempt
        await _logSecurityEvent(
            userId, 'device_already_bound_to_another_user', {
          'attemptedDeviceId': persistentDeviceId,
          'existingUserEmail': existingBinding['email'],
          'existingUserId': existingBinding['userId'],
          'details':
              'Attempted to bind device that is already registered to another user',
        });

        throw Exception(
            'This device is already registered to another user. Only one user per device is allowed.');
      }

      // Generate enhanced device ID for this user
      final enhancedDeviceId =
          await getEnhancedDeviceId(userId, userEmail, phoneNumber);

      // Update user document with device information
      final now = DateTime.now();
      await _firestore.collection('mobile_users').doc(userId).update({
        'registeredDeviceId': enhancedDeviceId,
        'deviceInfo': deviceInfo,
        'deviceRegisteredAt': FieldValue.serverTimestamp(),
        'isDeviceBound': true,
        'securityEvents': FieldValue.arrayUnion([
          {
            'type': 'device_bound',
            'timestamp': now.toIso8601String(),
            'deviceId': persistentDeviceId,
            'details':
                'Device successfully bound to account with strict one-user-per-device policy',
          }
        ]),
      });

      if (kDebugMode) {
        print('DEBUG: ✅ Device bound successfully with user-specific ID');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error binding device: $e');
      }
      throw Exception('Failed to bind device: $e');
    }
  }

  /// Validate device for user login with optimized performance
  static Future<DeviceValidationResult> validateDeviceForUser(
      String userId) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔍 Validating device for user: $userId');
      }

      // Add timeout to Firestore query to prevent hanging
      final userDoc =
          await _firestore.collection('mobile_users').doc(userId).get().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception('User data fetch timed out');
        },
      );

      if (!userDoc.exists) {
        return const DeviceValidationResult(
          isValid: false,
          reason: 'User not found',
          action: DeviceValidationAction.signOut,
        );
      }

      final userData = userDoc.data()!;
      final userEmail = userData['email'] ?? '';
      final phoneNumber = userData['phoneNumber'] ?? '';
      final registeredDeviceId = userData['registeredDeviceId'];
      final isDeviceBound = userData['isDeviceBound'] ?? false;

      // Bypass device validation for demo account
      if (DemoAccountService.shouldBypassEmailVerification(userEmail)) {
        if (kDebugMode) {
          print('DEBUG: 🎯 Bypassing device validation for demo account');
        }
        return const DeviceValidationResult(
          isValid: true,
          reason: 'Demo account - device validation bypassed',
          action: DeviceValidationAction.allowAccess,
        );
      }

      // Get current persistent device ID with timeout
      final currentPersistentDeviceId = await _getPersistentDeviceId().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Device ID generation timed out');
        },
      );

      // If device is not bound yet, allow binding
      if (!isDeviceBound || registeredDeviceId == null) {
        return const DeviceValidationResult(
          isValid: true,
          reason: 'Device not bound yet - allowing binding',
          action: DeviceValidationAction.bindDevice,
        );
      }

      // Extract persistent device ID from registered device ID for comparison
      final registeredPersistentDeviceId =
          extractBaseDeviceId(registeredDeviceId);

      // Check if current device matches registered device (with migration support)
      final isDeviceMatch = await _validateDeviceMatch(
          currentPersistentDeviceId,
          registeredPersistentDeviceId,
          userId,
          userEmail,
          phoneNumber);

      if (isDeviceMatch) {
        // Additional validation: check if the user data hash matches (for enhanced device IDs)
        final registeredUserDataHash = extractUserDataHash(registeredDeviceId);
        if (registeredUserDataHash != null) {
          final currentUserDataHash = sha256
              .convert(utf8.encode('${userId}_${userEmail}_$phoneNumber'))
              .toString();
          if (registeredUserDataHash != currentUserDataHash) {
            // User data has changed, this might be a security issue
            await _logSecurityEvent(userId, 'user_data_mismatch', {
              'deviceId': currentPersistentDeviceId,
              'details':
                  'User data hash mismatch - possible account compromise',
            });

            return const DeviceValidationResult(
              isValid: false,
              reason: 'User data validation failed. Please contact support.',
              action: DeviceValidationAction.blockAccess,
            );
          }
        }

        // Log successful validation
        await _logSecurityEvent(userId, 'device_validation_success', {
          'deviceId': currentPersistentDeviceId,
          'details':
              'Device validation successful with strict one-user-per-device policy',
        });

        return const DeviceValidationResult(
          isValid: true,
          reason: 'Device matches registered device',
          action: DeviceValidationAction.allowAccess,
        );
      } else {
        // Log unauthorized access attempt
        await _logSecurityEvent(userId, 'unauthorized_device_access', {
          'attemptedDeviceId': currentPersistentDeviceId,
          'registeredDeviceId': registeredPersistentDeviceId,
          'details': 'Unauthorized device access attempt - different device',
        });

        return const DeviceValidationResult(
          isValid: false,
          reason:
              'This device is not registered to your account. Only one device per user is allowed.',
          action: DeviceValidationAction.blockAccess,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error validating device: $e');
      }

      // Check if this is a timeout or network error for new users
      if (e.toString().contains('timed out') ||
          e.toString().contains('timeout')) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Device validation timed out - checking if new user');
        }

        // For timeout errors, check if user has any device bound
        try {
          final userDoc = await _firestore
              .collection('mobile_users')
              .doc(userId)
              .get()
              .timeout(const Duration(seconds: 5));

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final isDeviceBound = userData['isDeviceBound'] ?? false;

            if (!isDeviceBound) {
              // New user with timeout - allow binding but log the issue
              if (kDebugMode) {
                print(
                    'DEBUG: ⚠️ Allowing new user device binding despite timeout');
              }
              return const DeviceValidationResult(
                isValid: true,
                reason: 'New user - allowing device binding despite timeout',
                action: DeviceValidationAction.bindDevice,
              );
            }
          }
        } catch (timeoutError) {
          if (kDebugMode) {
            print(
                'DEBUG: ❌ Secondary validation also timed out: $timeoutError');
          }
        }
      }

      return const DeviceValidationResult(
        isValid: false,
        reason:
            'Device validation failed. Please ensure you have a stable internet connection and try again.',
        action: DeviceValidationAction.signOut,
      );
    }
  }

  /// Check if device is already bound to another user (strict one-user-per-device policy)
  static Future<Map<String, dynamic>?> _checkDeviceAlreadyBound(
      String baseDeviceId, String currentUserId) async {
    try {
      if (kDebugMode) {
        print(
            'DEBUG: 🔍 Checking if device $baseDeviceId is already bound to another user');
      }

      // First check if current user is demo account - if so, bypass check
      final currentUserDoc =
          await _firestore.collection('mobile_users').doc(currentUserId).get();
      if (currentUserDoc.exists) {
        final currentUserData = currentUserDoc.data()!;
        final currentUserEmail = currentUserData['email'] ?? '';

        if (DemoAccountService.shouldBypassEmailVerification(
            currentUserEmail)) {
          if (kDebugMode) {
            print('DEBUG: 🎯 Bypassing device binding check for demo account');
          }
          return null; // No existing binding for demo account
        }
      }

      // Strict one-user-per-device policy: no shared device mode
      // Query all users to find any with this base device ID
      final allUsersQuery = await _firestore
          .collection('mobile_users')
          .where('isDeviceBound', isEqualTo: true)
          .get();

      for (final doc in allUsersQuery.docs) {
        if (doc.id == currentUserId) continue; // Skip current user

        final userData = doc.data();
        final registeredDeviceId = userData['registeredDeviceId'];

        if (registeredDeviceId != null) {
          // Extract base device ID from registered device ID
          final registeredBaseDeviceId =
              extractBaseDeviceId(registeredDeviceId);

          // If base device IDs match, this device is already bound to another user
          if (registeredBaseDeviceId == baseDeviceId) {
            if (kDebugMode) {
              print('DEBUG: ❌ Device already bound to user: ${doc.id}');
            }
            return {
              'userId': doc.id,
              'email': userData['email'] ?? 'Unknown',
              'name': userData['name'] ?? 'Unknown User',
            };
          }
        }
      }

      if (kDebugMode) {
        print('DEBUG: ✅ Device is not bound to any other user');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error checking device binding: $e');
      }
      return null;
    }
  }

  /// Log security event
  static Future<void> _logSecurityEvent(
      String userId, String eventType, Map<String, dynamic> details) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('mobile_users').doc(userId).update({
        'securityEvents': FieldValue.arrayUnion([
          {
            'type': eventType,
            'timestamp': now.toIso8601String(),
            ...details,
          }
        ]),
      });
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error logging security event: $e');
      }
    }
  }

  /// Force logout and clear device binding on security breach
  static Future<void> handleSecurityBreach(String userId, String reason) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🚨 Security breach detected for user: $userId');
        print('DEBUG: 🚨 Reason: $reason');
      }

      // Log the security breach
      await _logSecurityEvent(userId, 'security_breach', {
        'reason': reason,
        'action': 'forced_logout_and_device_unbind',
        'severity': 'high',
      });

      // Clear device binding to force re-registration
      final now = DateTime.now();
      await _firestore.collection('mobile_users').doc(userId).update({
        'registeredDeviceId': null,
        'deviceInfo': null,
        'deviceRegisteredAt': null,
        'isDeviceBound': false,
        'securityBreach': {
          'detected': true,
          'timestamp': now.toIso8601String(),
          'reason': reason,
        },
      });

      if (kDebugMode) {
        print('DEBUG: ✅ Device binding cleared due to security breach');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error handling security breach: $e');
      }
    }
  }

  /// Force logout all sessions for a user (security measure)
  static Future<void> forceLogoutAllSessions(String userId) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🚨 Forcing logout of all sessions for user: $userId');
      }

      // Update user document to invalidate all sessions
      final now = DateTime.now();
      await _firestore.collection('mobile_users').doc(userId).update({
        'forceLogout': true,
        'sessionInvalidatedAt': FieldValue.serverTimestamp(),
        'securityEvents': FieldValue.arrayUnion([
          {
            'type': 'force_logout_all_sessions',
            'timestamp': now.toIso8601String(),
            'reason': 'Security measure - multiple device access attempt',
          }
        ]),
      });

      if (kDebugMode) {
        print('DEBUG: ✅ All sessions invalidated for user');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error forcing logout: $e');
      }
    }
  }

  /// Check if user session is still valid
  static Future<bool> isSessionValid(String userId) async {
    try {
      final userDoc =
          await _firestore.collection('mobile_users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final forceLogout = userData['forceLogout'] ?? false;

      return !forceLogout;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error checking session validity: $e');
      }
      return false;
    }
  }

  /// Clear force logout flag after successful re-authentication
  static Future<void> clearForceLogoutFlag(String userId) async {
    try {
      await _firestore.collection('mobile_users').doc(userId).update({
        'forceLogout': false,
        'sessionValidatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error clearing force logout flag: $e');
      }
    }
  }

  /// Migrate existing user from old device ID system to new enhanced device ID system
  /// This method should be called during login for users who have the old device ID format
  static Future<bool> migrateToEnhancedDeviceId(String userId) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔄 Migrating user to user-specific device ID: $userId');
      }

      final userDoc =
          await _firestore.collection('mobile_users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found during migration');
      }

      final userData = userDoc.data()!;
      final userEmail = userData['email'] ?? '';
      final phoneNumber = userData['phoneNumber'] ?? '';
      final currentRegisteredDeviceId = userData['registeredDeviceId'];
      final isDeviceBound = userData['isDeviceBound'] ?? false;

      // Only migrate if user has an old device ID bound
      if (!isDeviceBound || currentRegisteredDeviceId == null) {
        if (kDebugMode) {
          print('DEBUG: ⏭️ User has no device bound, skipping migration');
        }
        return false;
      }

      // Generate new enhanced device ID
      final newEnhancedDeviceId =
          await getEnhancedDeviceId(userId, userEmail, phoneNumber);

      // Check if the current device ID is already enhanced (contains ':' separator)
      // If it contains ':', it's likely already enhanced
      if (currentRegisteredDeviceId.contains(':')) {
        if (kDebugMode) {
          print(
              'DEBUG: ✅ Device ID appears to be already enhanced, no migration needed');
        }
        return false;
      }

      // Update user document with new enhanced device ID
      final now = DateTime.now();
      await _firestore.collection('mobile_users').doc(userId).update({
        'registeredDeviceId': newEnhancedDeviceId,
        'deviceMigratedAt': FieldValue.serverTimestamp(),
        'securityEvents': FieldValue.arrayUnion([
          {
            'type': 'device_id_migrated',
            'timestamp': now.toIso8601String(),
            'oldDeviceId': currentRegisteredDeviceId,
            'newDeviceId': newEnhancedDeviceId,
            'details':
                'Migrated from basic to enhanced device identifier with strict one-user-per-device policy',
          }
        ]),
      });

      if (kDebugMode) {
        print('DEBUG: ✅ Successfully migrated to user-specific device ID');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error during device ID migration: $e');
      }
      return false;
    }
  }

  /// Clear cached device information
  static void clearCache() {
    _cachedDeviceId = null;
    _cachedDeviceInfo = null;
  }
}

/// Device validation result
class DeviceValidationResult {
  final bool isValid;
  final String reason;
  final DeviceValidationAction action;

  const DeviceValidationResult({
    required this.isValid,
    required this.reason,
    required this.action,
  });
}

/// Device validation actions
enum DeviceValidationAction {
  allowAccess,
  bindDevice,
  blockAccess,
  signOut,
}
