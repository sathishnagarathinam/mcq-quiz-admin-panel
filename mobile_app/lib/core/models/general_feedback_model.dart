import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for general user feedback (not tied to specific quiz results)
class GeneralFeedbackModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String category;
  final String subject;
  final String message;
  final int rating; // 1-5 stars
  final DateTime submittedAt;
  final FeedbackStatus status;
  final String? adminResponse;
  final DateTime? respondedAt;
  final String? respondedBy;
  final Map<String, dynamic>? metadata;

  const GeneralFeedbackModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.category,
    required this.subject,
    required this.message,
    required this.rating,
    required this.submittedAt,
    required this.status,
    this.adminResponse,
    this.respondedAt,
    this.respondedBy,
    this.metadata,
  });

  /// Create from Firestore document
  factory GeneralFeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GeneralFeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      category: data['category'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      rating: data['rating'] ?? 0,
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
      'category': category,
      'subject': subject,
      'message': message,
      'rating': rating,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.toString().split('.').last,
      'adminResponse': adminResponse,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'respondedBy': respondedBy,
      'metadata': metadata,
    };
  }

  /// Copy with new values
  GeneralFeedbackModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? category,
    String? subject,
    String? message,
    int? rating,
    DateTime? submittedAt,
    FeedbackStatus? status,
    String? adminResponse,
    DateTime? respondedAt,
    String? respondedBy,
    Map<String, dynamic>? metadata,
  }) {
    return GeneralFeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      rating: rating ?? this.rating,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Feedback status enum
enum FeedbackStatus {
  pending,
  reviewed,
  responded,
  archived,
}

/// Feedback categories
class FeedbackCategory {
  static const String general = 'general';
  static const String bugReport = 'bug_report';
  static const String featureRequest = 'feature_request';
  static const String appPerformance = 'app_performance';
  static const String contentQuality = 'content_quality';
  static const String userExperience = 'user_experience';
  static const String other = 'other';

  static const Map<String, String> categoryLabels = {
    general: 'General Feedback',
    bugReport: 'Bug Report',
    featureRequest: 'Feature Request',
    appPerformance: 'App Performance',
    contentQuality: 'Content Quality',
    userExperience: 'User Experience',
    other: 'Other',
  };

  static const Map<String, String> categoryDescriptions = {
    general: 'General comments and suggestions',
    bugReport: 'Report bugs or technical issues',
    featureRequest: 'Suggest new features or improvements',
    appPerformance: 'Issues with app speed or performance',
    contentQuality: 'Feedback about quiz content and questions',
    userExperience: 'Comments about app design and usability',
    other: 'Other feedback not covered above',
  };

  static List<String> get allCategories => categoryLabels.keys.toList();
}
