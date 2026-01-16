import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle Google Play demo account functionality
class DemoAccountService {
  static const String _demoEmail = 'googleplay.demo@dakshinpostalacademy.com';
  static const String _demoPassword = 'GooglePlay2024!';

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if current user is the demo account
  static bool isDemoAccount() {
    final user = _auth.currentUser;
    return user?.email == _demoEmail;
  }

  /// Check if email verification should be bypassed for demo account
  static bool shouldBypassEmailVerification(String? email) {
    return email == _demoEmail;
  }

  /// Get demo account credentials for testing
  static Map<String, String> getDemoCredentials() {
    return {
      'email': _demoEmail,
      'password': _demoPassword,
    };
  }

  /// Verify demo account exists and is properly configured
  static Future<bool> verifyDemoAccount() async {
    try {
      if (kDebugMode) {
        print('🧪 Verifying demo account...');
      }

      // Try to sign in with demo credentials
      final credential = await _auth.signInWithEmailAndPassword(
        email: _demoEmail,
        password: _demoPassword,
      );

      if (credential.user != null) {
        if (kDebugMode) {
          print('✅ Demo account verified successfully');
        }

        // Check if user document exists in Firestore
        final userDoc = await _firestore
            .collection('mobile_users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          if (kDebugMode) {
            print('✅ Demo account Firestore document exists');
          }
          return true;
        } else {
          if (kDebugMode) {
            print('⚠️ Demo account Firestore document missing');
          }
          return false;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Demo account verification failed: $e');
      }
      return false;
    }
  }

  /// Create or update demo account data in Firestore
  static Future<void> ensureDemoAccountData() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email != _demoEmail) {
        return;
      }

      if (kDebugMode) {
        print('🔧 Ensuring demo account data...');
      }

      final demoUserData = {
        'uid': user.uid,
        'email': _demoEmail,
        'name': 'Google Play Reviewer',
        'phoneNumber': '+919876543210',
        'officeName': 'Demo Post Office',
        'designation': 'Inspector',
        'userType': 'mobile_user',
        'role': 'user',
        'isActive': true,
        'emailVerified': true,
        'profileComplete': true,

        // Pre-loaded quiz statistics for demo
        'quizzesTaken': 15,
        'totalScore': 1250,
        'averageScore': 83.3,

        // Enhanced stats for better demo experience
        'stats': {
          'totalQuizzes': 15,
          'totalScore': 1250,
          'averageScore': 83.3,
          'currentStreak': 5,
          'longestStreak': 12,
          'totalTimeSpent': 7200, // 2 hours in seconds
        },

        // User preferences
        'preferences': {
          'notifications': true,
          'darkMode': false,
          'language': 'en',
          'easyMode': false, // Start in expert mode to show all features
        },

        // Device info (demo account bypasses device binding)
        'registeredDeviceId': 'demo_device_bypass',
        'deviceInfo': {'demo': true, 'type': 'demo_account'},
        'isDeviceBound': true,

        // FCM token (will be set when user logs in)
        'fcmToken': null,

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update mobile_users collection
      await _firestore
          .collection('mobile_users')
          .doc(user.uid)
          .set(demoUserData, SetOptions(merge: true));

      // Also update users collection for compatibility
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(demoUserData, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Demo account data updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to ensure demo account data: $e');
      }
    }
  }

  /// Get demo account information for display
  static Map<String, dynamic> getDemoAccountInfo() {
    return {
      'name': 'Google Play Reviewer',
      'email': _demoEmail,
      'phoneNumber': '+919876543210',
      'officeName': 'Demo Post Office',
      'designation': 'Inspector',
      'quizzesTaken': 15,
      'totalScore': 1250,
      'averageScore': 83.3,
      'currentStreak': 5,
      'longestStreak': 12,
      'totalTimeSpent': 7200,
    };
  }

  /// Sign in with demo account (for testing purposes)
  static Future<bool> signInWithDemoAccount() async {
    try {
      if (kDebugMode) {
        print('🧪 Signing in with demo account...');
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: _demoEmail,
        password: _demoPassword,
      );

      if (credential.user != null) {
        // Ensure demo account data is properly set up
        await ensureDemoAccountData();

        if (kDebugMode) {
          print('✅ Demo account sign-in successful');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Demo account sign-in failed: $e');
      }
      return false;
    }
  }

  /// Check if demo account needs setup
  static Future<bool> needsSetup() async {
    try {
      // Try to get user by email
      final methods = await _auth.fetchSignInMethodsForEmail(_demoEmail);
      return methods.isEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not check demo account status: $e');
      }
      return true; // Assume needs setup if we can't check
    }
  }

  /// Display demo account status for debugging
  static Future<void> displayDemoAccountStatus() async {
    if (!kDebugMode) return;

    print('\n🎯 DEMO ACCOUNT STATUS:');
    print('========================');
    print('📧 Email: $_demoEmail');
    print('🔑 Password: $_demoPassword');

    try {
      final needsSetup = await DemoAccountService.needsSetup();
      print('🔧 Needs Setup: ${needsSetup ? "YES" : "NO"}');

      if (!needsSetup) {
        final isVerified = await verifyDemoAccount();
        print('✅ Verified: ${isVerified ? "YES" : "NO"}');
      }

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('👤 Current User: ${currentUser.email}');
        print('🎯 Is Demo Account: ${isDemoAccount()}');
      } else {
        print('👤 Current User: None');
      }
    } catch (e) {
      print('❌ Status Check Error: $e');
    }

    print('========================\n');
  }
}
