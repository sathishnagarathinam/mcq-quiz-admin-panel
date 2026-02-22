import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_email_auth_service.dart';
import '../services/device_auth_service.dart';
import '../services/credential_storage_service.dart';
import '../services/demo_account_service.dart';

// Key for storing authenticated phone number (same as in auth_provider_minimal.dart)
const String _authPhoneKey = 'authenticated_phone_number';

/// User model for email authentication
class EmailUser {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final String officeName;
  final String designation;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  // Device Security Fields
  final String? registeredDeviceId;
  final Map<String, dynamic>? deviceInfo;
  final DateTime? deviceRegisteredAt;
  final bool isDeviceBound;
  final List<Map<String, dynamic>>? securityEvents;

  const EmailUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.officeName,
    required this.designation,
    required this.emailVerified,
    this.createdAt,
    this.lastLoginAt,
    // Device Security Fields
    this.registeredDeviceId,
    this.deviceInfo,
    this.deviceRegisteredAt,
    this.isDeviceBound = false,
    this.securityEvents,
  });

  EmailUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
    String? officeName,
    String? designation,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    // Device Security Fields
    String? registeredDeviceId,
    Map<String, dynamic>? deviceInfo,
    DateTime? deviceRegisteredAt,
    bool? isDeviceBound,
    List<Map<String, dynamic>>? securityEvents,
  }) {
    return EmailUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      officeName: officeName ?? this.officeName,
      designation: designation ?? this.designation,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      // Device Security Fields
      registeredDeviceId: registeredDeviceId ?? this.registeredDeviceId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      deviceRegisteredAt: deviceRegisteredAt ?? this.deviceRegisteredAt,
      isDeviceBound: isDeviceBound ?? this.isDeviceBound,
      securityEvents: securityEvents ?? this.securityEvents,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'officeName': officeName,
      'designation': designation,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      // Device Security Fields
      'registeredDeviceId': registeredDeviceId,
      'deviceInfo': deviceInfo,
      'deviceRegisteredAt': deviceRegisteredAt?.toIso8601String(),
      'isDeviceBound': isDeviceBound,
      'securityEvents': securityEvents,
    };
  }

  factory EmailUser.fromFirebaseUser(User user, Map<String, dynamic> userData) {
    return EmailUser(
      uid: user.uid,
      email: user.email ?? userData['email'] ?? '',
      name: userData['name'] ?? user.displayName ?? '',
      phoneNumber: userData['phoneNumber'] ?? user.phoneNumber ?? '',
      officeName: userData['officeName'] ?? '',
      designation: userData['designation'] ?? '',
      emailVerified: user.emailVerified,
      createdAt:
          _parseDateTime(userData['createdAt']) ?? (user.metadata.creationTime),
      lastLoginAt: _parseDateTime(userData['lastLoginAt']) ??
          (user.metadata.lastSignInTime),
      // Device Security Fields
      registeredDeviceId: userData['registeredDeviceId'],
      deviceInfo: userData['deviceInfo'],
      deviceRegisteredAt: _parseDateTime(userData['deviceRegisteredAt']),
      isDeviceBound: userData['isDeviceBound'] ?? false,
      securityEvents: userData['securityEvents'] != null
          ? List<Map<String, dynamic>>.from(userData['securityEvents'])
          : null,
    );
  }

  /// Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is Timestamp) {
        // Firestore Timestamp
        return value.toDate();
      } else if (value is String) {
        // ISO string format
        return DateTime.parse(value);
      } else if (value is DateTime) {
        // Already a DateTime
        return value;
      } else {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Unknown date format: ${value.runtimeType} - $value');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to parse date: $value - $e');
      }
      return null;
    }
  }
}

/// Email Authentication state
class EmailAuthState {
  final EmailUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isRegistering;
  final bool isLoggingIn;

  const EmailAuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isRegistering = false,
    this.isLoggingIn = false,
  });

  EmailAuthState copyWith({
    EmailUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isRegistering,
    bool? isLoggingIn,
  }) {
    return EmailAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isRegistering: isRegistering ?? this.isRegistering,
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
    );
  }
}

/// Email Authentication Provider
class EmailAuthNotifier extends StateNotifier<EmailAuthState> {
  EmailAuthNotifier() : super(const EmailAuthState()) {
    _checkAuthState();
    _listenToAuthChanges();
  }

  /// Check current authentication state
  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _loadUserData(user);
    } else {
      // No Firebase Auth user, check for phone-authenticated user
      _checkPhoneAuthUser();
    }
  }

  /// Check for phone-authenticated user from SharedPreferences
  Future<void> _checkPhoneAuthUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString(_authPhoneKey);

      if (kDebugMode) {
        print('DEBUG: 📱 Checking for phone-authenticated user: $savedPhone');
      }

      if (savedPhone != null && savedPhone.isNotEmpty) {
        // Load user data from mobile_users collection
        await _loadPhoneUserData(savedPhone);
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error checking phone auth user: $e');
      }
    }
  }

  /// Load user data for phone-authenticated user from Firestore
  Future<void> _loadPhoneUserData(String phoneNumber) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 📱 Loading phone user data for: $phoneNumber');
      }

      // Query mobile_users collection by phone number
      final querySnapshot = await FirebaseFirestore.instance
          .collection('mobile_users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final docId = querySnapshot.docs.first.id;

        // Verify device binding
        final storedDeviceId = userData['deviceId'] as String?;
        final currentDeviceId = await DeviceAuthService.getDeviceId();

        if (storedDeviceId != currentDeviceId) {
          if (kDebugMode) {
            print('DEBUG: ❌ Device mismatch for phone user, clearing auth');
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_authPhoneKey);
          return;
        }

        // Create EmailUser from phone user data
        final emailUser = EmailUser(
          uid: docId,
          email: userData['email'] ?? '',
          name: userData['name'] ?? '',
          phoneNumber: userData['phoneNumber'] ?? phoneNumber,
          officeName: userData['officeName'] ?? '',
          designation: userData['designation'] ?? '',
          emailVerified: true, // Phone verified users are considered verified
          createdAt: userData['createdAt']?.toDate(),
          lastLoginAt: userData['lastLoginAt']?.toDate(),
          registeredDeviceId: storedDeviceId,
          isDeviceBound: true,
        );

        state = state.copyWith(
          user: emailUser,
          isAuthenticated: true,
          error: null,
        );

        if (kDebugMode) {
          print('DEBUG: ✅ Phone user data loaded: ${emailUser.name}');
        }
      } else {
        if (kDebugMode) {
          print('DEBUG: ❌ Phone user not found in Firestore');
        }
        // Clear invalid phone auth
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authPhoneKey);
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error loading phone user data: $e');
      }
    }
  }

  /// Listen to Firebase auth state changes
  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user);
      } else {
        // User signed out from Firebase, check for phone-authenticated user
        await _checkPhoneAuthUser();
        if (!state.isAuthenticated) {
          // No phone auth either, clear state
          state = const EmailAuthState();
          if (kDebugMode) {
            print('DEBUG: 🔄 Auth state changed: User signed out');
          }
        }
      }
    });
  }

  /// Public method to reload phone user data (call after registration)
  Future<void> reloadPhoneUserData() async {
    if (kDebugMode) {
      print('DEBUG: 🔄 Reloading phone user data...');
    }
    await _checkPhoneAuthUser();
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(User firebaseUser) async {
    try {
      // SYNC: If Firebase Auth shows email verified, sync to Firestore
      // This fixes the issue where Firestore emailVerified field is out of sync
      if (firebaseUser.emailVerified) {
        if (kDebugMode) {
          print(
              'DEBUG: 🔄 Email verified in Firebase Auth, syncing to Firestore...');
        }
        await FirebaseEmailAuthService.syncEmailVerificationStatus(
          firebaseUser.uid,
        );
      }

      // Check if email is verified first (bypass for demo account)
      if (!firebaseUser.emailVerified &&
          !DemoAccountService.shouldBypassEmailVerification(
              firebaseUser.email)) {
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          error: 'Email verification required',
        );
        return;
      }

      // STRICT device validation for auth state changes - ENFORCE one user per device
      try {
        if (kDebugMode) {
          print('DEBUG: 🔍 Validating device during auth state change...');
        }

        final deviceValidation =
            await DeviceAuthService.validateDeviceForUser(firebaseUser.uid)
                .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            if (kDebugMode) {
              print(
                  'DEBUG: ⏰ Device validation timed out during auth state change');
            }
            return const DeviceValidationResult(
              isValid: false,
              reason: 'Device validation timed out. Please restart the app.',
              action: DeviceValidationAction.signOut,
            );
          },
        );

        if (!deviceValidation.isValid) {
          if (kDebugMode) {
            print(
                'DEBUG: ❌ Device validation failed during auth state change: ${deviceValidation.reason}');
            print('DEBUG: 🔒 Enforcing one-user-per-device policy');
          }
          await FirebaseAuth.instance.signOut();
          state = state.copyWith(
            user: null,
            isAuthenticated: false,
            error: deviceValidation.reason,
          );
          return;
        }

        // Handle device binding if needed
        if (deviceValidation.action == DeviceValidationAction.bindDevice) {
          try {
            await DeviceAuthService.bindDeviceToUser(firebaseUser.uid)
                .timeout(const Duration(seconds: 12));
            if (kDebugMode) {
              print('DEBUG: ✅ Device bound to user during auth state change');
            }
          } catch (e) {
            if (kDebugMode) {
              print(
                  'DEBUG: ❌ Failed to bind device during auth state change: $e');
            }
            // CRITICAL: Device binding failure blocks authentication
            await FirebaseAuth.instance.signOut();
            state = state.copyWith(
              user: null,
              isAuthenticated: false,
              error:
                  'Device registration failed. Please restart the app and try again.',
            );
            return;
          }
        }

        if (kDebugMode) {
          print('DEBUG: ✅ Device validation passed during auth state change');
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              'DEBUG: ❌ Device validation error during auth state change: $e');
          print(
              'DEBUG: 🔒 Blocking authentication due to device validation failure');
        }
        // STRICT ENFORCEMENT: Sign out on any device validation error
        await FirebaseAuth.instance.signOut();
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          error: 'Device validation failed. Please restart the app.',
        );
        return;
      }

      // Check session validity with timeout
      try {
        final isSessionValid =
            await DeviceAuthService.isSessionValid(firebaseUser.uid)
                .timeout(const Duration(seconds: 5));
        if (!isSessionValid) {
          await FirebaseAuth.instance.signOut();
          state = state.copyWith(
            user: null,
            isAuthenticated: false,
            error: 'Your session has been invalidated for security reasons.',
          );
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              'DEBUG: ⚠️ Session validation failed during auth state change: $e');
          print('DEBUG: ⚠️ Continuing with basic authentication');
        }
      }

      // Load user data with timeout
      try {
        final userData =
            await FirebaseEmailAuthService.getUserData(firebaseUser.uid)
                .timeout(const Duration(seconds: 8));

        final emailUser = userData != null
            ? EmailUser.fromFirebaseUser(firebaseUser, userData)
            : EmailUser.fromFirebaseUser(firebaseUser, {});

        state = state.copyWith(
          user: emailUser,
          isAuthenticated: true,
          error: null,
        );

        if (kDebugMode) {
          print('DEBUG: ✅ User data loaded successfully: ${firebaseUser.uid}');
          print(
              'DEBUG: 🔒 Device validation enforced during auth state change');
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              'DEBUG: ⚠️ Failed to load user data during auth state change: $e');
          print('DEBUG: ⚠️ Creating basic user profile');
        }

        // Create basic user profile if Firestore data loading fails
        final emailUser = EmailUser.fromFirebaseUser(firebaseUser, {});
        state = state.copyWith(
          user: emailUser,
          isAuthenticated: true,
          error: null,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Failed to load user data: $e');
        print('DEBUG: ⚠️ Continuing without full user data due to error');
      }
      // Don't sign out users on auth state change errors, just log the issue
      // This prevents infinite loading states
    }
  }

  /// Register new user with email and password
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    state = state.copyWith(isRegistering: true, isLoading: true, error: null);

    try {
      if (kDebugMode) {
        print('DEBUG: 📧 Starting registration for: $email');
      }

      final result = await FirebaseEmailAuthService.registerUser(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        officeName: officeName,
        designation: designation,
      );

      if (result['success'] == true) {
        // Don't authenticate user immediately after registration
        // User must verify email first before being able to login
        state = state.copyWith(
          user: null, // Don't set user until email is verified
          isAuthenticated: false, // Keep as false until email verification
          isRegistering: false,
          isLoading: false,
          error: null,
        );

        if (kDebugMode) {
          print('DEBUG: ✅ Registration successful: ${result['uid']}');
          print('DEBUG: 📧 Email verification required before login');
        }

        // User is already signed out by the Firebase service after registration
        return true;
      } else {
        // Handle registration failure
        final errorMessage =
            result['message'] ?? result['error'] ?? 'Registration failed';

        if (kDebugMode) {
          print('DEBUG: ❌ Registration failed: $errorMessage');
        }

        state = state.copyWith(
          isRegistering: false,
          isLoading: false,
          error: errorMessage,
        );
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Registration failed: $e');
      }
      state = state.copyWith(
        isRegistering: false,
        isLoading: false,
        error: e.toString(),
      );
    }

    return false;
  }

  /// Sign in user with email and password
  /// Fixed with timeout handling and fallback mechanisms to prevent loading state issues
  Future<bool> signInUser({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoggingIn: true, isLoading: true, error: null);

    try {
      if (kDebugMode) {
        print('DEBUG: 🔐 Starting login for: $email');
      }

      final result = await FirebaseEmailAuthService.signInUser(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        if (kDebugMode) {
          print('DEBUG: 📝 Sign-in result received: ${result.keys}');
          print(
              'DEBUG: 📝 Email confirmed in result: ${result['emailConfirmed']}');
        }

        // Get the current user from Firebase after successful sign-in
        final user = FirebaseAuth.instance.currentUser;
        if (kDebugMode) {
          print(
              'DEBUG: 📝 Current user from Firebase: ${user != null ? 'not null' : 'null'}');
          if (user != null) {
            print('DEBUG: 📝 User ID: ${user.uid}');
            print('DEBUG: 📝 Email verified: ${user.emailVerified}');
          }
        }

        if (user != null) {
          // SYNC: If Firebase Auth shows email verified, sync to Firestore
          // This fixes the issue where Firestore emailVerified field is out of sync
          if (user.emailVerified) {
            if (kDebugMode) {
              print(
                  'DEBUG: 🔄 Email verified in Firebase Auth during login, syncing to Firestore...');
            }
            await FirebaseEmailAuthService.syncEmailVerificationStatus(
              user.uid,
            );
          }

          // Check if email is verified (bypass for demo account)
          if (!user.emailVerified &&
              !DemoAccountService.shouldBypassEmailVerification(user.email)) {
            state = state.copyWith(
              isLoggingIn: false,
              isLoading: false,
              error:
                  'Please verify your email address before logging in. Check your inbox for the verification link.',
            );
            return false;
          }

          // STRICT device validation - ENFORCE one user per device policy
          try {
            if (kDebugMode) {
              print('DEBUG: 🔍 Starting STRICT device validation...');
            }

            // Add timeout to device validation but don't allow bypass for security
            final deviceValidation =
                await DeviceAuthService.validateDeviceForUser(user.uid).timeout(
              const Duration(seconds: 30), // Optimized timeout for reliability
              onTimeout: () {
                if (kDebugMode) {
                  print(
                      'DEBUG: ⏰ Device validation timed out - blocking login for security');
                }
                return const DeviceValidationResult(
                  isValid: false,
                  reason:
                      'Device validation is taking longer than expected. Please ensure you have a stable internet connection and try again.',
                  action: DeviceValidationAction.signOut,
                );
              },
            );

            if (!deviceValidation.isValid) {
              if (kDebugMode) {
                print(
                    'DEBUG: ❌ Device validation failed: ${deviceValidation.reason}');
                print('DEBUG: 🔒 Enforcing one-user-per-device policy');
              }

              // STRICT ENFORCEMENT: Block login for any device validation failure
              await FirebaseAuth.instance.signOut();
              state = state.copyWith(
                isLoggingIn: false,
                isLoading: false,
                error: deviceValidation.reason,
              );
              return false;
            }

            // Handle device binding if needed (for new users)
            if (deviceValidation.action == DeviceValidationAction.bindDevice) {
              try {
                if (kDebugMode) {
                  print('DEBUG: 🔗 Binding device for new user...');
                }
                await DeviceAuthService.bindDeviceToUser(user.uid).timeout(
                  const Duration(seconds: 15),
                  onTimeout: () {
                    throw Exception(
                        'Device binding timed out. Please try again.');
                  },
                );
                if (kDebugMode) {
                  print('DEBUG: ✅ Device bound to user successfully');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('DEBUG: ❌ Failed to bind device: $e');
                }
                // CRITICAL: Device binding failure blocks login for security
                await FirebaseAuth.instance.signOut();
                state = state.copyWith(
                  isLoggingIn: false,
                  isLoading: false,
                  error:
                      'Device registration failed. Please ensure you have a stable connection and try again.',
                );
                return false;
              }
            }

            if (kDebugMode) {
              print(
                  'DEBUG: ✅ Device validation passed - user authorized for this device');
            }
          } catch (e) {
            if (kDebugMode) {
              print('DEBUG: ❌ Device validation error: $e');
              print(
                  'DEBUG: 🔒 Blocking login due to device validation failure');
            }
            // STRICT ENFORCEMENT: No fallback for device validation errors
            await FirebaseAuth.instance.signOut();
            state = state.copyWith(
              isLoggingIn: false,
              isLoading: false,
              error:
                  'Device validation failed. Please ensure you have a stable connection and try again.',
            );
            return false;
          }

          // Check session validity with timeout
          try {
            final isSessionValid =
                await DeviceAuthService.isSessionValid(user.uid)
                    .timeout(const Duration(seconds: 5));
            if (!isSessionValid) {
              await FirebaseAuth.instance.signOut();
              state = state.copyWith(
                isLoggingIn: false,
                isLoading: false,
                error: 'Your session has been invalidated. Please login again.',
              );
              return false;
            }
          } catch (e) {
            if (kDebugMode) {
              print('DEBUG: ⚠️ Session validation failed: $e');
              print('DEBUG: ⚠️ Proceeding with login (fallback mode)');
            }
            // Continue with login even if session validation fails
          }

          // Load user data from Firestore with timeout
          try {
            final userData =
                await FirebaseEmailAuthService.getUserData(user.uid)
                    .timeout(const Duration(seconds: 10));

            final emailUser = userData != null
                ? EmailUser.fromFirebaseUser(user, userData)
                : EmailUser.fromFirebaseUser(user, {});

            state = state.copyWith(
              user: emailUser,
              isAuthenticated: true,
              isLoggingIn: false,
              isLoading: false,
              error: null,
            );

            if (kDebugMode) {
              print('DEBUG: ✅ Login successful: ${user.uid}');
              print(
                  'DEBUG: 🔒 Device validation enforced - one user per device policy active');
            }
            return true;
          } catch (e) {
            if (kDebugMode) {
              print('DEBUG: ⚠️ Failed to load user data: $e');
              print('DEBUG: ⚠️ Creating basic user profile');
            }

            // Create basic user profile if Firestore data loading fails
            final emailUser = EmailUser.fromFirebaseUser(user, {});
            state = state.copyWith(
              user: emailUser,
              isAuthenticated: true,
              isLoggingIn: false,
              isLoading: false,
              error: null,
            );

            if (kDebugMode) {
              print(
                  'DEBUG: ✅ Login successful with basic user data: ${user.uid}');
            }
            return true;
          }
        } else {
          // User is null despite successful sign-in
          if (kDebugMode) {
            print('DEBUG: ❌ User is null despite successful sign-in');
          }
          state = state.copyWith(
            isLoggingIn: false,
            isLoading: false,
            error: 'Login failed: User data not available',
          );
          return false;
        }
      } else {
        // Handle sign-in error
        if (kDebugMode) {
          print('DEBUG: ❌ Sign-in failed');
          print('DEBUG: 📝 Error code: ${result['error']}');
          print('DEBUG: 📝 Error message: ${result['message']}');
        }

        state = state.copyWith(
          isLoggingIn: false,
          isLoading: false,
          error: result['message'] ?? result['error'] ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Login failed: $e');
      }
      state = state.copyWith(
        isLoggingIn: false,
        isLoading: false,
        error: 'Login failed. Please check your connection and try again.',
      );
    }

    return false;
  }

  /// Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    try {
      final result = await FirebaseEmailAuthService.sendPasswordReset(email);
      if (result['success'] == true) {
        return true;
      } else {
        state = state.copyWith(
            error: result['message'] ?? 'Failed to send password reset email');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await FirebaseEmailAuthService.signOut();

      // Clear stored credentials on sign out
      await CredentialStorageService.clearStoredCredentials();

      // Clear phone auth from SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authPhoneKey);
        if (kDebugMode) {
          print('DEBUG: ✅ Phone auth cleared from SharedPreferences');
        }
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Error clearing phone auth: $e');
        }
      }

      state = const EmailAuthState();
      if (kDebugMode) {
        print('DEBUG: ✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Sign out failed: $e');
      }
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated && state.user != null;

  /// Get current user
  EmailUser? get currentUser => state.user;
}

/// Email Auth Provider
final emailAuthProvider =
    StateNotifierProvider<EmailAuthNotifier, EmailAuthState>((ref) {
  return EmailAuthNotifier();
});
