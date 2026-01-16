import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_auth_service.dart';
import '../services/device_auth_service.dart';

// Auth state class with error handling
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final User? user;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.user,
  });

  static const initial = AuthState();
  static const loading = AuthState(isLoading: true);
  static const unauthenticated = AuthState(isAuthenticated: false);

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      user: user ?? this.user,
    );
  }
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  // final FirebaseAuthService _authService; // Unused for now
  String? _verificationId;

  AuthNotifier(FirebaseAuthService authService) : super(AuthState.initial) {
    _init();
  }

  User? get currentUser => state.user;

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
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
        state = AuthState.unauthenticated;
      }
    });
  }

  Future<bool> sendOTP(String phoneNumber) async {
    state = AuthState.loading;
    try {
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
      state = AuthState.unauthenticated;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> registerWithPhone(
      String phoneNumber, Map<String, dynamic> userData) async {
    return await sendOTP(phoneNumber);
  }

  Future<bool> verifyRegistrationOTP(
      String otp, Map<String, dynamic> userData) async {
    final success = await verifyOTP(otp);
    if (success) {
      // Save user data to Firestore after successful verification
      // TODO: Implement user data saving
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
