import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore Test Service
/// Simple service to test Firestore connectivity and permissions
class FirestoreTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test basic Firestore connectivity
  static Future<Map<String, dynamic>> testFirestoreConnection() async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🧪 Testing Firestore connection...');
      }

      // Test 1: Try to write a simple test document
      final testData = {
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firestore connection test',
      };

      final docRef = _firestore.collection('test').doc('connection_test');
      await docRef.set(testData);

      if (kDebugMode) {
        print('DEBUG: ✅ Test document written successfully');
      }

      // Test 2: Try to read the document back
      final doc = await docRef.get();
      if (doc.exists) {
        if (kDebugMode) {
          print('DEBUG: ✅ Test document read successfully');
          print('DEBUG: 📄 Document data: ${doc.data()}');
        }
      } else {
        if (kDebugMode) {
          print('DEBUG: ⚠️ Test document not found after write');
        }
      }

      // Test 3: Try to delete the test document
      await docRef.delete();
      if (kDebugMode) {
        print('DEBUG: ✅ Test document deleted successfully');
      }

      return {
        'success': true,
        'message': 'Firestore connection test passed',
      };

    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Firestore connection test failed: $e');
        print('DEBUG: ❌ Error type: ${e.runtimeType}');
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': 'Firestore connection test failed',
      };
    }
  }

  /// Test mobile_users collection specifically
  static Future<Map<String, dynamic>> testMobileUsersCollection() async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🧪 Testing mobile_users collection...');
      }

      // Test writing to mobile_users collection
      final testUserData = {
        'uid': 'test_user_123',
        'email': 'test@example.com',
        'name': 'Test User',
        'phoneNumber': '+1234567890',
        'officeName': 'Test Office',
        'designation': 'Test',
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

      final docRef = _firestore.collection('mobile_users').doc('test_user_123');
      await docRef.set(testUserData);

      if (kDebugMode) {
        print('DEBUG: ✅ Test user document written to mobile_users collection');
      }

      // Read it back
      final doc = await docRef.get();
      if (doc.exists) {
        if (kDebugMode) {
          print('DEBUG: ✅ Test user document read successfully');
        }
      }

      // Clean up
      await docRef.delete();
      if (kDebugMode) {
        print('DEBUG: ✅ Test user document deleted');
      }

      return {
        'success': true,
        'message': 'mobile_users collection test passed',
      };

    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ mobile_users collection test failed: $e');
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': 'mobile_users collection test failed',
      };
    }
  }

  /// Check Firestore security rules
  static Future<Map<String, dynamic>> checkFirestoreRules() async {
    try {
      if (kDebugMode) {
        print('DEBUG: 🧪 Checking Firestore security rules...');
      }

      // Try to read from a collection without authentication
      final querySnapshot = await _firestore
          .collection('mobile_users')
          .limit(1)
          .get();

      if (kDebugMode) {
        print('DEBUG: ✅ Firestore query executed successfully');
        print('DEBUG: 📊 Documents found: ${querySnapshot.docs.length}');
      }

      return {
        'success': true,
        'message': 'Firestore rules allow access',
        'documentsFound': querySnapshot.docs.length,
      };

    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Firestore rules check failed: $e');
      }

      // Check if it's a permission error
      if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
        return {
          'success': false,
          'error': 'permission_denied',
          'message': 'Firestore security rules are blocking access. You may need to update the rules.',
        };
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': 'Firestore rules check failed',
      };
    }
  }

  /// Run all Firestore tests
  static Future<Map<String, dynamic>> runAllTests() async {
    if (kDebugMode) {
      print('DEBUG: 🧪 Running all Firestore tests...');
    }

    final results = <String, dynamic>{};

    // Test 1: Basic connection
    results['connection'] = await testFirestoreConnection();

    // Test 2: Mobile users collection
    results['mobile_users'] = await testMobileUsersCollection();

    // Test 3: Security rules
    results['rules'] = await checkFirestoreRules();

    // Overall result
    final allPassed = results.values.every((result) => result['success'] == true);

    if (kDebugMode) {
      print('DEBUG: 🧪 All tests completed. Overall success: $allPassed');
    }

    return {
      'success': allPassed,
      'results': results,
      'message': allPassed ? 'All Firestore tests passed' : 'Some Firestore tests failed',
    };
  }
}
