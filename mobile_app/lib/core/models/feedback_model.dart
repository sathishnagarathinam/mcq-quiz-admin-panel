import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for user feedback on quiz results
class FeedbackModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String examId;
  final String examName;
  final String examType;
  final int rating; // 1-5 stars
  final String comment;
  final int userScore;
  final int totalQuestions;
  final double percentage;
  final DateTime submittedAt;
  final FeedbackStatus status;
  final String? adminResponse;
  final DateTime? respondedAt;
  final String? respondedBy;
  final Map<String, dynamic>? metadata;

  const FeedbackModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.examId,
    required this.examName,
    required this.examType,
    required this.rating,
    required this.comment,
    required this.userScore,
    required this.totalQuestions,
    required this.percentage,
    required this.submittedAt,
    required this.status,
    this.adminResponse,
    this.respondedAt,
    this.respondedBy,
    this.metadata,
  });

  /// Create from Firestore document
  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      examId: data['examId'] ?? '',
      examName: data['examName'] ?? '',
      examType: data['examType'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      userScore: data['userScore'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      percentage: (data['percentage'] ?? 0.0).toDouble(),
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.toString() == 'FeedbackStatus.${data['status']}',
        orElse: () => FeedbackStatus.pending,
      ),
      adminResponse: data['adminResponse'],
      respondedAt: data['respondedAt'] != null 
          ? (data['respondedAt'] as Timestamp).toDate() 
          : null,
      respondedBy: data['respondedBy'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'examId': examId,
      'examName': examName,
      'examType': examType,
      'rating': rating,
      'comment': comment,
      'userScore': userScore,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.name,
      'adminResponse': adminResponse,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'respondedBy': respondedBy,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? examId,
    String? examName,
    String? examType,
    int? rating,
    String? comment,
    int? userScore,
    int? totalQuestions,
    double? percentage,
    DateTime? submittedAt,
    FeedbackStatus? status,
    String? adminResponse,
    DateTime? respondedAt,
    String? respondedBy,
    Map<String, dynamic>? metadata,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      examType: examType ?? this.examType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      userScore: userScore ?? this.userScore,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      percentage: percentage ?? this.percentage,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get display name for the exam
  String get displayName {
    if (examName.isNotEmpty) return examName;
    return 'Quiz Feedback';
  }

  /// Get formatted percentage
  String get formattedPercentage {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Get rating as stars
  String get ratingStars {
    return '★' * rating + '☆' * (5 - rating);
  }

  /// Check if feedback has admin response
  bool get hasAdminResponse {
    return adminResponse != null && adminResponse!.isNotEmpty;
  }

  /// Get time since submission
  String get timeSinceSubmission {
    final now = DateTime.now();
    final difference = now.difference(submittedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}';
    }
  }

  @override
  String toString() {
    return 'FeedbackModel(id: $id, examName: $examName, rating: $rating, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Feedback status enum
enum FeedbackStatus {
  pending,
  reviewed,
  responded,
  archived,
}

/// Extension for feedback status
extension FeedbackStatusExtension on FeedbackStatus {
  String get displayName {
    switch (this) {
      case FeedbackStatus.pending:
        return 'Pending Review';
      case FeedbackStatus.reviewed:
        return 'Reviewed';
      case FeedbackStatus.responded:
        return 'Responded';
      case FeedbackStatus.archived:
        return 'Archived';
    }
  }

  String get description {
    switch (this) {
      case FeedbackStatus.pending:
        return 'Waiting for admin review';
      case FeedbackStatus.reviewed:
        return 'Reviewed by admin';
      case FeedbackStatus.responded:
        return 'Admin has responded';
      case FeedbackStatus.archived:
        return 'Archived feedback';
    }
  }
}

/// Feedback category for better organization
enum FeedbackCategory {
  general,
  difficulty,
  content,
  technical,
  suggestion,
}

/// Extension for feedback category
extension FeedbackCategoryExtension on FeedbackCategory {
  String get displayName {
    switch (this) {
      case FeedbackCategory.general:
        return 'General Feedback';
      case FeedbackCategory.difficulty:
        return 'Difficulty Level';
      case FeedbackCategory.content:
        return 'Content Quality';
      case FeedbackCategory.technical:
        return 'Technical Issues';
      case FeedbackCategory.suggestion:
        return 'Suggestions';
    }
  }
}
