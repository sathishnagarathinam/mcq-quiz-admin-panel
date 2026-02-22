import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Key for storing authenticated phone number (same as in auth_provider_minimal.dart)
const String _authPhoneKey = 'authenticated_phone_number';

/// Centralized authentication helper service
/// Handles both Firebase Auth users and phone-authenticated users
class AuthHelperService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user is authenticated (either via Firebase Auth or phone auth)
  static Future<bool> isUserAuthenticated() async {
    // Check Firebase Auth first
    if (_auth.currentUser != null) {
      developer.log('AuthHelper: User authenticated via Firebase Auth');
      return true;
    }

    // Check phone auth via SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString(_authPhoneKey);
      if (savedPhone != null && savedPhone.isNotEmpty) {
        developer.log('AuthHelper: User authenticated via phone auth: $savedPhone');
        return true;
      }
    } catch (e) {
      developer.log('AuthHelper: Error checking phone auth: $e');
    }

    developer.log('AuthHelper: User not authenticated');
    return false;
  }

  /// Get the current user ID
  /// Returns Firebase UID for Firebase Auth users, or phone number (without +) for phone auth users
  static Future<String?> getCurrentUserId() async {
    // Check Firebase Auth first
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      developer.log('AuthHelper: Got Firebase user ID: ${firebaseUser.uid}');
      return firebaseUser.uid;
    }

    // Check phone auth via SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString(_authPhoneKey);
      if (savedPhone != null && savedPhone.isNotEmpty) {
        // Return phone number without + as user ID (matches Firestore document ID)
        final userId = savedPhone.replaceAll('+', '');
        developer.log('AuthHelper: Got phone user ID: $userId');
        return userId;
      }
    } catch (e) {
      developer.log('AuthHelper: Error getting phone user ID: $e');
    }

    developer.log('AuthHelper: No user ID found');
    return null;
  }

  /// Get the current user's phone number
  static Future<String?> getCurrentPhoneNumber() async {
    // Check Firebase Auth first
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null && firebaseUser.phoneNumber != null) {
      return firebaseUser.phoneNumber;
    }

    // Check phone auth via SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString(_authPhoneKey);
      if (savedPhone != null && savedPhone.isNotEmpty) {
        return savedPhone;
      }
    } catch (e) {
      developer.log('AuthHelper: Error getting phone number: $e');
    }

    return null;
  }

  /// Get the current user's email
  static Future<String?> getCurrentEmail() async {
    // Check Firebase Auth first
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null && firebaseUser.email != null) {
      return firebaseUser.email;
    }

    // For phone auth users, get email from Firestore
    try {
      final userId = await getCurrentUserId();
      if (userId != null) {
        final doc = await _firestore.collection('mobile_users').doc(userId).get();
        if (doc.exists) {
          return doc.data()?['email'] as String?;
        }
      }
    } catch (e) {
      developer.log('AuthHelper: Error getting email: $e');
    }

    return null;
  }

  /// Get the current user's name
  static Future<String?> getCurrentUserName() async {
    // Check Firebase Auth first
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null && firebaseUser.displayName != null) {
      return firebaseUser.displayName;
    }

    // For phone auth users, get name from Firestore
    try {
      final userId = await getCurrentUserId();
      if (userId != null) {
        final doc = await _firestore.collection('mobile_users').doc(userId).get();
        if (doc.exists) {
          return doc.data()?['name'] as String?;
        }
      }
    } catch (e) {
      developer.log('AuthHelper: Error getting user name: $e');
    }

    return null;
  }

  /// Check if the current user is a phone-authenticated user
  static Future<bool> isPhoneAuthUser() async {
    // If Firebase Auth user exists, not a phone-only user
    if (_auth.currentUser != null) {
      return false;
    }

    // Check phone auth via SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString(_authPhoneKey);
      return savedPhone != null && savedPhone.isNotEmpty;
    } catch (e) {
      developer.log('AuthHelper: Error checking if phone auth user: $e');
    }

    return false;
  }
}

