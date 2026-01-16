import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import '../models/exam_model.dart';
import '../models/payment_model.dart';
import '../models/razorpay_models.dart';
import '../services/razorpay_payment_service.dart';

/// Provider for managing payment state and operations
///
/// Uses Razorpay payment gateway for processing quiz payments.
class PaymentProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  final Map<String, bool> _examPaymentStatus = {};
  List<PaymentModel> _paymentHistory = [];
  late RazorpayPaymentService _razorpayService;
  String? _currentMerchantOrderId;
  String? _currentRazorpayOrderId;
  RazorpayOrderData? _currentOrderData;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PaymentModel> get paymentHistory => _paymentHistory;
  String? get currentMerchantOrderId => _currentMerchantOrderId;
  String? get currentRazorpayOrderId => _currentRazorpayOrderId;
  RazorpayOrderData? get currentOrderData => _currentOrderData;

  PaymentProvider() {
    _initializeService();
  }

  /// Initialize Razorpay Payment Service
  void _initializeService() {
    _razorpayService = RazorpayPaymentService();
    developer.log('✅ RazorpayPaymentService initialized');
  }

  /// Check if user has paid for a specific exam
  bool hasUserPaidForExam(String examId) {
    return _examPaymentStatus[examId] ?? false;
  }

  /// Load payment status for an exam
  Future<void> loadExamPaymentStatus(String examId) async {
    try {
      // Payment status loading disabled - payment infrastructure preserved for future integration
      _examPaymentStatus[examId] = false;
      notifyListeners();
    } catch (e) {
      developer.log('Error loading payment status for exam $examId: $e');
    }
  }

  /// Load payment status for multiple exams
  Future<void> loadMultipleExamPaymentStatus(List<String> examIds) async {
    try {
      for (final examId in examIds) {
        // Payment status loading disabled - payment infrastructure preserved for future integration
        _examPaymentStatus[examId] = false;
      }
      notifyListeners();
    } catch (e) {
      developer.log('Error loading payment status for multiple exams: $e');
    }
  }

  /// Test backend connectivity
  Future<bool> testBackendConnectivity() async {
    try {
      developer.log('🔍 Testing backend connectivity...');
      // Backend connectivity check disabled - payment infrastructure preserved for future integration
      developer.log('📡 Backend connectivity: Disabled');
      return false;
    } catch (e) {
      developer.log('❌ Backend connectivity test failed: $e');
      return false;
    }
  }

  /// Create Razorpay order and return order data for checkout
  ///
  /// Returns RazorpayOrderResponse with order details needed to open checkout
  Future<RazorpayOrderResponse> createRazorpayOrder({
    required ExamModel exam,
    required String userEmail,
    required String userPhone,
    required String userId,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      developer.log('🚀 Creating Razorpay order for exam: ${exam.id}');
      developer.log('   Original Price: ${exam.price}');
      developer.log('   Discount: ${exam.discountPercentage}%');
      developer.log('   Final Price: ${exam.discountedPrice}');

      // Use discounted price if available, otherwise use regular price
      final finalAmount = exam.hasDiscount ? exam.discountedPrice : exam.price;

      final response = await _razorpayService.createOrder(
        userId: userId,
        examId: exam.id,
        amount: finalAmount,
        userEmail: userEmail,
        userPhone: userPhone,
        discountPercentage: exam.discountPercentage,
        couponCode: exam.couponCode,
        bannerRoutedFrom: exam.bannerRoutedFrom,
      );

      if (response.success && response.data != null) {
        _currentOrderData = response.data;
        _currentMerchantOrderId = response.data!.merchantOrderId;
        _currentRazorpayOrderId = response.data!.orderId;

        developer.log('✅ Razorpay order created successfully');
        developer.log('   Order ID: ${response.data!.orderId}');
        developer
            .log('   Merchant Order ID: ${response.data!.merchantOrderId}');
      } else {
        developer.log('❌ Failed to create order: ${response.message}');
        _setError(response.message ?? 'Failed to create order');
      }

      return response;
    } catch (e) {
      developer.log('❌ Error creating Razorpay order: $e');
      _setError(e.toString());

      return RazorpayOrderResponse(
        success: false,
        message: e.toString(),
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Verify Razorpay payment with signature
  Future<bool> verifyRazorpayPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String merchantOrderId,
  }) async {
    try {
      developer.log('🔍 Verifying Razorpay payment...');
      developer.log('   Payment ID: $paymentId');
      developer.log('   Order ID: $orderId');

      final response = await _razorpayService.verifyPayment(
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
        merchantOrderId: merchantOrderId,
      );

      if (response.isPaid) {
        developer.log('✅ Payment verified successfully');
        return true;
      }

      developer.log('❌ Payment verification failed: ${response.message}');
      return false;
    } catch (e) {
      developer.log('❌ Error verifying payment: $e');
      return false;
    }
  }

  /// Check payment status by merchant order ID
  Future<bool> checkPaymentStatus(String merchantOrderId) async {
    try {
      developer.log('🔍 Checking payment status: $merchantOrderId');

      final response =
          await _razorpayService.checkPaymentStatus(merchantOrderId);

      if (response.isPaid) {
        developer.log('✅ Payment confirmed');
        return true;
      }

      developer.log('⏳ Payment not yet confirmed: ${response.status}');
      return false;
    } catch (e) {
      developer.log('❌ Error checking payment status: $e');
      return false;
    }
  }

  /// Load user's payment history
  Future<void> loadPaymentHistory() async {
    try {
      _setLoading(true);
      // Payment history loading disabled - payment infrastructure preserved for future integration
      _paymentHistory = [];
      notifyListeners();
    } catch (e) {
      developer.log('Error loading payment history: $e');
      _setError('Failed to load payment history');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear payment status cache
  void clearPaymentStatusCache() {
    _examPaymentStatus.clear();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _setError(null);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
