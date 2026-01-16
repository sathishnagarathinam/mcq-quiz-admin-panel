import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Simple Authentication Service
/// Minimal approach to avoid PigeonUserDetails issues
class SimpleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _mobileUsersCollection = 'mobile_users';

  /// Register user with minimal Firebase interaction
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔐 Starting simple user registration for: $email');
      }

      // Step 1: Create Firebase Auth user (minimal interaction)
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed');
      }

      if (kDebugMode) {
        print('DEBUG: ✅ Firebase Auth user created: ${user.uid}');
      }

      // Step 2: Store user data in Firestore immediately
      try {
        await _storeUserData(
          uid: user.uid,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          officeName: officeName,
          designation: designation,
        );

        if (kDebugMode) {
          print('DEBUG: ✅ User data stored in Firestore');
        }
      } catch (firestoreError) {
        if (kDebugMode) {
          print('DEBUG: ❌ Firestore storage failed: $firestoreError');
          print('DEBUG: ❌ Firestore error type: ${firestoreError.runtimeType}');
        }

        // Even if Firestore fails, we consider registration successful
        // since Firebase Auth worked. User can still login.
        if (kDebugMode) {
          print(
              'DEBUG: ⚠️ Registration completed but user data storage failed');
        }
      }

      // Step 3: Send email verification (in background, don't wait)
      _sendEmailVerificationAsync(user);

      return {
        'success': true,
        'uid': user.uid,
        'email': user.email,
        'message': 'Registration successful',
      };
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Firebase Auth error: ${e.code} - ${e.message}');
      }

      return {
        'success': false,
        'error': e.code,
        'message': _getFirebaseErrorMessage(e),
      };
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ General error: $e');
      }

      return {
        'success': false,
        'error': 'unknown',
        'message': 'Registration failed. Please try again.',
      };
    }
  }

  /// Sign in user with minimal Firebase interaction
  static Future<Map<String, dynamic>> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔐 Starting simple user sign in for: $email');
      }

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Sign in failed');
      }

      if (kDebugMode) {
        print('DEBUG: ✅ User signed in: ${user.uid}');
      }

      // Update last login time (in background, don't wait)
      _updateLastLoginAsync(user.uid);

      return {
        'success': true,
        'uid': user.uid,
        'email': user.email,
        'emailVerified': user.emailVerified,
        'message': 'Sign in successful',
      };
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Firebase Auth error: ${e.code} - ${e.message}');
      }

      return {
        'success': false,
        'error': e.code,
        'message': _getFirebaseErrorMessage(e),
      };
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ General error: $e');
      }

      return {
        'success': false,
        'error': 'unknown',
        'message': 'Sign in failed. Please try again.',
      };
    }
  }

  /// Send password reset email
  static Future<Map<String, dynamic>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': _getFirebaseErrorMessage(e),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'unknown',
        'message': 'Failed to send password reset email',
      };
    }
  }

  /// Store user data in Firestore
  static Future<void> _storeUserData({
    required String uid,
    required String email,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    if (kDebugMode) {
      print('DEBUG: 📝 Preparing to store user data for UID: $uid');
      print('DEBUG: 📝 Collection: $_mobileUsersCollection');
    }

    final userData = {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'officeName': officeName,
      'designation': designation,
      'userType': 'mobile_user',
      'emailVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'profileComplete': true,
      'isActive': true,
      'quizzesTaken': 0,
      'totalScore': 0,
      'averageScore': 0.0,
      'preferences': {
        'notifications': true,
        'darkMode': false,
        'language': 'en',
      },
    };

    if (kDebugMode) {
      print('DEBUG: 📝 User data prepared: ${userData.keys.toList()}');
    }

    try {
      await _firestore
          .collection(_mobileUsersCollection)
          .doc(uid)
          .set(userData);
      if (kDebugMode) {
        print('DEBUG: ✅ Firestore document created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Firestore set operation failed: $e');
        print('DEBUG: ❌ Error details: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Send email verification asynchronously (don't block registration)
  static void _sendEmailVerificationAsync(User user) {
    Future.microtask(() async {
      try {
        await user.sendEmailVerification();
        if (kDebugMode) {
          print('DEBUG: ✅ Email verification sent');
        }
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Email verification failed: $e');
        }
      }
    });
  }

  /// Update last login time asynchronously
  static void _updateLastLoginAsync(String uid) {
    Future.microtask(() async {
      try {
        await _firestore.collection(_mobileUsersCollection).doc(uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) {
          print('DEBUG: ✅ Last login time updated');
        }
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Last login update failed: $e');
        }
      }
    });
  }

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc =
          await _firestore.collection(_mobileUsersCollection).doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to get user data: $e');
      }
      return null;
    }
  }

  /// Get Firebase error message
  static String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled.';
      default:
        return e.message ?? 'An authentication error occurred.';
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

  /// Email validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Password validation
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
    return null;
  }
}
