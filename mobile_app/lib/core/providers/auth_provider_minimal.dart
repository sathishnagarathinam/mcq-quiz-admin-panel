import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_auth_service.dart';
import '../services/device_auth_service.dart';
import '../services/fcm_service.dart';

// Key for storing authenticated phone number
const String _authPhoneKey = 'authenticated_phone_number';

// Auth state class with error handling
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final User? user;
  final String? phoneNumber; // Store authenticated phone number

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.user,
    this.phoneNumber,
  });

  static const initial = AuthState();
  static const loading = AuthState(isLoading: true);
  static const unauthenticated = AuthState(isAuthenticated: false);

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    User? user,
    String? phoneNumber,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      user: user ?? this.user,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  // final FirebaseAuthService _authService; // Unused for now
  String? _verificationId;

  // Flag to skip device validation during registration OTP verification
  bool _isRegistrationInProgress = false;

  AuthNotifier(FirebaseAuthService authService) : super(AuthState.initial) {
    _init();
  }

  User? get currentUser => state.user;
  String? get authenticatedPhoneNumber => state.phoneNumber;

  void _init() {
    // First, check for phone-based authentication from SharedPreferences
    _checkPhoneAuth();

    // Also listen to Firebase Auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        // Skip device validation during registration - we'll handle it after user is created
        if (_isRegistrationInProgress) {
          if (kDebugMode) {
            print('DEBUG: ⏭️ Skipping device validation during registration');
          }
          return;
        }

        // Validate device for this user
        try {
          final deviceValidation =
              await DeviceAuthService.validateDeviceForUser(user.uid);

          if (!deviceValidation.isValid) {
            // Device validation failed - sign out user
            await FirebaseAuth.instance.signOut();
            state = state.copyWith(
              isAuthenticated: false,
              user: null,
              error: deviceValidation.reason,
            );
            return;
          }

          // Handle device binding if needed
          if (deviceValidation.action == DeviceValidationAction.bindDevice) {
            try {
              await DeviceAuthService.bindDeviceToUser(user.uid);
              if (kDebugMode) {
                print(
                    'DEBUG: ✅ Device bound to user during phone auth startup');
              }
            } catch (e) {
              if (kDebugMode) {
                print(
                    'DEBUG: ❌ Failed to bind device during phone auth startup: $e');
              }
              // Sign out user if device binding fails
              await FirebaseAuth.instance.signOut();
              state = state.copyWith(
                isAuthenticated: false,
                user: null,
                error:
                    'Only registered user is allowed to Login in this device',
              );
              return;
            }
          } else if (deviceValidation.action ==
              DeviceValidationAction.allowAccess) {
            // For existing users, attempt migration to enhanced device ID
            try {
              await DeviceAuthService.migrateToEnhancedDeviceId(user.uid);
              if (kDebugMode) {
                print(
                    'DEBUG: ✅ Device ID migration completed during phone auth startup');
              }
            } catch (e) {
              if (kDebugMode) {
                print(
                    'DEBUG: ⚠️ Device ID migration failed during phone auth startup (non-critical): $e');
              }
              // Migration failure is non-critical, continue with authentication
            }
          }

          // Check if session is still valid
          final isSessionValid =
              await DeviceAuthService.isSessionValid(user.uid);
          if (!isSessionValid) {
            await FirebaseAuth.instance.signOut();
            state = state.copyWith(
              isAuthenticated: false,
              user: null,
              error: 'Your session has been invalidated for security reasons.',
            );
            return;
          }

          state = AuthState(isAuthenticated: true, user: user);
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: ❌ Device validation failed during phone auth: $e');
          }
          // Sign out user on any error
          await FirebaseAuth.instance.signOut();
          state = state.copyWith(
            isAuthenticated: false,
            user: null,
            error: 'Authentication failed: ${e.toString()}',
          );
        }
      } else {
        // Only set unauthenticated if we don't have phone-based auth
        if (!state.isAuthenticated) {
          state = AuthState.unauthenticated;
        }
      }
    });
  }

  /// Check for phone-based authentication from SharedPreferences
  Future<void> _checkPhoneAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString(_authPhoneKey);

      if (kDebugMode) {
        print('DEBUG: Checking saved phone auth: $savedPhone');
      }

      if (savedPhone != null && savedPhone.isNotEmpty) {
        // Verify the user still exists in Firestore and device matches
        final querySnapshot = await FirebaseFirestore.instance
            .collection('mobile_users')
            .where('phoneNumber', isEqualTo: savedPhone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          final storedDeviceId = userData['deviceId'] as String?;
          final currentDeviceId = await DeviceAuthService.getDeviceId();

          if (storedDeviceId == currentDeviceId) {
            if (kDebugMode) {
              print('DEBUG: ✅ Phone auth restored from SharedPreferences');
            }
            state = state.copyWith(
              isAuthenticated: true,
              phoneNumber: savedPhone,
            );
          } else {
            if (kDebugMode) {
              print('DEBUG: ❌ Device mismatch, clearing saved auth');
            }
            await prefs.remove(_authPhoneKey);
          }
        } else {
          if (kDebugMode) {
            print('DEBUG: ❌ User not found in Firestore, clearing saved auth');
          }
          await prefs.remove(_authPhoneKey);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error checking phone auth: $e');
      }
    }
  }

  /// Save phone authentication to SharedPreferences
  Future<void> _savePhoneAuth(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authPhoneKey, phoneNumber);
      if (kDebugMode) {
        print('DEBUG: ✅ Phone auth saved to SharedPreferences: $phoneNumber');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error saving phone auth: $e');
      }
    }
  }

  /// Clear phone authentication from SharedPreferences
  Future<void> _clearPhoneAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authPhoneKey);
      if (kDebugMode) {
        print('DEBUG: ✅ Phone auth cleared from SharedPreferences');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error clearing phone auth: $e');
      }
    }
  }

  /// Check if a user exists in Firestore by phone number
  /// Returns: 'exists' if user found, 'not_found' if new user, or error message
  Future<String> checkUserExists(String phoneNumber) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Checking if user exists for phone: $phoneNumber');
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('mobile_users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          print('DEBUG: ✅ User found in Firestore');
        }
        return 'exists';
      } else {
        if (kDebugMode) {
          print('DEBUG: ❌ User not found in Firestore - new user');
        }
        return 'not_found';
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error checking user existence: $e');
      }
      return 'error: ${e.toString()}';
    }
  }

  /// Login existing user directly without OTP (OTP only required during registration)
  Future<bool> loginExistingUser(String phoneNumber) async {
    state = AuthState.loading;
    try {
      if (kDebugMode) {
        print('DEBUG: Logging in existing user: $phoneNumber');
      }

      // Get user data from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('mobile_users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not found. Please register first.',
        );
        return false;
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final String? storedDeviceId = userData['deviceId'];

      // Validate device binding
      final currentDeviceId = await DeviceAuthService.getDeviceId();

      if (storedDeviceId != null &&
          storedDeviceId.isNotEmpty &&
          storedDeviceId != currentDeviceId) {
        state = state.copyWith(
          isLoading: false,
          error:
              'This account is registered on another device. Please use the original device.',
        );
        return false;
      }

      // If no device bound yet, bind this device
      if (storedDeviceId == null || storedDeviceId.isEmpty) {
        await FirebaseFirestore.instance
            .collection('mobile_users')
            .doc(userDoc.id)
            .update({'deviceId': currentDeviceId});
        if (kDebugMode) {
          print('DEBUG: ✅ Device bound to user during login');
        }
      }

      // Update last login timestamp
      await FirebaseFirestore.instance
          .collection('mobile_users')
          .doc(userDoc.id)
          .update({'lastLoginAt': FieldValue.serverTimestamp()});

      // Save phone auth to SharedPreferences for persistence
      await _savePhoneAuth(phoneNumber);

      // Initialize FCM and save token
      try {
        await FCMService.initialize();
        await FCMService.saveTokenToUser(userDoc.id);
        if (kDebugMode) {
          print(
              'DEBUG: ✅ FCM initialized and token saved for user: ${userDoc.id}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Failed to initialize FCM: $e');
        }
      }

      // Set authenticated state (without Firebase Auth user for phone-only login)
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        phoneNumber: phoneNumber,
        error: null,
      );

      if (kDebugMode) {
        print('DEBUG: ✅ Existing user logged in successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error logging in existing user: $e');
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> sendOTP(String phoneNumber) async {
    state = AuthState.loading;

    if (kDebugMode) {
      print('DEBUG: 📱 sendOTP called with phoneNumber: "$phoneNumber"');
      print('DEBUG: 📱 Phone number length: ${phoneNumber.length}');
    }

    try {
      // Check if this is a test phone number
      final testPhoneNumbers = {
        '+919876543210': '123456', // Demo account
        '+911234567890': '654321', // Test account 1
        '+919999999999': '123456', // Google Play Reviewer
      };

      if (testPhoneNumbers.containsKey(phoneNumber)) {
        if (kDebugMode) {
          print('DEBUG: ✅ Test phone number detected: $phoneNumber');
        }
        // For test numbers, simulate OTP sent
        _verificationId =
            'test_verification_id_${DateTime.now().millisecondsSinceEpoch}';
        state = state.copyWith(isLoading: false);
        return true;
      }

      if (kDebugMode) {
        print('DEBUG: 📱 Sending OTP to Firebase for: $phoneNumber');
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(isLoading: false, error: e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          state = state.copyWith(isLoading: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
    return true;
  }

  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      state = state.copyWith(error: 'Verification ID not found');
      return false;
    }

    state = AuthState.loading;
    try {
      // Check if this is a test verification ID
      final isTestVerification =
          _verificationId!.startsWith('test_verification_id_');

      if (isTestVerification) {
        // For test phone numbers, validate OTP locally
        final testPhoneNumbers = {
          '+919876543210': '123456', // Demo account
          '+911234567890': '654321', // Test account 1
          '+919999999999': '123456', // Google Play Reviewer
        };

        // Find which test number this is for (we'll accept any valid test OTP)
        bool isValidTestOTP = testPhoneNumbers.values.contains(otp);

        if (!isValidTestOTP) {
          state = state.copyWith(
            isLoading: false,
            error:
                'Invalid OTP. For test numbers, use: 123456, 654321, or 123456',
          );
          return false;
        }

        if (kDebugMode) {
          print('DEBUG: ✅ Test OTP verified: $otp');
        }

        // Test OTP is valid - return true to proceed with registration/login
        state = state.copyWith(isLoading: false, isAuthenticated: true);
        return true;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        // Validate device for this user
        final deviceValidation =
            await DeviceAuthService.validateDeviceForUser(user.uid);

        if (!deviceValidation.isValid) {
          // Device validation failed - sign out and show error
          await FirebaseAuth.instance.signOut();
          state = state.copyWith(
            isLoading: false,
            error: deviceValidation.reason,
          );
          return false;
        }

        // Handle device binding if needed
        if (deviceValidation.action == DeviceValidationAction.bindDevice) {
          try {
            await DeviceAuthService.bindDeviceToUser(user.uid);
            if (kDebugMode) {
              print(
                  'DEBUG: ✅ Device bound to user during phone OTP verification');
            }
          } catch (e) {
            if (kDebugMode) {
              print(
                  'DEBUG: ❌ Failed to bind device during OTP verification: $e');
            }
            // CRITICAL: Do not continue with login if device binding fails
            await FirebaseAuth.instance.signOut();
            state = state.copyWith(
              isLoading: false,
              error: 'Only registered user is allowed to Login in this device',
            );
            return false;
          }
        } else if (deviceValidation.action ==
            DeviceValidationAction.allowAccess) {
          // For existing users, attempt migration to enhanced device ID
          try {
            await DeviceAuthService.migrateToEnhancedDeviceId(user.uid);
            if (kDebugMode) {
              print(
                  'DEBUG: ✅ Device ID migration completed during OTP verification');
            }
          } catch (e) {
            if (kDebugMode) {
              print(
                  'DEBUG: ⚠️ Device ID migration failed during OTP verification (non-critical): $e');
            }
            // Migration failure is non-critical, continue with authentication
          }
        }

        // Check if session is still valid (not force logged out)
        final isSessionValid = await DeviceAuthService.isSessionValid(user.uid);
        if (!isSessionValid) {
          await FirebaseAuth.instance.signOut();
          state = state.copyWith(
            isLoading: false,
            error:
                'Your session has been invalidated for security reasons. Please login again.',
          );
          return false;
        }

        // Clear any force logout flags
        await DeviceAuthService.clearForceLogoutFlag(user.uid);

        // Update last login time in Firestore
        try {
          await FirebaseFirestore.instance
              .collection('mobile_users')
              .doc(user.uid)
              .update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: ⚠️ Failed to update last login time: $e');
          }
        }

        // Initialize FCM and save token
        try {
          await FCMService.initialize();
          await FCMService.saveTokenToUser(user.uid);
          if (kDebugMode) {
            print(
                'DEBUG: ✅ FCM initialized and token saved for user: ${user.uid}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: ⚠️ Failed to initialize FCM: $e');
          }
        }
      }

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = AuthState.loading;
    try {
      await FirebaseAuth.instance.signOut();
      await _clearPhoneAuth(); // Clear phone-based auth
      state = AuthState.unauthenticated;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> registerWithPhone(
      String phoneNumber, Map<String, dynamic> userData) async {
    return await sendOTP(phoneNumber);
  }

  /// Verify OTP for registration only - skips device validation since user doesn't exist yet
  Future<bool> _verifyOTPForRegistration(String otp) async {
    if (_verificationId == null) {
      state = state.copyWith(error: 'Verification ID not found');
      return false;
    }

    try {
      // Check if this is a test verification ID
      final isTestVerification =
          _verificationId!.startsWith('test_verification_id_');

      if (isTestVerification) {
        // For test phone numbers, validate OTP locally
        final testPhoneNumbers = {
          '+919876543210': '123456', // Demo account
          '+911234567890': '654321', // Test account 1
          '+919999999999': '123456', // Google Play Reviewer
        };

        // Find which test number this is for (we'll accept any valid test OTP)
        bool isValidTestOTP = testPhoneNumbers.values.contains(otp);

        if (!isValidTestOTP) {
          state = state.copyWith(
            isLoading: false,
            error:
                'Invalid OTP. For test numbers, use: 123456, 654321, or 123456',
          );
          return false;
        }

        if (kDebugMode) {
          print('DEBUG: ✅ Test OTP verified for registration: $otp');
        }

        return true;
      }

      // For real phone numbers, verify with Firebase
      // Set flag to skip device validation in auth state listener
      _isRegistrationInProgress = true;

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user != null) {
          if (kDebugMode) {
            print('DEBUG: ✅ Firebase OTP verified for registration');
          }
          // Sign out immediately - we don't want Firebase Auth for phone-only users
          // We'll manage auth state ourselves using SharedPreferences
          await FirebaseAuth.instance.signOut();
          _isRegistrationInProgress = false;
          return true;
        }

        _isRegistrationInProgress = false;
        return false;
      } catch (e) {
        _isRegistrationInProgress = false;
        rethrow;
      }
    } catch (e) {
      _isRegistrationInProgress = false;
      if (kDebugMode) {
        print('DEBUG: ❌ OTP verification error: $e');
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyRegistrationOTP(
      String otp, Map<String, dynamic> userData) async {
    if (kDebugMode) {
      print('DEBUG: verifyRegistrationOTP called with userData: $userData');
    }

    state = AuthState.loading;

    final success = await _verifyOTPForRegistration(otp);

    if (kDebugMode) {
      print('DEBUG: _verifyOTPForRegistration returned: $success');
    }

    if (success) {
      // Save user data to Firestore after successful verification
      try {
        if (kDebugMode) {
          print('DEBUG: Saving user data to Firestore after OTP verification');
        }

        // Get the phone number from userData
        final phoneNumber = userData['phoneNumber'] as String?;

        if (kDebugMode) {
          print('DEBUG: Phone number from userData: $phoneNumber');
        }

        if (phoneNumber == null || phoneNumber.isEmpty) {
          if (kDebugMode) {
            print('DEBUG: ❌ Phone number not found in userData');
          }
          state = state.copyWith(
            isLoading: false,
            error: 'Phone number not found. Please try again.',
          );
          return false;
        }

        // Get device ID for device binding
        if (kDebugMode) {
          print('DEBUG: Getting device ID...');
        }
        final deviceId = await DeviceAuthService.getDeviceId();
        if (kDebugMode) {
          print('DEBUG: Device ID: $deviceId');
        }

        // Create document ID from phone number (remove + sign)
        final docId = phoneNumber.replaceAll('+', '');
        if (kDebugMode) {
          print('DEBUG: Creating Firestore document with ID: $docId');
        }

        // Create user document in Firestore
        final userDocRef =
            FirebaseFirestore.instance.collection('mobile_users').doc(docId);

        final userDataToSave = {
          'phoneNumber': phoneNumber,
          'name': userData['name'] ?? '',
          'email': userData['email'] ?? '',
          'officeName': userData['officeName'] ?? '',
          'designation': userData['designation'] ?? '',
          'deviceId': deviceId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isPhoneVerified': true,
        };

        if (kDebugMode) {
          print('DEBUG: Saving data to Firestore: $userDataToSave');
        }

        await userDocRef.set(userDataToSave);

        if (kDebugMode) {
          print('DEBUG: ✅ User data saved to Firestore successfully');
        }

        // Save phone auth to SharedPreferences for persistence
        await _savePhoneAuth(phoneNumber);

        // Initialize FCM and save token
        try {
          await FCMService.initialize();
          // Get the user ID from Firestore using phone number
          final userQuery = await FirebaseFirestore.instance
              .collection('mobile_users')
              .where('phoneNumber', isEqualTo: phoneNumber)
              .limit(1)
              .get();

          if (userQuery.docs.isNotEmpty) {
            final userId = userQuery.docs.first.id;
            await FCMService.saveTokenToUser(userId);
            if (kDebugMode) {
              print(
                  'DEBUG: ✅ FCM initialized and token saved for new user: $userId');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: ⚠️ Failed to initialize FCM after registration: $e');
          }
        }

        // Update auth state to authenticated
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          phoneNumber: phoneNumber,
          error: null,
        );

        return true;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('DEBUG: ❌ Error saving user data to Firestore: $e');
          print('DEBUG: Stack trace: $stackTrace');
        }
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to save user data: ${e.toString()}',
        );
        return false;
      }
    } else {
      if (kDebugMode) {
        print('DEBUG: ❌ OTP verification failed');
      }
    }
    return success;
  }

  Future<bool> resendRegistrationOTP(String phoneNumber) async {
    return await sendOTP(phoneNumber);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthNotifier(authService);
});

final currentUserProvider = Provider<User?>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return authNotifier.currentUser;
});
