import 'package:cloud_firestore/cloud_firestore.dart';

/// User progress model for tracking exam performance and statistics
class UserProgressModel {
  final String userId;
  final int totalExamsAttempted;
  final int totalExamsPassed;
  final double averageScore;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final Map<String, int> categoryProgress; // category -> exams completed
  final Map<String, double> categoryScores; // category -> average score
  final DateTime lastExamDate;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProgressModel({
    required this.userId,
    required this.totalExamsAttempted,
    required this.totalExamsPassed,
    required this.averageScore,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.categoryProgress,
    required this.categoryScores,
    required this.lastExamDate,
    required this.currentStreak,
    required this.longestStreak,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    return UserProgressModel(
      userId: json['userId'] ?? '',
      totalExamsAttempted: json['totalExamsAttempted'] ?? 0,
      totalExamsPassed: json['totalExamsPassed'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
      totalQuestionsAnswered: json['totalQuestionsAnswered'] ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] ?? 0,
      categoryProgress: Map<String, int>.from(json['categoryProgress'] ?? {}),
      categoryScores: Map<String, double>.from(json['categoryScores'] ?? {}),
      lastExamDate: DateTime.parse(
        json['lastExamDate'] ?? DateTime.now().toIso8601String(),
      ),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  factory UserProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProgressModel(
      userId: doc.id,
      totalExamsAttempted: data['totalExamsAttempted'] ?? 0,
      totalExamsPassed: data['totalExamsPassed'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      totalQuestionsAnswered: data['totalQuestionsAnswered'] ?? 0,
      totalCorrectAnswers: data['totalCorrectAnswers'] ?? 0,
      categoryProgress: Map<String, int>.from(data['categoryProgress'] ?? {}),
      categoryScores: Map<String, double>.from(data['categoryScores'] ?? {}),
      lastExamDate: (data['lastExamDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalExamsAttempted': totalExamsAttempted,
      'totalExamsPassed': totalExamsPassed,
      'averageScore': averageScore,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrectAnswers': totalCorrectAnswers,
      'categoryProgress': categoryProgress,
      'categoryScores': categoryScores,
      'lastExamDate': lastExamDate.toIso8601String(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalExamsAttempted': totalExamsAttempted,
      'totalExamsPassed': totalExamsPassed,
      'averageScore': averageScore,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrectAnswers': totalCorrectAnswers,
      'categoryProgress': categoryProgress,
      'categoryScores': categoryScores,
      'lastExamDate': Timestamp.fromDate(lastExamDate),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get pass percentage
  double get passPercentage {
    if (totalExamsAttempted == 0) return 0.0;
    return (totalExamsPassed / totalExamsAttempted) * 100;
  }

  /// Get accuracy percentage
  double get accuracyPercentage {
    if (totalQuestionsAnswered == 0) return 0.0;
    return (totalCorrectAnswers / totalQuestionsAnswered) * 100;
  }

  /// Get progress level based on exams attempted
  String get progressLevel {
    if (totalExamsAttempted >= 50) return 'Expert';
    if (totalExamsAttempted >= 20) return 'Advanced';
    if (totalExamsAttempted >= 10) return 'Intermediate';
    if (totalExamsAttempted >= 5) return 'Beginner';
    return 'Starter';
  }

  /// Get progress percentage for level (0-100)
  double get levelProgress {
    final currentLevel = progressLevel;
    switch (currentLevel) {
      case 'Starter':
        return (totalExamsAttempted / 5) * 100;
      case 'Beginner':
        return ((totalExamsAttempted - 5) / 5) * 100;
      case 'Intermediate':
        return ((totalExamsAttempted - 10) / 10) * 100;
      case 'Advanced':
        return ((totalExamsAttempted - 20) / 30) * 100;
      case 'Expert':
        return 100.0;
      default:
        return 0.0;
    }
  }

  UserProgressModel copyWith({
    String? userId,
    int? totalExamsAttempted,
    int? totalExamsPassed,
    double? averageScore,
    int? totalQuestionsAnswered,
    int? totalCorrectAnswers,
    Map<String, int>? categoryProgress,
    Map<String, double>? categoryScores,
    DateTime? lastExamDate,
    int? currentStreak,
    int? longestStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProgressModel(
      userId: userId ?? this.userId,
      totalExamsAttempted: totalExamsAttempted ?? this.totalExamsAttempted,
      totalExamsPassed: totalExamsPassed ?? this.totalExamsPassed,
      averageScore: averageScore ?? this.averageScore,
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      categoryScores: categoryScores ?? this.categoryScores,
      lastExamDate: lastExamDate ?? this.lastExamDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
