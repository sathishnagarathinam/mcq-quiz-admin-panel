import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'demo_account_service.dart';

/// Email/Password Authentication Service
class EmailAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register user with email and password
  static Future<User?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 📧 Starting email registration for: $email');
      }

      // Create user with email and password
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        if (kDebugMode) {
          print('DEBUG: ✅ User created successfully: ${user.uid}');
        }

        // Update display name
        await user.updateDisplayName(name);

        // Save user details to Firestore
        await _saveUserToFirestore(
          user: user,
          name: name,
          phoneNumber: phoneNumber,
          officeName: officeName,
          designation: designation,
        );

        // Send email verification with proper action code settings
        await _sendEmailVerificationWithDomain(user);

        if (kDebugMode) {
          print('DEBUG: ✅ Email verification sent to: $email');
        }

        return user;
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Registration failed: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Unexpected error during registration: $e');
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
    return null;
  }

  /// Sign in user with email and password
  static Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔐 Attempting login for: $email');
      }

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        if (kDebugMode) {
          print('DEBUG: ✅ Login successful: ${user.uid}');
          print('DEBUG: 📧 Email verified: ${user.emailVerified}');
        }

        // Check if email is verified (bypass for demo account)
        if (!user.emailVerified &&
            !DemoAccountService.shouldBypassEmailVerification(user.email)) {
          if (kDebugMode) {
            print('DEBUG: ❌ Email not verified, blocking login');
          }
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message:
                'Please verify your email address before logging in. Check your inbox for the verification link.',
          );
        }

        // Update last login time
        await _updateLastLogin(user.uid);

        return user;
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Login failed: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Unexpected error during login: $e');
      }
      throw Exception('Login failed: ${e.toString()}');
    }
    return null;
  }

  /// Save user details to Firestore
  static Future<void> _saveUserToFirestore({
    required User user,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    try {
      final userData = {
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'phoneNumber': phoneNumber,
        'officeName': officeName,
        'designation': designation,
        'userType': 'mobile_user',
        'role': 'user',
        'emailVerified': user.emailVerified,
        'profileComplete': true,
        'isActive': true,
        'quizzesTaken': 0,
        'totalScore': 0,
        'averageScore': 0.0,
        'stats': {
          'totalQuizzes': 0,
          'totalScore': 0,
          'averageScore': 0.0,
          'currentStreak': 0,
          'longestStreak': 0,
          'totalTimeSpent': 0,
        },
        'preferences': {
          'darkMode': false,
          'notifications': true,
          'language': 'en',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('mobile_users').doc(user.uid).set(userData);

      if (kDebugMode) {
        print('DEBUG: ✅ User data saved to Firestore: ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to save user data: $e');
      }
      throw Exception('Failed to save user data: ${e.toString()}');
    }
  }

  /// Update last login time
  static Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ⚠️ Failed to update last login: $e');
      }
      // Don't throw error for this non-critical operation
    }
  }

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to get user data: $e');
      }
    }
    return null;
  }

  /// Send email verification with proper domain configuration
  static Future<void> _sendEmailVerificationWithDomain(User user) async {
    try {
      // Configure action code settings for email verification
      final actionCodeSettings = ActionCodeSettings(
        // Use your app's domain or a custom domain
        url: 'https://mcq-quiz-system.firebaseapp.com/__/auth/action',
        // This must be true for mobile apps
        handleCodeInApp: true,
        // iOS bundle ID
        iOSBundleId: 'com.mcqquiz.app',
        // Android package name
        androidPackageName: 'com.mcqquiz.app',
        // Install if not available? (optional)
        androidInstallApp: true,
        // Minimum version (optional)
        androidMinimumVersion: '21',
      );

      await user.sendEmailVerification(actionCodeSettings);

      if (kDebugMode) {
        print(
            'DEBUG: ✅ Email verification sent with proper domain configuration');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'DEBUG: ⚠️ Failed to send email verification with domain, using default: $e');
      }
      // Fallback to default email verification
      await user.sendEmailVerification();
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Configure action code settings for password reset
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://mcq-quiz-system.firebaseapp.com/__/auth/action',
        handleCodeInApp: false, // Password reset should open in browser
        iOSBundleId: 'com.mcqquiz.app',
        androidPackageName: 'com.mcqquiz.app',
      );

      await _auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );

      if (kDebugMode) {
        print('DEBUG: ✅ Password reset email sent to: $email');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Password reset failed: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  /// Resend email verification
  static Future<void> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null &&
          !user.emailVerified &&
          !DemoAccountService.shouldBypassEmailVerification(user.email)) {
        await _sendEmailVerificationWithDomain(user);
        if (kDebugMode) {
          print('DEBUG: ✅ Email verification resent to: ${user.email}');
        }
      } else {
        throw Exception('No user found or email already verified');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to resend email verification: $e');
      }
      throw Exception('Failed to resend verification email: ${e.toString()}');
    }
  }

  /// Check if current user's email is verified
  static Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload(); // Refresh user data
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to check email verification: $e');
      }
      return false;
    }
  }

  /// Sign out user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (kDebugMode) {
        print('DEBUG: ✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Sign out failed: $e');
      }
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is logged in
  static bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Handle Firebase Auth exceptions
  static Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception(
            'Password is too weak. Please use at least 6 characters.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email address.');
      case 'invalid-email':
        return Exception('Please enter a valid email address.');
      case 'user-not-found':
        return Exception('No account found with this email address.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later.');
      case 'operation-not-allowed':
        return Exception('Email/password authentication is not enabled.');
      case 'email-not-verified':
        return Exception(
            'Please verify your email address before logging in. Check your inbox for the verification link.');
      default:
        return Exception(
            e.message ?? 'Authentication failed. Please try again.');
    }
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  static String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null; // Password is valid
  }
}
