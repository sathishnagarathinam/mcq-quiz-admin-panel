import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/paid_quiz_access_model.dart';
import '../models/exam_model.dart';

/// Service for managing paid quiz access with 30-day expiry
class PaidQuizAccessService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _accessCollection = 'paid_quiz_access';
  static const String _userAccessCollection =
      'exam_access'; // Matches backend collection name
  static const String _freeAccessCollection =
      'free_quiz_access'; // Admin-granted free access collection

  /// Create access record after successful payment
  static Future<PaidQuizAccessModel?> createAccessRecord({
    required String examId,
    required String examName,
    required String paymentId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final accessRecord = PaidQuizAccessModel.fromPayment(
        userId: currentUser.uid,
        examId: examId,
        examName: examName,
        paymentId: paymentId,
      );

      // Save to global collection
      final docRef = await _firestore
          .collection(_accessCollection)
          .add(accessRecord.toFirestore());

      // Also save to user's subcollection for faster queries
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userAccessCollection)
          .doc(examId)
          .set(accessRecord.toFirestore());

      developer.log('✅ Created quiz access record for exam: $examId');

      return accessRecord.copyWith(id: docRef.id);
    } catch (e) {
      developer.log('❌ Error creating access record: $e');
      return null;
    }
  }

  /// Get user's access status for a specific exam
  static Future<QuizAccessStatus> getQuizAccessStatus({
    required String examId,
    required ExamModel exam,
  }) async {
    try {
      developer.log('🔍 getQuizAccessStatus called for exam: $examId');
      developer.log('   - exam.name: ${exam.name}');
      developer.log('   - exam.isFree: ${exam.isFree}');
      developer.log('   - exam.price: ${exam.price}');

      // If quiz is free, return free status
      if (exam.isFree) {
        developer
            .log('✅ Quiz is FREE (globally) - returning QuizAccessStatus.free');
        return QuizAccessStatus.free;
      }

      developer.log('💰 Quiz is PAID - checking access records...');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        developer.log('❌ No current user - returning notPurchased');
        return QuizAccessStatus.notPurchased;
      }

      // First, check for admin-granted free access
      final hasFreeAccess = await _checkAdminGrantedFreeAccess(
        userId: currentUser.uid,
        examId: examId,
      );

      if (hasFreeAccess) {
        developer.log(
            '✅ Admin-granted FREE access found - returning QuizAccessStatus.free');
        return QuizAccessStatus.free;
      }

      // Check user's paid access record
      final accessRecord = await getUserQuizAccess(examId);

      if (accessRecord == null) {
        developer.log('❌ No access record found - returning notPurchased');
        return QuizAccessStatus.notPurchased;
      }

      // Check if access is still valid
      if (accessRecord.isValidAccess) {
        developer.log('✅ Valid paid access record found - returning purchased');
        return QuizAccessStatus.purchased;
      } else {
        developer.log('⚠️ Access record expired - returning expired');
        return QuizAccessStatus.expired;
      }
    } catch (e) {
      developer.log('❌ Error getting quiz access status: $e');
      return QuizAccessStatus.notPurchased;
    }
  }

  /// Check if user has admin-granted free access for a specific exam
  static Future<bool> _checkAdminGrantedFreeAccess({
    required String userId,
    required String examId,
  }) async {
    try {
      developer.log('🔍 Checking for admin-granted free access...');
      developer.log('   - userId: $userId');
      developer.log('   - examId: $examId');

      // Query the free_quiz_access collection for this user and exam
      final querySnapshot = await _firestore
          .collection(_freeAccessCollection)
          .where('userId', isEqualTo: userId)
          .where('examId', isEqualTo: examId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        developer.log('   ❌ No admin-granted free access found');
        return false;
      }

      // Check if access has expired
      final doc = querySnapshot.docs.first;
      final data = doc.data();

      developer.log('   📄 Found free access record: ${doc.id}');
      developer.log('   📄 Data: $data');

      // Check expiry if set
      if (data['expiresAt'] != null) {
        final expiresAt = (data['expiresAt'] as Timestamp).toDate();
        if (DateTime.now().isAfter(expiresAt)) {
          developer.log(
              '   ⚠️ Admin-granted free access has EXPIRED at: $expiresAt');
          return false;
        }
        developer.log('   ✅ Free access valid until: $expiresAt');
      } else {
        developer.log('   ✅ Free access is PERMANENT (no expiry)');
      }

      return true;
    } catch (e) {
      developer.log('❌ Error checking admin-granted free access: $e');
      return false;
    }
  }

  /// Get user's access record for a specific exam
  static Future<PaidQuizAccessModel?> getUserQuizAccess(String examId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        developer.log('❌ No current user for quiz access check');
        return null;
      }

      developer.log(
          '🔍 Checking exam access for user: ${currentUser.uid}, exam: $examId');
      developer.log(
          '   Looking in collection: users/${currentUser.uid}/$_userAccessCollection/$examId');

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userAccessCollection)
          .doc(examId)
          .get();

      if (doc.exists) {
        developer.log('✅ Access record found!');
        developer.log('   Data: ${doc.data()}');
        final accessModel = PaidQuizAccessModel.fromFirestore(doc);
        developer.log('   Parsed model: $accessModel');
        return accessModel;
      }

      developer.log('❌ No access record found for exam: $examId');
      return null;
    } catch (e) {
      developer.log('❌ Error getting user quiz access: $e');
      return null;
    }
  }

  /// Get all user's quiz access records
  static Future<List<PaidQuizAccessModel>> getUserAllQuizAccess() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        developer.log('❌ No current user for getting all quiz access');
        return [];
      }

      developer.log('🔍 Getting all quiz access for user: ${currentUser.uid}');
      developer.log(
          '   Collection path: users/${currentUser.uid}/$_userAccessCollection');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userAccessCollection)
          .get(); // Removed orderBy to avoid index requirement

      developer.log('📊 Found ${querySnapshot.docs.length} access records');

      final accessRecords = querySnapshot.docs.map((doc) {
        developer.log('   - Doc ID: ${doc.id}, Data: ${doc.data()}');
        return PaidQuizAccessModel.fromFirestore(doc);
      }).toList();

      // Sort by purchaseDate in descending order
      accessRecords.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

      developer.log('✅ Returning ${accessRecords.length} access records');
      return accessRecords;
    } catch (e) {
      developer.log('❌ Error getting user all quiz access: $e');
      developer.log('   Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Update attempt count when user starts a quiz
  static Future<void> recordQuizAttempt(String examId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final docRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userAccessCollection)
          .doc(examId);

      await docRef.update({
        'attemptCount': FieldValue.increment(1),
        'lastAttemptDate': Timestamp.fromDate(DateTime.now()),
      });

      developer.log('✅ Recorded quiz attempt for exam: $examId');
    } catch (e) {
      developer.log('❌ Error recording quiz attempt: $e');
    }
  }

  /// Check if user can attempt a quiz (has valid access)
  static Future<bool> canUserAttemptQuiz({
    required String examId,
    required ExamModel exam,
  }) async {
    final status = await getQuizAccessStatus(examId: examId, exam: exam);
    return status.canAttempt;
  }

  /// Get access details for instruction screen
  static Future<Map<String, dynamic>> getAccessDetails({
    required String examId,
    required ExamModel exam,
  }) async {
    try {
      final status = await getQuizAccessStatus(examId: examId, exam: exam);

      if (status == QuizAccessStatus.free) {
        return {
          'status': status,
          'canAttempt': true,
          'message': 'This quiz is free to attempt',
          'showPayment': false,
        };
      }

      if (status == QuizAccessStatus.purchased) {
        final accessRecord = await getUserQuizAccess(examId);
        if (accessRecord != null) {
          return {
            'status': status,
            'canAttempt': true,
            'message': 'Access expires in ${accessRecord.remainingDays} days',
            'showPayment': false,
            'remainingDays': accessRecord.remainingDays,
            'expiryDate': accessRecord.expiryDate,
            'attemptCount': accessRecord.attemptCount,
            'isExpiringSoon': accessRecord.isExpiringSoon,
          };
        }
      }

      // Not purchased or expired
      return {
        'status': status,
        'canAttempt': false,
        'message': status == QuizAccessStatus.expired
            ? 'Your access has expired. Purchase again for 30 days access'
            : 'Purchase this quiz for 30 days unlimited access',
        'showPayment': true,
        'price': exam.price,
        'currency': exam.currency,
      };
    } catch (e) {
      developer.log('❌ Error getting access details: $e');
      return {
        'status': QuizAccessStatus.notPurchased,
        'canAttempt': false,
        'message': 'Unable to verify access. Please try again.',
        'showPayment': true,
      };
    }
  }

  /// Clean up expired access records (can be called periodically)
  static Future<void> cleanupExpiredAccess() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userAccessCollection)
          .where('expiryDate', isLessThan: Timestamp.fromDate(now))
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        developer.log(
            '✅ Cleaned up ${querySnapshot.docs.length} expired access records');
      }
    } catch (e) {
      developer.log('❌ Error cleaning up expired access: $e');
    }
  }

  /// Get expiring access records (for notifications)
  static Future<List<PaidQuizAccessModel>> getExpiringSoonAccess() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection(_userAccessCollection)
          .where('isActive', isEqualTo: true)
          .where('expiryDate', isGreaterThan: Timestamp.fromDate(now))
          .where('expiryDate',
              isLessThanOrEqualTo: Timestamp.fromDate(threeDaysFromNow))
          .get();

      return querySnapshot.docs
          .map((doc) => PaidQuizAccessModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      developer.log('❌ Error getting expiring access records: $e');
      return [];
    }
  }
}
