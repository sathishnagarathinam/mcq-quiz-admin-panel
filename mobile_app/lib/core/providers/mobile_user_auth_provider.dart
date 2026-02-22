import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fcm_service.dart';
import '../services/device_auth_service.dart';
import '../services/credential_storage_service.dart';

/// Mobile User Model (separate from admin users)
class MobileUser {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final String officeName;
  final String designation;
  final bool emailVerified;
  final bool isActive;
  final int quizzesTaken;
  final int totalScore;
  final double averageScore;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? preferences;

  // Device Security Fields
  final String? registeredDeviceId;
  final Map<String, dynamic>? deviceInfo;
  final DateTime? deviceRegisteredAt;
  final bool isDeviceBound;
  final List<Map<String, dynamic>>? securityEvents;

  const MobileUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.officeName,
    required this.designation,
    required this.emailVerified,
    required this.isActive,
    this.quizzesTaken = 0,
    this.totalScore = 0,
    this.averageScore = 0.0,
    this.createdAt,
    this.lastLoginAt,
    this.preferences,
    // Device Security Fields
    this.registeredDeviceId,
    this.deviceInfo,
    this.deviceRegisteredAt,
    this.isDeviceBound = false,
    this.securityEvents,
  });

  factory MobileUser.fromFirestore(Map<String, dynamic> data) {
    return MobileUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      officeName: data['officeName'] ?? '',
      designation: data['designation'] ?? '',
      emailVerified: data['emailVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      quizzesTaken: data['quizzesTaken'] ?? 0,
      totalScore: data['totalScore'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      createdAt: data['createdAt']?.toDate(),
      lastLoginAt: data['lastLoginAt']?.toDate(),
      preferences: data['preferences'],
      // Device Security Fields
      registeredDeviceId: data['registeredDeviceId'],
      deviceInfo: data['deviceInfo'],
      deviceRegisteredAt: data['deviceRegisteredAt']?.toDate(),
      isDeviceBound: data['isDeviceBound'] ?? false,
      securityEvents: data['securityEvents'] != null
          ? List<Map<String, dynamic>>.from(data['securityEvents'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'officeName': officeName,
      'designation': designation,
      'emailVerified': emailVerified,
      'isActive': isActive,
      'quizzesTaken': quizzesTaken,
      'totalScore': totalScore,
      'averageScore': averageScore,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'preferences': preferences,
      // Device Security Fields
      'registeredDeviceId': registeredDeviceId,
      'deviceInfo': deviceInfo,
      'deviceRegisteredAt': deviceRegisteredAt != null
          ? Timestamp.fromDate(deviceRegisteredAt!)
          : null,
      'isDeviceBound': isDeviceBound,
      'securityEvents': securityEvents,
    };
  }

  MobileUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
    String? officeName,
    String? designation,
    bool? emailVerified,
    bool? isActive,
    int? quizzesTaken,
    int? totalScore,
    double? averageScore,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    // Device Security Fields
    String? registeredDeviceId,
    Map<String, dynamic>? deviceInfo,
    DateTime? deviceRegisteredAt,
    bool? isDeviceBound,
    List<Map<String, dynamic>>? securityEvents,
  }) {
    return MobileUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      officeName: officeName ?? this.officeName,
      designation: designation ?? this.designation,
      emailVerified: emailVerified ?? this.emailVerified,
      isActive: isActive ?? this.isActive,
      quizzesTaken: quizzesTaken ?? this.quizzesTaken,
      totalScore: totalScore ?? this.totalScore,
      averageScore: averageScore ?? this.averageScore,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      // Device Security Fields
      registeredDeviceId: registeredDeviceId ?? this.registeredDeviceId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      deviceRegisteredAt: deviceRegisteredAt ?? this.deviceRegisteredAt,
      isDeviceBound: isDeviceBound ?? this.isDeviceBound,
      securityEvents: securityEvents ?? this.securityEvents,
    );
  }
}

/// Mobile User Authentication State
class MobileUserAuthState {
  final MobileUser? user;
  final bool isLoading;
  final bool isRegistering;
  final bool isLoggingIn;
  final String? error;
  final bool isAuthenticated;

  const MobileUserAuthState({
    this.user,
    this.isLoading = false,
    this.isRegistering = false,
    this.isLoggingIn = false,
    this.error,
    this.isAuthenticated = false,
  });

  MobileUserAuthState copyWith({
    MobileUser? user,
    bool? isLoading,
    bool? isRegistering,
    bool? isLoggingIn,
    String? error,
    bool? isAuthenticated,
  }) {
    return MobileUserAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isRegistering: isRegistering ?? this.isRegistering,
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Firebase Mobile User Authentication Provider
class FirebaseMobileUserAuthNotifier
    extends StateNotifier<MobileUserAuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseMobileUserAuthNotifier() : super(const MobileUserAuthState()) {
    _initializeAuth();
  }

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    await _checkAuthState();
    _listenToAuthChanges();
  }

  /// Check current authentication state
  Future<void> _checkAuthState() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    }
  }

  /// Listen to Firebase Auth state changes
  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        state = const MobileUserAuthState();
      }
    });
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🔄 _loadUserData called for UID: $uid');
      }

      // Try to get user from mobile_users collection
      final mobileUserDoc =
          await _firestore.collection('mobile_users').doc(uid).get();

      if (mobileUserDoc.exists) {
        final userData = mobileUserDoc.data();
        if (userData != null) {
          final mobileUser = MobileUser.fromFirestore(userData);
          if (kDebugMode) {
            print(
                'DEBUG: 📊 MobileUser created - name: ${mobileUser.name}, email: ${mobileUser.email}');
          }
          state = state.copyWith(
            user: mobileUser,
            isAuthenticated: true,
            error: null,
          );
          return;
        }
      }

      // If user document not found, sign out the user
      if (kDebugMode) {
        print('DEBUG: ❌ User document not found, signing out');
      }
      await signOut();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error loading user data: $e');
      }
      state = state.copyWith(error: e.toString());
    }
  }

  /// Register a new user
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    state = state.copyWith(isRegistering: true, error: null);

    try {
      // Create user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Update user profile
        await user.updateDisplayName(name);

        // Create user document in Firestore
        await _firestore.collection('mobile_users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'phoneNumber': phoneNumber,
          'officeName': officeName,
          'designation': designation,
          'emailVerified': user.emailVerified,
          'isActive': true,
          'quizzesTaken': 0,
          'totalScore': 0,
          'averageScore': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'preferences': {},
        });

        // Send email verification
        await user.sendEmailVerification();

        state = state.copyWith(isRegistering: false);
        return true;
      }

      state = state.copyWith(
        isRegistering: false,
        error: 'Registration failed',
      );
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: _getFirebaseErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Sign in user
  Future<bool> signInUser({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoggingIn: true, error: null);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Validate device for this user
        final deviceValidation =
            await DeviceAuthService.validateDeviceForUser(user.uid);

        if (!deviceValidation.isValid) {
          // Device validation failed - sign out and show error
          await _auth.signOut();
          state = state.copyWith(
            isLoggingIn: false,
            error: deviceValidation.reason,
          );
          return false;
        }

        // Handle device binding if needed
        if (deviceValidation.action == DeviceValidationAction.bindDevice) {
          try {
            await DeviceAuthService.bindDeviceToUser(user.uid);
            if (kDebugMode) {
              print('DEBUG: ✅ Device bound to user on first login');
            }
          } catch (e) {
            if (kDebugMode) {
              print('DEBUG: ❌ Failed to bind device: $e');
            }
            // CRITICAL: Do not continue with login if device binding fails
            await _auth.signOut();
            state = state.copyWith(
              isLoggingIn: false,
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
              print('DEBUG: ✅ Device ID migration completed for existing user');
            }
          } catch (e) {
            if (kDebugMode) {
              print('DEBUG: ⚠️ Device ID migration failed (non-critical): $e');
            }
            // Migration failure is non-critical, continue with login
          }
        }

        // Check if session is still valid (not force logged out)
        final isSessionValid = await DeviceAuthService.isSessionValid(user.uid);
        if (!isSessionValid) {
          await _auth.signOut();
          state = state.copyWith(
            isLoggingIn: false,
            error:
                'Your session has been invalidated for security reasons. Please login again.',
          );
          return false;
        }

        // Clear any force logout flags and update last login time
        await DeviceAuthService.clearForceLogoutFlag(user.uid);
        await _firestore.collection('mobile_users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        // Initialize FCM and save token
        try {
          await FCMService.initialize();
          await FCMService.saveTokenToUser(user.uid);
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: ⚠️ Failed to initialize FCM: $e');
          }
        }

        state = state.copyWith(isLoggingIn: false);
        return true;
      }

      state = state.copyWith(
        isLoggingIn: false,
        error: 'Sign in failed',
      );
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoggingIn: false,
        error: _getFirebaseErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoggingIn: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Clear stored credentials on sign out
      await CredentialStorageService.clearStoredCredentials();

      state = const MobileUserAuthState();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Sign out error: $e');
      }
    }
  }

  /// Get Firebase error message
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

/// Mobile User Authentication Provider (Firebase-based)
final mobileUserAuthProvider =
    StateNotifierProvider<FirebaseMobileUserAuthNotifier, MobileUserAuthState>(
        (ref) {
  return FirebaseMobileUserAuthNotifier();
});

/// Current Mobile User Provider
final currentMobileUserProvider = Provider<MobileUser?>((ref) {
  final authState = ref.watch(mobileUserAuthProvider);
  return authState.user;
});
