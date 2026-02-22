// Razorpay Payment Models
//
// Models for Razorpay payment integration including order creation,
// payment responses, and verification.

/// Request model for creating a Razorpay order
class RazorpayOrderRequest {
  final String userId;
  final String examId;
  final double amount;
  final String userEmail;
  final String userPhone;

  RazorpayOrderRequest({
    required this.userId,
    required this.examId,
    required this.amount,
    required this.userEmail,
    required this.userPhone,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'examId': examId,
        'amount': amount,
        'userEmail': userEmail,
        'userPhone': userPhone,
      };
}

/// Response model for Razorpay order creation from backend
class RazorpayOrderResponse {
  final bool success;
  final String? message;
  final RazorpayOrderData? data;

  RazorpayOrderResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? RazorpayOrderData.fromJson(json['data'])
          : null,
    );
  }
}

/// Order data returned from backend
class RazorpayOrderData {
  final String orderId; // Razorpay order_id
  final String merchantOrderId; // Our internal order ID
  final int amount; // Amount in paise
  final String currency;
  final String keyId; // Razorpay key for checkout
  final String? receipt;
  final String? description;

  RazorpayOrderData({
    required this.orderId,
    required this.merchantOrderId,
    required this.amount,
    required this.currency,
    required this.keyId,
    this.receipt,
    this.description,
  });

  factory RazorpayOrderData.fromJson(Map<String, dynamic> json) {
    // Parse amount - could be int, String, or double from backend
    // Amount should be in paise (smallest unit)
    int parsedAmount = 0;
    final amountValue = json['amount'];

    if (amountValue is int) {
      parsedAmount = amountValue;
    } else if (amountValue is String) {
      parsedAmount = int.tryParse(amountValue) ?? 0;
    } else if (amountValue is double) {
      parsedAmount = amountValue.toInt();
    } else if (amountValue != null) {
      // Fallback: try to convert to string first, then to int
      parsedAmount = int.tryParse(amountValue.toString()) ?? 0;
    }

    return RazorpayOrderData(
      orderId:
          json['orderId']?.toString() ?? json['order_id']?.toString() ?? '',
      merchantOrderId: json['merchantOrderId']?.toString() ??
          json['receipt']?.toString() ??
          '',
      amount: parsedAmount,
      currency: json['currency']?.toString() ?? 'INR',
      keyId: json['keyId']?.toString() ?? json['key_id']?.toString() ?? '',
      receipt: json['receipt']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

/// Result from Razorpay payment (success callback)
class RazorpayPaymentResult {
  final bool success;
  final String? paymentId; // razorpay_payment_id
  final String? orderId; // razorpay_order_id
  final String? signature; // razorpay_signature
  final String? merchantOrderId; // Our internal order ID
  final String message;

  RazorpayPaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.merchantOrderId,
    this.message = '',
  });

  /// Whether payment was successful and has all required fields
  bool get isComplete =>
      success && paymentId != null && orderId != null && signature != null;

  /// Create from Razorpay success response
  factory RazorpayPaymentResult.success(
      Map<dynamic, dynamic> response, String? merchantOrderId) {
    return RazorpayPaymentResult(
      success: true,
      paymentId: response['razorpay_payment_id']?.toString(),
      orderId: response['razorpay_order_id']?.toString(),
      signature: response['razorpay_signature']?.toString(),
      merchantOrderId: merchantOrderId,
      message: 'Payment successful',
    );
  }

  /// Create from Razorpay error
  factory RazorpayPaymentResult.error(String message, String? merchantOrderId) {
    return RazorpayPaymentResult(
      success: false,
      merchantOrderId: merchantOrderId,
      message: message,
    );
  }
}

/// Payment verification response from backend
class RazorpayVerificationResponse {
  final bool success;
  final String? status;
  final String? message;
  final bool verified;

  RazorpayVerificationResponse({
    required this.success,
    this.status,
    this.message,
    this.verified = false,
  });

  factory RazorpayVerificationResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayVerificationResponse(
      success: json['success'] ?? false,
      status: json['status'],
      message: json['message'],
      verified: json['verified'] ?? false,
    );
  }

  bool get isPaid => verified || status == 'paid' || status == 'captured';
}
