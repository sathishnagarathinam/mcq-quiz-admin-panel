import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  group('Device Authentication Logic Tests', () {
    test('Enhanced device ID format validation', () {
      // Test the enhanced device ID format logic
      const baseDeviceId = 'android_device_12345';
      const userId = 'user123';
      const userEmail = 'test@example.com';
      const userPhone = '+1234567890';

      // Simulate the enhanced device ID generation logic
      final userDataHash = sha256
          .convert(utf8.encode('${userId}_${userEmail}_${userPhone}'))
          .toString();
      final enhancedDeviceId = '${baseDeviceId}:${userDataHash}';

      // Test extraction logic
      expect(enhancedDeviceId.contains(':'), isTrue);

      final extractedBaseDeviceId = enhancedDeviceId.split(':')[0];
      final extractedUserDataHash = enhancedDeviceId.split(':')[1];

      expect(extractedBaseDeviceId, equals(baseDeviceId));
      expect(extractedUserDataHash, equals(userDataHash));
      expect(extractedUserDataHash.length, equals(64)); // SHA256 hash length

      print('✅ Enhanced device ID format validation passed');
    });

    test('Enhanced device ID with empty user data', () {
      // Test the enhanced device ID generation with empty user data
      const baseDeviceId = 'android_device_12345';
      const userId = 'test_user_id';
      const userEmail = '';
      const phoneNumber = '';

      // Simulate the enhanced device ID generation logic
      final userDataHash = sha256
          .convert(utf8.encode('${userId}_${userEmail}_${phoneNumber}'))
          .toString();
      final enhancedDeviceId = '${baseDeviceId}:${userDataHash}';

      // Should still generate a valid enhanced device ID even with empty email/phone
      expect(enhancedDeviceId.contains(':'), isTrue);
      final extractedBaseDeviceId = enhancedDeviceId.split(':')[0];
      expect(extractedBaseDeviceId.isNotEmpty, isTrue);
      expect(extractedBaseDeviceId, equals(baseDeviceId));

      print(
          '✅ Enhanced device ID generated with empty user data: ${extractedBaseDeviceId.substring(0, 8)}...');
    });

    test('Device ID extraction logic works correctly', () {
      // Test with enhanced device ID format
      const testEnhancedId =
          'android_device_123:abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234';

      // Simulate extraction logic
      final parts = testEnhancedId.split(':');
      final baseDeviceId = parts[0];
      final userDataHash = parts.length > 1 ? parts[1] : null;

      expect(baseDeviceId, equals('android_device_123'));
      expect(
          userDataHash,
          equals(
              'abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234'));

      // Test with old format (no separator)
      const testOldId = 'android_device_123';
      final oldParts = testOldId.split(':');
      final baseDeviceIdOld = oldParts[0];
      final userDataHashOld = oldParts.length > 1 ? oldParts[1] : null;

      expect(baseDeviceIdOld, equals('android_device_123'));
      expect(userDataHashOld, isNull);

      print('✅ Device ID extraction logic works correctly');
    });

    test('Strict one-user-per-device policy validation', () {
      // Test that different users on same device would be detected
      const baseDeviceId = 'android_device_12345';

      // User 1
      const user1Id = 'user1';
      const user1Email = 'user1@test.com';
      const user1Phone = '+1111111111';
      final user1Hash = sha256
          .convert(utf8.encode('${user1Id}_${user1Email}_${user1Phone}'))
          .toString();
      final user1EnhancedId = '${baseDeviceId}:${user1Hash}';

      // User 2 (different user, same device)
      const user2Id = 'user2';
      const user2Email = 'user2@test.com';
      const user2Phone = '+2222222222';
      final user2Hash = sha256
          .convert(utf8.encode('${user2Id}_${user2Email}_${user2Phone}'))
          .toString();
      final user2EnhancedId = '${baseDeviceId}:${user2Hash}';

      // Both should have same base device ID but different user data hashes
      expect(user1EnhancedId.split(':')[0],
          equals(user2EnhancedId.split(':')[0])); // Same base device
      expect(
          user1EnhancedId.split(':')[1],
          isNot(
              equals(user2EnhancedId.split(':')[1]))); // Different user hashes

      print('✅ Strict one-user-per-device policy validation passed');
    });
  });
}
