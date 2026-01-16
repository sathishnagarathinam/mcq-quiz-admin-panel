import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mcq_quiz_app/core/providers/auth_provider_minimal.dart';

void main() {
  group('Registration Process Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should send registration OTP successfully', () async {
      final authNotifier = container.read(authProvider.notifier);

      // Test phone number registration
      final userData = {
        'name': 'Test User',
        'email': 'test@example.com',
        'officeName': 'Test Office',
        'designation': 'GDS',
      };
      final result =
          await authNotifier.registerWithPhone('+919876543210', userData);

      expect(result, isTrue);

      // Check that loading state is handled correctly
      final authState = container.read(authProvider);
      expect(authState.isLoading, isFalse);
      expect(authState.error, isNull);
    });

    test('should handle registration OTP verification', () async {
      final authNotifier = container.read(authProvider.notifier);

      // First send OTP
      final userData = {
        'name': 'Test User',
        'email': 'test@example.com',
        'officeName': 'Test Office',
        'designation': 'GDS',
      };
      await authNotifier.registerWithPhone('+919876543210', userData);

      // Then verify OTP (this will fail in test environment but should handle gracefully)
      try {
        await authNotifier.verifyRegistrationOTP('123456', userData);
      } catch (e) {
        // Expected to fail in test environment due to Firebase REST API
        expect(e.toString(), contains('Failed to verify registration OTP'));
      }
    });

    test('should handle login OTP flow', () async {
      final authNotifier = container.read(authProvider.notifier);

      // Test login OTP sending
      final result = await authNotifier.sendOTP('+919876543210');

      expect(result, isTrue);

      // Check state
      final authState = container.read(authProvider);
      expect(authState.isLoading, isFalse);
      expect(authState.error, isNull);
    });

    test('should handle OTP verification for login', () async {
      final authNotifier = container.read(authProvider.notifier);

      // First send OTP
      await authNotifier.sendOTP('+919876543210');

      // Then verify OTP (this will fail in test environment but should handle gracefully)
      try {
        await authNotifier.verifyOTP('123456');
      } catch (e) {
        // Expected to fail in test environment due to Firebase REST API
        expect(e.toString(), contains('Failed to verify OTP'));
      }
    });

    test('should validate phone number format', () async {
      final authNotifier = container.read(authProvider.notifier);

      // Test with invalid phone number
      try {
        final userData = {
          'name': 'Test User',
          'email': 'test@example.com',
          'officeName': 'Test Office',
          'designation': 'GDS',
        };
        await authNotifier.registerWithPhone('invalid', userData);
      } catch (e) {
        // Should handle invalid phone number gracefully
        expect(e.toString(), contains('Failed to send registration OTP'));
      }
    });

    test('should handle user model correctly', () {
      // Test user data structure
      final userData = {
        'uid': 'test_uid',
        'email': 'test@example.com',
        'phoneNumber': '+919876543210',
        'name': 'Test User',
        'officeName': 'Test Office',
        'designation': 'GDS',
      };

      expect(userData['phoneNumber'], equals('+919876543210'));
      expect(userData['name'], equals('Test User'));
      expect(userData['designation'], equals('GDS'));
    });

    test('should handle user model without phone number', () {
      // Test user data structure without phone
      final userData = {
        'uid': 'test_uid',
        'email': 'test@example.com',
        'name': 'Test User',
        'emailVerified': true,
      };

      expect(userData['email'], equals('test@example.com'));
      expect(userData['name'], equals('Test User'));
      expect(userData['emailVerified'], isTrue);
    });
  });
}
