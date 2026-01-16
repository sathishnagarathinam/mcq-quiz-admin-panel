import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

/// Test service for Firebase Auth when billing is not enabled
/// This service simulates Firebase Auth behavior for development/testing
class FirebaseAuthTestService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Storage keys for session data
  static const String _registrationDataKey = 'firebase_registration_data';
  static const String _tempRegistrationDataKey = 'temp_registration_data';
  static const String _testOtpKey = 'test_otp';
  static const String _testPhoneKey = 'test_phone';

  // Test OTP for development
  static const String _defaultTestOtp = '123456';

  /// Send OTP for registration (Test Mode)
  static Future<void> sendRegistrationOTP({
    required String phoneNumber,
    required String name,
    required String email,
    required String officeName,
    required String designation,
  }) async {
    try {
      print('DEBUG: FirebaseAuthTestService.sendRegistrationOTP called');
      print(
          'DEBUG: Data - name: $name, email: $email, phone: $phoneNumber, office: $officeName, designation: $designation');

      // Store temporary registration data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tempRegistrationDataKey,
          '{"name":"$name","email":"$email","officeName":"$officeName","designation":"$designation"}');

      // Store test data
      await prefs.setString(_testOtpKey, _defaultTestOtp);
      await prefs.setString(_testPhoneKey, phoneNumber);

      print('DEBUG: Registration data stored in SharedPreferences');

      // Don't create Firestore document during registration - only during login
      // This prevents permission errors and follows the correct flow

      // Simulate delay
      await Future.delayed(const Duration(seconds: 1));

      print('TEST MODE: OTP sent to $phoneNumber. Use OTP: $_defaultTestOtp');
      print(
          'DEBUG: Registration OTP process completed - no Firestore document created yet');
    } catch (e) {
      print('DEBUG: Error in sendRegistrationOTP: $e');
      throw Exception('Failed to send registration OTP: $e');
    }
  }

  /// Send OTP for login (Test Mode)
  static Future<void> sendLoginOTP(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store test data
      await prefs.setString(_testOtpKey, _defaultTestOtp);
      await prefs.setString(_testPhoneKey, phoneNumber);

      // Simulate delay
      await Future.delayed(const Duration(seconds: 1));

      print('TEST MODE: OTP sent to $phoneNumber. Use OTP: $_defaultTestOtp');
    } catch (e) {
      throw Exception('Failed to send login OTP: $e');
    }
  }

  /// Verify OTP for registration (Test Mode)
  static Future<User?> verifyRegistrationOTP(String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedOtp = prefs.getString(_testOtpKey);
      final phoneNumber = prefs.getString(_testPhoneKey);
      final tempDataString = prefs.getString(_tempRegistrationDataKey);

      if (storedOtp == null || phoneNumber == null) {
        throw Exception('Test session expired. Please try again.');
      }

      if (tempDataString == null) {
        throw Exception('Registration data not found. Please try again.');
      }

      // Verify OTP
      if (otp != storedOtp) {
        throw Exception('Invalid OTP. Please try again.');
      }

      // Parse temporary registration data
      final tempData = tempDataString.split('","');
      final name = tempData[0].split('":"')[1];
      final email = tempData[1].split('":"')[1];
      final officeName = tempData[2].split('":"')[1];
      final designation = tempData[3].split('":"')[1].replaceAll('"}', '');

      // Don't create Firestore document during registration OTP verification
      // This will be done during login process

      // Store registration data locally
      await prefs.setString(_registrationDataKey,
          '{"name":"$name","email":"$email","phoneNumber":"$phoneNumber","officeName":"$officeName","designation":"$designation","registrationDate":"${DateTime.now().toIso8601String()}"}');

      // Clear temporary data
      await prefs.remove(_testOtpKey);
      await prefs.remove(_testPhoneKey);
      await prefs.remove(_tempRegistrationDataKey);

      print('TEST MODE: Registration completed for $name');

      // Return null since we're not actually creating a Firebase user
      return null;
    } catch (e) {
      throw Exception('Failed to verify registration OTP: $e');
    }
  }

  /// Verify OTP for login (Test Mode)
  static Future<User?> verifyLoginOTP(String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedOtp = prefs.getString(_testOtpKey);
      final phoneNumber = prefs.getString(_testPhoneKey);

      if (storedOtp == null || phoneNumber == null) {
        throw Exception('Test session expired. Please try again.');
      }

      // Verify OTP
      if (otp != storedOtp) {
        throw Exception('Invalid OTP. Please try again.');
      }

      // Get registration data if it exists
      final registrationDataString = prefs.getString(_registrationDataKey);

      if (registrationDataString != null) {
        // Parse registration data
        final registrationData = registrationDataString.split('","');
        final name = registrationData[0].split('":"')[1];
        final email = registrationData[1].split('":"')[1];
        final officeName = registrationData[2].split('":"')[1];
        final designation = registrationData[3].split('":"')[1].split('","')[0];

        // Create Firestore document now during login
        final testUserId = 'test_${DateTime.now().millisecondsSinceEpoch}';

        try {
          await FirestoreService.createUserDocument(
            uid: testUserId,
            name: name,
            email: email,
            phoneNumber: phoneNumber,
            officeName: officeName,
            designation: designation,
          );
          print(
              'TEST MODE: User document created in Firestore with ID: $testUserId');
        } catch (e) {
          print('TEST MODE: Warning - Could not create Firestore document: $e');
          // Continue with login even if Firestore fails
        }
      }

      // Clear test data
      await prefs.remove(_testOtpKey);
      await prefs.remove(_testPhoneKey);

      print('TEST MODE: Login completed for $phoneNumber');

      // Return null since we're not actually signing in a Firebase user
      return null;
    } catch (e) {
      throw Exception('Failed to verify login OTP: $e');
    }
  }

  /// Get current user (Test Mode)
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign out (Test Mode)
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Check if user is signed in (Test Mode)
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Get user stream (Test Mode)
  static Stream<User?> get userStream => _auth.authStateChanges();

  /// Check if a phone number has been registered (Test Mode)
  static Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      // In test mode, we can check Firestore for existing users
      // This is a simplified check - in production you'd query by phone number
      return false; // For now, always return false to allow registration
    } catch (e) {
      return false;
    }
  }

  /// Get test OTP for development
  static String getTestOTP() {
    return _defaultTestOtp;
  }
}
