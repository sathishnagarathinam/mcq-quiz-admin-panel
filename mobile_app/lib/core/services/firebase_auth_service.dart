import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Storage keys for session data
  static const String _registrationDataKey = 'firebase_registration_data';
  static const String _verificationIdKey = 'firebase_verification_id';
  static const String _tempRegistrationDataKey = 'temp_registration_data';

  /// Send OTP for registration
  static Future<void> sendRegistrationOTP({
    required String phoneNumber,
    required String name,
    required String email,
    required String officeName,
    required String designation,
  }) async {
    try {
      // Store temporary registration data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tempRegistrationDataKey,
          '{"name":"$name","email":"$email","officeName":"$officeName","designation":"$designation"}');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          await _completeRegistration(
              credential, name, email, officeName, designation, phoneNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'billing-not-enabled') {
            throw Exception(
                'Firebase SMS billing is not enabled. Please enable billing in Firebase Console or use a test phone number.');
          }
          throw Exception('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Store verification ID for later use
          await prefs.setString(_verificationIdKey, verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      throw Exception('Failed to send registration OTP: $e');
    }
  }

  /// Send OTP for login
  static Future<void> sendLoginOTP(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'billing-not-enabled') {
            throw Exception(
                'Firebase SMS billing is not enabled. Please enable billing in Firebase Console or use a test phone number.');
          }
          throw Exception('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Store verification ID for later use
          await prefs.setString(_verificationIdKey, verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      throw Exception('Failed to send login OTP: $e');
    }
  }

  /// Verify OTP for registration
  static Future<User?> verifyRegistrationOTP(String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final verificationId = prefs.getString(_verificationIdKey);
      final tempDataString = prefs.getString(_tempRegistrationDataKey);

      if (verificationId == null) {
        throw Exception('Verification ID not found. Please try again.');
      }

      if (tempDataString == null) {
        throw Exception('Registration data not found. Please try again.');
      }

      // Parse temporary registration data
      final tempData = tempDataString.split('","');
      final name = tempData[0].split('":"')[1];
      final email = tempData[1].split('":"')[1];
      final officeName = tempData[2].split('":"')[1];
      final designation = tempData[3].split('":"')[1].replaceAll('"}', '');

      // Create credential and sign in
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Update user profile
        await user.updateDisplayName(name);
        await user.updateEmail(email);

        // Create Firestore document
        await FirestoreService.createUserDocument(
          uid: user.uid,
          name: name,
          email: email,
          phoneNumber: user.phoneNumber ?? '',
          officeName: officeName,
          designation: designation,
        );

        // Store registration data locally
        await prefs.setString(_registrationDataKey,
            '{"name":"$name","email":"$email","phoneNumber":"${user.phoneNumber}","officeName":"$officeName","designation":"$designation","registrationDate":"${DateTime.now().toIso8601String()}"}');

        // Clear temporary data
        await prefs.remove(_verificationIdKey);
        await prefs.remove(_tempRegistrationDataKey);

        // Sign out the user after registration (they need to login separately)
        await _auth.signOut();
      }

      return user;
    } catch (e) {
      throw Exception('Failed to verify registration OTP: $e');
    }
  }

  /// Verify OTP for login
  static Future<User?> verifyLoginOTP(String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final verificationId = prefs.getString(_verificationIdKey);

      if (verificationId == null) {
        throw Exception('Verification ID not found. Please try again.');
      }

      // Create credential and sign in
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Update last login in Firestore
        await FirestoreService.updateLastLogin(user.uid);

        // Clear verification ID
        await prefs.remove(_verificationIdKey);
      }

      return user;
    } catch (e) {
      throw Exception('Failed to verify login OTP: $e');
    }
  }

  /// Complete registration (for auto-verification)
  static Future<void> _completeRegistration(
    PhoneAuthCredential credential,
    String name,
    String email,
    String officeName,
    String designation,
    String phoneNumber,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Update user profile
        await user.updateDisplayName(name);
        await user.updateEmail(email);

        // Create Firestore document
        await FirestoreService.createUserDocument(
          uid: user.uid,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          officeName: officeName,
          designation: designation,
        );

        // Store registration data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_registrationDataKey,
            '{"name":"$name","email":"$email","phoneNumber":"$phoneNumber","officeName":"$officeName","designation":"$designation","registrationDate":"${DateTime.now().toIso8601String()}"}');

        // Sign out the user after registration
        await _auth.signOut();
      }
    } catch (e) {
      throw Exception('Failed to complete registration: $e');
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Check if user is signed in
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Get user stream
  static Stream<User?> get userStream => _auth.authStateChanges();
}
