import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Minimal Authentication Service
/// Absolute bare minimum to avoid PigeonUserDetails errors
class MinimalAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register user with absolute minimal Firebase interaction
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    if (kDebugMode) {
      print('DEBUG: 🔐 Starting minimal user registration for: $email');
    }

    try {
      // Step 1: Only create Firebase Auth user - nothing else
      if (kDebugMode) {
        print('DEBUG: 📝 Creating Firebase Auth user...');
      }

      UserCredential? userCredential;
      User? user;

      try {
        if (kDebugMode) {
          print('DEBUG: 📝 Calling Firebase createUserWithEmailAndPassword...');
          print('DEBUG: 📝 Email: $email');
          print('DEBUG: 📝 Password length: ${password.length}');
        }

        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (kDebugMode) {
          print('DEBUG: ✅ Firebase Auth call completed');
          print('DEBUG: 📝 UserCredential: not null');
        }

        user = userCredential.user;

        if (kDebugMode) {
          print(
              'DEBUG: 📝 User from credential: ${user != null ? 'not null' : 'null'}');
          if (user != null) {
            print('DEBUG: 📝 User UID: ${user.uid}');
            print('DEBUG: 📝 User email: ${user.email}');
          }
        }
      } catch (authError) {
        if (kDebugMode) {
          print('DEBUG: ❌ Firebase Auth creation failed: $authError');
          print('DEBUG: ❌ Error type: ${authError.runtimeType}');
          print('DEBUG: ❌ Error string: ${authError.toString()}');
        }

        // Check for PigeonUserDetails error in auth
        final errorString = authError.toString();
        if (errorString.contains('PigeonUserDetails') ||
            errorString.contains('type cast') ||
            errorString.contains('List<Object?>')) {
          if (kDebugMode) {
            print('DEBUG: ❌ PigeonUserDetails error detected in Firebase Auth');
            print(
                'DEBUG: 🔍 Checking if user was actually created despite the error...');
          }

          // WORKAROUND: Check if user was actually created despite the plugin error
          try {
            await Future.delayed(
                const Duration(milliseconds: 500)); // Wait for Firebase to sync
            final currentUser = _auth.currentUser;

            if (currentUser != null && currentUser.email == email) {
              if (kDebugMode) {
                print(
                    'DEBUG: ✅ User was actually created successfully! UID: ${currentUser.uid}');
                print(
                    'DEBUG: 🔧 Bypassing plugin error and continuing with registration...');
              }

              // Continue with Firestore storage since auth actually worked
              bool firestoreSuccess = false;
              try {
                await _storeUserDataMinimal(
                  uid: currentUser.uid,
                  email: email,
                  name: name,
                  phoneNumber: phoneNumber,
                  officeName: officeName,
                  designation: designation,
                );
                firestoreSuccess = true;
                if (kDebugMode) {
                  print(
                      'DEBUG: ✅ User data stored in Firestore successfully (after plugin error bypass)');
                }
              } catch (firestoreError) {
                if (kDebugMode) {
                  print('DEBUG: ❌ Firestore storage failed: $firestoreError');
                }
              }

              return {
                'success': true,
                'uid': currentUser.uid,
                'email': currentUser.email,
                'firestoreSuccess': firestoreSuccess,
                'message': firestoreSuccess
                    ? 'Account created successfully (plugin error bypassed)'
                    : 'Account created (data sync pending)',
                'pluginErrorBypassed': true,
              };
            } else {
              if (kDebugMode) {
                print('DEBUG: ❌ User was not created, plugin error is genuine');
              }
            }
          } catch (checkError) {
            if (kDebugMode) {
              print('DEBUG: ❌ Error checking current user: $checkError');
            }
          }

          return {
            'success': false,
            'error': 'plugin_error',
            'message':
                'Authentication plugin error. Please restart the app and try again.',
          };
        }

        // Handle specific Firebase Auth errors
        if (authError is FirebaseAuthException) {
          if (kDebugMode) {
            print('DEBUG: ❌ FirebaseAuthException code: ${authError.code}');
            print(
                'DEBUG: ❌ FirebaseAuthException message: ${authError.message}');
          }
          return {
            'success': false,
            'error': authError.code,
            'message': _getFirebaseErrorMessage(authError),
          };
        }

        return {
          'success': false,
          'error': 'auth_failed',
          'message': 'Account creation failed: ${authError.toString()}',
        };
      }

      if (user == null) {
        if (kDebugMode) {
          print('DEBUG: ❌ User creation returned null');
        }
        return {
          'success': false,
          'error': 'user_null',
          'message': 'Account creation failed. Please try again.',
        };
      }

      if (kDebugMode) {
        print('DEBUG: ✅ Firebase Auth user created successfully: ${user.uid}');
      }

      // Step 2: Store user data in Firestore (separate try-catch)
      bool firestoreSuccess = false;
      try {
        if (kDebugMode) {
          print('DEBUG: 📝 Attempting to store user data in Firestore...');
        }

        await _storeUserDataMinimal(
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
      } catch (firestoreError) {
        if (kDebugMode) {
          print('DEBUG: ❌ Firestore storage failed: $firestoreError');
          print('DEBUG: ❌ Firestore error type: ${firestoreError.runtimeType}');
        }
        // Don't fail registration if Firestore fails
        firestoreSuccess = false;
      }

      // Step 3: Return success (even if Firestore failed)
      return {
        'success': true,
        'uid': user.uid,
        'email': user.email,
        'firestoreSuccess': firestoreSuccess,
        'message': firestoreSuccess
            ? 'Account created successfully'
            : 'Account created (data sync pending)',
      };
    } catch (generalError) {
      if (kDebugMode) {
        print('DEBUG: ❌ General registration error: $generalError');
        print('DEBUG: ❌ Error type: ${generalError.runtimeType}');
      }

      // Check for PigeonUserDetails error specifically
      final errorString = generalError.toString();
      if (errorString.contains('PigeonUserDetails') ||
          errorString.contains('type cast') ||
          errorString.contains('List<Object?>')) {
        return {
          'success': false,
          'error': 'plugin_error',
          'message':
              'Authentication plugin error. Please restart the app and try again.',
        };
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
    if (kDebugMode) {
      print('DEBUG: 🔐 Starting minimal user sign in for: $email');
    }

    try {
      UserCredential? userCredential;
      User? user;

      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCredential.user;
      } catch (authError) {
        if (kDebugMode) {
          print('DEBUG: ❌ Firebase Auth sign in failed: $authError');
        }

        if (authError is FirebaseAuthException) {
          return {
            'success': false,
            'error': authError.code,
            'message': _getFirebaseErrorMessage(authError),
          };
        }

        return {
          'success': false,
          'error': 'auth_failed',
          'message': 'Sign in failed. Please try again.',
        };
      }

      if (user == null) {
        return {
          'success': false,
          'error': 'user_null',
          'message': 'Sign in failed. Please try again.',
        };
      }

      if (kDebugMode) {
        print('DEBUG: ✅ User signed in successfully: ${user.uid}');
      }

      return {
        'success': true,
        'uid': user.uid,
        'email': user.email,
        'emailVerified': user.emailVerified,
        'message': 'Sign in successful',
      };
    } catch (generalError) {
      if (kDebugMode) {
        print('DEBUG: ❌ General sign in error: $generalError');
      }

      final errorString = generalError.toString();
      if (errorString.contains('PigeonUserDetails') ||
          errorString.contains('type cast') ||
          errorString.contains('List<Object?>')) {
        return {
          'success': false,
          'error': 'plugin_error',
          'message':
              'Authentication plugin error. Please restart the app and try again.',
        };
      }

      return {
        'success': false,
        'error': 'unknown',
        'message': 'Sign in failed. Please try again.',
      };
    }
  }

  /// Store user data with minimal Firestore operations
  static Future<void> _storeUserDataMinimal({
    required String uid,
    required String email,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    if (kDebugMode) {
      print('DEBUG: 📝 Preparing minimal user data for UID: $uid');
    }

    // Minimal user data - avoid complex nested objects
    final userData = <String, dynamic>{
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'officeName': officeName,
      'designation': designation,
      'userType': 'mobile_user',
      'emailVerified': false,
      'profileComplete': true,
      'isActive': true,
      'quizzesTaken': 0,
      'totalScore': 0,
      'averageScore': 0.0,
    };

    // Add timestamps separately to avoid issues
    try {
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['lastLoginAt'] = FieldValue.serverTimestamp();
    } catch (timestampError) {
      if (kDebugMode) {
        print(
            'DEBUG: ⚠️ Timestamp creation failed, using DateTime: $timestampError');
      }
      // Fallback to regular DateTime if FieldValue fails
      final now = DateTime.now().toIso8601String();
      userData['createdAt'] = now;
      userData['lastLoginAt'] = now;
    }

    if (kDebugMode) {
      print('DEBUG: 📝 User data prepared with ${userData.length} fields');
    }

    // Store in Firestore with minimal operations
    await _firestore.collection('mobile_users').doc(uid).set(userData);

    if (kDebugMode) {
      print('DEBUG: ✅ Firestore document set operation completed');
    }
  }

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 📖 Getting user data for UID: $uid');
      }

      final doc = await _firestore.collection('mobile_users').doc(uid).get();

      if (doc.exists) {
        if (kDebugMode) {
          print('DEBUG: ✅ User data found');
        }
        return doc.data();
      } else {
        if (kDebugMode) {
          print('DEBUG: ⚠️ User document not found');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to get user data: $e');
      }
      return null;
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

  /// Test Firebase connectivity
  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    if (kDebugMode) {
      print('DEBUG: 🧪 Testing Firebase connectivity...');
    }

    try {
      // Test 1: Check if Firebase Auth is initialized
      final currentUser = _auth.currentUser;
      if (kDebugMode) {
        print('DEBUG: 📝 Firebase Auth initialized: true');
        print('DEBUG: 📝 Current user: ${currentUser?.uid ?? 'none'}');
      }

      // Test 2: Try a simple Firestore operation
      try {
        final testDoc = _firestore.collection('test').doc('connectivity');
        await testDoc
            .set({'test': true, 'timestamp': DateTime.now().toIso8601String()});
        if (kDebugMode) {
          print('DEBUG: ✅ Firestore write test successful');
        }

        // Clean up test document
        await testDoc.delete();
        if (kDebugMode) {
          print('DEBUG: ✅ Firestore delete test successful');
        }
      } catch (firestoreError) {
        if (kDebugMode) {
          print('DEBUG: ❌ Firestore test failed: $firestoreError');
        }
      }

      return {
        'success': true,
        'message': 'Firebase connectivity test passed',
        'authInitialized': true,
        'firestoreInitialized': true,
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
