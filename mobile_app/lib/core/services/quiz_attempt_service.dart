import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_attempt_model.dart';
import '../models/exam_model.dart';
import 'analytics_service.dart';

/// Service for managing quiz attempts
class QuizAttemptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analyticsService = AnalyticsService();

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Start a new quiz attempt
  Future<String> startQuizAttempt(ExamModel exam) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final attempt = QuizAttemptModel(
        id: '', // Will be set by Firestore
        userId: currentUserId!,
        examId: exam.id,
        examName: exam.name,
        examType: exam.examType,
        attemptedAt: DateTime.now(),
        isCompleted: false,
        status: 'in_progress',
        totalQuestions: exam.numberOfQuestions,
      );

      final docRef = await _firestore
          .collection('quiz_attempts')
          .add(attempt.toFirestore());

      // Also increment the exam's total attempts
      await _incrementExamAttempts(exam.id);

      return docRef.id;
    } catch (e) {
      print('Error starting quiz attempt: $e');
      rethrow;
    }
  }

  /// Complete a quiz attempt
  Future<void> completeQuizAttempt({
    required String attemptId,
    required int score,
    required int correctAnswers,
    required int timeSpent,
    Map<String, dynamic>? answers,
  }) async {
    try {
      print('🔄 Completing quiz attempt: $attemptId');

      // Calculate score percentage for consistency
      final attemptDoc =
          await _firestore.collection('quiz_attempts').doc(attemptId).get();
      if (!attemptDoc.exists) {
        throw Exception('Quiz attempt not found: $attemptId');
      }

      final attemptData = attemptDoc.data() as Map<String, dynamic>;
      final totalQuestions = attemptData['totalQuestions'] as int? ?? 1;
      final scorePercentage = (score / totalQuestions * 100).round();

      // Update the quiz attempt document with all necessary fields
      await _firestore.collection('quiz_attempts').doc(attemptId).update({
        'completedAt': FieldValue.serverTimestamp(),
        'score': score,
        'correctAnswers': correctAnswers,
        'timeSpent': timeSpent,
        'isCompleted': true,
        'status': 'completed',
        'answers': answers,
        'scorePercentage':
            scorePercentage, // Add percentage for web app compatibility
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Quiz attempt updated in Firestore');

      // Get the updated quiz attempt to trigger analytics update
      final updatedAttemptDoc =
          await _firestore.collection('quiz_attempts').doc(attemptId).get();
      if (updatedAttemptDoc.exists) {
        final attempt = QuizAttemptModel.fromFirestore(updatedAttemptDoc);
        print('📊 Triggering analytics update for user: ${attempt.userId}');

        // Update user analytics with the completed quiz
        await _analyticsService.updateUserAnalyticsAfterQuiz(attempt);
        print('✅ Analytics updated successfully');
      }
    } catch (e) {
      print('❌ Error completing quiz attempt: $e');
      rethrow;
    }
  }

  /// Abandon a quiz attempt
  Future<void> abandonQuizAttempt(String attemptId) async {
    try {
      await _firestore.collection('quiz_attempts').doc(attemptId).update({
        'status': 'abandoned',
      });
    } catch (e) {
      print('Error abandoning quiz attempt: $e');
      rethrow;
    }
  }

  /// Get user's recent quiz attempts
  Stream<List<QuizAttemptModel>> getUserRecentAttempts({int limit = 10}) {
    // Get current user ID
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(<QuizAttemptModel>[]);
    }

    // Clean up any test data on first load
    cleanupTestQuizAttempts();

    // Return a stream that listens to Firestore changes
    return _firestore
        .collection('quiz_attempts')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('attemptedAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return <QuizAttemptModel>[];
      }

      final attempts = snapshot.docs
          .map((doc) => QuizAttemptModel.fromFirestore(doc))
          .toList();

      return attempts;
    }).handleError((error) {
      return <QuizAttemptModel>[];
    });
  }

  /// Get user's attempts for a specific exam
  Stream<List<QuizAttemptModel>> getUserExamAttempts(String examId) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('quiz_attempts')
        .where('userId', isEqualTo: currentUserId)
        .where('examId', isEqualTo: examId)
        .orderBy('attemptedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => QuizAttemptModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get user's best score for an exam
  Future<QuizAttemptModel?> getUserBestScore(String examId) async {
    if (currentUserId == null) return null;

    try {
      final snapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: currentUserId)
          .where('examId', isEqualTo: examId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('score', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return QuizAttemptModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get user's quiz statistics
  Future<Map<String, dynamic>> getUserQuizStats() async {
    if (currentUserId == null) {
      return {
        'totalAttempts': 0,
        'completedQuizzes': 0,
        'averageScore': 0.0,
        'totalTimeSpent': 0,
      };
    }

    try {
      final snapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: currentUserId)
          .get();

      final attempts = snapshot.docs
          .map((doc) => QuizAttemptModel.fromFirestore(doc))
          .toList();

      final completedAttempts = attempts.where((a) => a.isCompleted).toList();

      double averageScore = 0.0;
      int totalTimeSpent = 0;

      if (completedAttempts.isNotEmpty) {
        final totalScore = completedAttempts
            .where((a) => a.score != null)
            .fold(0, (totalSum, a) => totalSum + a.score!);

        final validScores =
            completedAttempts.where((a) => a.score != null).length;
        if (validScores > 0) {
          averageScore = totalScore / validScores;
        }

        totalTimeSpent = completedAttempts
            .where((a) => a.timeSpent != null)
            .fold(0, (totalSum, a) => totalSum + a.timeSpent!);
      }

      return {
        'totalAttempts': attempts.length,
        'completedQuizzes': completedAttempts.length,
        'averageScore': averageScore,
        'totalTimeSpent': totalTimeSpent,
      };
    } catch (e) {
      return {
        'totalAttempts': 0,
        'completedQuizzes': 0,
        'averageScore': 0.0,
        'totalTimeSpent': 0,
      };
    }
  }

  /// Check if user has attempted an exam
  Future<bool> hasUserAttemptedExam(String examId) async {
    if (currentUserId == null) return false;

    try {
      final snapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: currentUserId)
          .where('examId', isEqualTo: examId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get user's last attempt for an exam
  Future<QuizAttemptModel?> getUserLastAttempt(String examId) async {
    if (currentUserId == null) return null;

    try {
      final snapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: currentUserId)
          .where('examId', isEqualTo: examId)
          .orderBy('attemptedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return QuizAttemptModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Increment exam's total attempts count
  Future<void> _incrementExamAttempts(String examId) async {
    try {
      final examRef = _firestore.collection('exams').doc(examId);

      await _firestore.runTransaction((transaction) async {
        final examDoc = await transaction.get(examRef);

        if (examDoc.exists) {
          final currentAttempts = examDoc.data()?['totalAttempts'] ?? 0;
          transaction.update(examRef, {
            'totalAttempts': currentAttempts + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // Silently handle error
    }
  }

  /// Delete a quiz attempt
  Future<void> deleteQuizAttempt(String attemptId) async {
    try {
      await _firestore.collection('quiz_attempts').doc(attemptId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Clean up test quiz attempts (for debugging)
  Future<void> cleanupTestQuizAttempts() async {
    if (currentUserId == null) return;

    try {
      // Get all quiz attempts for current user
      final snapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: currentUserId)
          .get();

      // Delete test attempts (those with specific test exam IDs)
      final testExamIds = [
        'postal-guide-001',
        'postal-volumes-001',
        'general-knowledge-001'
      ];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final examId = data['examId'] as String?;

        if (examId != null && testExamIds.contains(examId)) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      // Silently handle error
    }
  }

  /// Get all attempts for admin (for analytics)
  Stream<List<QuizAttemptModel>> getAllAttempts({int limit = 100}) {
    return _firestore
        .collection('quiz_attempts')
        .orderBy('attemptedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => QuizAttemptModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get attempts for a specific exam (for admin analytics)
  Stream<List<QuizAttemptModel>> getExamAttempts(String examId,
      {int limit = 50}) {
    return _firestore
        .collection('quiz_attempts')
        .where('examId', isEqualTo: examId)
        .orderBy('attemptedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => QuizAttemptModel.fromFirestore(doc))
          .toList();
    });
  }
}
