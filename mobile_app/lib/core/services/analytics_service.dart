import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_analytics_model.dart';
import '../models/platform_analytics_model.dart';
import '../models/quiz_attempt_model.dart';

/// Service for managing user and platform analytics
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user analytics
  Future<UserAnalyticsModel?> getUserAnalytics(String userId) async {
    print('📊 AnalyticsService: Getting analytics for user: $userId');
    try {
      final doc =
          await _firestore.collection('user_analytics').doc(userId).get();

      if (doc.exists) {
        print('✅ AnalyticsService: Found existing analytics for user: $userId');
        return UserAnalyticsModel.fromFirestore(doc);
      }

      print(
          '⚠️ AnalyticsService: No analytics found, creating initial for user: $userId');
      // Create initial analytics if doesn't exist
      return await _createInitialUserAnalytics(userId);
    } catch (e) {
      print('❌ AnalyticsService: Error getting user analytics: $e');
      return null;
    }
  }

  /// Get current user analytics
  Future<UserAnalyticsModel?> getCurrentUserAnalytics() async {
    if (currentUserId == null) return null;

    // Get analytics and backfill if needed
    final analytics = await getUserAnalytics(currentUserId!);
    if (analytics == null) {
      // Try to backfill analytics from existing quiz attempts
      await _backfillUserAnalytics(currentUserId!);
      return await getUserAnalytics(currentUserId!);
    }

    return analytics;
  }

  /// Backfill analytics for users who have quiz attempts but no analytics
  Future<void> _backfillUserAnalytics(String userId) async {
    try {
      // Get all quiz attempts for this user
      final attemptsSnapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt')
          .get();

      if (attemptsSnapshot.docs.isEmpty) {
        // No completed attempts, create initial analytics
        await _createInitialUserAnalytics(userId);
        return;
      }

      // Create initial analytics
      UserAnalyticsModel analytics = await _createInitialUserAnalytics(userId);

      // Process each completed attempt to build up analytics
      for (final doc in attemptsSnapshot.docs) {
        final attempt = QuizAttemptModel.fromFirestore(doc);
        if (attempt.isCompleted && attempt.status == 'completed') {
          // Update analytics with this attempt
          final updatedStatistics =
              _updateStatistics(analytics.statistics, attempt);
          final updatedPerformance =
              _updatePerformance(analytics.performance, attempt);
          final updatedActivity = _updateActivity(analytics.activity, attempt);
          final updatedProgress =
              _updateProgress(analytics.progress, updatedStatistics);

          analytics = analytics.copyWith(
            statistics: updatedStatistics,
            performance: updatedPerformance,
            activity: updatedActivity,
            progress: updatedProgress,
            lastUpdated: DateTime.now(),
          );
        }
      }

      // Save the backfilled analytics
      await _firestore
          .collection('user_analytics')
          .doc(userId)
          .set(analytics.toFirestore());

      print(
          '✅ Backfilled analytics for user $userId with ${attemptsSnapshot.docs.length} quiz attempts');
    } catch (e) {
      print('Error backfilling user analytics: $e');
    }
  }

  /// Update user analytics after quiz completion
  Future<void> updateUserAnalyticsAfterQuiz(QuizAttemptModel attempt) async {
    if (attempt.userId.isEmpty) return;

    try {
      print('📊 Updating analytics for user: ${attempt.userId}');
      print(
          '📝 Attempt details: ${attempt.examName} - Score: ${attempt.score}/${attempt.totalQuestions} - Status: ${attempt.status}');

      final analyticsRef =
          _firestore.collection('user_analytics').doc(attempt.userId);

      UserAnalyticsModel? updatedAnalytics;

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(analyticsRef);

        UserAnalyticsModel analytics;
        if (doc.exists) {
          analytics = UserAnalyticsModel.fromFirestore(doc);
          print('📈 Found existing analytics for user');
        } else {
          analytics = await _createInitialUserAnalytics(attempt.userId);
          print('🆕 Created new analytics for user');
        }

        // Update statistics
        final updatedStatistics =
            _updateStatistics(analytics.statistics, attempt);
        final updatedPerformance =
            _updatePerformance(analytics.performance, attempt);
        final updatedActivity = _updateActivity(analytics.activity, attempt);
        final updatedProgress =
            _updateProgress(analytics.progress, updatedStatistics);

        print(
            '📊 Updated stats - Completed: ${updatedStatistics.totalQuizzesCompleted}, Attempted: ${updatedStatistics.totalQuizzesAttempted}');
        print(
            '🎯 Average score: ${updatedStatistics.averageScore.toStringAsFixed(1)}%');

        final newAnalytics = analytics.copyWith(
          statistics: updatedStatistics,
          performance: updatedPerformance,
          activity: updatedActivity,
          progress: updatedProgress,
          lastUpdated: DateTime.now(),
        );

        transaction.set(analyticsRef, newAnalytics.toFirestore());
        print('✅ Analytics saved to Firestore');

        updatedAnalytics = newAnalytics;
      });

      // Update user document with latest statistics for admin panel (outside transaction)
      if (updatedAnalytics != null) {
        await _updateUserDocumentStats(attempt.userId, updatedAnalytics!);
      }

      // Update platform analytics
      await _updatePlatformAnalytics(attempt);
      print('✅ Platform analytics updated');
      print('✅ User document stats updated');
    } catch (e) {
      print('❌ Error updating user analytics: $e');
      rethrow; // Re-throw to ensure calling code knows about the failure
    }
  }

  /// Update user activity (login, session)
  Future<void> updateUserActivity(
    String userId, {
    bool isLogin = false,
    double? sessionDuration,
  }) async {
    try {
      final analyticsRef = _firestore.collection('user_analytics').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(analyticsRef);

        UserAnalyticsModel analytics;
        if (doc.exists) {
          analytics = UserAnalyticsModel.fromFirestore(doc);
        } else {
          analytics = await _createInitialUserAnalytics(userId);
        }

        UserActivity updatedActivity = analytics.activity;

        if (isLogin) {
          updatedActivity = UserActivity(
            loginCount: analytics.activity.loginCount + 1,
            lastLoginDate: DateTime.now(),
            sessionsThisWeek: _calculateSessionsThisWeek(analytics.activity),
            sessionsThisMonth: _calculateSessionsThisMonth(analytics.activity),
            dailyActivity:
                _updateDailyActivity(analytics.activity.dailyActivity),
            recentExamTypes: analytics.activity.recentExamTypes,
            averageSessionDuration: sessionDuration != null
                ? _calculateAverageSessionDuration(
                    analytics.activity.averageSessionDuration,
                    sessionDuration,
                    analytics.activity.loginCount,
                  )
                : analytics.activity.averageSessionDuration,
          );
        }

        final updatedAnalytics = analytics.copyWith(
          activity: updatedActivity,
          lastUpdated: DateTime.now(),
        );

        transaction.set(analyticsRef, updatedAnalytics.toFirestore());
      });
    } catch (e) {
      print('Error updating user activity: $e');
    }
  }

  /// Get platform analytics
  Future<PlatformAnalyticsModel?> getPlatformAnalytics() async {
    try {
      final doc =
          await _firestore.collection('platform_analytics').doc('global').get();

      if (doc.exists) {
        return PlatformAnalyticsModel.fromFirestore(doc);
      }

      // Generate fresh analytics if doesn't exist
      return await _generatePlatformAnalytics();
    } catch (e) {
      print('Error getting platform analytics: $e');
      return null;
    }
  }

  /// Get user analytics for multiple users (admin function)
  Future<List<UserAnalyticsModel>> getUserAnalyticsList({
    int limit = 50,
    String? orderBy,
    bool descending = true,
  }) async {
    try {
      Query query = _firestore.collection('user_analytics');

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserAnalyticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user analytics list: $e');
      return [];
    }
  }

  /// Get top performers
  Future<List<UserAnalyticsModel>> getTopPerformers({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('user_analytics')
          .orderBy('performance.averageScore', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserAnalyticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting top performers: $e');
      return [];
    }
  }

  /// Get recent quiz attempts for analytics
  Future<List<QuizAttemptModel>> getRecentQuizAttempts({
    String? userId,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('quiz_attempts');

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      query = query.orderBy('attemptedAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => QuizAttemptModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting recent quiz attempts: $e');
      return [];
    }
  }

  /// Create initial user analytics
  Future<UserAnalyticsModel> _createInitialUserAnalytics(String userId) async {
    final analytics = UserAnalyticsModel(
      userId: userId,
      statistics: const UserStatistics(
        totalQuizzesAttempted: 0,
        totalQuizzesCompleted: 0,
        totalQuestionsAnswered: 0,
        totalCorrectAnswers: 0,
        totalTimeSpent: 0,
        currentStreak: 0,
        longestStreak: 0,
      ),
      performance: const UserPerformance(
        bestScore: 0.0,
        averageScore: 0.0,
        worstScore: 0.0,
        bestTime: 0,
        averageTime: 0.0,
        categoryScores: {},
        categoryAttempts: {},
        recentScores: [],
      ),
      activity: UserActivity(
        loginCount: 1,
        lastLoginDate: DateTime.now(),
        sessionsThisWeek: 1,
        sessionsThisMonth: 1,
        dailyActivity: {_getTodayKey(): 0},
        recentExamTypes: [],
        averageSessionDuration: 0.0,
      ),
      progress: const UserProgress(
        currentLevel: 'Beginner',
        levelProgress: 0.0,
        experiencePoints: 0,
        achievements: [],
        badges: {},
        rank: 0,
        improvementRate: 0.0,
      ),
      lastUpdated: DateTime.now(),
    );

    await _firestore
        .collection('user_analytics')
        .doc(userId)
        .set(analytics.toFirestore());

    return analytics;
  }

  /// Update statistics after quiz
  UserStatistics _updateStatistics(
      UserStatistics current, QuizAttemptModel attempt) {
    final isCompleted = attempt.isCompleted && attempt.status == 'completed';

    return UserStatistics(
      totalQuizzesAttempted: current.totalQuizzesAttempted + 1,
      totalQuizzesCompleted: isCompleted
          ? current.totalQuizzesCompleted + 1
          : current.totalQuizzesCompleted,
      totalQuestionsAnswered:
          current.totalQuestionsAnswered + (attempt.totalQuestions ?? 0),
      totalCorrectAnswers:
          current.totalCorrectAnswers + (attempt.correctAnswers ?? 0),
      totalTimeSpent: current.totalTimeSpent + (attempt.timeSpent ?? 0),
      currentStreak: _calculateCurrentStreak(current, attempt),
      longestStreak: _calculateLongestStreak(current, attempt),
      lastQuizDate: attempt.completedAt ?? attempt.attemptedAt,
    );
  }

  /// Update performance metrics
  UserPerformance _updatePerformance(
      UserPerformance current, QuizAttemptModel attempt) {
    if (!attempt.isCompleted || attempt.scorePercentage == null) {
      return current;
    }

    final score = attempt.scorePercentage!;
    final timeSpent = attempt.timeSpent ?? 0;
    final newRecentScores = List<ScoreHistory>.from(current.recentScores);

    newRecentScores.add(ScoreHistory(
      score: score,
      date: attempt.completedAt ?? attempt.attemptedAt,
      examType: attempt.examType,
      timeSpent: timeSpent,
    ));

    // Keep only last 10 scores
    if (newRecentScores.length > 10) {
      newRecentScores.removeAt(0);
    }

    final newCategoryScores = Map<String, double>.from(current.categoryScores);
    final newCategoryAttempts = Map<String, int>.from(current.categoryAttempts);

    // Update category stats
    final category = attempt.examType;
    final currentCategoryScore = newCategoryScores[category] ?? 0.0;
    final currentCategoryAttempts = newCategoryAttempts[category] ?? 0;

    newCategoryScores[category] =
        ((currentCategoryScore * currentCategoryAttempts) + score) /
            (currentCategoryAttempts + 1);
    newCategoryAttempts[category] = currentCategoryAttempts + 1;

    // Calculate new average score from all recent scores
    final allScores = newRecentScores.map((s) => s.score).toList();
    final newAverageScore = allScores.isNotEmpty
        ? allScores.reduce((a, b) => a + b) / allScores.length
        : 0.0;

    // Calculate new average time from all recent scores with valid time data
    final validTimes = newRecentScores
        .where((s) => s.timeSpent > 0) // Only attempts with valid time
        .map((s) => s.timeSpent.toDouble())
        .toList();

    final newAverageTime = validTimes.isNotEmpty
        ? validTimes.reduce((a, b) => a + b) / validTimes.length
        : (timeSpent > 0 ? timeSpent.toDouble() : current.averageTime);

    print('📊 Performance Update:');
    print(
        '   Score: $score% (Best: ${score > current.bestScore ? score : current.bestScore}%)');
    print(
        '   Average Score: ${newAverageScore.toStringAsFixed(1)}% (was: ${current.averageScore.toStringAsFixed(1)}%)');
    print(
        '   Time: ${timeSpent}s (Best: ${timeSpent > 0 && (current.bestTime == 0 || timeSpent < current.bestTime) ? timeSpent : current.bestTime}s)');
    print(
        '   Average Time: ${newAverageTime.toStringAsFixed(1)}s (was: ${current.averageTime.toStringAsFixed(1)}s)');

    return UserPerformance(
      bestScore: score > current.bestScore ? score : current.bestScore,
      averageScore: newAverageScore,
      worstScore: current.worstScore == 0.0 || score < current.worstScore
          ? score
          : current.worstScore,
      bestTime: timeSpent > 0 &&
              (current.bestTime == 0 || timeSpent < current.bestTime)
          ? timeSpent
          : current.bestTime,
      averageTime: newAverageTime,
      categoryScores: newCategoryScores,
      categoryAttempts: newCategoryAttempts,
      recentScores: newRecentScores,
    );
  }

  /// Update activity metrics
  UserActivity _updateActivity(UserActivity current, QuizAttemptModel attempt) {
    final newDailyActivity = Map<String, int>.from(current.dailyActivity);
    final todayKey = _getTodayKey();
    newDailyActivity[todayKey] = (newDailyActivity[todayKey] ?? 0) + 1;

    final newRecentExamTypes = List<String>.from(current.recentExamTypes);
    if (!newRecentExamTypes.contains(attempt.examType)) {
      newRecentExamTypes.add(attempt.examType);
      if (newRecentExamTypes.length > 5) {
        newRecentExamTypes.removeAt(0);
      }
    }

    return UserActivity(
      loginCount: current.loginCount,
      lastLoginDate: current.lastLoginDate,
      sessionsThisWeek: current.sessionsThisWeek,
      sessionsThisMonth: current.sessionsThisMonth,
      dailyActivity: newDailyActivity,
      recentExamTypes: newRecentExamTypes,
      averageSessionDuration: current.averageSessionDuration,
    );
  }

  /// Update progress and achievements
  UserProgress _updateProgress(
      UserProgress current, UserStatistics statistics) {
    final newExperiencePoints = _calculateExperiencePoints(statistics);
    final newLevel = _calculateLevel(newExperiencePoints);
    final newLevelProgress =
        _calculateLevelProgress(newExperiencePoints, newLevel);

    return UserProgress(
      currentLevel: newLevel,
      levelProgress: newLevelProgress,
      experiencePoints: newExperiencePoints,
      achievements: _updateAchievements(current.achievements, statistics),
      badges: _updateBadges(current.badges, statistics),
      rank: current.rank, // Will be updated separately
      improvementRate: _calculateImprovementRate(current, statistics),
    );
  }

  // Helper methods
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int _calculateCurrentStreak(
      UserStatistics current, QuizAttemptModel attempt) {
    // Implementation for calculating current streak
    return current.currentStreak + (attempt.isCompleted ? 1 : 0);
  }

  int _calculateLongestStreak(
      UserStatistics current, QuizAttemptModel attempt) {
    final newStreak = _calculateCurrentStreak(current, attempt);
    return newStreak > current.longestStreak
        ? newStreak
        : current.longestStreak;
  }

  int _calculateSessionsThisWeek(UserActivity activity) {
    // Implementation for calculating sessions this week
    return activity.sessionsThisWeek + 1;
  }

  int _calculateSessionsThisMonth(UserActivity activity) {
    // Implementation for calculating sessions this month
    return activity.sessionsThisMonth + 1;
  }

  Map<String, int> _updateDailyActivity(Map<String, int> current) {
    final updated = Map<String, int>.from(current);
    final todayKey = _getTodayKey();
    updated[todayKey] = (updated[todayKey] ?? 0) + 1;
    return updated;
  }

  double _calculateAverageSessionDuration(
      double current, double newDuration, int sessionCount) {
    if (sessionCount == 0) return newDuration;
    return ((current * sessionCount) + newDuration) / (sessionCount + 1);
  }

  int _calculateExperiencePoints(UserStatistics statistics) {
    return (statistics.totalQuizzesCompleted * 10) +
        (statistics.totalCorrectAnswers * 2) +
        (statistics.currentStreak * 5);
  }

  String _calculateLevel(int experiencePoints) {
    if (experiencePoints >= 5000) return 'Master';
    if (experiencePoints >= 3000) return 'Expert';
    if (experiencePoints >= 1500) return 'Advanced';
    if (experiencePoints >= 500) return 'Intermediate';
    return 'Beginner';
  }

  double _calculateLevelProgress(int experiencePoints, String level) {
    switch (level) {
      case 'Beginner':
        return (experiencePoints / 500) * 100;
      case 'Intermediate':
        return ((experiencePoints - 500) / 1000) * 100;
      case 'Advanced':
        return ((experiencePoints - 1500) / 1500) * 100;
      case 'Expert':
        return ((experiencePoints - 3000) / 2000) * 100;
      default:
        return 100.0;
    }
  }

  List<String> _updateAchievements(
      List<String> current, UserStatistics statistics) {
    final achievements = List<String>.from(current);

    if (statistics.totalQuizzesCompleted >= 1 &&
        !achievements.contains('First Quiz')) {
      achievements.add('First Quiz');
    }
    if (statistics.totalQuizzesCompleted >= 10 &&
        !achievements.contains('Quiz Master')) {
      achievements.add('Quiz Master');
    }
    if (statistics.currentStreak >= 5 &&
        !achievements.contains('Streak Master')) {
      achievements.add('Streak Master');
    }

    return achievements;
  }

  Map<String, bool> _updateBadges(
      Map<String, bool> current, UserStatistics statistics) {
    final badges = Map<String, bool>.from(current);

    badges['perfectScore'] = statistics.totalCorrectAnswers > 0 &&
        statistics.totalCorrectAnswers == statistics.totalQuestionsAnswered;
    badges['speedDemon'] = statistics.totalTimeSpent > 0; // Add speed logic
    badges['consistent'] = statistics.currentStreak >= 7;

    return badges;
  }

  double _calculateImprovementRate(
      UserProgress current, UserStatistics statistics) {
    // Implementation for calculating improvement rate over time
    return current.improvementRate; // Placeholder
  }

  Future<void> _updatePlatformAnalytics(QuizAttemptModel attempt) async {
    // Implementation for updating platform-wide analytics
    // This would aggregate data across all users
  }

  Future<PlatformAnalyticsModel> _generatePlatformAnalytics() async {
    // Implementation for generating fresh platform analytics
    // This would query all user data and generate aggregate statistics
    return PlatformAnalyticsModel(
      registrationStats: const UserRegistrationStats(
        totalUsers: 0,
        activeUsers: 0,
        inactiveUsers: 0,
        dailyRegistrations: {},
        weeklyRegistrations: {},
        monthlyRegistrations: {},
        usersByDesignation: {},
        growthRate: 0.0,
      ),
      engagementStats: const UserEngagementStats(
        averageSessionDuration: 0.0,
        totalSessions: 0,
        sessionsByDay: {},
        engagementByHour: {},
        retentionRate: 0.0,
        averageQuizzesPerUser: 0,
        deviceTypes: {},
      ),
      quizStats: const QuizUsageStats(
        totalQuizAttempts: 0,
        totalQuizCompletions: 0,
        popularCategories: {},
        categoryAverageScores: {},
        overallAverageScore: 0.0,
        totalQuestionsAnswered: 0,
        averageCompletionTime: 0.0,
        difficultyDistribution: {},
      ),
      systemStats: const SystemPerformanceStats(
        averageResponseTime: 0.0,
        uptime: 100.0,
        totalApiCalls: 0,
        errorCounts: {},
        cacheHitRate: 0.0,
        concurrentUsers: 0,
        databasePerformance: 0.0,
      ),
      lastUpdated: DateTime.now(),
    );
  }

  /// Update user document with latest statistics for admin panel
  Future<void> _updateUserDocumentStats(
      String userId, UserAnalyticsModel analytics) async {
    try {
      print('📊 Updating user document stats for: $userId');

      final userRef = _firestore.collection('mobile_users').doc(userId);

      // First check if user document exists
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        print('⚠️ User document does not exist for: $userId');
        print('⚠️ This might indicate a user ID mismatch issue');
        return;
      }

      print('📊 User document exists, updating stats...');
      print(
          '📊 Stats to update: ${analytics.statistics.totalQuizzesCompleted} quizzes, ${analytics.statistics.averageScore.toStringAsFixed(1)}% avg');

      // Update user document with latest statistics
      await userRef.update({
        'quizzesTaken': analytics.statistics.totalQuizzesCompleted,
        'totalScore': analytics.statistics.totalCorrectAnswers,
        'averageScore': analytics.statistics.averageScore,
        'stats.totalQuizzes': analytics.statistics.totalQuizzesCompleted,
        'stats.totalScore': analytics.statistics.totalCorrectAnswers,
        'stats.averageScore': analytics.statistics.averageScore,
        'stats.currentStreak': analytics.statistics.currentStreak,
        'stats.longestStreak': analytics.statistics.longestStreak,
        'stats.totalTimeSpent': analytics.statistics.totalTimeSpent,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ User document updated with latest stats successfully');
      print(
          '✅ Updated fields: quizzesTaken=${analytics.statistics.totalQuizzesCompleted}, averageScore=${analytics.statistics.averageScore.toStringAsFixed(1)}');
    } catch (e) {
      print('❌ Error updating user document stats: $e');
      print('❌ User ID: $userId');
      print(
          '❌ This error might prevent statistics from showing in admin panel');
      // Don't rethrow here as this is a secondary operation, but log more details
    }
  }
}
