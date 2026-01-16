import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking user quiz attempts
class QuizAttemptModel {
  final String id;
  final String userId;
  final String examId;
  final String examName;
  final String examType;
  final DateTime attemptedAt;
  final DateTime? completedAt;
  final int? score;
  final int? totalQuestions;
  final int? correctAnswers;
  final int? timeSpent; // in seconds
  final bool isCompleted;
  final Map<String, dynamic>? answers; // User's answers
  final String status; // 'in_progress', 'completed', 'abandoned'

  const QuizAttemptModel({
    required this.id,
    required this.userId,
    required this.examId,
    required this.examName,
    required this.examType,
    required this.attemptedAt,
    this.completedAt,
    this.score,
    this.totalQuestions,
    this.correctAnswers,
    this.timeSpent,
    required this.isCompleted,
    this.answers,
    required this.status,
  });

  /// Create from Firestore document
  factory QuizAttemptModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      // Handle Timestamp conversion
      DateTime attemptedAt;
      if (data['attemptedAt'] is Timestamp) {
        attemptedAt = (data['attemptedAt'] as Timestamp).toDate();
      } else if (data['attemptedAt'] is String) {
        attemptedAt = DateTime.parse(data['attemptedAt']);
      } else {
        attemptedAt = DateTime.now();
      }

      DateTime? completedAt;
      if (data['completedAt'] != null) {
        if (data['completedAt'] is Timestamp) {
          completedAt = (data['completedAt'] as Timestamp).toDate();
        } else if (data['completedAt'] is String) {
          completedAt = DateTime.parse(data['completedAt']);
        }
      }

      return QuizAttemptModel(
        id: doc.id,
        userId: data['userId'] ?? '',
        examId: data['examId'] ?? '',
        examName: data['examName'] ?? '',
        examType: data['examType'] ?? '',
        attemptedAt: attemptedAt,
        completedAt: completedAt,
        score: data['score'],
        totalQuestions: data['totalQuestions'],
        correctAnswers: data['correctAnswers'],
        timeSpent: data['timeSpent'],
        isCompleted: data['isCompleted'] ?? false,
        answers: data['answers'] as Map<String, dynamic>?,
        status: data['status'] ?? 'in_progress',
      );
    } catch (e) {
      print('Error parsing QuizAttemptModel from Firestore: $e');
      // Return a default model to prevent crashes
      return QuizAttemptModel(
        id: doc.id,
        userId: '',
        examId: '',
        examName: 'Error Loading Attempt',
        examType: 'Unknown',
        attemptedAt: DateTime.now(),
        isCompleted: false,
        status: 'error',
      );
    }
  }

  /// Create from JSON
  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      examId: json['examId'] ?? '',
      examName: json['examName'] ?? '',
      examType: json['examType'] ?? '',
      attemptedAt: DateTime.parse(json['attemptedAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      correctAnswers: json['correctAnswers'],
      timeSpent: json['timeSpent'],
      isCompleted: json['isCompleted'] ?? false,
      answers: json['answers'] as Map<String, dynamic>?,
      status: json['status'] ?? 'in_progress',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'examId': examId,
      'examName': examName,
      'examType': examType,
      'attemptedAt': attemptedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'timeSpent': timeSpent,
      'isCompleted': isCompleted,
      'answers': answers,
      'status': status,
    };
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'examId': examId,
      'examName': examName,
      'examType': examType,
      'attemptedAt': Timestamp.fromDate(attemptedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'timeSpent': timeSpent,
      'isCompleted': isCompleted,
      'answers': answers,
      'status': status,
    };
  }

  /// Get display name for the exam
  String get displayName {
    if (examName.isNotEmpty) return examName;
    return 'Quiz Attempt';
  }

  /// Get formatted attempt date
  String get formattedAttemptDate {
    final now = DateTime.now();
    final difference = now.difference(attemptedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get score percentage
  double? get scorePercentage {
    if (score != null && totalQuestions != null && totalQuestions! > 0) {
      return (score! / totalQuestions!) * 100;
    }
    return null;
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'completed':
        return '#4CAF50'; // Green
      case 'in_progress':
        return '#FF9800'; // Orange
      case 'abandoned':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'abandoned':
        return 'Abandoned';
      default:
        return 'Unknown';
    }
  }

  /// Copy with method for updating fields
  QuizAttemptModel copyWith({
    String? id,
    String? userId,
    String? examId,
    String? examName,
    String? examType,
    DateTime? attemptedAt,
    DateTime? completedAt,
    int? score,
    int? totalQuestions,
    int? correctAnswers,
    int? timeSpent,
    bool? isCompleted,
    Map<String, dynamic>? answers,
    String? status,
  }) {
    return QuizAttemptModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      examType: examType ?? this.examType,
      attemptedAt: attemptedAt ?? this.attemptedAt,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      timeSpent: timeSpent ?? this.timeSpent,
      isCompleted: isCompleted ?? this.isCompleted,
      answers: answers ?? this.answers,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'QuizAttemptModel(id: $id, examName: $examName, status: $status, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizAttemptModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
