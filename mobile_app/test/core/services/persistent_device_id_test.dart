import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_quiz_app/core/services/device_auth_service.dart';

void main() {
  group('Device ID Extraction Tests', () {
    test('should extract base device ID correctly', () {
      const enhancedDeviceId = 'abc123def456:user_hash_789';

      final baseDeviceId =
          DeviceAuthService.extractBaseDeviceId(enhancedDeviceId);
      expect(baseDeviceId, equals('abc123def456'));
    });

    test('should extract user data hash correctly', () {
      const enhancedDeviceId = 'abc123def456:user_hash_789';

      final userDataHash =
          DeviceAuthService.extractUserDataHash(enhancedDeviceId);
      expect(userDataHash, equals('user_hash_789'));
    });

    test('should handle old format device IDs without colon', () {
      const oldFormatDeviceId = 'abc123def456';

      final baseDeviceId =
          DeviceAuthService.extractBaseDeviceId(oldFormatDeviceId);
      expect(baseDeviceId, equals('abc123def456'));

      final userDataHash =
          DeviceAuthService.extractUserDataHash(oldFormatDeviceId);
      expect(userDataHash, isNull);
    });
  });
}
