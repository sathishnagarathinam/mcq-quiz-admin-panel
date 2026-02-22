import '../models/exam_model.dart';
import '../models/payment_model.dart';

/// Abstract interface for payment gateways
abstract class PaymentGatewayInterface {
  /// Initialize the payment gateway
  Future<bool> initialize();

  /// Check if the payment gateway is available/installed
  Future<bool> isAvailable();

  /// Initiate a payment transaction
  Future<void> initiatePayment({
    required ExamModel exam,
    required String userEmail,
    required String userPhone,
    required Function(PaymentSuccessResult) onSuccess,
    required Function(String) onError,
  });

  /// Verify payment status
  Future<bool> verifyPayment({
    required String transactionId,
    required String orderId,
    String? signature,
  });

  /// Save payment record to database
  Future<void> savePaymentRecord({
    required String examId,
    required String examName,
    required double amount,
    required String currency,
    required PaymentSuccessResult paymentResult,
    required PaymentStatus status,
  });

  /// Get user's payment history for this gateway
  Future<List<PaymentModel>> getUserPaymentHistory();

  /// Check if user has paid for an exam using this gateway
  Future<bool> hasUserPaidForExam(String examId);

  /// Get the gateway type
  PaymentGateway get gatewayType;

  /// Get the gateway display name
  String get displayName;

  /// Get the gateway configuration
  Map<String, dynamic> get configuration;
}

/// Generic payment success result
class PaymentSuccessResult {
  final String transactionId;
  final String orderId;
  final String? signature;
  final PaymentGateway gateway;
  final Map<String, dynamic>? additionalData;

  const PaymentSuccessResult({
    required this.transactionId,
    required this.orderId,
    this.signature,
    required this.gateway,
    this.additionalData,
  });
}

/// Payment gateway factory
class PaymentGatewayFactory {
  static PaymentGatewayInterface? createGateway(PaymentGateway gateway) {
    // Payment processing is currently disabled
    // Add payment gateway implementations here when integrating with a new provider
    return null;
  }

  static List<PaymentGateway> getAvailableGateways() {
    // Payment processing is currently disabled
    return [];
  }
}
