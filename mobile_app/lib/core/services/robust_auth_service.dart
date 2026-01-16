import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Robust Authentication Service
/// Handles Firebase Auth with better error handling for PigeonUserDetails issues
class RobustAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _mobileUsersCollection = 'mobile_users';

  /// Register user with robust error handling
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
        print('DEBUG: 🔐 Starting robust user registration for: $email');
      }

      // Step 1: Create Firebase Auth user
      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (authError) {
        if (kDebugMode) {
          print('DEBUG: ❌ Firebase Auth creation failed: $authError');
        }
        
        // Handle specific Firebase Auth errors
        if (authError is FirebaseAuthException) {
          throw _handleFirebaseAuthException(authError);
        }
        
        // Handle PigeonUserDetails error
        if (authError.toString().contains('PigeonUserDetails') || 
            authError.toString().contains('type cast')) {
          throw Exception('Authentication service error. Please try again in a moment.');
        }
        
        throw Exception('Registration failed: ${authError.toString()}');
      }

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Registration failed: User creation returned null');
      }

      if (kDebugMode) {
        print('DEBUG: ✅ Firebase Auth user created: ${user.uid}');
      }

      // Step 2: Update user profile (non-critical)
      try {
        await user.updateDisplayName(name);
        if (kDebugMode) {
          print('DEBUG: ✅ Display name updated');
        }
      } catch (profileError) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Display name update failed (non-critical): $profileError');
        }
        // Continue registration even if profile update fails
      }

      // Step 3: Send email verification (non-critical)
      try {
        await user.sendEmailVerification();
        if (kDebugMode) {
          print('DEBUG: ✅ Email verification sent');
        }
      } catch (emailError) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Email verification failed (non-critical): $emailError');
        }
        // Continue registration even if email verification fails
      }

      // Step 4: Store user data in Firestore
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
        }
        
        // If Firestore fails, we should still consider registration successful
        // but log the error for later resolution
        if (kDebugMode) {
          print('DEBUG: ⚠️ Registration completed but user data storage failed');
        }
      }

      return {
        'success': true,
        'uid': user.uid,
        'email': user.email,
        'message': 'Registration completed successfully',
      };

    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Registration failed with error: $e');
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'message': _getErrorMessage(e),
      };
    }
  }

  /// Sign in user with robust error handling
  static Future<Map<String, dynamic>> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔐 Starting robust user sign in for: $email');
      }

      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (authError) {
        if (kDebugMode) {
          print('DEBUG: ❌ Firebase Auth sign in failed: $authError');
        }
        
        if (authError is FirebaseAuthException) {
          throw _handleFirebaseAuthException(authError);
        }
        
        if (authError.toString().contains('PigeonUserDetails') || 
            authError.toString().contains('type cast')) {
          throw Exception('Authentication service error. Please try again in a moment.');
        }
        
        throw Exception('Sign in failed: ${authError.toString()}');
      }

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Sign in failed: User authentication returned null');
      }

      if (kDebugMode) {
        print('DEBUG: ✅ User signed in successfully: ${user.uid}');
      }

      // Update last login time (non-critical)
      try {
        await _updateLastLoginTime(user.uid);
      } catch (updateError) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Last login update failed (non-critical): $updateError');
        }
      }

      return {
        'success': true,
        'uid': user.uid,
        'email': user.email,
        'emailVerified': user.emailVerified,
        'message': 'Sign in successful',
      };

    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Sign in failed with error: $e');
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'message': _getErrorMessage(e),
      };
    }
  }

  /// Send password reset email
  static Future<Map<String, dynamic>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': _getErrorMessage(e),
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

    await _firestore.collection(_mobileUsersCollection).doc(uid).set(userData);
  }

  /// Update last login time
  static Future<void> _updateLastLoginTime(String uid) async {
    await _firestore.collection(_mobileUsersCollection).doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  /// Handle Firebase Auth exceptions
  static Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No account found with this email address.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email address.');
      case 'weak-password':
        return Exception('Password is too weak. Please choose a stronger password.');
      case 'invalid-email':
        return Exception('Please enter a valid email address.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error. Please check your internet connection.');
      case 'operation-not-allowed':
        return Exception('Email/password authentication is not enabled.');
      default:
        return Exception(e.message ?? 'An authentication error occurred.');
    }
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('PigeonUserDetails') || errorString.contains('type cast')) {
      return 'Authentication service temporarily unavailable. Please try again.';
    }
    
    if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    return error.toString().replaceAll('Exception: ', '');
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
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
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
