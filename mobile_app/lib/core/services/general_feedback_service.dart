import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/general_feedback_model.dart';

/// Service for managing general user feedback
class GeneralFeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _feedbackCollection = 'general_feedback';
  static const String _userFeedbackCollection = 'general_feedback';

  /// Submit general feedback
  static Future<bool> submitGeneralFeedback({
    required String category,
    required String subject,
    required String message,
    required int rating,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final feedback = GeneralFeedbackModel(
        id: '', // Will be set by Firestore
        userId: currentUser.uid,
        userEmail: currentUser.email ?? '',
        userName: currentUser.displayName ?? 'Anonymous User',
        category: category,
        subject: subject,
        message: message,
        rating: rating,
        submittedAt: DateTime.now(),
        status: FeedbackStatus.pending,
        metadata: {
          'app_version': '1.0.0',
          'platform': 'mobile',
          'feedback_type': 'general',
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

      developer.log('General feedback submitted successfully: ${docRef.id}');
      return true;
    } catch (e) {
      developer.log('Error submitting general feedback: $e');
      return false;
    }
  }

  /// Get user's general feedback history
  static Future<List<GeneralFeedbackModel>> getUserFeedbackHistory() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_feedbackCollection)
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GeneralFeedbackModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      developer.log('Error getting user feedback history: $e');
      return [];
    }
  }

  /// Stream of user's general feedback with real-time updates
  static Stream<List<GeneralFeedbackModel>> getUserFeedbackStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_feedbackCollection)
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GeneralFeedbackModel.fromFirestore(doc))
            .toList());
  }

  /// Get all general feedback (for admin)
  static Future<List<GeneralFeedbackModel>> getAllGeneralFeedback() async {
    try {
      final querySnapshot = await _firestore
          .collection(_feedbackCollection)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GeneralFeedbackModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      developer.log('Error getting all general feedback: $e');
      return [];
    }
  }

  /// Update feedback status (for admin)
  static Future<bool> updateFeedbackStatus({
    required String feedbackId,
    required FeedbackStatus status,
    String? adminResponse,
    String? respondedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
      };

      if (adminResponse != null) {
        updateData['adminResponse'] = adminResponse;
        updateData['respondedAt'] = Timestamp.fromDate(DateTime.now());
      }

      if (respondedBy != null) {
        updateData['respondedBy'] = respondedBy;
      }

      // Update in main feedback collection
      await _firestore
          .collection(_feedbackCollection)
          .doc(feedbackId)
          .update(updateData);

      developer.log('General feedback status updated: $feedbackId');
      return true;
    } catch (e) {
      developer.log('Error updating general feedback status: $e');
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

      // Delete from main collection
      await _firestore.collection(_feedbackCollection).doc(feedbackId).delete();

      // Delete from user's subcollection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userFeedbackCollection)
          .doc(feedbackId)
          .delete();

      developer.log('General feedback deleted: $feedbackId');
      return true;
    } catch (e) {
      developer.log('Error deleting general feedback: $e');
      return false;
    }
  }

  /// Update feedback (for editing)
  static Future<bool> updateGeneralFeedback({
    required String feedbackId,
    required String category,
    required String subject,
    required String message,
    required int rating,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final updateData = {
        'category': category,
        'subject': subject,
        'message': message,
        'rating': rating,
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

      developer.log('General feedback updated: $feedbackId');
      return true;
    } catch (e) {
      developer.log('Error updating general feedback: $e');
      return false;
    }
  }

  /// Get feedback statistics
  static Future<Map<String, int>> getFeedbackStatistics() async {
    try {
      final querySnapshot =
          await _firestore.collection(_feedbackCollection).get();

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'reviewed': 0,
        'responded': 0,
        'archived': 0,
      };

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending';

        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      developer.log('Error getting feedback statistics: $e');
      return {};
    }
  }
}
