import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/core/services/credential_storage_service.dart';

void main() {
  group('CredentialStorageService Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should store and retrieve credentials correctly', () async {
      const email = 'test@example.com';
      const password = 'testPassword123';
      const rememberMe = true;

      // Store credentials
      await CredentialStorageService.storeCredentials(
        email: email,
        password: password,
        rememberMe: rememberMe,
        enableAutoLogin: true,
      );

      // Check if remember me is enabled
      final isRememberMeEnabled = await CredentialStorageService.isRememberMeEnabled();
      expect(isRememberMeEnabled, isTrue);

      // Check if auto-login is enabled
      final isAutoLoginEnabled = await CredentialStorageService.isAutoLoginEnabled();
      expect(isAutoLoginEnabled, isTrue);

      // Retrieve stored email
      final storedEmail = await CredentialStorageService.getStoredEmail();
      expect(storedEmail, equals(email));

      // Retrieve stored credentials
      final storedCredentials = await CredentialStorageService.getStoredCredentials();
      expect(storedCredentials, isNotNull);
      expect(storedCredentials!['email'], equals(email));
      expect(storedCredentials['passwordHash'], isNotNull);
      expect(storedCredentials['passwordHash']!.length, equals(64)); // SHA256 hash length

      // Verify password
      final isPasswordValid = await CredentialStorageService.verifyStoredPassword(password);
      expect(isPasswordValid, isTrue);

      // Verify wrong password
      final isWrongPasswordValid = await CredentialStorageService.verifyStoredPassword('wrongPassword');
      expect(isWrongPasswordValid, isFalse);
    });

    test('should clear credentials correctly', () async {
      const email = 'test@example.com';
      const password = 'testPassword123';

      // Store credentials first
      await CredentialStorageService.storeCredentials(
        email: email,
        password: password,
        rememberMe: true,
      );

      // Verify credentials are stored
      final isRememberMeEnabled = await CredentialStorageService.isRememberMeEnabled();
      expect(isRememberMeEnabled, isTrue);

      // Clear credentials
      await CredentialStorageService.clearStoredCredentials();

      // Verify credentials are cleared
      final isRememberMeEnabledAfterClear = await CredentialStorageService.isRememberMeEnabled();
      expect(isRememberMeEnabledAfterClear, isFalse);

      final storedEmailAfterClear = await CredentialStorageService.getStoredEmail();
      expect(storedEmailAfterClear, isNull);

      final storedCredentialsAfterClear = await CredentialStorageService.getStoredCredentials();
      expect(storedCredentialsAfterClear, isNull);
    });

    test('should not store credentials when remember me is false', () async {
      const email = 'test@example.com';
      const password = 'testPassword123';

      // Store credentials with remember me false
      await CredentialStorageService.storeCredentials(
        email: email,
        password: password,
        rememberMe: false,
      );

      // Verify credentials are not stored
      final isRememberMeEnabled = await CredentialStorageService.isRememberMeEnabled();
      expect(isRememberMeEnabled, isFalse);

      final storedEmail = await CredentialStorageService.getStoredEmail();
      expect(storedEmail, isNull);

      final storedCredentials = await CredentialStorageService.getStoredCredentials();
      expect(storedCredentials, isNull);
    });

    test('should handle auto-login settings correctly', () async {
      // Initially auto-login should be disabled
      final initialAutoLogin = await CredentialStorageService.isAutoLoginEnabled();
      expect(initialAutoLogin, isFalse);

      // Enable auto-login
      await CredentialStorageService.setAutoLoginEnabled(true);
      final autoLoginEnabled = await CredentialStorageService.isAutoLoginEnabled();
      expect(autoLoginEnabled, isTrue);

      // Disable auto-login
      await CredentialStorageService.setAutoLoginEnabled(false);
      final autoLoginDisabled = await CredentialStorageService.isAutoLoginEnabled();
      expect(autoLoginDisabled, isFalse);
    });

    test('should update last login time correctly', () async {
      const email = 'test@example.com';
      const password = 'testPassword123';

      // Store credentials first
      await CredentialStorageService.storeCredentials(
        email: email,
        password: password,
        rememberMe: true,
      );

      // Get initial storage info
      final initialInfo = await CredentialStorageService.getStorageInfo();
      final initialLastLogin = initialInfo['lastLoginTime'];

      // Wait a bit and update last login time
      await Future.delayed(const Duration(milliseconds: 100));
      await CredentialStorageService.updateLastLoginTime();

      // Get updated storage info
      final updatedInfo = await CredentialStorageService.getStorageInfo();
      final updatedLastLogin = updatedInfo['lastLoginTime'];

      // Verify last login time was updated
      expect(updatedLastLogin, isNotNull);
      expect(updatedLastLogin, isNot(equals(initialLastLogin)));
    });

    test('should provide correct storage info', () async {
      const email = 'test@example.com';
      const password = 'testPassword123';

      // Initially storage should be empty
      final initialInfo = await CredentialStorageService.getStorageInfo();
      expect(initialInfo['rememberMeEnabled'], isFalse);
      expect(initialInfo['autoLoginEnabled'], isFalse);
      expect(initialInfo['hasStoredEmail'], isFalse);
      expect(initialInfo['hasStoredPasswordHash'], isFalse);

      // Store credentials
      await CredentialStorageService.storeCredentials(
        email: email,
        password: password,
        rememberMe: true,
        enableAutoLogin: true,
      );

      // Check storage info after storing credentials
      final updatedInfo = await CredentialStorageService.getStorageInfo();
      expect(updatedInfo['rememberMeEnabled'], isTrue);
      expect(updatedInfo['autoLoginEnabled'], isTrue);
      expect(updatedInfo['hasStoredEmail'], isTrue);
      expect(updatedInfo['hasStoredPasswordHash'], isTrue);
      expect(updatedInfo['lastLoginTime'], isNotNull);
    });
  });
}
