/// PhonePe Payment Request Model
class PhonePePaymentRequest {
  final String userId;
  final String examId;
  final double amount;
  final String userEmail;
  final String userPhone;

  PhonePePaymentRequest({
    required this.userId,
    required this.examId,
    required this.amount,
    required this.userEmail,
    required this.userPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'examId': examId,
      'amount': amount,
      'userEmail': userEmail,
      'userPhone': userPhone,
    };
  }
}

/// PhonePe Payment Response Model
class PhonePePaymentResponse {
  final bool success;
  final String code;
  final String message;
  final PhonePePaymentData? data;

  PhonePePaymentResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });

  factory PhonePePaymentResponse.fromJson(Map<String, dynamic> json) {
    return PhonePePaymentResponse(
      success: json['success'] ?? false,
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PhonePePaymentData.fromJson(json['data'])
          : null,
    );
  }
}

/// PhonePe Payment Data Model (Standard Checkout v2)
class PhonePePaymentData {
  final String? merchantTransactionId;
  final String? merchantOrderId; // Standard Checkout v2 uses this
  final String? orderId; // PhonePe's order ID
  final String? orderToken; // Token for SDK-based payments
  final String? paymentUrl; // Redirect URL for web payments
  final String? redirectUrl; // Alternative redirect URL
  final double? amount;

  PhonePePaymentData({
    this.merchantTransactionId,
    this.merchantOrderId,
    this.orderId,
    this.orderToken,
    this.paymentUrl,
    this.redirectUrl,
    this.amount,
  });

  factory PhonePePaymentData.fromJson(Map<String, dynamic> json) {
    return PhonePePaymentData(
      merchantTransactionId: json['merchantTransactionId'],
      merchantOrderId: json['merchantOrderId'],
      orderId: json['orderId'],
      orderToken: json['orderToken'],
      paymentUrl: json['paymentUrl'],
      redirectUrl: json['redirectUrl'],
      amount:
          json['amount'] != null ? (json['amount'] as num).toDouble() : null,
    );
  }
}

/// PhonePe Payment Status Response
class PhonePeStatusResponse {
  final bool success;
  final String code;
  final String message;
  final PhonePeStatusData? data;

  PhonePeStatusResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });

  factory PhonePeStatusResponse.fromJson(Map<String, dynamic> json) {
    return PhonePeStatusResponse(
      success: json['success'] ?? false,
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PhonePeStatusData.fromJson(json['data'])
          : null,
    );
  }
}

/// PhonePe Status Data Model
class PhonePeStatusData {
  final String? state; // COMPLETED, FAILED, PENDING
  final String? transactionId;
  final double? amount;
  final String? responseCode;

  PhonePeStatusData({
    this.state,
    this.transactionId,
    this.amount,
    this.responseCode,
  });

  factory PhonePeStatusData.fromJson(Map<String, dynamic> json) {
    return PhonePeStatusData(
      state: json['state'],
      transactionId: json['transactionId'],
      amount:
          json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      responseCode: json['responseCode'],
    );
  }

  bool get isCompleted => state == 'COMPLETED';
  bool get isFailed => state == 'FAILED';
  bool get isPending => state == 'PENDING';
}

/// Result from PhonePe SDK payment initiation
class PhonePeSdkPaymentResult {
  final bool success;
  final String message;
  final String? merchantTransactionId;
  final bool isPending;
  final String? paymentUrl; // Fallback URL for web checkout

  PhonePeSdkPaymentResult({
    required this.success,
    required this.message,
    this.merchantTransactionId,
    this.isPending = false,
    this.paymentUrl,
  });

  /// Whether payment needs backend verification
  bool get needsVerification => isPending || success;

  /// Whether fallback to web checkout is available
  bool get hasFallback => paymentUrl != null;
}
