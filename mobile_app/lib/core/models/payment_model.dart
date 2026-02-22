import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment gateway types
enum PaymentGateway {
  razorpay,
  unknown, // Placeholder for future payment gateways
}

/// Extension for payment gateway
extension PaymentGatewayExtension on PaymentGateway {
  String get displayName {
    switch (this) {
      case PaymentGateway.razorpay:
        return 'Razorpay';
      case PaymentGateway.unknown:
        return 'Unknown';
    }
  }

  String get value {
    switch (this) {
      case PaymentGateway.razorpay:
        return 'razorpay';
      case PaymentGateway.unknown:
        return 'unknown';
    }
  }

  static PaymentGateway? fromString(String value) {
    try {
      return PaymentGateway.values.firstWhere(
        (gateway) => gateway.value == value,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Model for payment transactions
class PaymentModel {
  final String id;
  final String userId;
  final String examId;
  final String examName;
  final double amount;
  final String currency;
  final PaymentGateway gateway;

  // Razorpay specific fields
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final String? razorpaySignature;

  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  const PaymentModel({
    required this.id,
    required this.userId,
    required this.examId,
    required this.examName,
    required this.amount,
    required this.currency,
    required this.gateway,
    required this.status,
    required this.createdAt,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.razorpaySignature,
    this.completedAt,
    this.metadata,
  });

  /// Create from Firestore document
  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PaymentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      examId: data['examId'] ?? '',
      examName: data['examName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'INR',
      gateway:
          PaymentGatewayExtension.fromString(data['gateway'] ?? 'unknown') ??
              PaymentGateway.unknown,
      razorpayPaymentId: data['razorpayPaymentId'],
      razorpayOrderId: data['razorpayOrderId'],
      razorpaySignature: data['razorpaySignature'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${data['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'examId': examId,
      'examName': examName,
      'amount': amount,
      'currency': currency,
      'gateway': gateway.value,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  PaymentModel copyWith({
    String? id,
    String? userId,
    String? examId,
    String? examName,
    double? amount,
    String? currency,
    PaymentGateway? gateway,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      gateway: gateway ?? this.gateway,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpaySignature: razorpaySignature ?? this.razorpaySignature,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

/// Extension for payment status
extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isSuccessful => this == PaymentStatus.completed;
  bool get isFailed =>
      this == PaymentStatus.failed || this == PaymentStatus.cancelled;
  bool get isPending =>
      this == PaymentStatus.pending || this == PaymentStatus.processing;
}
