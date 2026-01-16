import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_progress_model.dart';
import 'mobile_user_auth_provider.dart';

/// User progress service for managing user statistics
class UserProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user progress stream
  static Stream<UserProgressModel?> getUserProgressStream(String userId) {
    return _firestore
        .collection('user_progress')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return _createDefaultProgress(userId);
      }
      return UserProgressModel.fromFirestore(doc);
    });
  }

  /// Get user progress once
  static Future<UserProgressModel?> getUserProgress(String userId) async {
    try {
      final doc =
          await _firestore.collection('user_progress').doc(userId).get();

      if (!doc.exists) {
        return _createDefaultProgress(userId);
      }

      return UserProgressModel.fromFirestore(doc);
    } catch (e) {
      return _createDefaultProgress(userId);
    }
  }

  /// Create default progress for new users
  static UserProgressModel _createDefaultProgress(String userId) {
    return UserProgressModel(
      userId: userId,
      totalExamsAttempted: 0,
      totalExamsPassed: 0,
      averageScore: 0.0,
      totalQuestionsAnswered: 0,
      totalCorrectAnswers: 0,
      categoryProgress: {},
      categoryScores: {},
      lastExamDate: DateTime.now(),
      currentStreak: 0,
      longestStreak: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update user progress after exam completion
  static Future<void> updateProgressAfterExam({
    required String userId,
    required String examCategory,
    required int score,
    required int totalQuestions,
    required bool passed,
  }) async {
    try {
      final docRef = _firestore.collection('user_progress').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        UserProgressModel currentProgress;
        if (doc.exists) {
          currentProgress = UserProgressModel.fromFirestore(doc);
        } else {
          currentProgress = _createDefaultProgress(userId);
        }

        // Calculate new values
        final newTotalExams = currentProgress.totalExamsAttempted + 1;
        final newTotalPassed =
            currentProgress.totalExamsPassed + (passed ? 1 : 0);
        final newTotalQuestions =
            currentProgress.totalQuestionsAnswered + totalQuestions;
        final newTotalCorrect = currentProgress.totalCorrectAnswers + score;

        // Calculate new average score
        final newAverageScore = newTotalQuestions > 0
            ? (newTotalCorrect / newTotalQuestions) * 100
            : 0.0;

        // Update category progress
        final newCategoryProgress =
            Map<String, int>.from(currentProgress.categoryProgress);
        newCategoryProgress[examCategory] =
            (newCategoryProgress[examCategory] ?? 0) + 1;

        // Update category scores
        final newCategoryScores =
            Map<String, double>.from(currentProgress.categoryScores);
        final currentCategoryScore = newCategoryScores[examCategory] ?? 0.0;
        final categoryExamCount = newCategoryProgress[examCategory] ?? 1;
        final examScorePercentage = (score / totalQuestions) * 100;

        newCategoryScores[examCategory] = categoryExamCount == 1
            ? examScorePercentage
            : ((currentCategoryScore * (categoryExamCount - 1)) +
                    examScorePercentage) /
                categoryExamCount;

        // Update streak
        final today = DateTime.now();
        final lastExamDate = currentProgress.lastExamDate;
        final daysDifference = today.difference(lastExamDate).inDays;

        int newCurrentStreak = currentProgress.currentStreak;
        int newLongestStreak = currentProgress.longestStreak;

        if (passed) {
          if (daysDifference <= 1) {
            newCurrentStreak += 1;
          } else {
            newCurrentStreak = 1;
          }
          newLongestStreak = newCurrentStreak > newLongestStreak
              ? newCurrentStreak
              : newLongestStreak;
        } else {
          newCurrentStreak = 0;
        }

        final updatedProgress = currentProgress.copyWith(
          totalExamsAttempted: newTotalExams,
          totalExamsPassed: newTotalPassed,
          averageScore: newAverageScore,
          totalQuestionsAnswered: newTotalQuestions,
          totalCorrectAnswers: newTotalCorrect,
          categoryProgress: newCategoryProgress,
          categoryScores: newCategoryScores,
          lastExamDate: today,
          currentStreak: newCurrentStreak,
          longestStreak: newLongestStreak,
          updatedAt: today,
        );

        transaction.set(docRef, updatedProgress.toFirestore());
      });
    } catch (e) {
      // Handle error silently for now
      print('Error updating user progress: $e');
    }
  }

  /// Initialize progress for new user
  static Future<void> initializeUserProgress(String userId) async {
    try {
      final docRef = _firestore.collection('user_progress').doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        final defaultProgress = _createDefaultProgress(userId);
        await docRef.set(defaultProgress.toFirestore());
      }
    } catch (e) {
      print('Error initializing user progress: $e');
    }
  }
}

/// Provider for current user's progress
final userProgressProvider = StreamProvider<UserProgressModel?>((ref) {
  final authState = ref.watch(mobileUserAuthProvider);
  final user = authState.user;

  if (user == null) {
    return Stream.value(null);
  }

  return UserProgressService.getUserProgressStream(user.uid);
});

/// Provider for user progress once (not stream)
final userProgressOnceProvider = FutureProvider<UserProgressModel?>((ref) {
  final authState = ref.watch(mobileUserAuthProvider);
  final user = authState.user;

  if (user == null) {
    return Future.value(null);
  }

  return UserProgressService.getUserProgress(user.uid);
});
