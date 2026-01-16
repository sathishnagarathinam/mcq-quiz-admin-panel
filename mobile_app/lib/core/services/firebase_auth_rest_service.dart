import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

class FirebaseAuthRestService {
  static const String _baseUrl = 'https://identitytoolkit.googleapis.com/v1';
  static const String _apiKey =
      'AIzaSyDIdFTL8Xl-E02bYB_HnuymfGBRRL6xBqk'; // Firebase API key from config

  // Storage keys for session data
  static const String _sessionInfoKey = 'firebase_session_info';
  static const String _phoneNumberKey = 'firebase_phone_number';
  static const String _registrationDataKey = 'firebase_registration_data';

  // Send OTP to phone number for registration
  static Future<Map<String, dynamic>> sendRegistrationOTP(
      String phoneNumber) async {
    final url =
        Uri.parse('$_baseUrl/accounts:sendVerificationCode?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'recaptchaToken':
            'dummy_token', // For testing, implement reCAPTCHA in production
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      // Store session info for later verification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionInfoKey, result['sessionInfo']);
      await prefs.setString(_phoneNumberKey, phoneNumber);

      return result;
    } else {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  // Send OTP to phone number for login
  static Future<Map<String, dynamic>> sendLoginOTP(String phoneNumber) async {
    final url =
        Uri.parse('$_baseUrl/accounts:sendVerificationCode?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'recaptchaToken':
            'dummy_token', // For testing, implement reCAPTCHA in production
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      // Store session info for later verification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionInfoKey, result['sessionInfo']);
      await prefs.setString(_phoneNumberKey, phoneNumber);

      return result;
    } else {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  // Verify OTP and complete registration
  static Future<Map<String, dynamic>> verifyRegistrationOTP(
    String code, {
    required String name,
    required String email,
    required String officeName,
    required String designation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionInfo = prefs.getString(_sessionInfoKey);
    final phoneNumber = prefs.getString(_phoneNumberKey);

    if (sessionInfo == null || phoneNumber == null) {
      throw Exception('Session expired. Please try again.');
    }

    final url =
        Uri.parse('$_baseUrl/accounts:signInWithPhoneNumber?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionInfo': sessionInfo,
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      // Update user profile with name and email
      await updateUserProfile(result['idToken'], name, email);

      // Store user data in Firestore
      await FirestoreService.createUserDocument(
        uid: result['localId'],
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        officeName: officeName,
        designation: designation,
      );

      // Store registration data locally
      await prefs.setString(
          _registrationDataKey,
          jsonEncode({
            'name': name,
            'email': email,
            'phoneNumber': phoneNumber,
            'officeName': officeName,
            'designation': designation,
            'registrationDate': DateTime.now().toIso8601String(),
          }));

      // Clear session data
      await prefs.remove(_sessionInfoKey);
      await prefs.remove(_phoneNumberKey);

      return result;
    } else {
      throw Exception('Failed to verify OTP: ${response.body}');
    }
  }

  // Verify OTP for login
  static Future<Map<String, dynamic>> verifyLoginOTP(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionInfo = prefs.getString(_sessionInfoKey);

    if (sessionInfo == null) {
      throw Exception('Session expired. Please try again.');
    }

    final url =
        Uri.parse('$_baseUrl/accounts:signInWithPhoneNumber?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionInfo': sessionInfo,
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      // Clear session data
      await prefs.remove(_sessionInfoKey);
      await prefs.remove(_phoneNumberKey);

      return result;
    } else {
      throw Exception('Failed to verify OTP: ${response.body}');
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile(
      String idToken, String name, String email) async {
    final url = Uri.parse('$_baseUrl/accounts:update?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'displayName': name,
        'email': email,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // Get user info
  static Future<Map<String, dynamic>> getUserInfo(String idToken) async {
    final url = Uri.parse('$_baseUrl/accounts:lookup?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user info: ${response.body}');
    }
  }

  // Refresh token
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final url =
        Uri.parse('https://securetoken.googleapis.com/v1/token?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to refresh token: ${response.body}');
    }
  }

  // Sign out (client-side only)
  static Future<void> signOut() async {
    // Clear local storage/preferences
    // This is handled in the auth provider
  }
}
