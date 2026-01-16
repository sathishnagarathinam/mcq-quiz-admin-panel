import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/feedback_model.dart';
import '../models/exam_model.dart';

/// Service for handling user feedback operations
class FeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _feedbackCollection = 'feedback';
  static const String _userFeedbackCollection = 'user_feedback';

  /// Submit feedback for a quiz result
  static Future<bool> submitFeedback({
    required ExamModel exam,
    required int userScore,
    required int totalQuestions,
    required int rating,
    required String comment,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final percentage =
          totalQuestions > 0 ? (userScore / totalQuestions * 100) : 0.0;

      final feedback = FeedbackModel(
        id: '', // Will be set by Firestore
        userId: currentUser.uid,
        userEmail: currentUser.email ?? '',
        userName: currentUser.displayName ?? 'Anonymous User',
        examId: exam.id,
        examName: exam.name,
        examType: exam.examType,
        rating: rating,
        comment: comment,
        userScore: userScore,
        totalQuestions: totalQuestions,
        percentage: percentage,
        submittedAt: DateTime.now(),
        status: FeedbackStatus.pending,
        metadata: {
          'app_version': '1.0.0',
          'platform': 'mobile',
          'exam_type': exam.examType,
          'exam_price': exam.price,
          'exam_is_free': exam.isFree,
        },
      );

      // Save to main feedback collection
      final docRef = await _firestore
          .collection(_feedbackCollection)
          .add(feedback.toFirestore());

      // Also save to user's feedback subcollection for easy querying
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userFeedbackCollection)
          .doc(docRef.id)
          .set(feedback.toFirestore());

      developer.log('Feedback submitted successfully: ${docRef.id}');
      return true;
    } catch (e) {
      developer.log('Error submitting feedback: $e');
      return false;
    }
  }

  /// Get user's feedback history
  static Future<List<FeedbackModel>> getUserFeedbackHistory() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userFeedbackCollection)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      developer.log('Error fetching user feedback history: $e');
      return [];
    }
  }

  /// Check if user has already submitted feedback for an exam
  static Future<bool> hasUserSubmittedFeedback(String examId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userFeedbackCollection)
          .where('examId', isEqualTo: examId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      developer.log('Error checking feedback submission: $e');
      return false;
    }
  }

  /// Get feedback for a specific exam
  static Future<FeedbackModel?> getFeedbackForExam(String examId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userFeedbackCollection)
          .where('examId', isEqualTo: examId)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return FeedbackModel.fromFirestore(querySnapshot.docs.first);
      }

      return null;
    } catch (e) {
      developer.log('Error fetching feedback for exam: $e');
      return null;
    }
  }

  /// Update feedback (for editing)
  static Future<bool> updateFeedback({
    required String feedbackId,
    required int rating,
    required String comment,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final updateData = {
        'rating': rating,
        'comment': comment,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // Update in main feedback collection
      await _firestore
          .collection(_feedbackCollection)
          .doc(feedbackId)
          .update(updateData);

      // Update in user's feedback subcollection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userFeedbackCollection)
          .doc(feedbackId)
          .update(updateData);

      developer.log('Feedback updated successfully: $feedbackId');
      return true;
    } catch (e) {
      developer.log('Error updating feedback: $e');
      return false;
    }
  }

  /// Delete feedback
  static Future<bool> deleteFeedback(String feedbackId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Delete from main feedback collection
      await _firestore.collection(_feedbackCollection).doc(feedbackId).delete();

      // Delete from user's feedback subcollection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userFeedbackCollection)
          .doc(feedbackId)
          .delete();

      developer.log('Feedback deleted successfully: $feedbackId');
      return true;
    } catch (e) {
      developer.log('Error deleting feedback: $e');
      return false;
    }
  }

  /// Get feedback statistics for user
  static Future<Map<String, dynamic>> getUserFeedbackStats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userFeedbackCollection)
          .get();

      final feedbacks = querySnapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();

      if (feedbacks.isEmpty) {
        return {
          'totalFeedbacks': 0,
          'averageRating': 0.0,
          'lastFeedbackDate': null,
          'responseRate': 0.0,
        };
      }

      final totalFeedbacks = feedbacks.length;
      final averageRating =
          feedbacks.map((f) => f.rating).reduce((a, b) => a + b) /
              totalFeedbacks;
      final lastFeedbackDate = feedbacks
          .map((f) => f.submittedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final respondedFeedbacks =
          feedbacks.where((f) => f.hasAdminResponse).length;
      final responseRate = (respondedFeedbacks / totalFeedbacks) * 100;

      return {
        'totalFeedbacks': totalFeedbacks,
        'averageRating': averageRating,
        'lastFeedbackDate': lastFeedbackDate,
        'responseRate': responseRate,
        'ratingDistribution': _getRatingDistribution(feedbacks),
      };
    } catch (e) {
      developer.log('Error fetching feedback stats: $e');
      return {
        'totalFeedbacks': 0,
        'averageRating': 0.0,
        'lastFeedbackDate': null,
        'responseRate': 0.0,
      };
    }
  }

  /// Get rating distribution
  static Map<int, int> _getRatingDistribution(List<FeedbackModel> feedbacks) {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final feedback in feedbacks) {
      distribution[feedback.rating] = (distribution[feedback.rating] ?? 0) + 1;
    }

    return distribution;
  }

  /// Stream of user's feedback
  static Stream<List<FeedbackModel>> getUserFeedbackStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection(_userFeedbackCollection)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc))
            .toList());
  }
}
