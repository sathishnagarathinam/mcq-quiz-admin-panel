import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

/// PhonePe Standard Checkout v2 SDK Configuration
/// Uses OAuth-based authentication (Client ID + Client Secret)
///
/// IMPORTANT: For Standard Checkout v2, there are TWO different IDs:
/// - Merchant ID (MID): Used for SDK initialization
/// - Client ID: Used for backend OAuth API calls
class PhonePeSdkConfig {
  // Toggle between production and sandbox mode
  // Set to true for production credentials
  static const bool useProductionMode = true; // PRODUCTION MODE ENABLED

  // Production credentials (Standard Checkout v2)
  // Merchant ID is used for SDK initialization
  static const String _prodMerchantId = 'M23KW70E4WTCU';
  // Client ID is used for backend OAuth API calls
  static const String _prodClientId = 'SU2511201301021610273145';
  static const String _prodClientSecret =
      'c04e5e52-0afa-4b59-92b4-da8df20cfc86';
  static const int _prodClientVersion = 1;

  // Sandbox/Test credentials
  static const String _sandboxMerchantId = 'PGTESTPAYUAT86';
  static const String _sandboxClientId = 'PGTESTPAYUAT';
  static const String _sandboxClientSecret =
      '099eb0cd-02cf-4e2a-8aca-3e6c6aff0399';
  static const int _sandboxClientVersion = 1;

  // Active credentials based on mode
  // Merchant ID for SDK initialization
  static String get merchantId =>
      useProductionMode ? _prodMerchantId : _sandboxMerchantId;
  // Client ID for backend OAuth
  static String get clientId =>
      useProductionMode ? _prodClientId : _sandboxClientId;
  static String get clientSecret =>
      useProductionMode ? _prodClientSecret : _sandboxClientSecret;
  static int get clientVersion =>
      useProductionMode ? _prodClientVersion : _sandboxClientVersion;

  // Environment: PRODUCTION or SANDBOX
  static String get environment => useProductionMode ? 'PRODUCTION' : 'SANDBOX';

  // App ID / Flow ID for SDK initialization
  // Per PhonePe: FlowID must be alphanumeric, at least 8 characters
  // This is a static app identifier used during SDK init
  static const String appId = 'MCQQUIZ01';

  // Enable logging for debugging
  static const bool enableLogging = true;

  /// Generate a unique Flow ID for each transaction
  /// Per PhonePe requirements: alphanumeric, at least 8 characters, unique per transaction
  static String generateFlowId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart =
        List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    return 'MCQ${timestamp.substring(timestamp.length - 6)}$randomPart';
  }

  // App schema for deep linking (used by PhonePe SDK to return to app)
  // This should match the URL scheme defined in AndroidManifest.xml and Info.plist
  static const String appSchema = 'mcqquizapp';
}

/// Service for handling PhonePe SDK-based payments (Standard Checkout v2)
/// For Standard Checkout v2, the backend creates the order token,
/// and the SDK uses that token to process payment.
class PhonePeSdkService {
  static bool _isInitialized = false;

  /// Initialize the PhonePe SDK
  /// Parameters: init(environment, merchantId, appId/flowId, enableLogs)
  static Future<bool> initializeSDK() async {
    if (_isInitialized) {
      developer.log('📱 PhonePe SDK already initialized');
      return true;
    }

    try {
      developer.log('📱 Initializing PhonePe SDK (Standard Checkout v2)...');
      developer.log('📱 Environment: ${PhonePeSdkConfig.environment}');
      developer.log('📱 Merchant ID: ${PhonePeSdkConfig.merchantId}');
      developer.log('📱 App ID: ${PhonePeSdkConfig.appId}');

      // PhonePePaymentSdk.init(environment, merchantId, appId/flowId, enableLogs)
      // Note: merchantId (M23KW70E4WTCU) is different from clientId (for OAuth)
      final result = await PhonePePaymentSdk.init(
        PhonePeSdkConfig.environment, // "PRODUCTION" or "SANDBOX"
        PhonePeSdkConfig.merchantId, // Merchant ID (M23KW70E4WTCU)
        PhonePeSdkConfig.appId, // App ID / Flow ID (can be empty)
        PhonePeSdkConfig.enableLogging, // Enable logging for debugging
      );

      _isInitialized = result;
      developer.log('✅ PhonePe SDK initialized: $_isInitialized');
      return _isInitialized;
    } catch (e, stackTrace) {
      developer.log('❌ Failed to initialize PhonePe SDK: $e');
      developer.log('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Start payment using PhonePe SDK with Order Token (Standard Checkout v2)
  /// The orderToken and orderId are obtained from the backend after creating an order
  /// Returns a map with 'success', 'message', and optionally 'orderId'
  ///
  /// Per PhonePe documentation, startTransaction expects a JSON string with:
  /// - orderId: PhonePe's order ID from Create Order API
  /// - merchantId: Merchant ID
  /// - token: Order token from Create Order API
  /// - paymentMode.type: "PAY_PAGE" for Standard Checkout
  ///
  /// IMPORTANT: This method includes a SHORT timeout to quickly detect
  /// if PhonePe app is not installed and fallback to web checkout.
  static Future<Map<String, dynamic>> startPaymentWithToken({
    required String orderToken,
    required String phonePeOrderId, // PhonePe's order ID (not merchantOrderId)
    required String merchantOrderId, // Our order ID for tracking
    String? callbackUrl, // Not used for SDK - kept for backward compatibility
  }) async {
    try {
      // Ensure SDK is initialized with SHORT timeout (3 seconds)
      if (!_isInitialized) {
        developer.log('📱 SDK not initialized, attempting initialization...');
        final initialized = await initializeSDK().timeout(
          const Duration(seconds: 3), // Reduced from 10 to 3 seconds
          onTimeout: () {
            developer.log('❌ SDK initialization timed out after 3 seconds');
            return false;
          },
        );
        if (!initialized) {
          developer.log('❌ SDK initialization failed, need fallback');
          return {
            'success': false,
            'message': 'PhonePe SDK not available - use web checkout',
            'needsFallback': true,
          };
        }
      }

      // Check if PhonePe app is installed BEFORE attempting transaction
      // Using getUpiAppsForAndroid() to check for installed UPI apps including PhonePe
      developer.log('🔍 Checking for installed UPI apps...');
      try {
        final upiAppsJson =
            await PhonePePaymentSdk.getUpiAppsForAndroid().timeout(
          const Duration(seconds: 2), // Quick 2-second timeout
          onTimeout: () => null,
        );

        if (upiAppsJson != null) {
          developer.log('📱 UPI Apps found: $upiAppsJson');
          // Check if PhonePe is in the list
          final hasPhonePe = upiAppsJson.toLowerCase().contains('phonepe') ||
              upiAppsJson.toLowerCase().contains('com.phonepe');
          developer.log('📱 PhonePe app installed: $hasPhonePe');

          if (!hasPhonePe) {
            developer
                .log('⚠️ PhonePe app not installed - fallback to web checkout');
            return {
              'success': false,
              'message': 'PhonePe app not installed - use web checkout',
              'needsFallback': true,
            };
          }
        } else {
          // If we can't get the list, still try to proceed (iOS or error)
          developer.log('⚠️ Could not get UPI apps list - will try SDK anyway');
        }
      } catch (e) {
        // If checking fails, still try to proceed with SDK
        developer.log('⚠️ Error checking UPI apps: $e - will try SDK anyway');
      }

      developer
          .log('💳 Starting PhonePe SDK payment (Standard Checkout v2)...');
      developer.log('   PhonePe Order ID: $phonePeOrderId');
      developer.log('   Merchant Order ID: $merchantOrderId');
      developer.log('   Merchant ID: ${PhonePeSdkConfig.merchantId}');
      developer.log('   App Schema: ${PhonePeSdkConfig.appSchema}');

      // Construct the JSON payload as per PhonePe documentation
      final Map<String, dynamic> payload = {
        'orderId': phonePeOrderId, // PhonePe's order ID
        'merchantId': PhonePeSdkConfig.merchantId, // Merchant ID
        'token': orderToken, // Order token from Create Order API
        'paymentMode': {'type': 'PAY_PAGE'}, // Standard Checkout
      };

      // Convert to JSON string as required by SDK
      final String requestBody = jsonEncode(payload);
      developer.log('📤 SDK Request Payload: $requestBody');

      // CRITICAL: Use SHORT timeout (5 seconds) to quickly fallback if SDK hangs
      developer.log('🚀 Calling PhonePePaymentSdk.startTransaction...');

      final response = await PhonePePaymentSdk.startTransaction(
        requestBody, // JSON string payload
        PhonePeSdkConfig.appSchema, // App's deep link scheme
      ).timeout(
        const Duration(seconds: 5), // Reduced from 30 to 5 seconds
        onTimeout: () {
          developer.log('⏱️ SDK startTransaction timed out after 5 seconds');
          // Return null to trigger fallback
          return null;
        },
      );

      developer.log('📥 SDK Response: $response');

      // Handle null response (timeout or SDK issue)
      if (response == null) {
        developer
            .log('⚠️ SDK returned null - PhonePe app may not be installed');
        return {
          'success': false,
          'message': 'PhonePe app not available - use web checkout',
          'needsFallback': true,
        };
      }

      // Parse response
      final status = response['status'];
      developer.log('📊 SDK Status: $status');

      if (status == 'SUCCESS') {
        return {
          'success': true,
          'message': 'Payment successful',
          'orderId': merchantOrderId,
        };
      } else if (status == 'FAILURE') {
        final errorMsg = response['error'] ?? 'Payment failed';
        developer.log('❌ SDK Payment failed: $errorMsg');

        // Check if failure is due to app not installed
        final errorLower = errorMsg.toString().toLowerCase();
        if (errorLower.contains('not installed') ||
            errorLower.contains('app not found') ||
            errorLower.contains('no activity')) {
          return {
            'success': false,
            'message': 'PhonePe app not installed - use web checkout',
            'needsFallback': true,
          };
        }

        return {
          'success': false,
          'message': errorMsg,
        };
      } else {
        // PENDING or other status - need to verify with backend
        return {
          'success': false,
          'message': 'Payment pending verification',
          'pending': true,
          'orderId': merchantOrderId,
        };
      }
    } catch (e) {
      developer.log('❌ PhonePe SDK error: $e');

      // Check if error indicates app not installed
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('not installed') ||
          errorStr.contains('activity not found') ||
          errorStr.contains('no activity') ||
          errorStr.contains('unable to resolve')) {
        return {
          'success': false,
          'message': 'PhonePe app not available - use web checkout',
          'needsFallback': true,
        };
      }

      return {
        'success': false,
        'message': 'Payment error: $e',
        'needsFallback': true, // Default to fallback on any error
      };
    }
  }

  /// Legacy method for backward compatibility
  /// Now delegates to startPaymentWithToken after obtaining token from backend
  static Future<Map<String, dynamic>> startPayment({
    required String merchantTransactionId,
    required double amount,
    required String userId,
    required String userPhone,
    required String callbackUrl,
  }) async {
    developer.log(
        '⚠️ Legacy startPayment called - use startPaymentWithToken for Standard Checkout v2');
    return {
      'success': false,
      'message':
          'Please use startPaymentWithToken with order token from backend',
    };
  }
}
