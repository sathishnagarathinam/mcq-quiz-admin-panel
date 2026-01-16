import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'fcm_service.dart';

/// Supabase Authentication Service
/// Handles user authentication using Supabase Auth
class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register user with Supabase Auth
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    if (kDebugMode) {
      print('DEBUG: 🔐 Starting Supabase user registration for: $email');
    }

    try {
      // Step 1: Register user with Supabase Auth
      if (kDebugMode) {
        print('DEBUG: 📝 Calling Supabase signUp...');
        print('DEBUG: 📝 Email: $email');
        print('DEBUG: 📝 Password length: ${password.length}');
      }

      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone_number': phoneNumber,
          'office_name': officeName,
          'designation': designation,
          'user_type': 'mobile_user',
        },
      );

      if (kDebugMode) {
        print('DEBUG: ✅ Supabase signUp completed');
        print('DEBUG: 📝 User: ${response.user != null ? 'not null' : 'null'}');
        print(
          'DEBUG: 📝 Session: ${response.session != null ? 'not null' : 'null'}',
        );
      }

      final User? user = response.user;
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
        print('DEBUG: ✅ Supabase user created successfully: ${user.id}');
        print('DEBUG: 📝 User email: ${user.email}');
        print('DEBUG: 📝 Email confirmed: ${user.emailConfirmedAt != null}');
      }

      // Step 2: Store additional user data in Firestore (for now)
      // TODO: Migrate to Supabase database later
      bool firestoreSuccess = false;
      try {
        if (kDebugMode) {
          print('DEBUG: 📝 Storing user data in Firestore...');
        }

        await _storeUserDataInFirestore(
          uid: user.id,
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
          await saveFCMTokenForUser(user.id);
          if (kDebugMode) {
            print(
              'DEBUG: ✅ FCM token saved during registration for user: ${user.id}',
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

      return {
        'success': true,
        'uid': user.id,
        'email': user.email,
        'emailConfirmed': user.emailConfirmedAt != null,
        'firestoreSuccess': firestoreSuccess,
        'message': firestoreSuccess
            ? 'Account created successfully'
            : 'Account created (data sync pending)',
      };
    } on AuthException catch (authError) {
      if (kDebugMode) {
        print('DEBUG: ❌ Supabase Auth error: ${authError.message}');
        print('DEBUG: ❌ Error code: ${authError.statusCode}');
      }

      return {
        'success': false,
        'error': authError.statusCode ?? 'auth_error',
        'message': _getSupabaseErrorMessage(authError),
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

  /// Sign in user with Supabase Auth
  static Future<Map<String, dynamic>> signInUser({
    required String email,
    required String password,
  }) async {
    if (kDebugMode) {
      print('DEBUG: 🔐 Starting Supabase user sign in for: $email');
    }

    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = response.user;
      final Session? session = response.session;

      if (kDebugMode) {
        print('DEBUG: 📝 Response user: ${user != null ? 'not null' : 'null'}');
        print(
          'DEBUG: 📝 Response session: ${session != null ? 'not null' : 'null'}',
        );
        if (user != null) {
          print('DEBUG: 📝 User ID: ${user.id}');
          print('DEBUG: 📝 User email: ${user.email}');
          print('DEBUG: 📝 Email confirmed at: ${user.emailConfirmedAt}');
          print('DEBUG: 📝 Email confirmed: ${user.emailConfirmedAt != null}');
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

      if (kDebugMode) {
        print('DEBUG: ✅ User signed in successfully: ${user.id}');
        print('DEBUG: 📝 Email confirmed: ${user.emailConfirmedAt != null}');
      }

      // Save FCM token for push notifications
      try {
        await saveFCMTokenForUser(user.id);
        if (kDebugMode) {
          print('DEBUG: ✅ FCM token saved for user: ${user.id}');
        }
      } catch (fcmError) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Failed to save FCM token: $fcmError');
        }
        // Don't fail sign-in if FCM token saving fails
      }

      // Don't include the user object in the response as it's not serializable
      // Instead, get the current user from Supabase client in the auth provider
      return {
        'success': true,
        'uid': user.id,
        'email': user.email,
        'emailConfirmed': user.emailConfirmedAt != null,
        'message': 'Sign in successful',
      };
    } on AuthException catch (authError) {
      if (kDebugMode) {
        print('DEBUG: ❌ Supabase Auth sign in error: ${authError.message}');
        print('DEBUG: ❌ Error status code: ${authError.statusCode}');
        print('DEBUG: ❌ Full error: $authError');
      }

      return {
        'success': false,
        'error': authError.statusCode ?? 'auth_error',
        'message': _getSupabaseErrorMessage(authError),
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
      await _supabase.auth.resetPasswordForEmail(email);
      return {'success': true, 'message': 'Password reset email sent'};
    } on AuthException catch (authError) {
      return {
        'success': false,
        'error': authError.statusCode ?? 'auth_error',
        'message': _getSupabaseErrorMessage(authError),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'unknown',
        'message': 'Failed to send password reset email',
      };
    }
  }

  /// Store user data in Firestore (temporary - will migrate to Supabase DB)
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

  /// Create user document from Supabase user data (for missing documents)
  static Future<void> createUserDocumentFromSupabaseUser({
    required String uid,
    required String email,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    if (kDebugMode) {
      print('DEBUG: 🔧 Creating user document from Supabase user data');
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

  /// Get user data from Firestore (temporary - will migrate to Supabase DB)
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

  /// Get Supabase error message
  static String _getSupabaseErrorMessage(AuthException e) {
    if (kDebugMode) {
      print('DEBUG: 🔍 Processing error message: "${e.message}"');
      print('DEBUG: 🔍 Status code: "${e.statusCode}"');
    }

    switch (e.statusCode) {
      case '400':
        if (kDebugMode) {
          print('DEBUG: 🔍 Checking for various 400 errors...');
          print('DEBUG: 🔍 Error message: "${e.message}"');
          print(
            'DEBUG: 🔍 Contains "Email not confirmed": ${e.message.contains('Email not confirmed')}',
          );
          print(
            'DEBUG: 🔍 Contains "Invalid login credentials": ${e.message.contains('Invalid login credentials')}',
          );
          print(
            'DEBUG: 🔍 Contains "invalid": ${e.message.toLowerCase().contains('invalid')}',
          );
          print(
            'DEBUG: 🔍 Contains "credentials": ${e.message.toLowerCase().contains('credentials')}',
          );
        }

        // Check for invalid credentials first (common case)
        if (e.message.contains('Invalid login credentials') ||
            e.message.contains('invalid credentials') ||
            (e.message.toLowerCase().contains('invalid') &&
                (e.message.toLowerCase().contains('login') ||
                    e.message.toLowerCase().contains('credentials') ||
                    e.message.toLowerCase().contains('password') ||
                    e.message.toLowerCase().contains('email')))) {
          if (kDebugMode) {
            print('DEBUG: ✅ Matched invalid credentials error');
          }
          return 'Invalid email or password. Please check your credentials and try again.';
        }

        // Check for email confirmation errors
        if (e.message.contains('Email not confirmed') ||
            e.message.contains('email not confirmed') ||
            e.message.contains('not confirmed')) {
          if (kDebugMode) {
            print('DEBUG: ✅ Matched email confirmation error');
          }
          return 'Please verify your email address before logging in. Check your inbox for the verification link.';
        }

        // Other 400 errors
        if (e.message.contains('email') && !e.message.contains('password')) {
          return 'Please enter a valid email address.';
        } else if (e.message.contains('password') &&
            !e.message.contains('email')) {
          return 'Password must be at least 6 characters long.';
        }

        if (kDebugMode) {
          print('DEBUG: ⚠️ No specific 400 error match, using default');
        }
        return 'Invalid request. Please check your input.';
      case '422':
        if (e.message.contains('already registered')) {
          return 'An account already exists with this email address.';
        }
        return 'Email already registered or invalid format.';
      case '401':
        if (kDebugMode) {
          print('DEBUG: ✅ 401 Unauthorized - Invalid credentials');
        }
        return 'Invalid email or password. Please check your credentials and try again.';
      case '429':
        return 'Too many requests. Please try again later.';
      case '500':
        return 'Server error. Please try again later.';
      default:
        if (kDebugMode) {
          print(
            'DEBUG: 🔍 Default case - Status: ${e.statusCode}, Message: "${e.message}"',
          );
        }

        // Check for invalid credentials in any status code
        if (e.message.toLowerCase().contains('invalid') &&
            (e.message.toLowerCase().contains('login') ||
                e.message.toLowerCase().contains('credentials') ||
                e.message.toLowerCase().contains('password') ||
                e.message.toLowerCase().contains('email'))) {
          if (kDebugMode) {
            print('DEBUG: ✅ Matched invalid credentials in default case');
          }
          return 'Invalid email or password. Please check your credentials and try again.';
        }

        return e.message.isNotEmpty
            ? e.message
            : 'An authentication error occurred.';
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      // Sign out from Supabase
      await _supabase.auth.signOut();

      if (kDebugMode) {
        print('DEBUG: ✅ User signed out from Supabase successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Supabase sign out error: $e');
      }
      // Even if there's an error, we should clear local state
      rethrow;
    }
  }

  /// Check if current user's email is verified
  static Future<bool> isEmailVerified() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Refresh user data to get latest verification status
        await _supabase.auth.refreshSession();
        final refreshedUser = _supabase.auth.currentUser;
        return refreshedUser?.emailConfirmedAt != null;
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
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = response.user;
      if (user != null) {
        final bool isVerified = user.emailConfirmedAt != null;

        if (kDebugMode) {
          print('DEBUG: 📧 Email verification status: $isVerified');
        }

        // If email is not verified, sign out immediately
        if (!isVerified) {
          await _supabase.auth.signOut();
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
    } on AuthException catch (authError) {
      if (kDebugMode) {
        print(
          'DEBUG: ❌ Auth error checking verification: ${authError.message}',
        );
      }

      // Handle specific auth errors
      if (authError.message.contains('Invalid login credentials')) {
        return {'verified': false, 'message': 'Invalid email or password.'};
      } else if (authError.message.contains('Email not confirmed')) {
        return {
          'verified': false,
          'message': 'Email not verified yet. Please check your inbox.',
        };
      }

      return {'verified': false, 'message': authError.message};
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

  /// Resend email verification
  static Future<Map<String, dynamic>> resendEmailVerification({
    String? email,
  }) async {
    try {
      String? targetEmail;

      // If email is provided, use it; otherwise try to get from current user
      if (email != null && email.isNotEmpty) {
        targetEmail = email;
      } else {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          targetEmail = user.email;
        }
      }

      if (targetEmail == null || targetEmail.isEmpty) {
        return {
          'success': false,
          'error': 'no_email',
          'message': 'No email address provided for resending verification',
        };
      }

      if (kDebugMode) {
        print('DEBUG: 📧 Resending verification email to: $targetEmail');
      }

      // Use Supabase resend method for signup verification
      await _supabase.auth.resend(type: OtpType.signup, email: targetEmail);

      if (kDebugMode) {
        print('DEBUG: ✅ Verification email resent successfully');
      }

      return {
        'success': true,
        'message': 'Verification email sent successfully',
      };
    } on AuthException catch (authError) {
      if (kDebugMode) {
        print(
          'DEBUG: ❌ Auth error resending verification: ${authError.message}',
        );
      }

      String errorMessage;
      switch (authError.statusCode) {
        case '429':
          errorMessage =
              'Too many requests. Please wait before requesting another verification email.';
          break;
        case '422':
          errorMessage = 'Email may already be verified or invalid.';
          break;
        default:
          errorMessage = authError.message.isNotEmpty
              ? authError.message
              : 'Failed to resend verification email';
      }

      return {
        'success': false,
        'error': authError.statusCode ?? 'auth_error',
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

  /// Test Supabase connectivity
  static Future<Map<String, dynamic>> testSupabaseConnection() async {
    if (kDebugMode) {
      print('DEBUG: 🧪 Testing Supabase connectivity...');
    }

    try {
      // Test 1: Check if Supabase is initialized
      final currentUser = _supabase.auth.currentUser;
      if (kDebugMode) {
        print('DEBUG: 📝 Supabase initialized: true');
        print('DEBUG: 📝 Current user: ${currentUser?.id ?? 'none'}');
      }

      // Test 2: Try a simple auth operation (get session)
      final session = _supabase.auth.currentSession;
      if (kDebugMode) {
        print(
          'DEBUG: 📝 Current session: ${session != null ? 'active' : 'none'}',
        );
      }

      return {
        'success': true,
        'message': 'Supabase connectivity test passed',
        'supabaseInitialized': true,
        'hasSession': session != null,
        'currentUser': currentUser?.id,
      };
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Supabase connectivity test failed: $e');
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': 'Supabase connectivity test failed',
      };
    }
  }
}
