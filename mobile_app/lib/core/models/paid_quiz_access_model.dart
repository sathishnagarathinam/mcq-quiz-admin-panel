import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking paid quiz access with expiry dates
class PaidQuizAccessModel {
  final String id;
  final String userId;
  final String examId;
  final String examName;
  final String paymentId; // Reference to the payment record
  final DateTime purchaseDate;
  final DateTime expiryDate; // 30 days from purchase
  final bool isActive;
  final int attemptCount;
  final DateTime? lastAttemptDate;
  final Map<String, dynamic>? metadata;

  const PaidQuizAccessModel({
    required this.id,
    required this.userId,
    required this.examId,
    required this.examName,
    required this.paymentId,
    required this.purchaseDate,
    required this.expiryDate,
    this.isActive = true,
    this.attemptCount = 0,
    this.lastAttemptDate,
    this.metadata,
  });

  /// Create from Firestore document
  /// Handles both old format (purchaseDate/expiryDate) and new format (accessGrantedAt/accessExpiresAt)
  factory PaidQuizAccessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle both old and new field names from backend
    DateTime purchaseDate;
    DateTime expiryDate;

    // Try new backend format first (accessGrantedAt/accessExpiresAt)
    if (data['accessGrantedAt'] != null) {
      purchaseDate = (data['accessGrantedAt'] as Timestamp).toDate();
    } else if (data['purchaseDate'] != null) {
      purchaseDate = (data['purchaseDate'] as Timestamp).toDate();
    } else {
      purchaseDate = DateTime.now();
    }

    if (data['accessExpiresAt'] != null) {
      expiryDate = (data['accessExpiresAt'] as Timestamp).toDate();
    } else if (data['expiryDate'] != null) {
      expiryDate = (data['expiryDate'] as Timestamp).toDate();
    } else {
      expiryDate = DateTime.now().add(const Duration(days: 30));
    }

    return PaidQuizAccessModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      examId: data['examId'] ?? '',
      examName: data['examName'] ?? '',
      paymentId: data['paymentTransactionId'] ?? data['paymentId'] ?? '',
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      isActive: data['isActive'] ?? true,
      attemptCount: data['attemptCount'] ?? 0,
      lastAttemptDate: data['lastAttemptDate'] != null
          ? (data['lastAttemptDate'] as Timestamp).toDate()
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
      'paymentId': paymentId,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isActive': isActive,
      'attemptCount': attemptCount,
      'lastAttemptDate':
          lastAttemptDate != null ? Timestamp.fromDate(lastAttemptDate!) : null,
      'metadata': metadata,
    };
  }

  /// Check if access is still valid (not expired and active)
  bool get isValidAccess {
    final now = DateTime.now();
    return isActive && now.isBefore(expiryDate);
  }

  /// Get remaining days until expiry
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;
    return expiryDate.difference(now).inDays;
  }

  /// Get remaining hours until expiry
  int get remainingHours {
    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;
    return expiryDate.difference(now).inHours;
  }

  /// Check if access is expiring soon (within 3 days)
  bool get isExpiringSoon {
    return remainingDays <= 3 && remainingDays > 0;
  }

  /// Create a copy with updated fields
  PaidQuizAccessModel copyWith({
    String? id,
    String? userId,
    String? examId,
    String? examName,
    String? paymentId,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    bool? isActive,
    int? attemptCount,
    DateTime? lastAttemptDate,
    Map<String, dynamic>? metadata,
  }) {
    return PaidQuizAccessModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      paymentId: paymentId ?? this.paymentId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptDate: lastAttemptDate ?? this.lastAttemptDate,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create new access record from payment
  factory PaidQuizAccessModel.fromPayment({
    required String userId,
    required String examId,
    required String examName,
    required String paymentId,
    DateTime? purchaseDate,
  }) {
    final purchase = purchaseDate ?? DateTime.now();
    final expiry = purchase.add(const Duration(days: 30));

    return PaidQuizAccessModel(
      id: '', // Will be set by Firestore
      userId: userId,
      examId: examId,
      examName: examName,
      paymentId: paymentId,
      purchaseDate: purchase,
      expiryDate: expiry,
      isActive: true,
      attemptCount: 0,
      metadata: {
        'accessDuration': 30, // days
        'createdAt': purchase.toIso8601String(),
      },
    );
  }

  @override
  String toString() {
    return 'PaidQuizAccessModel(id: $id, examId: $examId, userId: $userId, '
        'isValidAccess: $isValidAccess, remainingDays: $remainingDays, '
        'attemptCount: $attemptCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaidQuizAccessModel &&
        other.id == id &&
        other.userId == userId &&
        other.examId == examId;
  }

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ examId.hashCode;
}

/// Access status enum for UI display
enum QuizAccessStatus {
  free, // Quiz is free
  purchased, // User has valid paid access
  expired, // User's paid access has expired
  notPurchased, // User hasn't purchased this paid quiz
}

/// Extension for quiz access status
extension QuizAccessStatusExtension on QuizAccessStatus {
  String get displayName {
    switch (this) {
      case QuizAccessStatus.free:
        return 'Free';
      case QuizAccessStatus.purchased:
        return 'Purchased';
      case QuizAccessStatus.expired:
        return 'Expired';
      case QuizAccessStatus.notPurchased:
        return 'Not Purchased';
    }
  }

  String get description {
    switch (this) {
      case QuizAccessStatus.free:
        return 'This quiz is free to attempt';
      case QuizAccessStatus.purchased:
        return 'You have access to this quiz';
      case QuizAccessStatus.expired:
        return 'Your access has expired. Purchase again to continue';
      case QuizAccessStatus.notPurchased:
        return 'Purchase this quiz to get 30 days access';
    }
  }

  bool get canAttempt {
    return this == QuizAccessStatus.free || this == QuizAccessStatus.purchased;
  }

  bool get requiresPayment {
    return this == QuizAccessStatus.notPurchased ||
        this == QuizAccessStatus.expired;
  }
}
