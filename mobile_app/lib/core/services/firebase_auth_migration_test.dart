import 'package:flutter/foundation.dart';
import 'firebase_email_auth_service.dart';

/// Test class to verify Firebase Email Authentication migration
class FirebaseAuthMigrationTest {
  /// Test Firebase connectivity and basic functionality
  static Future<Map<String, dynamic>> runMigrationTests() async {
    if (kDebugMode) {
      print('🧪 Starting Firebase Auth Migration Tests...');
    }

    final results = <String, dynamic>{
      'testsPassed': 0,
      'testsFailed': 0,
      'tests': <Map<String, dynamic>>[],
    };

    // Test 1: Firebase Connectivity
    await _testFirebaseConnectivity(results);

    // Test 2: Email Validation
    await _testEmailValidation(results);

    // Test 3: Password Validation
    await _testPasswordValidation(results);

    // Test 4: Service Methods Exist
    await _testServiceMethods(results);

    final totalTests = results['testsPassed'] + results['testsFailed'];
    final successRate = totalTests > 0 ? (results['testsPassed'] / totalTests * 100).toStringAsFixed(1) : '0.0';

    if (kDebugMode) {
      print('🧪 Migration Tests Complete:');
      print('   ✅ Passed: ${results['testsPassed']}');
      print('   ❌ Failed: ${results['testsFailed']}');
      print('   📊 Success Rate: $successRate%');
    }

    results['successRate'] = successRate;
    return results;
  }

  /// Test Firebase connectivity
  static Future<void> _testFirebaseConnectivity(Map<String, dynamic> results) async {
    try {
      if (kDebugMode) {
        print('🔍 Testing Firebase connectivity...');
      }

      final connectivityResult = await FirebaseEmailAuthService.testFirebaseConnection();
      
      if (connectivityResult['success'] == true) {
        _addTestResult(results, 'Firebase Connectivity', true, 'Firebase is properly initialized');
      } else {
        _addTestResult(results, 'Firebase Connectivity', false, connectivityResult['message'] ?? 'Unknown error');
      }
    } catch (e) {
      _addTestResult(results, 'Firebase Connectivity', false, 'Exception: $e');
    }
  }

  /// Test email validation
  static Future<void> _testEmailValidation(Map<String, dynamic> results) async {
    try {
      if (kDebugMode) {
        print('🔍 Testing email validation...');
      }

      final testCases = [
        {'email': 'test@example.com', 'expected': true},
        {'email': 'user.name+tag@domain.co.uk', 'expected': true},
        {'email': 'invalid-email', 'expected': false},
        {'email': '@domain.com', 'expected': false},
        {'email': 'test@', 'expected': false},
        {'email': '', 'expected': false},
      ];

      bool allPassed = true;
      String errorMessage = '';

      for (final testCase in testCases) {
        final email = testCase['email'] as String;
        final expected = testCase['expected'] as bool;
        final actual = FirebaseEmailAuthService.isValidEmail(email);

        if (actual != expected) {
          allPassed = false;
          errorMessage = 'Email "$email" validation failed. Expected: $expected, Got: $actual';
          break;
        }
      }

      _addTestResult(results, 'Email Validation', allPassed, allPassed ? 'All email validation tests passed' : errorMessage);
    } catch (e) {
      _addTestResult(results, 'Email Validation', false, 'Exception: $e');
    }
  }

  /// Test password validation
  static Future<void> _testPasswordValidation(Map<String, dynamic> results) async {
    try {
      if (kDebugMode) {
        print('🔍 Testing password validation...');
      }

      final testCases = [
        {'password': 'Password123', 'shouldPass': true},
        {'password': 'StrongPass1', 'shouldPass': true},
        {'password': 'weak', 'shouldPass': false}, // Too short
        {'password': 'password123', 'shouldPass': false}, // No uppercase
        {'password': 'PASSWORD123', 'shouldPass': false}, // No lowercase
        {'password': 'Password', 'shouldPass': false}, // No number
      ];

      bool allPassed = true;
      String errorMessage = '';

      for (final testCase in testCases) {
        final password = testCase['password'] as String;
        final shouldPass = testCase['shouldPass'] as bool;
        final validationError = FirebaseEmailAuthService.validatePassword(password);
        final actuallyPassed = validationError == null;

        if (actuallyPassed != shouldPass) {
          allPassed = false;
          errorMessage = 'Password "$password" validation failed. Expected to ${shouldPass ? 'pass' : 'fail'}, but ${actuallyPassed ? 'passed' : 'failed'}';
          break;
        }
      }

      _addTestResult(results, 'Password Validation', allPassed, allPassed ? 'All password validation tests passed' : errorMessage);
    } catch (e) {
      _addTestResult(results, 'Password Validation', false, 'Exception: $e');
    }
  }

  /// Test that all required service methods exist
  static Future<void> _testServiceMethods(Map<String, dynamic> results) async {
    try {
      if (kDebugMode) {
        print('🔍 Testing service methods exist...');
      }

      // Test that methods can be called (they should exist and not throw NoSuchMethodError)
      final methodTests = <String, bool>{};

      // Test static methods exist by checking if they can be referenced
      try {
        // These should not throw NoSuchMethodError
        FirebaseEmailAuthService.isValidEmail;
        methodTests['isValidEmail'] = true;
      } catch (e) {
        methodTests['isValidEmail'] = false;
      }

      try {
        FirebaseEmailAuthService.validatePassword;
        methodTests['validatePassword'] = true;
      } catch (e) {
        methodTests['validatePassword'] = false;
      }

      try {
        FirebaseEmailAuthService.getCurrentUser;
        methodTests['getCurrentUser'] = true;
      } catch (e) {
        methodTests['getCurrentUser'] = false;
      }

      try {
        FirebaseEmailAuthService.testFirebaseConnection;
        methodTests['testFirebaseConnection'] = true;
      } catch (e) {
        methodTests['testFirebaseConnection'] = false;
      }

      final failedMethods = methodTests.entries.where((entry) => !entry.value).map((entry) => entry.key).toList();
      
      if (failedMethods.isEmpty) {
        _addTestResult(results, 'Service Methods', true, 'All required methods exist');
      } else {
        _addTestResult(results, 'Service Methods', false, 'Missing methods: ${failedMethods.join(', ')}');
      }
    } catch (e) {
      _addTestResult(results, 'Service Methods', false, 'Exception: $e');
    }
  }

  /// Add test result to results map
  static void _addTestResult(Map<String, dynamic> results, String testName, bool passed, String message) {
    if (passed) {
      results['testsPassed']++;
    } else {
      results['testsFailed']++;
    }

    results['tests'].add({
      'name': testName,
      'passed': passed,
      'message': message,
    });

    if (kDebugMode) {
      final status = passed ? '✅' : '❌';
      print('   $status $testName: $message');
    }
  }

  /// Run a quick connectivity test
  static Future<bool> quickConnectivityTest() async {
    try {
      final result = await FirebaseEmailAuthService.testFirebaseConnection();
      return result['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Quick connectivity test failed: $e');
      }
      return false;
    }
  }
}
