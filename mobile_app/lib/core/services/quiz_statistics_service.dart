import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/feedback_model.dart';

/// Service for managing quiz statistics and ratings
class QuizStatisticsService {
  static final _firestore = FirebaseFirestore.instance;
  static const String _feedbackCollection = 'feedback';
  static const String _quizStatsCollection = 'quiz_statistics';

  /// Get quiz statistics (attempts, highest score, average rating)
  static Future<Map<String, dynamic>> getQuizStatistics(String examId) async {
    try {
      // Query attempts from the top-level quiz_attempts collection
      final topLevelAttemptsSnapshot = await _firestore
          .collection('quiz_attempts')
          .where('examId', isEqualTo: examId)
          .get();

      int totalAttempts = topLevelAttemptsSnapshot.docs.length;
      int highestScore = 0;

      // Find highest score among all attempts
      for (final attemptDoc in topLevelAttemptsSnapshot.docs) {
        final score = attemptDoc['score'] as int? ?? 0;
        if (score > highestScore) {
          highestScore = score;
        }
      }

      developer.log(
          'Quiz Statistics for $examId: totalAttempts=$totalAttempts, highestScore=$highestScore');

      // Get feedback for ratings
      final feedbackSnapshot = await _firestore
          .collection(_feedbackCollection)
          .where('examId', isEqualTo: examId)
          .get();

      final feedbacks = feedbackSnapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();

      // Calculate rating statistics
      double averageRating = 0.0;
      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      if (feedbacks.isNotEmpty) {
        final totalRating =
            feedbacks.fold<int>(0, (total, f) => total + f.rating);
        averageRating = totalRating / feedbacks.length;

        for (final feedback in feedbacks) {
          ratingDistribution[feedback.rating] =
              (ratingDistribution[feedback.rating] ?? 0) + 1;
        }
      }

      return {
        'totalAttempts': totalAttempts,
        'highestScore': highestScore,
        'averageRating': double.parse(averageRating.toStringAsFixed(1)),
        'totalRatings': feedbacks.length,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      developer.log('Error getting quiz statistics: $e');
      return {
        'totalAttempts': 0,
        'highestScore': 0,
        'averageRating': 0.0,
        'totalRatings': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  /// Get all ratings and reviews for a quiz
  static Future<List<FeedbackModel>> getQuizRatings(String examId) async {
    try {
      final snapshot = await _firestore
          .collection(_feedbackCollection)
          .where('examId', isEqualTo: examId)
          .get();

      final feedbacks =
          snapshot.docs.map((doc) => FeedbackModel.fromFirestore(doc)).toList();

      // Sort by submittedAt in descending order (newest first)
      feedbacks.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      return feedbacks;
    } catch (e) {
      developer.log('Error getting quiz ratings: $e');
      return [];
    }
  }

  /// Get user's previous attempts for a quiz
  static Future<List<Map<String, dynamic>>> getUserQuizAttempts(
    String userId,
    String examId,
  ) async {
    try {
      // Query from top-level quiz_attempts collection (where attempts are actually saved)
      final snapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: userId)
          .where('examId', isEqualTo: examId)
          .where('status', isEqualTo: 'completed')
          .get();

      developer.log(
          'getUserQuizAttempts: Found ${snapshot.docs.length} attempts for user $userId, exam $examId');

      // Sort by attemptedAt in descending order (newest first)
      final attempts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      attempts.sort((a, b) {
        final aTime = a['attemptedAt'] as Timestamp?;
        final bTime = b['attemptedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return attempts;
    } catch (e) {
      developer.log('Error getting user quiz attempts: $e');
      return [];
    }
  }

  /// Get user's highest score for a quiz
  static Future<int?> getUserHighestScore(String userId, String examId) async {
    try {
      final attempts = await getUserQuizAttempts(userId, examId);
      if (attempts.isEmpty) return null;

      final scores = attempts.map((a) => a['score'] as int? ?? 0).toList();
      return scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b);
    } catch (e) {
      developer.log('Error getting user highest score: $e');
      return null;
    }
  }

  /// Check if user has previously attempted a quiz
  static Future<bool> hasUserAttemptedQuiz(
    String userId,
    String examId,
  ) async {
    try {
      final attempts = await getUserQuizAttempts(userId, examId);
      return attempts.isNotEmpty;
    } catch (e) {
      developer.log('Error checking user quiz attempt: $e');
      return false;
    }
  }

  /// Get user's previous score for a quiz
  static Future<int?> getUserPreviousScore(
    String userId,
    String examId,
  ) async {
    try {
      final attempts = await getUserQuizAttempts(userId, examId);
      if (attempts.length < 2) return null; // Need at least 2 attempts

      // Return second most recent score
      return attempts[1]['score'] as int?;
    } catch (e) {
      developer.log('Error getting user previous score: $e');
      return null;
    }
  }
}
