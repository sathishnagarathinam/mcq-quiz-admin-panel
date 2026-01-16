import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../models/razorpay_models.dart';

/// Razorpay Payment Service
///
/// Handles all Razorpay payment operations including:
/// - Creating orders via backend API
/// - Verifying payments
/// - Managing payment state
class RazorpayPaymentService {
  static const String _baseUrl =
      'https://us-central1-mcq-quiz-system.cloudfunctions.net/api';

  final Dio _dio;

  RazorpayPaymentService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ));

  /// Create a Razorpay order via backend
  ///
  /// Returns order details needed to open Razorpay checkout
  Future<RazorpayOrderResponse> createOrder({
    required String userId,
    required String examId,
    required double amount,
    required String userEmail,
    required String userPhone,
    double discountPercentage = 0.0,
    String? couponCode,
    String? bannerRoutedFrom,
  }) async {
    try {
      developer.log('🔵 Creating Razorpay order...');
      developer.log('   User: $userId, Exam: $examId, Amount: $amount');
      if (discountPercentage > 0) {
        developer.log('   Discount: $discountPercentage%');
        developer.log('   Coupon: $couponCode');
        developer.log('   Banner: $bannerRoutedFrom');
      }

      final response = await _dio.post(
        '$_baseUrl/payments/create-order',
        data: {
          'userId': userId,
          'examId': examId,
          'amount': amount,
          'userEmail': userEmail,
          'userPhone': userPhone,
          'discountPercentage': discountPercentage,
          'couponCode': couponCode,
          'bannerRoutedFrom': bannerRoutedFrom,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      developer.log('✅ Order created: ${response.data}');
      return RazorpayOrderResponse.fromJson(response.data);
    } on DioException catch (e) {
      developer.log('❌ Dio error creating order: ${e.message}');
      developer.log('   Response: ${e.response?.data}');

      String errorMessage = 'Failed to create payment order';
      if (e.response?.data != null && e.response?.data['error'] != null) {
        errorMessage = e.response?.data['error'];
      } else if (e.response?.data != null &&
          e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      return RazorpayOrderResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      developer.log('❌ Error creating order: $e');
      return RazorpayOrderResponse(
        success: false,
        message: 'Failed to create payment order: $e',
      );
    }
  }

  /// Verify payment signature with backend
  ///
  /// This should be called after successful payment to verify signature
  Future<RazorpayVerificationResponse> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String merchantOrderId,
  }) async {
    try {
      developer.log('🔵 Verifying Razorpay payment...');
      developer.log('   Payment ID: $paymentId');
      developer.log('   Order ID: $orderId');

      final response = await _dio.post(
        '$_baseUrl/payments/verify',
        data: {
          'paymentId': paymentId,
          'orderId': orderId,
          'signature': signature,
          'merchantOrderId': merchantOrderId,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      developer.log('✅ Verification response: ${response.data}');
      return RazorpayVerificationResponse.fromJson(response.data);
    } on DioException catch (e) {
      developer.log('❌ Dio error verifying payment: ${e.message}');
      developer.log('   Status code: ${e.response?.statusCode}');
      developer.log('   Response data: ${e.response?.data}');

      String errorMessage = 'Payment verification failed';
      if (e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          errorMessage = data['error'].toString();
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }

      return RazorpayVerificationResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      developer.log('❌ Error verifying payment: $e');
      return RazorpayVerificationResponse(
        success: false,
        message: 'Payment verification failed: $e',
      );
    }
  }

  /// Check payment status by order ID
  Future<RazorpayVerificationResponse> checkPaymentStatus(
      String merchantOrderId) async {
    try {
      developer.log('🔵 Checking payment status for: $merchantOrderId');

      final response = await _dio.get(
        '$_baseUrl/payments/status/$merchantOrderId',
      );

      developer.log('✅ Status response: ${response.data}');
      return RazorpayVerificationResponse.fromJson(response.data);
    } on DioException catch (e) {
      developer.log('❌ Error checking status: ${e.message}');
      return RazorpayVerificationResponse(
        success: false,
        message: 'Failed to check payment status',
      );
    } catch (e) {
      developer.log('❌ Error checking status: $e');
      return RazorpayVerificationResponse(
        success: false,
        message: 'Failed to check payment status: $e',
      );
    }
  }
}
