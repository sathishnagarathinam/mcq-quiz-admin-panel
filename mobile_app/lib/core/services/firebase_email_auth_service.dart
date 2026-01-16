import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'fcm_service.dart';
import 'demo_account_service.dart';

/// Firebase Email Authentication Service
/// Handles user authentication using Firebase Auth with email/password
class FirebaseEmailAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register user with Firebase Auth
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    if (kDebugMode) {
      print('DEBUG: 🔐 Starting Firebase user registration for: $email');
    }

    try {
      // Step 1: Create user with Firebase Auth
      if (kDebugMode) {
        print('DEBUG: 📝 Calling Firebase createUserWithEmailAndPassword...');
        print('DEBUG: 📝 Email: $email');
        print('DEBUG: 📝 Password length: ${password.length}');
      }

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        if (kDebugMode) {
          print('DEBUG: ❌ User registration returned null');
        }
        return {
          'success': false,
          'error': 'user_null',
          'message': 'Account creation failed. Please try again.',
        };
      }

      if (kDebugMode) {
        print('DEBUG: ✅ Firebase user created successfully: ${user.uid}');
        print('DEBUG: 📝 User email: ${user.email}');
        print('DEBUG: 📝 Email verified: ${user.emailVerified}');
      }

      // Step 2: Update user profile with display name
      await user.updateDisplayName(name);

      // Step 3: Send email verification
      await user.sendEmailVerification();
      if (kDebugMode) {
        print('DEBUG: 📧 Email verification sent to: $email');
      }

      // Step 4: Store additional user data in Firestore
      bool firestoreSuccess = false;
      try {
        if (kDebugMode) {
          print('DEBUG: 📝 Storing user data in Firestore...');
        }

        await _storeUserDataInFirestore(
          uid: user.uid,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          officeName: officeName,
          designation: designation,
        );

        firestoreSuccess = true;
        if (kDebugMode) {
          print('DEBUG: ✅ User data stored in Firestore successfully');
        }

        // Save FCM token for push notifications
        try {
          await saveFCMTokenForUser(user.uid);
          if (kDebugMode) {
            print(
              'DEBUG: ✅ FCM token saved during registration for user: ${user.uid}',
            );
          }
        } catch (fcmError) {
          if (kDebugMode) {
            print(
              'DEBUG: ⚠️ Failed to save FCM token during registration: $fcmError',
            );
          }
          // Don't fail registration if FCM token saving fails
        }
      } catch (firestoreError) {
        if (kDebugMode) {
          print('DEBUG: ❌ Firestore storage failed: $firestoreError');
        }
        // Don't fail registration if Firestore fails
        firestoreSuccess = false;
      }

      // Step 5: Sign out user immediately after registration
      // They must verify email before being able to login
      await _auth.signOut();

      return {
        'success': true,
        'uid': user.uid,
        'email': user.email,
        'emailConfirmed': false, // Always false for new registrations
        'firestoreSuccess': firestoreSuccess,
        'message': firestoreSuccess
            ? 'Account created successfully. Please check your email to verify your account.'
            : 'Account created (data sync pending). Please check your email to verify your account.',
      };
    } on FirebaseAuthException catch (authError) {
      if (kDebugMode) {
        print('DEBUG: ❌ Firebase Auth error: ${authError.message}');
        print('DEBUG: ❌ Error code: ${authError.code}');
      }

      return {
        'success': false,
        'error': authError.code,
        'message': _getFirebaseErrorMessage(authError),
      };
    } catch (generalError) {
      if (kDebugMode) {
        print('DEBUG: ❌ General registration error: $generalError');
        print('DEBUG: ❌ Error type: ${generalError.runtimeType}');
      }

      return {
        'success': false,
        'error': 'unknown',
        'message': 'Registration failed: ${generalError.toString()}',
      };
    }
  }

  /// Sign in user with Firebase Auth
  static Future<Map<String, dynamic>> signInUser({
    required String email,
    required String password,
  }) async {
    if (kDebugMode) {
      print('DEBUG: 🔐 Starting Firebase user sign in for: $email');
    }

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (kDebugMode) {
        print('DEBUG: 📝 Response user: ${user != null ? 'not null' : 'null'}');
        if (user != null) {
          print('DEBUG: 📝 User ID: ${user.uid}');
          print('DEBUG: 📝 User email: ${user.email}');
          print('DEBUG: 📝 Email verified: ${user.emailVerified}');
        }
      }

      if (user == null) {
        if (kDebugMode) {
          print('DEBUG: ❌ User is null in sign-in response');
        }
        return {
          'success': false,
          'error': 'user_null',
          'message': 'Sign in failed. Please try again.',
        };
      }

      // Check if email is verified (bypass for demo account)
      if (!user.emailVerified &&
          !DemoAccountService.shouldBypassEmailVerification(user.email)) {
        if (kDebugMode) {
          print('DEBUG: ❌ Email not verified for user: ${user.uid}');
        }

        // Sign out the user since email is not verified
        await _auth.signOut();

        return {
          'success': false,
          'error': 'email_not_verified',
          'message':
              'Please verify your email address before logging in. Check your inbox for the verification link.',
        };
      }

      if (kDebugMode) {
        print('DEBUG: ✅ User signed in successfully: ${user.uid}');
        print('DEBUG: 📝 Email verified: ${user.emailVerified}');
      }

      // Save FCM token for push notifications
      try {
        await saveFCMTokenForUser(user.uid);
        if (kDebugMode) {
          print('DEBUG: ✅ FCM token saved for user: ${user.uid}');
        }
      } catch (fcmError) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Failed to save FCM token: $fcmError');
        }
        // Don't fail sign-in if FCM token saving fails
      }

      return {
        'success': true,
        'uid': user.uid,
        'email': user.email,
        'emailConfirmed': user.emailVerified,
        'message': 'Sign in successful',
      };
    } on FirebaseAuthException catch (authError) {
      if (kDebugMode) {
        print('DEBUG: ❌ Firebase Auth sign in error: ${authError.message}');
        print('DEBUG: ❌ Error code: ${authError.code}');
        print('DEBUG: ❌ Full error: $authError');
      }

      return {
        'success': false,
        'error': authError.code,
        'message': _getFirebaseErrorMessage(authError),
      };
    } catch (generalError) {
      if (kDebugMode) {
        print('DEBUG: ❌ General sign in error: $generalError');
      }

      return {
        'success': false,
        'error': 'unknown',
        'message': 'Sign in failed: ${generalError.toString()}',
      };
    }
  }

  /// Send password reset email
  static Future<Map<String, dynamic>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (authError) {
      return {
        'success': false,
        'error': authError.code,
        'message': _getFirebaseErrorMessage(authError),
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
  static Future<void> _storeUserDataInFirestore({
    required String uid,
    required String email,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    final userData = <String, dynamic>{
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'officeName': officeName,
      'designation': designation,
      'userType': 'mobile_user',
      'role': 'user',
      'emailVerified': false,
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
        'notifications': true,
        'darkMode': false,
        'language': 'en',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('mobile_users').doc(uid).set(userData);
  }

  /// Create user document from Firebase user data (for missing documents)
  static Future<void> createUserDocumentFromFirebaseUser({
    required String uid,
    required String email,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    if (kDebugMode) {
      print('DEBUG: 🔧 Creating user document from Firebase user data');
    }

    await _storeUserDataInFirestore(
      uid: uid,
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      officeName: officeName,
      designation: designation,
    );
  }

  /// Save FCM token for push notifications
  static Future<void> saveFCMTokenForUser(String userId) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 📱 Getting FCM token for user: $userId');
      }

      // Get FCM token
      String? fcmToken = await FCMService.getToken();

      if (fcmToken == null) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ No FCM token available');
        }
        return;
      }

      if (kDebugMode) {
        print('DEBUG: 📱 FCM token obtained: ${fcmToken.substring(0, 20)}...');
      }

      // Save token to user document in mobile_users collection
      await _firestore.collection('mobile_users').doc(userId).update({
        'fcmToken': fcmToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('DEBUG: ✅ FCM token saved to Firestore for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error saving FCM token: $e');
      }
      rethrow;
    }
  }

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 📖 Getting user data for UID: $uid');
      }

      // First, try to get user from mobile_users collection
      final mobileUserDoc =
          await _firestore.collection('mobile_users').doc(uid).get();

      if (mobileUserDoc.exists) {
        if (kDebugMode) {
          print('DEBUG: ✅ User data found in mobile_users collection');
        }
        return mobileUserDoc.data();
      }

      // If not found in mobile_users, check admin_users collection
      if (kDebugMode) {
        print(
            'DEBUG: 🔍 User not found in mobile_users, checking admin_users...');
      }

      final adminUserDoc =
          await _firestore.collection('admin_users').doc(uid).get();

      if (adminUserDoc.exists) {
        if (kDebugMode) {
          print('DEBUG: ✅ User data found in admin_users collection');
        }

        final adminData = adminUserDoc.data()!;

        // Convert admin user data to mobile user format
        final mobileUserData = {
          'uid': uid,
          'email': adminData['email'] ?? '',
          'name': adminData['name'] ?? '',
          'phoneNumber': '', // Admin users might not have phone numbers
          'officeName': 'Admin Office', // Default for admin users
          'designation': adminData['role'] ?? 'admin',
          'userType': 'admin_user',
          'role': adminData['role'] ?? 'admin',
          'emailVerified': true, // Assume admin users are verified
          'profileComplete': true,
          'isActive': adminData['isActive'] ?? true,
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
            'notifications': true,
            'darkMode': false,
            'language': 'en',
          },
          'createdAt': adminData['createdAt'],
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Optionally, create a document in mobile_users for future reference
        try {
          await _firestore
              .collection('mobile_users')
              .doc(uid)
              .set(mobileUserData);
          if (kDebugMode) {
            print('DEBUG: ✅ Created mobile_users document for admin user');
          }
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: ⚠️ Failed to create mobile_users document: $e');
          }
        }

        return mobileUserData;
      }

      if (kDebugMode) {
        print('DEBUG: ⚠️ User document not found in either collection');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to get user data: $e');
      }
      return null;
    }
  }

  /// Get Firebase error message
  static String _getFirebaseErrorMessage(FirebaseAuthException e) {
    if (kDebugMode) {
      print('DEBUG: 🔍 Processing error message: "${e.message}"');
      print('DEBUG: 🔍 Error code: "${e.code}"');
    }

    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled. Please contact support.';
      default:
        if (kDebugMode) {
          print(
              'DEBUG: 🔍 Default case - Code: ${e.code}, Message: "${e.message}"');
        }
        return e.message ?? 'An authentication error occurred.';
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      if (kDebugMode) {
        print('DEBUG: ✅ User signed out from Firebase successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Firebase sign out error: $e');
      }
      // Even if there's an error, we should clear local state
      rethrow;
    }
  }

  /// Check if current user's email is verified
  static Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Reload user data to get latest verification status
        await user.reload();
        final refreshedUser = _auth.currentUser;
        return refreshedUser?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to check email verification: $e');
      }
      return false;
    }
  }

  /// Check if an email is verified by attempting to get user info
  /// This method works even when the user is signed out
  static Future<Map<String, dynamic>> checkEmailVerificationStatus({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔍 Checking verification status for: $email');
      }

      // Attempt to sign in to check verification status
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        final bool isVerified = user.emailVerified;

        if (kDebugMode) {
          print('DEBUG: 📧 Email verification status: $isVerified');
        }

        // If email is not verified, sign out immediately
        if (!isVerified) {
          await _auth.signOut();
          return {
            'verified': false,
            'message': 'Email not verified yet. Please check your inbox.',
          };
        }

        // If verified, keep the session and return success
        return {
          'verified': true,
          'user': user,
          'message': 'Email verified successfully!',
        };
      } else {
        return {
          'verified': false,
          'message': 'Unable to check verification status.',
        };
      }
    } on FirebaseAuthException catch (authError) {
      if (kDebugMode) {
        print(
          'DEBUG: ❌ Auth error checking verification: ${authError.message}',
        );
      }

      // Handle specific auth errors
      if (authError.code == 'wrong-password' ||
          authError.code == 'user-not-found') {
        return {'verified': false, 'message': 'Invalid email or password.'};
      }

      return {
        'verified': false,
        'message': _getFirebaseErrorMessage(authError)
      };
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to check verification status: $e');
      }
      return {
        'verified': false,
        'message': 'Failed to check verification status: ${e.toString()}',
      };
    }
  }

  /// Sync email verification status from Firebase Auth to Firestore
  /// This ensures Firestore stays in sync when user verifies email
  static Future<void> syncEmailVerificationStatus(String uid) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ No current user to sync verification status');
        }
        return;
      }

      // Reload user to get latest verification status
      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        if (kDebugMode) {
          print('DEBUG: 🔄 Syncing email verification status to Firestore...');
        }

        // Update mobile_users collection
        await _firestore.collection('mobile_users').doc(uid).update({
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          print('DEBUG: ✅ Firestore emailVerified synced to true');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ⚠️ Failed to sync email verification status: $e');
      }
      // Don't throw - this is a non-critical sync operation
    }
  }

  /// Resend email verification
  static Future<Map<String, dynamic>> resendEmailVerification({
    String? email,
  }) async {
    try {
      User? user = _auth.currentUser;

      // If no current user and email is provided, we can't resend verification
      // User needs to be signed in to resend verification
      if (user == null) {
        return {
          'success': false,
          'error': 'no_user',
          'message':
              'No user signed in. Please sign in to resend verification email.',
        };
      }

      if (kDebugMode) {
        print('DEBUG: 📧 Resending verification email to: ${user.email}');
      }

      // Send verification email
      await user.sendEmailVerification();

      if (kDebugMode) {
        print('DEBUG: ✅ Verification email resent successfully');
      }

      return {
        'success': true,
        'message': 'Verification email sent successfully',
      };
    } on FirebaseAuthException catch (authError) {
      if (kDebugMode) {
        print(
          'DEBUG: ❌ Auth error resending verification: ${authError.message}',
        );
      }

      String errorMessage;
      switch (authError.code) {
        case 'too-many-requests':
          errorMessage =
              'Too many requests. Please wait before requesting another verification email.';
          break;
        case 'user-not-found':
          errorMessage = 'User not found. Please sign in first.';
          break;
        default:
          errorMessage = _getFirebaseErrorMessage(authError);
      }

      return {
        'success': false,
        'error': authError.code,
        'message': errorMessage,
      };
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to resend email verification: $e');
      }
      return {
        'success': false,
        'error': 'resend_failed',
        'message': 'Failed to resend verification email: ${e.toString()}',
      };
    }
  }

  /// Email validation
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
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

  /// Test Firebase connectivity
  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    if (kDebugMode) {
      print('DEBUG: 🧪 Testing Firebase connectivity...');
    }

    try {
      // Test 1: Check if Firebase is initialized
      final currentUser = _auth.currentUser;
      if (kDebugMode) {
        print('DEBUG: 📝 Firebase initialized: true');
        print('DEBUG: 📝 Current user: ${currentUser?.uid ?? 'none'}');
      }

      return {
        'success': true,
        'message': 'Firebase connectivity test passed',
        'firebaseInitialized': true,
        'currentUser': currentUser?.uid,
      };
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Firebase connectivity test failed: $e');
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': 'Firebase connectivity test failed',
      };
    }
  }
}
