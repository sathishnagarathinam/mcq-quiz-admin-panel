import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../models/phonepe_models.dart';
import 'phonepe_sdk_service.dart';

class PhonePePaymentService {
  final Dio _dio;
  final String _baseUrl;

  PhonePePaymentService({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  /// Initialize PhonePe SDK (call this early in app lifecycle)
  Future<bool> initializeSDK() async {
    return await PhonePeSdkService.initializeSDK();
  }

  /// Create a payment order with backend and initiate SDK payment
  /// For Standard Checkout v2: Backend creates order token, SDK uses it
  /// Returns the order ID and payment result
  ///
  /// IMPORTANT: This method now properly handles SDK failures and returns
  /// appropriate flags for fallback to web checkout.
  Future<PhonePeSdkPaymentResult> initiateSDKPayment({
    required String userId,
    required String examId,
    required double amount,
    required String userEmail,
    required String userPhone,
  }) async {
    String? merchantOrderId;
    String? paymentUrl;

    try {
      developer.log(
          '🚀 Creating PhonePe order via backend (Standard Checkout v2)...');

      // Step 1: Create order with backend to get order token
      // Add timeout to prevent indefinite waiting
      final orderResponse = await _dio.post(
        '$_baseUrl/payments/create-order',
        data: {
          'userId': userId,
          'examId': examId,
          'amount': amount,
          'userEmail': userEmail,
          'userPhone': userPhone,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (orderResponse.statusCode != 200) {
        throw Exception(
            'Failed to create payment order: ${orderResponse.statusCode}');
      }

      final paymentData = PhonePePaymentResponse.fromJson(orderResponse.data);
      merchantOrderId = paymentData.data?.merchantOrderId ??
          paymentData.data?.merchantTransactionId;
      final orderToken = paymentData.data?.orderToken;
      final phonePeOrderId =
          paymentData.data?.orderId; // PhonePe's order ID for SDK
      paymentUrl =
          paymentData.data?.paymentUrl ?? paymentData.data?.redirectUrl;

      if (merchantOrderId == null) {
        throw Exception('No order ID received from backend');
      }

      developer.log('✅ Order created: $merchantOrderId');
      developer.log('📦 PhonePe Order ID: $phonePeOrderId');
      developer.log('📦 Order token received: ${orderToken != null}');
      developer.log('🌐 Payment URL received: ${paymentUrl != null}');

      // Step 2: Initiate payment using PhonePe SDK with order token
      if (orderToken != null && phonePeOrderId != null) {
        // Standard Checkout v2: Use order token with proper JSON payload
        developer.log('📱 Attempting SDK payment...');
        final sdkResult = await PhonePeSdkService.startPaymentWithToken(
          orderToken: orderToken,
          phonePeOrderId: phonePeOrderId, // PhonePe's order ID for SDK payload
          merchantOrderId: merchantOrderId,
          callbackUrl: '$_baseUrl/payments/webhook',
        );

        // Check if SDK indicated it needs fallback (e.g., PhonePe app not installed)
        if (sdkResult['needsFallback'] == true) {
          developer.log(
              '⚠️ SDK indicated fallback needed, returning with payment URL');
          return PhonePeSdkPaymentResult(
            success: false,
            message: sdkResult['message'] ?? 'SDK not available',
            merchantTransactionId: merchantOrderId,
            isPending: false,
            paymentUrl: paymentUrl, // Return payment URL for fallback
          );
        }

        return PhonePeSdkPaymentResult(
          success: sdkResult['success'] ?? false,
          message: sdkResult['message'] ?? 'Unknown error',
          merchantTransactionId: merchantOrderId,
          isPending: sdkResult['pending'] ?? false,
          paymentUrl: paymentUrl, // Include payment URL in case needed later
        );
      } else {
        // No order token - return payment URL for web-based redirect
        developer.log(
            '⚠️ Missing order token or PhonePe order ID, using web redirect');
        if (paymentUrl != null) {
          return PhonePeSdkPaymentResult(
            success: false,
            message: 'Using web checkout',
            merchantTransactionId: merchantOrderId,
            isPending: false,
            paymentUrl: paymentUrl,
          );
        }
        throw Exception('Missing order token and payment URL');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      developer.log(
          '❌ DioException creating payment order: status=$statusCode, data=$responseData, message=${e.message}');

      String errorMessage = 'Network error';
      if (responseData is Map<String, dynamic> &&
          responseData['error'] != null) {
        errorMessage = responseData['error'];
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      // Return with payment URL if available for fallback
      return PhonePeSdkPaymentResult(
        success: false,
        message: errorMessage,
        merchantTransactionId: merchantOrderId,
        isPending: false,
        paymentUrl: paymentUrl,
      );
    } catch (e) {
      developer.log('❌ Error initiating SDK payment: $e');

      // Return with payment URL if available for fallback
      return PhonePeSdkPaymentResult(
        success: false,
        message: 'Failed to initiate payment: $e',
        merchantTransactionId: merchantOrderId,
        isPending: false,
        paymentUrl: paymentUrl,
      );
    }
  }

  /// Legacy method - Create a payment order with PhonePe backend (for backward compatibility)
  Future<PhonePePaymentResponse> createPaymentOrder({
    required String userId,
    required String examId,
    required double amount,
    required String userEmail,
    required String userPhone,
  }) async {
    try {
      developer.log('🚀 Creating PhonePe payment order...');

      final response = await _dio.post(
        '$_baseUrl/payments/create-order',
        data: {
          'userId': userId,
          'examId': examId,
          'amount': amount,
          'userEmail': userEmail,
          'userPhone': userPhone,
        },
      );

      if (response.statusCode == 200) {
        final paymentResponse = PhonePePaymentResponse.fromJson(response.data);
        developer.log(
            '✅ Payment order created: ${paymentResponse.data?.merchantTransactionId}');
        return paymentResponse;
      } else {
        throw Exception(
            'Failed to create payment order: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      developer.log(
          '❌ DioException creating payment order: status=$statusCode, data=$responseData, message=${e.message}');

      // Prefer backend-provided error message when available
      if (responseData is Map<String, dynamic> &&
          responseData['error'] != null) {
        throw Exception(responseData['error']);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log('❌ Error creating payment order: $e');
      throw Exception('Failed to create payment order: $e');
    }
  }

  /// Verify payment status with backend
  Future<PhonePeStatusResponse> verifyPaymentStatus({
    required String merchantTransactionId,
  }) async {
    try {
      developer.log('🔍 Verifying payment status for: $merchantTransactionId');

      final response = await _dio.get(
        '$_baseUrl/payments/verify/$merchantTransactionId',
      );

      if (response.statusCode == 200) {
        final statusResponse = PhonePeStatusResponse.fromJson(response.data);
        developer
            .log('✅ Payment status verified: ${statusResponse.data?.state}');
        return statusResponse;
      } else {
        throw Exception('Failed to verify payment: ${response.statusCode}');
      }
    } on DioException catch (e) {
      developer.log('❌ DioException verifying payment: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log('❌ Error verifying payment: $e');
      throw Exception('Failed to verify payment: $e');
    }
  }

  /// Poll payment status (fallback if webhook doesn't arrive)
  /// Polls every 3 seconds for up to 2 minutes
  Future<PhonePeStatusResponse?> pollPaymentStatus({
    required String merchantTransactionId,
    int maxAttempts = 40, // 40 * 3 seconds = 2 minutes
    int delaySeconds = 3,
  }) async {
    try {
      developer.log('⏱️ Starting payment status polling...');

      for (int i = 0; i < maxAttempts; i++) {
        try {
          final statusResponse = await verifyPaymentStatus(
            merchantTransactionId: merchantTransactionId,
          );

          if (statusResponse.data?.isCompleted ?? false) {
            developer.log('✅ Payment completed via polling');
            return statusResponse;
          }

          if (statusResponse.data?.isFailed ?? false) {
            developer.log('❌ Payment failed via polling');
            return statusResponse;
          }

          // Wait before next attempt
          await Future.delayed(Duration(seconds: delaySeconds));
        } catch (e) {
          developer.log('⚠️ Polling attempt ${i + 1} failed: $e');
          // Continue polling on error
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }

      developer.log('⏱️ Polling timeout - payment status not confirmed');
      return null;
    } catch (e) {
      developer.log('❌ Error during polling: $e');
      return null;
    }
  }

  /// Get payment URL for web checkout (fallback when SDK fails)
  Future<String?> getPaymentUrl({
    required String userId,
    required String examId,
    required double amount,
    required String userEmail,
    required String userPhone,
  }) async {
    try {
      developer.log('🌐 Getting payment URL for web checkout fallback...');

      final response = await _dio.post(
        '$_baseUrl/payments/create-order',
        data: {
          'userId': userId,
          'examId': examId,
          'amount': amount,
          'userEmail': userEmail,
          'userPhone': userPhone,
        },
      );

      if (response.statusCode == 200) {
        final paymentData = PhonePePaymentResponse.fromJson(response.data);
        final paymentUrl =
            paymentData.data?.paymentUrl ?? paymentData.data?.redirectUrl;

        if (paymentUrl != null) {
          developer.log('✅ Payment URL obtained for web checkout');
          return paymentUrl;
        } else {
          developer.log('⚠️ No payment URL in response');
          return null;
        }
      } else {
        developer.log('❌ Failed to get payment URL: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      developer.log('❌ DioException getting payment URL: ${e.message}');
      return null;
    } catch (e) {
      developer.log('❌ Error getting payment URL: $e');
      return null;
    }
  }

  /// Initiate payment with automatic fallback from SDK to web checkout
  /// First tries SDK payment, if it fails, falls back to web checkout
  ///
  /// IMPROVED: Now properly handles SDK timeouts and returns payment URL
  /// from the initial order creation for immediate fallback.
  Future<PhonePeSdkPaymentResult> initiatePaymentWithFallback({
    required String userId,
    required String examId,
    required double amount,
    required String userEmail,
    required String userPhone,
  }) async {
    try {
      developer.log('🚀 Initiating payment with fallback support...');

      // Step 1: Try SDK payment first
      // The SDK payment now returns paymentUrl from order creation
      developer.log('📱 Attempting SDK payment...');

      final sdkResult = await initiateSDKPayment(
        userId: userId,
        examId: examId,
        amount: amount,
        userEmail: userEmail,
        userPhone: userPhone,
      );

      developer.log(
          '📊 SDK Result: success=${sdkResult.success}, pending=${sdkResult.isPending}, hasFallback=${sdkResult.hasFallback}');

      // If SDK succeeded or is pending, return the result
      if (sdkResult.success || sdkResult.isPending) {
        developer.log('✅ SDK payment successful or pending');
        return sdkResult;
      }

      // SDK returned with payment URL - use it for fallback
      if (sdkResult.hasFallback && sdkResult.paymentUrl != null) {
        developer.log('✅ SDK returned payment URL for web checkout fallback');
        return PhonePeSdkPaymentResult(
          success: false,
          message: 'Fallback to web checkout',
          merchantTransactionId: sdkResult.merchantTransactionId,
          isPending: false,
          paymentUrl: sdkResult.paymentUrl,
        );
      }

      // SDK failed without payment URL - try to get one separately
      developer.log(
          '⚠️ SDK failed without payment URL, attempting separate fetch...');
      final paymentUrl = await getPaymentUrl(
        userId: userId,
        examId: examId,
        amount: amount,
        userEmail: userEmail,
        userPhone: userPhone,
      );

      if (paymentUrl != null) {
        developer.log('✅ Fallback to web checkout available (separate fetch)');
        return PhonePeSdkPaymentResult(
          success: false,
          message: 'Fallback to web checkout',
          merchantTransactionId: sdkResult.merchantTransactionId,
          isPending: false,
          paymentUrl: paymentUrl,
        );
      } else {
        developer.log('❌ Fallback to web checkout failed - no payment URL');
        return PhonePeSdkPaymentResult(
          success: false,
          message: sdkResult.message.isNotEmpty
              ? sdkResult.message
              : 'Payment failed: Unable to process payment. Please try again.',
          merchantTransactionId: sdkResult.merchantTransactionId,
          isPending: false,
        );
      }
    } catch (e) {
      developer.log('❌ Error in payment with fallback: $e');
      return PhonePeSdkPaymentResult(
        success: false,
        message: 'Payment error: ${e.toString()}',
        merchantTransactionId: null,
        isPending: false,
      );
    }
  }
}
