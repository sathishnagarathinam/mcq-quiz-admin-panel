import 'package:cloud_firestore/cloud_firestore.dart';

/// Platform-wide analytics model for admin dashboard
class PlatformAnalyticsModel {
  final UserRegistrationStats registrationStats;
  final UserEngagementStats engagementStats;
  final QuizUsageStats quizStats;
  final SystemPerformanceStats systemStats;
  final DateTime lastUpdated;

  const PlatformAnalyticsModel({
    required this.registrationStats,
    required this.engagementStats,
    required this.quizStats,
    required this.systemStats,
    required this.lastUpdated,
  });

  factory PlatformAnalyticsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PlatformAnalyticsModel(
      registrationStats:
          UserRegistrationStats.fromMap(data['registrationStats'] ?? {}),
      engagementStats:
          UserEngagementStats.fromMap(data['engagementStats'] ?? {}),
      quizStats: QuizUsageStats.fromMap(data['quizStats'] ?? {}),
      systemStats: SystemPerformanceStats.fromMap(data['systemStats'] ?? {}),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PlatformAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return PlatformAnalyticsModel(
      registrationStats:
          UserRegistrationStats.fromMap(json['registrationStats'] ?? {}),
      engagementStats:
          UserEngagementStats.fromMap(json['engagementStats'] ?? {}),
      quizStats: QuizUsageStats.fromMap(json['quizStats'] ?? {}),
      systemStats: SystemPerformanceStats.fromMap(json['systemStats'] ?? {}),
      lastUpdated: DateTime.parse(
          json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'registrationStats': registrationStats.toMap(),
      'engagementStats': engagementStats.toMap(),
      'quizStats': quizStats.toMap(),
      'systemStats': systemStats.toMap(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'registrationStats': registrationStats.toMap(),
      'engagementStats': engagementStats.toMap(),
      'quizStats': quizStats.toMap(),
      'systemStats': systemStats.toMap(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// User registration statistics
class UserRegistrationStats {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final Map<String, int> dailyRegistrations; // date -> count
  final Map<String, int> weeklyRegistrations; // week -> count
  final Map<String, int> monthlyRegistrations; // month -> count
  final Map<String, int> usersByDesignation; // designation -> count
  final double growthRate; // percentage growth

  const UserRegistrationStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.dailyRegistrations,
    required this.weeklyRegistrations,
    required this.monthlyRegistrations,
    required this.usersByDesignation,
    required this.growthRate,
  });

  factory UserRegistrationStats.fromMap(Map<String, dynamic> map) {
    return UserRegistrationStats(
      totalUsers: map['totalUsers'] ?? 0,
      activeUsers: map['activeUsers'] ?? 0,
      inactiveUsers: map['inactiveUsers'] ?? 0,
      dailyRegistrations:
          Map<String, int>.from(map['dailyRegistrations'] ?? {}),
      weeklyRegistrations:
          Map<String, int>.from(map['weeklyRegistrations'] ?? {}),
      monthlyRegistrations:
          Map<String, int>.from(map['monthlyRegistrations'] ?? {}),
      usersByDesignation:
          Map<String, int>.from(map['usersByDesignation'] ?? {}),
      growthRate: (map['growthRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'inactiveUsers': inactiveUsers,
      'dailyRegistrations': dailyRegistrations,
      'weeklyRegistrations': weeklyRegistrations,
      'monthlyRegistrations': monthlyRegistrations,
      'usersByDesignation': usersByDesignation,
      'growthRate': growthRate,
    };
  }

  double get activeUserPercentage {
    if (totalUsers == 0) return 0.0;
    return (activeUsers / totalUsers) * 100;
  }

  int get registrationsThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';
    return weeklyRegistrations[weekKey] ?? 0;
  }

  int get registrationsThisMonth {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return monthlyRegistrations[monthKey] ?? 0;
  }

  static int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysSinceStartOfYear = date.difference(startOfYear).inDays;
    return (daysSinceStartOfYear / 7).ceil();
  }
}

/// User engagement statistics
class UserEngagementStats {
  final double averageSessionDuration; // in minutes
  final int totalSessions;
  final Map<String, int> sessionsByDay; // day -> count
  final Map<String, double> engagementByHour; // hour -> engagement score
  final double retentionRate; // percentage
  final int averageQuizzesPerUser;
  final Map<String, int> deviceTypes; // device type -> count

  const UserEngagementStats({
    required this.averageSessionDuration,
    required this.totalSessions,
    required this.sessionsByDay,
    required this.engagementByHour,
    required this.retentionRate,
    required this.averageQuizzesPerUser,
    required this.deviceTypes,
  });

  factory UserEngagementStats.fromMap(Map<String, dynamic> map) {
    return UserEngagementStats(
      averageSessionDuration: (map['averageSessionDuration'] ?? 0.0).toDouble(),
      totalSessions: map['totalSessions'] ?? 0,
      sessionsByDay: Map<String, int>.from(map['sessionsByDay'] ?? {}),
      engagementByHour: Map<String, double>.from(map['engagementByHour'] ?? {}),
      retentionRate: (map['retentionRate'] ?? 0.0).toDouble(),
      averageQuizzesPerUser: map['averageQuizzesPerUser'] ?? 0,
      deviceTypes: Map<String, int>.from(map['deviceTypes'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageSessionDuration': averageSessionDuration,
      'totalSessions': totalSessions,
      'sessionsByDay': sessionsByDay,
      'engagementByHour': engagementByHour,
      'retentionRate': retentionRate,
      'averageQuizzesPerUser': averageQuizzesPerUser,
      'deviceTypes': deviceTypes,
    };
  }

  String get peakEngagementHour {
    if (engagementByHour.isEmpty) return 'N/A';
    final maxEntry = engagementByHour.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final hour = int.parse(maxEntry.key);
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  String get mostActiveDay {
    if (sessionsByDay.isEmpty) return 'N/A';
    final maxEntry = sessionsByDay.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return maxEntry.key;
  }
}

/// Quiz usage statistics
class QuizUsageStats {
  final int totalQuizAttempts;
  final int totalQuizCompletions;
  final Map<String, int> popularCategories; // category -> attempts
  final Map<String, double> categoryAverageScores; // category -> avg score
  final double overallAverageScore;
  final int totalQuestionsAnswered;
  final double averageCompletionTime; // in minutes
  final Map<String, int> difficultyDistribution; // difficulty -> count

  const QuizUsageStats({
    required this.totalQuizAttempts,
    required this.totalQuizCompletions,
    required this.popularCategories,
    required this.categoryAverageScores,
    required this.overallAverageScore,
    required this.totalQuestionsAnswered,
    required this.averageCompletionTime,
    required this.difficultyDistribution,
  });

  factory QuizUsageStats.fromMap(Map<String, dynamic> map) {
    return QuizUsageStats(
      totalQuizAttempts: map['totalQuizAttempts'] ?? 0,
      totalQuizCompletions: map['totalQuizCompletions'] ?? 0,
      popularCategories: Map<String, int>.from(map['popularCategories'] ?? {}),
      categoryAverageScores:
          Map<String, double>.from(map['categoryAverageScores'] ?? {}),
      overallAverageScore: (map['overallAverageScore'] ?? 0.0).toDouble(),
      totalQuestionsAnswered: map['totalQuestionsAnswered'] ?? 0,
      averageCompletionTime: (map['averageCompletionTime'] ?? 0.0).toDouble(),
      difficultyDistribution:
          Map<String, int>.from(map['difficultyDistribution'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalQuizAttempts': totalQuizAttempts,
      'totalQuizCompletions': totalQuizCompletions,
      'popularCategories': popularCategories,
      'categoryAverageScores': categoryAverageScores,
      'overallAverageScore': overallAverageScore,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'averageCompletionTime': averageCompletionTime,
      'difficultyDistribution': difficultyDistribution,
    };
  }

  double get completionRate {
    if (totalQuizAttempts == 0) return 0.0;
    return (totalQuizCompletions / totalQuizAttempts) * 100;
  }

  String get mostPopularCategory {
    if (popularCategories.isEmpty) return 'N/A';
    final maxEntry = popularCategories.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return maxEntry.key;
  }

  String get averageCompletionTimeFormatted {
    final minutes = averageCompletionTime.floor();
    final seconds = ((averageCompletionTime - minutes) * 60).round();
    return '${minutes}m ${seconds}s';
  }
}

/// System performance statistics
class SystemPerformanceStats {
  final double averageResponseTime; // in milliseconds
  final double uptime; // percentage
  final int totalApiCalls;
  final Map<String, int> errorCounts; // error type -> count
  final double cacheHitRate; // percentage
  final int concurrentUsers;
  final double databasePerformance; // query time in ms

  const SystemPerformanceStats({
    required this.averageResponseTime,
    required this.uptime,
    required this.totalApiCalls,
    required this.errorCounts,
    required this.cacheHitRate,
    required this.concurrentUsers,
    required this.databasePerformance,
  });

  factory SystemPerformanceStats.fromMap(Map<String, dynamic> map) {
    return SystemPerformanceStats(
      averageResponseTime: (map['averageResponseTime'] ?? 0.0).toDouble(),
      uptime: (map['uptime'] ?? 0.0).toDouble(),
      totalApiCalls: map['totalApiCalls'] ?? 0,
      errorCounts: Map<String, int>.from(map['errorCounts'] ?? {}),
      cacheHitRate: (map['cacheHitRate'] ?? 0.0).toDouble(),
      concurrentUsers: map['concurrentUsers'] ?? 0,
      databasePerformance: (map['databasePerformance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageResponseTime': averageResponseTime,
      'uptime': uptime,
      'totalApiCalls': totalApiCalls,
      'errorCounts': errorCounts,
      'cacheHitRate': cacheHitRate,
      'concurrentUsers': concurrentUsers,
      'databasePerformance': databasePerformance,
    };
  }

  String get systemHealth {
    if (uptime >= 99.5 && averageResponseTime < 500) return 'Excellent';
    if (uptime >= 99.0 && averageResponseTime < 1000) return 'Good';
    if (uptime >= 95.0 && averageResponseTime < 2000) return 'Fair';
    return 'Poor';
  }

  int get totalErrors {
    return errorCounts.values
        .fold(0, (totalSum, totalCount) => totalSum + totalCount);
  }

  double get errorRate {
    if (totalApiCalls == 0) return 0.0;
    return (totalErrors / totalApiCalls) * 100;
  }
}
