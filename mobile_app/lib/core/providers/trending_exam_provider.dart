import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_model.dart';

/// Provider for trending exams
final trendingExamsProvider = StreamProvider<List<ExamModel>>((ref) {
  return TrendingExamService().getTrendingExamsStream();
});

/// Service for managing trending exams
class TrendingExamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final ExamService _examService = ExamService(); // Unused for now

  /// Get trending exams stream
  Stream<List<ExamModel>> getTrendingExamsStream() {
    return _firestore
        .collection('exams')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final exams = snapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .where(
              (exam) => exam.questions.isNotEmpty) // Only exams with questions
          .toList();

      // Sort by trending priority first, then by total attempts
      exams.sort((a, b) {
        // Admin-marked trending exams come first
        if (a.isTrending && !b.isTrending) return -1;
        if (!a.isTrending && b.isTrending) return 1;

        // If both are trending or both are not trending, sort by priority/attempts
        if (a.isTrending && b.isTrending) {
          // Higher priority comes first
          final priorityComparison =
              b.trendingPriority.compareTo(a.trendingPriority);
          if (priorityComparison != 0) return priorityComparison;
        }

        // Sort by total attempts (higher first)
        return b.totalAttempts.compareTo(a.totalAttempts);
      });

      // Return top 10 trending exams
      return exams.take(10).toList();
    });
  }

  /// Increment exam attempt count
  Future<void> incrementExamAttempts(String examId) async {
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
      print('Error incrementing exam attempts: $e');
    }
  }

  /// Set exam as trending (admin function)
  Future<void> setExamTrending(String examId, bool isTrending,
      {int priority = 1}) async {
    try {
      await _firestore.collection('exams').doc(examId).update({
        'isTrending': isTrending,
        'trendingPriority': isTrending ? priority : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error setting exam trending status: $e');
      rethrow;
    }
  }

  /// Get exam statistics for admin
  Future<Map<String, dynamic>> getExamStatistics(String examId) async {
    try {
      final examDoc = await _firestore.collection('exams').doc(examId).get();

      if (!examDoc.exists) {
        throw Exception('Exam not found');
      }

      final data = examDoc.data()!;

      return {
        'totalAttempts': data['totalAttempts'] ?? 0,
        'isTrending': data['isTrending'] ?? false,
        'trendingPriority': data['trendingPriority'] ?? 0,
        'isActive': data['isActive'] ?? true,
        'questionsCount': (data['questions'] as List?)?.length ?? 0,
      };
    } catch (e) {
      print('Error getting exam statistics: $e');
      rethrow;
    }
  }

  /// Get all exams with their attempt counts (for admin dashboard)
  Future<List<Map<String, dynamic>>> getAllExamsWithStats() async {
    try {
      final snapshot = await _firestore.collection('exams').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'examType': data['examType'] ?? '',
          'totalAttempts': data['totalAttempts'] ?? 0,
          'isTrending': data['isTrending'] ?? false,
          'trendingPriority': data['trendingPriority'] ?? 0,
          'isActive': data['isActive'] ?? true,
          'questionsCount': (data['questions'] as List?)?.length ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error getting all exams with stats: $e');
      rethrow;
    }
  }

  /// Update trending priorities for multiple exams
  Future<void> updateTrendingPriorities(Map<String, int> examPriorities) async {
    try {
      final batch = _firestore.batch();

      for (final entry in examPriorities.entries) {
        final examRef = _firestore.collection('exams').doc(entry.key);
        batch.update(examRef, {
          'trendingPriority': entry.value,
          'isTrending': entry.value > 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error updating trending priorities: $e');
      rethrow;
    }
  }

  /// Get trending exams count
  Future<int> getTrendingExamsCount() async {
    try {
      final snapshot = await _firestore
          .collection('exams')
          .where('isTrending', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting trending exams count: $e');
      return 0;
    }
  }

  /// Get most attempted exams (for analytics)
  Future<List<Map<String, dynamic>>> getMostAttemptedExams(
      {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('exams')
          .where('isActive', isEqualTo: true)
          .orderBy('totalAttempts', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'examType': data['examType'] ?? '',
          'totalAttempts': data['totalAttempts'] ?? 0,
          'isTrending': data['isTrending'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('Error getting most attempted exams: $e');
      return [];
    }
  }
}

/// Provider for trending exam service
final trendingExamServiceProvider = Provider<TrendingExamService>((ref) {
  return TrendingExamService();
});

/// Provider for exam statistics
final examStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, examId) {
  final service = ref.read(trendingExamServiceProvider);
  return service.getExamStatistics(examId);
});

/// Provider for all exams with statistics
final allExamsWithStatsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.read(trendingExamServiceProvider);
  return service.getAllExamsWithStats();
});

/// Provider for most attempted exams
final mostAttemptedExamsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, limit) {
  final service = ref.read(trendingExamServiceProvider);
  return service.getMostAttemptedExams(limit: limit);
});
