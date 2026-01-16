import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/device_auth_service.dart';

/// Debug utility to test and verify one-user-per-device policy
class DeviceValidationDebug {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test the one-user-per-device policy enforcement
  static Future<Map<String, dynamic>> testOneUserPerDevicePolicy() async {
    if (!kDebugMode) {
      return {'error': 'Debug mode only'};
    }

    try {
      print('DEBUG: 🧪 Testing one-user-per-device policy...');

      // Get current device ID
      final deviceInfo = await DeviceAuthService.getDeviceIdDebugInfo();
      final currentDeviceId = deviceInfo['currentDeviceId'];

      print(
          'DEBUG: 📱 Current device ID: ${currentDeviceId?.substring(0, 12)}...');

      // Check all users in the database
      final allUsersQuery = await _firestore
          .collection('mobile_users')
          .where('isDeviceBound', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> usersOnThisDevice = [];
      List<Map<String, dynamic>> allBoundUsers = [];

      for (final doc in allUsersQuery.docs) {
        final userData = doc.data();
        final registeredDeviceId = userData['registeredDeviceId'];
        final email = userData['email'] ?? 'Unknown';
        final name = userData['name'] ?? 'Unknown';

        allBoundUsers.add({
          'userId': doc.id,
          'email': email,
          'name': name,
          'registeredDeviceId': registeredDeviceId,
        });

        if (registeredDeviceId != null) {
          final registeredBaseDeviceId =
              DeviceAuthService.extractBaseDeviceId(registeredDeviceId);

          if (registeredBaseDeviceId == currentDeviceId) {
            usersOnThisDevice.add({
              'userId': doc.id,
              'email': email,
              'name': name,
              'registeredDeviceId': registeredDeviceId,
            });
          }
        }
      }

      final result = {
        'currentDeviceId': currentDeviceId,
        'usersOnThisDevice': usersOnThisDevice,
        'usersOnThisDeviceCount': usersOnThisDevice.length,
        'allBoundUsers': allBoundUsers,
        'allBoundUsersCount': allBoundUsers.length,
        'policyViolation': usersOnThisDevice.length > 1,
        'deviceInfo': deviceInfo,
      };

      print('DEBUG: 📊 Users on this device: ${usersOnThisDevice.length}');
      print('DEBUG: 📊 Total bound users: ${allBoundUsers.length}');

      if (usersOnThisDevice.length > 1) {
        print('DEBUG: ❌ POLICY VIOLATION: Multiple users on same device!');
        for (final user in usersOnThisDevice) {
          print('DEBUG: 👤 User: ${user['email']} (${user['userId']})');
        }
      } else if (usersOnThisDevice.length == 1) {
        print('DEBUG: ✅ Policy compliant: One user on device');
        print('DEBUG: 👤 User: ${usersOnThisDevice[0]['email']}');
      } else {
        print('DEBUG: ℹ️ No users bound to this device');
      }

      return result;
    } catch (e) {
      print('DEBUG: ❌ Error testing policy: $e');
      return {'error': e.toString()};
    }
  }

  /// Clear all device bindings for testing (DEBUG ONLY)
  static Future<bool> clearAllDeviceBindings() async {
    if (!kDebugMode) {
      print('ERROR: This function is only available in debug mode');
      return false;
    }

    try {
      print('DEBUG: 🧹 Clearing all device bindings...');

      final allUsersQuery = await _firestore
          .collection('mobile_users')
          .where('isDeviceBound', isEqualTo: true)
          .get();

      int clearedCount = 0;
      for (final doc in allUsersQuery.docs) {
        await _firestore.collection('mobile_users').doc(doc.id).update({
          'isDeviceBound': false,
          'registeredDeviceId': FieldValue.delete(),
          'deviceInfo': FieldValue.delete(),
        });
        clearedCount++;
      }

      print('DEBUG: ✅ Cleared $clearedCount device bindings');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Error clearing device bindings: $e');
      return false;
    }
  }

  /// Simulate multiple user registration attempts on same device
  static Future<Map<String, dynamic>> simulateMultipleUserAttempts(
      List<String> userIds) async {
    if (!kDebugMode) {
      return {'error': 'Debug mode only'};
    }

    try {
      print('DEBUG: 🧪 Simulating multiple user attempts on same device...');

      final results = <String, dynamic>{};
      final currentDeviceId =
          (await DeviceAuthService.getDeviceIdDebugInfo())['currentDeviceId'];

      for (final userId in userIds) {
        try {
          print('DEBUG: 🔍 Testing validation for user: $userId');

          final validation =
              await DeviceAuthService.validateDeviceForUser(userId);

          results[userId] = {
            'isValid': validation.isValid,
            'reason': validation.reason,
            'action': validation.action.toString(),
          };

          print(
              'DEBUG: 📊 User $userId: ${validation.isValid ? "✅ ALLOWED" : "❌ BLOCKED"}');
          print('DEBUG: 📊 Reason: ${validation.reason}');
        } catch (e) {
          results[userId] = {
            'error': e.toString(),
          };
          print('DEBUG: ❌ Error for user $userId: $e');
        }
      }

      results['deviceId'] = currentDeviceId;
      results['summary'] = {
        'totalUsers': userIds.length,
        'allowedUsers':
            results.values.where((r) => r['isValid'] == true).length,
        'blockedUsers':
            results.values.where((r) => r['isValid'] == false).length,
      };

      return results;
    } catch (e) {
      print('DEBUG: ❌ Error in simulation: $e');
      return {'error': e.toString()};
    }
  }

  /// Check device ID consistency across app restarts
  static Future<Map<String, dynamic>> testDeviceIdConsistency() async {
    if (!kDebugMode) {
      return {'error': 'Debug mode only'};
    }

    try {
      print('DEBUG: 🧪 Testing device ID consistency...');

      // Clear cached device ID to simulate app restart
      DeviceAuthService.clearCachedDeviceId();

      // Get device ID multiple times
      final deviceIds = <String>[];
      for (int i = 0; i < 5; i++) {
        DeviceAuthService.clearCachedDeviceId();
        final deviceInfo = await DeviceAuthService.getDeviceIdDebugInfo();
        final deviceId = deviceInfo['currentDeviceId'];
        deviceIds.add(deviceId);
        print('DEBUG: 📱 Attempt ${i + 1}: ${deviceId?.substring(0, 12)}...');
      }

      final isConsistent = deviceIds.every((id) => id == deviceIds.first);

      print(
          'DEBUG: ${isConsistent ? "✅" : "❌"} Device ID consistency: $isConsistent');

      return {
        'deviceIds': deviceIds,
        'isConsistent': isConsistent,
        'uniqueIds': deviceIds.toSet().toList(),
        'uniqueCount': deviceIds.toSet().length,
      };
    } catch (e) {
      print('DEBUG: ❌ Error testing consistency: $e');
      return {'error': e.toString()};
    }
  }

  /// Print comprehensive device and policy status
  static Future<void> printDevicePolicyStatus() async {
    if (!kDebugMode) return;

    print('\n' + '=' * 60);
    print('🔒 ONE-USER-PER-DEVICE POLICY STATUS');
    print('=' * 60);

    try {
      final policyTest = await testOneUserPerDevicePolicy();
      final consistencyTest = await testDeviceIdConsistency();

      print(
          '📱 Current Device ID: ${policyTest['currentDeviceId']?.substring(0, 16)}...');
      print('👥 Users on this device: ${policyTest['usersOnThisDeviceCount']}');
      print('🌐 Total bound users: ${policyTest['allBoundUsersCount']}');
      print(
          '🔒 Policy violation: ${policyTest['policyViolation'] ? "❌ YES" : "✅ NO"}');
      print(
          '🔄 Device ID consistent: ${consistencyTest['isConsistent'] ? "✅ YES" : "❌ NO"}');

      if (policyTest['policyViolation'] == true) {
        print('\n⚠️  POLICY VIOLATION DETECTED:');
        for (final user in policyTest['usersOnThisDevice']) {
          print('   👤 ${user['email']} (${user['userId']})');
        }
      }

      print('=' * 60 + '\n');
    } catch (e) {
      print('❌ Error getting policy status: $e');
      print('=' * 60 + '\n');
    }
  }
}
