import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_attempt_model.dart';
import '../services/quiz_attempt_service.dart';

/// Provider for quiz attempt service
final quizAttemptServiceProvider = Provider<QuizAttemptService>((ref) {
  return QuizAttemptService();
});

/// Provider for user's recent quiz attempts
final userRecentAttemptsProvider =
    StreamProvider.family<List<QuizAttemptModel>, int>((ref, limit) {
  final service = ref.read(quizAttemptServiceProvider);
  return service.getUserRecentAttempts(limit: limit);
});

/// Provider for user's attempts for a specific exam
final userExamAttemptsProvider =
    StreamProvider.family<List<QuizAttemptModel>, String>((ref, examId) {
  final service = ref.read(quizAttemptServiceProvider);
  return service.getUserExamAttempts(examId);
});

/// Provider for user's best score for an exam
final userBestScoreProvider =
    FutureProvider.family<QuizAttemptModel?, String>((ref, examId) {
  final service = ref.read(quizAttemptServiceProvider);
  return service.getUserBestScore(examId);
});

/// Provider for user's quiz statistics
final userQuizStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final service = ref.read(quizAttemptServiceProvider);
  return service.getUserQuizStats();
});

/// Provider for checking if user has attempted an exam
final hasUserAttemptedExamProvider =
    FutureProvider.family<bool, String>((ref, examId) {
  final service = ref.read(quizAttemptServiceProvider);
  return service.hasUserAttemptedExam(examId);
});

/// Provider for user's last attempt for an exam
final userLastAttemptProvider =
    FutureProvider.family<QuizAttemptModel?, String>((ref, examId) {
  final service = ref.read(quizAttemptServiceProvider);
  return service.getUserLastAttempt(examId);
});

/// Provider for all attempts (admin use)
final allAttemptsProvider =
    StreamProvider.family<List<QuizAttemptModel>, int>((ref, limit) {
  final service = ref.read(quizAttemptServiceProvider);
  return service.getAllAttempts(limit: limit);
});

/// Provider for exam attempts (admin analytics)
final examAttemptsProvider =
    StreamProvider.family<List<QuizAttemptModel>, String>((ref, examId) {
  final service = ref.read(quizAttemptServiceProvider);
  return service.getExamAttempts(examId);
});

/// State notifier for managing current quiz attempt
class CurrentQuizAttemptNotifier extends StateNotifier<QuizAttemptModel?> {
  CurrentQuizAttemptNotifier(this._service) : super(null);

  final QuizAttemptService _service;

  /// Start a new quiz attempt
  Future<String> startAttempt(dynamic exam) async {
    try {
      final attemptId = await _service.startQuizAttempt(exam);

      // Create a new attempt model with the generated ID
      final attempt = QuizAttemptModel(
        id: attemptId,
        userId: _service.currentUserId!,
        examId: exam.id,
        examName: exam.name,
        examType: exam.examType,
        attemptedAt: DateTime.now(),
        isCompleted: false,
        status: 'in_progress',
        totalQuestions: exam.numberOfQuestions,
      );

      state = attempt;
      return attemptId;
    } catch (e) {
      print('Error starting attempt: $e');
      rethrow;
    }
  }

  /// Complete the current attempt
  Future<void> completeAttempt({
    required int score,
    required int correctAnswers,
    required int timeSpent,
    Map<String, dynamic>? answers,
  }) async {
    if (state == null) return;

    try {
      await _service.completeQuizAttempt(
        attemptId: state!.id,
        score: score,
        correctAnswers: correctAnswers,
        timeSpent: timeSpent,
        answers: answers,
      );

      // Update the state
      state = state!.copyWith(
        completedAt: DateTime.now(),
        score: score,
        correctAnswers: correctAnswers,
        timeSpent: timeSpent,
        isCompleted: true,
        status: 'completed',
        answers: answers,
      );
    } catch (e) {
      print('Error completing attempt: $e');
      rethrow;
    }
  }

  /// Abandon the current attempt
  Future<void> abandonAttempt() async {
    if (state == null) return;

    try {
      await _service.abandonQuizAttempt(state!.id);

      // Update the state
      state = state!.copyWith(status: 'abandoned');
    } catch (e) {
      print('Error abandoning attempt: $e');
      rethrow;
    }
  }

  /// Clear the current attempt
  void clearAttempt() {
    state = null;
  }

  /// Update attempt progress (for saving intermediate state)
  void updateProgress({
    Map<String, dynamic>? answers,
    int? timeSpent,
  }) {
    if (state == null) return;

    state = state!.copyWith(
      answers: answers ?? state!.answers,
      timeSpent: timeSpent ?? state!.timeSpent,
    );
  }
}

/// Provider for current quiz attempt
final currentQuizAttemptProvider =
    StateNotifierProvider<CurrentQuizAttemptNotifier, QuizAttemptModel?>((ref) {
  final service = ref.read(quizAttemptServiceProvider);
  return CurrentQuizAttemptNotifier(service);
});

/// Provider for recent attempts with exam details
final recentAttemptsWithDetailsProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final attemptsAsync = ref.watch(userRecentAttemptsProvider(10));

  return attemptsAsync.when(
    data: (attempts) {
      final attemptsWithDetails = <Map<String, dynamic>>[];

      for (final attempt in attempts) {
        attemptsWithDetails.add({
          'attempt': attempt,
          'examId': attempt.examId,
          'examName': attempt.examName,
          'examType': attempt.examType,
        });
      }

      return AsyncValue.data(attemptsWithDetails);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for user's completion rate
final userCompletionRateProvider = FutureProvider<double>((ref) async {
  final stats = await ref.read(userQuizStatsProvider.future);
  final totalAttempts = stats['totalAttempts'] as int;
  final completedQuizzes = stats['completedQuizzes'] as int;

  if (totalAttempts == 0) return 0.0;
  return (completedQuizzes / totalAttempts) * 100;
});

/// Provider for user's average score
final userAverageScoreProvider = FutureProvider<double>((ref) async {
  final stats = await ref.read(userQuizStatsProvider.future);
  return stats['averageScore'] as double;
});
