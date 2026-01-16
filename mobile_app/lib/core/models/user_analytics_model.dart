import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive user analytics model for detailed statistics
class UserAnalyticsModel {
  final String userId;
  final UserStatistics statistics;
  final UserPerformance performance;
  final UserActivity activity;
  final UserProgress progress;
  final DateTime lastUpdated;

  const UserAnalyticsModel({
    required this.userId,
    required this.statistics,
    required this.performance,
    required this.activity,
    required this.progress,
    required this.lastUpdated,
  });

  factory UserAnalyticsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserAnalyticsModel(
      userId: doc.id,
      statistics: UserStatistics.fromMap(data['statistics'] ?? {}),
      performance: UserPerformance.fromMap(data['performance'] ?? {}),
      activity: UserActivity.fromMap(data['activity'] ?? {}),
      progress: UserProgress.fromMap(data['progress'] ?? {}),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return UserAnalyticsModel(
      userId: json['userId'] ?? '',
      statistics: UserStatistics.fromMap(json['statistics'] ?? {}),
      performance: UserPerformance.fromMap(json['performance'] ?? {}),
      activity: UserActivity.fromMap(json['activity'] ?? {}),
      progress: UserProgress.fromMap(json['progress'] ?? {}),
      lastUpdated: DateTime.parse(
          json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'statistics': statistics.toMap(),
      'performance': performance.toMap(),
      'activity': activity.toMap(),
      'progress': progress.toMap(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'statistics': statistics.toMap(),
      'performance': performance.toMap(),
      'activity': activity.toMap(),
      'progress': progress.toMap(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  UserAnalyticsModel copyWith({
    String? userId,
    UserStatistics? statistics,
    UserPerformance? performance,
    UserActivity? activity,
    UserProgress? progress,
    DateTime? lastUpdated,
  }) {
    return UserAnalyticsModel(
      userId: userId ?? this.userId,
      statistics: statistics ?? this.statistics,
      performance: performance ?? this.performance,
      activity: activity ?? this.activity,
      progress: progress ?? this.progress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Basic user statistics
class UserStatistics {
  final int totalQuizzesAttempted;
  final int totalQuizzesCompleted;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final int totalTimeSpent; // in seconds
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastQuizDate;

  const UserStatistics({
    required this.totalQuizzesAttempted,
    required this.totalQuizzesCompleted,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.totalTimeSpent,
    required this.currentStreak,
    required this.longestStreak,
    this.lastQuizDate,
  });

  factory UserStatistics.fromMap(Map<String, dynamic> map) {
    return UserStatistics(
      totalQuizzesAttempted: map['totalQuizzesAttempted'] ?? 0,
      totalQuizzesCompleted: map['totalQuizzesCompleted'] ?? 0,
      totalQuestionsAnswered: map['totalQuestionsAnswered'] ?? 0,
      totalCorrectAnswers: map['totalCorrectAnswers'] ?? 0,
      totalTimeSpent: map['totalTimeSpent'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastQuizDate: map['lastQuizDate'] != null
          ? (map['lastQuizDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalQuizzesAttempted': totalQuizzesAttempted,
      'totalQuizzesCompleted': totalQuizzesCompleted,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrectAnswers': totalCorrectAnswers,
      'totalTimeSpent': totalTimeSpent,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastQuizDate':
          lastQuizDate != null ? Timestamp.fromDate(lastQuizDate!) : null,
    };
  }

  double get averageScore {
    if (totalQuestionsAnswered == 0) return 0.0;
    return (totalCorrectAnswers / totalQuestionsAnswered) * 100;
  }

  double get completionRate {
    if (totalQuizzesAttempted == 0) return 0.0;
    return (totalQuizzesCompleted / totalQuizzesAttempted) * 100;
  }

  String get formattedTotalTime {
    final hours = totalTimeSpent ~/ 3600;
    final minutes = (totalTimeSpent % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// User performance metrics
class UserPerformance {
  final double bestScore;
  final double averageScore;
  final double worstScore;
  final int bestTime; // in seconds
  final double averageTime;
  final Map<String, double> categoryScores; // category -> average score
  final Map<String, int> categoryAttempts; // category -> attempts count
  final List<ScoreHistory> recentScores;

  const UserPerformance({
    required this.bestScore,
    required this.averageScore,
    required this.worstScore,
    required this.bestTime,
    required this.averageTime,
    required this.categoryScores,
    required this.categoryAttempts,
    required this.recentScores,
  });

  factory UserPerformance.fromMap(Map<String, dynamic> map) {
    return UserPerformance(
      bestScore: (map['bestScore'] ?? 0.0).toDouble(),
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
      worstScore: (map['worstScore'] ?? 0.0).toDouble(),
      bestTime: map['bestTime'] ?? 0,
      averageTime: (map['averageTime'] ?? 0.0).toDouble(),
      categoryScores: Map<String, double>.from(map['categoryScores'] ?? {}),
      categoryAttempts: Map<String, int>.from(map['categoryAttempts'] ?? {}),
      recentScores: (map['recentScores'] as List<dynamic>?)
              ?.map((e) => ScoreHistory.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bestScore': bestScore,
      'averageScore': averageScore,
      'worstScore': worstScore,
      'bestTime': bestTime,
      'averageTime': averageTime,
      'categoryScores': categoryScores,
      'categoryAttempts': categoryAttempts,
      'recentScores': recentScores.map((e) => e.toMap()).toList(),
    };
  }

  String get bestTimeFormatted {
    final minutes = bestTime ~/ 60;
    final seconds = bestTime % 60;
    return '${minutes}m ${seconds}s';
  }

  String get averageTimeFormatted {
    final minutes = averageTime ~/ 60;
    final seconds = (averageTime % 60).round();
    return '${minutes}m ${seconds}s';
  }
}

/// Score history entry
class ScoreHistory {
  final double score;
  final DateTime date;
  final String examType;
  final int timeSpent; // in seconds

  const ScoreHistory({
    required this.score,
    required this.date,
    required this.examType,
    this.timeSpent = 0,
  });

  factory ScoreHistory.fromMap(Map<String, dynamic> map) {
    return ScoreHistory(
      score: (map['score'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      examType: map['examType'] ?? '',
      timeSpent: map['timeSpent'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'date': Timestamp.fromDate(date),
      'examType': examType,
      'timeSpent': timeSpent,
    };
  }

  /// Get formatted time
  String get timeFormatted {
    final minutes = timeSpent ~/ 60;
    final seconds = timeSpent % 60;
    return '${minutes}m ${seconds}s';
  }
}

/// User activity tracking
class UserActivity {
  final int loginCount;
  final DateTime? lastLoginDate;
  final int sessionsThisWeek;
  final int sessionsThisMonth;
  final Map<String, int> dailyActivity; // date -> quiz count
  final List<String> recentExamTypes;
  final double averageSessionDuration; // in minutes

  const UserActivity({
    required this.loginCount,
    this.lastLoginDate,
    required this.sessionsThisWeek,
    required this.sessionsThisMonth,
    required this.dailyActivity,
    required this.recentExamTypes,
    required this.averageSessionDuration,
  });

  factory UserActivity.fromMap(Map<String, dynamic> map) {
    return UserActivity(
      loginCount: map['loginCount'] ?? 0,
      lastLoginDate: map['lastLoginDate'] != null
          ? (map['lastLoginDate'] as Timestamp).toDate()
          : null,
      sessionsThisWeek: map['sessionsThisWeek'] ?? 0,
      sessionsThisMonth: map['sessionsThisMonth'] ?? 0,
      dailyActivity: Map<String, int>.from(map['dailyActivity'] ?? {}),
      recentExamTypes: List<String>.from(map['recentExamTypes'] ?? []),
      averageSessionDuration: (map['averageSessionDuration'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'loginCount': loginCount,
      'lastLoginDate':
          lastLoginDate != null ? Timestamp.fromDate(lastLoginDate!) : null,
      'sessionsThisWeek': sessionsThisWeek,
      'sessionsThisMonth': sessionsThisMonth,
      'dailyActivity': dailyActivity,
      'recentExamTypes': recentExamTypes,
      'averageSessionDuration': averageSessionDuration,
    };
  }

  bool get isActiveUser {
    if (lastLoginDate == null) return false;
    final daysSinceLastLogin = DateTime.now().difference(lastLoginDate!).inDays;
    return daysSinceLastLogin <= 7; // Active if logged in within last week
  }

  String get activityLevel {
    if (sessionsThisWeek >= 5) return 'Very Active';
    if (sessionsThisWeek >= 3) return 'Active';
    if (sessionsThisWeek >= 1) return 'Moderate';
    return 'Inactive';
  }
}

/// User progress and achievements
class UserProgress {
  final String currentLevel;
  final double levelProgress; // 0-100
  final int experiencePoints;
  final List<String> achievements;
  final Map<String, bool> badges;
  final int rank; // Global ranking
  final double improvementRate; // percentage improvement over time

  const UserProgress({
    required this.currentLevel,
    required this.levelProgress,
    required this.experiencePoints,
    required this.achievements,
    required this.badges,
    required this.rank,
    required this.improvementRate,
  });

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      currentLevel: map['currentLevel'] ?? 'Beginner',
      levelProgress: (map['levelProgress'] ?? 0.0).toDouble(),
      experiencePoints: map['experiencePoints'] ?? 0,
      achievements: List<String>.from(map['achievements'] ?? []),
      badges: Map<String, bool>.from(map['badges'] ?? {}),
      rank: map['rank'] ?? 0,
      improvementRate: (map['improvementRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentLevel': currentLevel,
      'levelProgress': levelProgress,
      'experiencePoints': experiencePoints,
      'achievements': achievements,
      'badges': badges,
      'rank': rank,
      'improvementRate': improvementRate,
    };
  }

  String get nextLevel {
    switch (currentLevel) {
      case 'Beginner':
        return 'Intermediate';
      case 'Intermediate':
        return 'Advanced';
      case 'Advanced':
        return 'Expert';
      case 'Expert':
        return 'Master';
      default:
        return 'Master';
    }
  }

  int get pointsToNextLevel {
    switch (currentLevel) {
      case 'Beginner':
        return 500 - experiencePoints;
      case 'Intermediate':
        return 1500 - experiencePoints;
      case 'Advanced':
        return 3000 - experiencePoints;
      case 'Expert':
        return 5000 - experiencePoints;
      default:
        return 0;
    }
  }
}
