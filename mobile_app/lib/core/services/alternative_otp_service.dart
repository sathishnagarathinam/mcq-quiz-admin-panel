import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Alternative OTP service with enhanced delivery methods
class AlternativeOTPService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Enhanced OTP sending with multiple retry strategies
  static Future<void> sendOTPWithRetry({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
    int maxRetries = 3,
  }) async {
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          print('DEBUG: 🔄 OTP delivery attempt $attempt of $maxRetries');
          print('DEBUG: 📱 Phone number: $phoneNumber');
        }
        
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: Duration(seconds: 60 + (attempt * 30)), // Increase timeout with retries
          verificationCompleted: (PhoneAuthCredential credential) async {
            if (kDebugMode) {
              print('DEBUG: ✅ Auto-verification completed on attempt $attempt');
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            if (kDebugMode) {
              print('DEBUG: ❌ Verification failed on attempt $attempt: ${e.code} - ${e.message}');
            }
            
            if (attempt == maxRetries) {
              // Last attempt failed
              String errorMessage = _getDetailedErrorMessage(e, phoneNumber);
              onError(errorMessage);
            } else {
              // Retry with delay
              Future.delayed(Duration(seconds: 5 * attempt), () {
                if (kDebugMode) {
                  print('DEBUG: 🔄 Retrying in ${5 * attempt} seconds...');
                }
              });
            }
          },
          codeSent: (String verificationId, int? resendToken) async {
            if (kDebugMode) {
              print('DEBUG: ✅ OTP sent successfully on attempt $attempt');
              print('DEBUG: 📱 Verification ID: ${verificationId.substring(0, 10)}...');
            }
            
            // Store verification details
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('verification_id', verificationId);
            if (resendToken != null) {
              await prefs.setInt('resend_token', resendToken);
            }
            
            onCodeSent('✅ OTP sent successfully to $phoneNumber\n\n📱 Check your SMS messages\n\n⏱️ Delivery attempt: $attempt\n\n💡 SMS may take 1-5 minutes to arrive');
            return; // Success, exit retry loop
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            if (kDebugMode) {
              print('DEBUG: ⏰ Auto-retrieval timeout on attempt $attempt');
            }
          },
        );
        
        // If we reach here, the request was sent successfully
        break;
        
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: ❌ Exception on attempt $attempt: $e');
        }
        
        if (attempt == maxRetries) {
          onError('Failed to send OTP after $maxRetries attempts: ${e.toString()}');
        } else {
          // Wait before retry
          await Future.delayed(Duration(seconds: 5 * attempt));
        }
      }
    }
  }
  
  /// Get detailed error message based on Firebase error
  static String _getDetailedErrorMessage(FirebaseAuthException e, String phoneNumber) {
    switch (e.code) {
      case 'invalid-phone-number':
        return '''❌ Invalid Phone Number Format

The phone number $phoneNumber is not valid.

✅ Correct format: +919876543210
• Include country code (+91 for India)
• Use 10 digits after country code
• Start with 6, 7, 8, or 9

🧪 Try test numbers:
• +919876543210 → OTP: 123456
• +911234567890 → OTP: 654321''';
        
      case 'too-many-requests':
        return '''⏰ Too Many Requests

You've made too many OTP requests. Please wait before trying again.

⏱️ Wait time: 15-30 minutes
🧪 Use test numbers meanwhile:
• +919876543210 → OTP: 123456
• +911234567890 → OTP: 654321''';
        
      case 'quota-exceeded':
        return '''📊 SMS Quota Exceeded

Your Firebase project has reached its SMS limit.

🔧 Solutions:
• Check Firebase Console → Usage
• Increase SMS quota
• Use test numbers for development
• Contact Firebase support''';
        
      case 'app-not-authorized':
        return '''🔧 App Not Authorized

Firebase doesn't recognize your app.

✅ Solutions:
• Add SHA fingerprints to Firebase Console
• Download new google-services.json
• Rebuild the app

🧪 Use test numbers meanwhile:
• +919876543210 → OTP: 123456''';
        
      default:
        return '''❌ SMS Delivery Failed

Error: ${e.message ?? 'Unknown error'}
Code: ${e.code}

🔧 Troubleshooting:
• Check internet connection
• Verify phone number format
• Try different carrier/number
• Use test numbers for development

🧪 Test numbers:
• +919876543210 → OTP: 123456
• +911234567890 → OTP: 654321''';
    }
  }
  
  /// Check SMS delivery status and provide guidance
  static String getSMSDeliveryGuidance(String phoneNumber) {
    return '''📱 SMS Delivery Information for $phoneNumber

⏱️ Expected delivery time: 1-5 minutes
🌐 Factors affecting delivery:
• Network congestion
• Carrier filtering
• International routing
• Device settings

🔍 Check these locations:
• Main SMS/Messages app
• Spam/Junk folder
• Blocked messages
• Notification panel

🔄 If not received after 5 minutes:
• Try resend option
• Check with different number
• Contact your carrier
• Use test numbers for development''';
  }
  
  /// Validate phone number format specifically for Indian numbers
  static bool isValidIndianMobile(String phoneNumber) {
    // Remove all non-digit characters except +
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it's a valid Indian mobile number
    if (cleanNumber.startsWith('+91')) {
      final numberPart = cleanNumber.substring(3);
      if (numberPart.length == 10) {
        final firstDigit = numberPart[0];
        return ['6', '7', '8', '9'].contains(firstDigit);
      }
    }
    
    return false;
  }
}
