import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/quiz_attempt_model.dart';
import 'analytics_service.dart';

/// Service to refresh analytics from existing quiz attempts
class AnalyticsRefreshService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final AnalyticsService _analyticsService = AnalyticsService();

  /// Get current user ID
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Refresh analytics from all existing quiz attempts
  static Future<Map<String, dynamic>> refreshAnalyticsFromQuizAttempts() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (kDebugMode) {
      print('🔄 Starting analytics refresh for user: $currentUserId');
    }

    try {
      // 1. Get all completed quiz attempts for the user
      final attemptsSnapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: currentUserId)
          .where('isCompleted', isEqualTo: true)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .get();

      if (kDebugMode) {
        print('📊 Found ${attemptsSnapshot.docs.length} completed quiz attempts');
      }

      if (attemptsSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No completed quiz attempts found');
        }
        return {
          'success': true,
          'message': 'No completed quiz attempts found',
          'totalAttempts': 0,
          'processedAttempts': 0,
        };
      }

      // 2. Process each completed attempt through the analytics service
      int processedCount = 0;
      int errorCount = 0;

      for (final doc in attemptsSnapshot.docs) {
        try {
          final attempt = QuizAttemptModel.fromFirestore(doc);
          
          if (kDebugMode) {
            print('🔄 Processing: ${attempt.examName} - Score: ${attempt.score}/${attempt.totalQuestions} - Time: ${attempt.timeSpent}s');
          }

          // Update analytics for this attempt
          await _analyticsService.updateUserAnalyticsAfterQuiz(attempt);
          processedCount++;

          // Small delay to avoid overwhelming Firestore
          await Future.delayed(const Duration(milliseconds: 100));

        } catch (e) {
          errorCount++;
          if (kDebugMode) {
            print('❌ Error processing attempt ${doc.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('✅ Analytics refresh completed');
        print('📊 Processed: $processedCount attempts');
        print('❌ Errors: $errorCount attempts');
      }

      return {
        'success': true,
        'message': 'Analytics refreshed successfully',
        'totalAttempts': attemptsSnapshot.docs.length,
        'processedAttempts': processedCount,
        'errorCount': errorCount,
      };

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing analytics: $e');
      }
      rethrow;
    }
  }

  /// Quick check if analytics need refreshing
  static Future<bool> needsAnalyticsRefresh() async {
    if (currentUserId == null) return false;

    try {
      // Check if user has analytics
      final analyticsDoc = await _firestore
          .collection('user_analytics')
          .doc(currentUserId)
          .get();

      if (!analyticsDoc.exists) {
        if (kDebugMode) {
          print('🔍 No analytics found - refresh needed');
        }
        return true;
      }

      final analyticsData = analyticsDoc.data() as Map<String, dynamic>;
      final completedQuizzes = analyticsData['statistics']?['totalQuizzesCompleted'] ?? 0;

      // Check if user has quiz attempts
      final attemptsSnapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: currentUserId)
          .where('isCompleted', isEqualTo: true)
          .limit(1)
          .get();

      final hasAttempts = attemptsSnapshot.docs.isNotEmpty;

      if (kDebugMode) {
        print('🔍 Analytics check: $completedQuizzes completed quizzes, has attempts: $hasAttempts');
      }

      // Needs refresh if user has attempts but analytics show 0 completed quizzes
      return hasAttempts && completedQuizzes == 0;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking analytics: $e');
      }
      return false;
    }
  }

  /// Auto-refresh analytics if needed
  static Future<void> autoRefreshIfNeeded() async {
    try {
      final needsRefresh = await needsAnalyticsRefresh();
      
      if (needsRefresh) {
        if (kDebugMode) {
          print('🔄 Auto-refreshing analytics...');
        }
        await refreshAnalyticsFromQuizAttempts();
      } else {
        if (kDebugMode) {
          print('✅ Analytics are up to date');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in auto-refresh: $e');
      }
    }
  }

  /// Get analytics summary for debugging
  static Future<Map<String, dynamic>> getAnalyticsSummary() async {
    if (currentUserId == null) {
      return {'error': 'User not authenticated'};
    }

    try {
      // Get analytics
      final analyticsDoc = await _firestore
          .collection('user_analytics')
          .doc(currentUserId)
          .get();

      // Get quiz attempts count
      final attemptsSnapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: currentUserId)
          .where('isCompleted', isEqualTo: true)
          .get();

      final summary = {
        'userId': currentUserId,
        'analyticsExists': analyticsDoc.exists,
        'totalQuizAttempts': attemptsSnapshot.docs.length,
      };

      if (analyticsDoc.exists) {
        final data = analyticsDoc.data() as Map<String, dynamic>;
        summary['analyticsCompletedQuizzes'] = data['statistics']?['totalQuizzesCompleted'] ?? 0;
        summary['analyticsAverageScore'] = data['performance']?['averageScore'] ?? 0.0;
        summary['analyticsCurrentStreak'] = data['statistics']?['currentStreak'] ?? 0;
      }

      return summary;

    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
