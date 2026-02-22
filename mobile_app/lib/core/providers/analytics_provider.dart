import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_analytics_model.dart';
import '../models/platform_analytics_model.dart';
import '../services/analytics_service.dart';
import '../services/realtime_analytics_service.dart';

/// Provider for analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Provider for real-time analytics service
final realtimeAnalyticsServiceProvider =
    Provider<RealtimeAnalyticsService>((ref) {
  return RealtimeAnalyticsService();
});

/// Provider for real-time user analytics stream
final realtimeUserAnalyticsProvider =
    StreamProvider<UserAnalyticsModel?>((ref) {
  final realtimeService = ref.read(realtimeAnalyticsServiceProvider);
  realtimeService.startUserAnalyticsListener();
  return realtimeService.userAnalyticsStream;
});

/// Provider for real-time platform analytics stream
final realtimePlatformAnalyticsProvider =
    StreamProvider<PlatformAnalyticsModel?>((ref) {
  final realtimeService = ref.read(realtimeAnalyticsServiceProvider);
  realtimeService.startPlatformAnalyticsListener();
  return realtimeService.platformAnalyticsStream;
});

/// Provider for real-time recent attempts stream
final realtimeRecentAttemptsProvider =
    StreamProvider.family<List<dynamic>, String?>((ref, userId) {
  final realtimeService = ref.read(realtimeAnalyticsServiceProvider);
  realtimeService.startRecentAttemptsListener(userId: userId);
  return realtimeService.recentAttemptsStream;
});

/// Provider for current user analytics (real-time stream)
/// Changed from FutureProvider to StreamProvider for real-time updates
final currentUserAnalyticsProvider =
    StreamProvider<UserAnalyticsModel?>((ref) async* {
  final realtimeService = ref.read(realtimeAnalyticsServiceProvider);

  // Set current user ID (supports both Firebase Auth and phone auth)
  await realtimeService.setCurrentUserId();

  // Start listening to user analytics
  realtimeService.startUserAnalyticsListener();

  // Yield from the stream
  yield* realtimeService.userAnalyticsStream;
});

/// Provider for user analytics by ID
final userAnalyticsProvider =
    FutureProvider.family<UserAnalyticsModel?, String>((ref, userId) async {
  final analyticsService = ref.read(analyticsServiceProvider);
  return await analyticsService.getUserAnalytics(userId);
});

/// Provider for platform analytics
final platformAnalyticsProvider =
    FutureProvider<PlatformAnalyticsModel?>((ref) async {
  final analyticsService = ref.read(analyticsServiceProvider);
  return await analyticsService.getPlatformAnalytics();
});

/// Provider for top performers
final topPerformersProvider =
    FutureProvider.family<List<UserAnalyticsModel>, int>((ref, limit) async {
  final analyticsService = ref.read(analyticsServiceProvider);
  return await analyticsService.getTopPerformers(limit: limit);
});

/// Provider for user analytics list (admin)
final userAnalyticsListProvider =
    FutureProvider.family<List<UserAnalyticsModel>, AnalyticsListParams>(
        (ref, params) async {
  final analyticsService = ref.read(analyticsServiceProvider);
  return await analyticsService.getUserAnalyticsList(
    limit: params.limit,
    orderBy: params.orderBy,
    descending: params.descending,
  );
});

/// Provider for recent quiz attempts
final recentQuizAttemptsProvider =
    FutureProvider.family<List<dynamic>, RecentAttemptsParams>(
        (ref, params) async {
  final analyticsService = ref.read(analyticsServiceProvider);
  return await analyticsService.getRecentQuizAttempts(
    userId: params.userId,
    limit: params.limit,
  );
});

/// State notifier for real-time analytics updates
class AnalyticsNotifier extends StateNotifier<AsyncValue<UserAnalyticsModel?>> {
  final AnalyticsService _analyticsService;
  final String? _userId;

  AnalyticsNotifier(this._analyticsService, this._userId)
      : super(const AsyncValue.loading()) {
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      if (_userId != null) {
        final analytics = await _analyticsService.getUserAnalytics(_userId!);
        state = AsyncValue.data(analytics);
      } else {
        final analytics = await _analyticsService.getCurrentUserAnalytics();
        state = AsyncValue.data(analytics);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadAnalytics();
  }

  Future<void> updateAfterQuiz(dynamic quizAttempt) async {
    try {
      await _analyticsService.updateUserAnalyticsAfterQuiz(quizAttempt);
      await refresh();
    } catch (error) {
      print('Error updating analytics after quiz: $error');
    }
  }

  /// Force refresh analytics after quiz completion
  Future<void> forceRefreshAfterQuiz() async {
    try {
      // Just refresh the provider state
      await refresh();
    } catch (error) {
      print('Error in force refresh after quiz: $error');
    }
  }

  Future<void> updateActivity(
      {bool isLogin = false, double? sessionDuration}) async {
    if (_userId == null) return;

    try {
      await _analyticsService.updateUserActivity(
        _userId!,
        isLogin: isLogin,
        sessionDuration: sessionDuration,
      );
      await refresh();
    } catch (error) {
      print('Error updating user activity: $error');
    }
  }
}

/// Provider for analytics notifier
final analyticsNotifierProvider = StateNotifierProvider.family<
    AnalyticsNotifier, AsyncValue<UserAnalyticsModel?>, String?>((ref, userId) {
  final analyticsService = ref.read(analyticsServiceProvider);
  return AnalyticsNotifier(analyticsService, userId);
});

/// Provider for current user analytics notifier
final currentUserAnalyticsNotifierProvider =
    StateNotifierProvider<AnalyticsNotifier, AsyncValue<UserAnalyticsModel?>>(
        (ref) {
  final analyticsService = ref.read(analyticsServiceProvider);
  return AnalyticsNotifier(analyticsService, null);
});

/// State notifier for platform analytics
class PlatformAnalyticsNotifier
    extends StateNotifier<AsyncValue<PlatformAnalyticsModel?>> {
  final AnalyticsService _analyticsService;

  PlatformAnalyticsNotifier(this._analyticsService)
      : super(const AsyncValue.loading()) {
    _loadPlatformAnalytics();
  }

  Future<void> _loadPlatformAnalytics() async {
    try {
      final analytics = await _analyticsService.getPlatformAnalytics();
      state = AsyncValue.data(analytics);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPlatformAnalytics();
  }
}

/// Provider for platform analytics notifier
final platformAnalyticsNotifierProvider = StateNotifierProvider<
    PlatformAnalyticsNotifier, AsyncValue<PlatformAnalyticsModel?>>((ref) {
  final analyticsService = ref.read(analyticsServiceProvider);
  return PlatformAnalyticsNotifier(analyticsService);
});

/// Parameters for analytics list queries
class AnalyticsListParams {
  final int limit;
  final String? orderBy;
  final bool descending;

  const AnalyticsListParams({
    this.limit = 50,
    this.orderBy,
    this.descending = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsListParams &&
        other.limit == limit &&
        other.orderBy == orderBy &&
        other.descending == descending;
  }

  @override
  int get hashCode => Object.hash(limit, orderBy, descending);
}

/// Parameters for recent attempts queries
class RecentAttemptsParams {
  final String? userId;
  final int limit;

  const RecentAttemptsParams({
    this.userId,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentAttemptsParams &&
        other.userId == userId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(userId, limit);
}

/// Provider for analytics statistics summary
final analyticsStatsSummaryProvider =
    FutureProvider<AnalyticsStatsSummary>((ref) async {
  final analyticsService = ref.read(analyticsServiceProvider);

  try {
    final currentUserAnalytics =
        await analyticsService.getCurrentUserAnalytics();
    final platformAnalytics = await analyticsService.getPlatformAnalytics();
    final topPerformers = await analyticsService.getTopPerformers(limit: 5);

    return AnalyticsStatsSummary(
      userAnalytics: currentUserAnalytics,
      platformAnalytics: platformAnalytics,
      topPerformers: topPerformers,
    );
  } catch (error) {
    throw Exception('Failed to load analytics summary: $error');
  }
});

/// Analytics statistics summary
class AnalyticsStatsSummary {
  final UserAnalyticsModel? userAnalytics;
  final PlatformAnalyticsModel? platformAnalytics;
  final List<UserAnalyticsModel> topPerformers;

  const AnalyticsStatsSummary({
    this.userAnalytics,
    this.platformAnalytics,
    required this.topPerformers,
  });
}

/// Provider for user ranking
final userRankingProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final analyticsService = ref.read(analyticsServiceProvider);

  try {
    // Get all users ordered by average score
    final allUsers = await analyticsService.getUserAnalyticsList(
      orderBy: 'performance.averageScore',
      descending: true,
      limit: 1000, // Adjust based on your user base
    );

    // Find the user's position
    final userIndex = allUsers.indexWhere((user) => user.userId == userId);
    return userIndex >= 0 ? userIndex + 1 : 0;
  } catch (error) {
    print('Error getting user ranking: $error');
    return 0;
  }
});

/// Provider for analytics dashboard data
final analyticsDashboardProvider =
    FutureProvider<AnalyticsDashboardData>((ref) async {
  final analyticsService = ref.read(analyticsServiceProvider);

  try {
    final platformAnalytics = await analyticsService.getPlatformAnalytics();
    final topPerformers = await analyticsService.getTopPerformers(limit: 10);
    final recentAttempts =
        await analyticsService.getRecentQuizAttempts(limit: 50);

    return AnalyticsDashboardData(
      platformAnalytics: platformAnalytics,
      topPerformers: topPerformers,
      recentAttempts: recentAttempts,
    );
  } catch (error) {
    throw Exception('Failed to load dashboard data: $error');
  }
});

/// Analytics dashboard data
class AnalyticsDashboardData {
  final PlatformAnalyticsModel? platformAnalytics;
  final List<UserAnalyticsModel> topPerformers;
  final List<dynamic> recentAttempts;

  const AnalyticsDashboardData({
    this.platformAnalytics,
    required this.topPerformers,
    required this.recentAttempts,
  });
}
