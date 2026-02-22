import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quiz_statistics_service.dart';
import '../services/auth_helper_service.dart';

/// Provider for quiz statistics service
final quizStatisticsServiceProvider = Provider<QuizStatisticsService>((ref) {
  return QuizStatisticsService();
});

/// Provider for quiz statistics (attempts, highest score, average rating)
final quizStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, examId) async {
  return QuizStatisticsService.getQuizStatistics(examId);
});

/// Provider for quiz ratings
final quizRatingsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, examId) async {
  return QuizStatisticsService.getQuizRatings(examId);
});

/// Provider for user's quiz attempts
final userQuizAttemptsProvider = FutureProvider.family<List<dynamic>, String>(
  (ref, examId) async {
    final currentUser = await ref.watch(currentUserIdAsyncProvider.future);
    if (currentUser == null) return [];
    return QuizStatisticsService.getUserQuizAttempts(currentUser, examId);
  },
);

/// Provider for user's highest score
final userHighestScoreProvider =
    FutureProvider.family<int?, String>((ref, examId) async {
  final currentUser = await ref.watch(currentUserIdAsyncProvider.future);
  if (currentUser == null) return null;
  return QuizStatisticsService.getUserHighestScore(currentUser, examId);
});

/// Provider for user's previous score
final userPreviousScoreProvider =
    FutureProvider.family<int?, String>((ref, examId) async {
  final currentUser = await ref.watch(currentUserIdAsyncProvider.future);
  if (currentUser == null) return null;
  return QuizStatisticsService.getUserPreviousScore(currentUser, examId);
});

/// Provider for checking if user has attempted a quiz
final userHasAttemptedQuizProvider =
    FutureProvider.family<bool, String>((ref, examId) async {
  final currentUser = await ref.watch(currentUserIdAsyncProvider.future);
  if (currentUser == null) return false;
  return QuizStatisticsService.hasUserAttemptedQuiz(currentUser, examId);
});

/// Provider for current user ID (async version - supports both Firebase Auth and phone auth)
final currentUserIdAsyncProvider = FutureProvider<String?>((ref) async {
  return AuthHelperService.getCurrentUserId();
});

/// Provider for current user ID (sync version - deprecated, use currentUserIdAsyncProvider)
@Deprecated('Use currentUserIdAsyncProvider instead')
final currentUserIdProvider = Provider<String?>((ref) {
  // This is kept for backward compatibility but returns null
  // Use currentUserIdAsyncProvider for proper auth support
  return null;
});
