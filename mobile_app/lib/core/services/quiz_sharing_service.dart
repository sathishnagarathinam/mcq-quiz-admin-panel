import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_model.dart';
import '../config/app_config.dart';

/// Service for handling quiz sharing functionality
class QuizSharingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Share a quiz with others
  static Future<void> shareQuiz({
    required ExamModel exam,
    String? customMessage,
    ShareType shareType = ShareType.general,
  }) async {
    try {
      final shareContent =
          _generateShareContent(exam, customMessage, shareType);

      await Share.share(
        shareContent.text,
        subject: shareContent.subject,
      );

      // Track sharing analytics
      await _trackSharingAnalytics(exam.id, shareType);
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing quiz: $e');
      }
      rethrow;
    }
  }

  /// Share quiz results/achievements
  static Future<void> shareQuizResult({
    required ExamModel exam,
    required int score,
    required int totalQuestions,
    String? customMessage,
  }) async {
    try {
      final percentage = ((score / totalQuestions) * 100).round();
      final shareContent = _generateResultShareContent(
          exam, score, totalQuestions, percentage, customMessage);

      await Share.share(
        shareContent.text,
        subject: shareContent.subject,
      );

      // Track result sharing analytics
      await _trackSharingAnalytics(exam.id, ShareType.result);
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing quiz result: $e');
      }
      rethrow;
    }
  }

  /// Share quiz with files (if any attachments)
  static Future<void> shareQuizWithFiles({
    required ExamModel exam,
    List<String>? filePaths,
    String? customMessage,
  }) async {
    try {
      final shareContent =
          _generateShareContent(exam, customMessage, ShareType.withFiles);

      if (filePaths != null && filePaths.isNotEmpty) {
        final xFiles = filePaths.map((path) => XFile(path)).toList();
        await Share.shareXFiles(
          xFiles,
          text: shareContent.text,
          subject: shareContent.subject,
        );
      } else {
        await Share.share(
          shareContent.text,
          subject: shareContent.subject,
        );
      }

      // Track sharing analytics
      await _trackSharingAnalytics(exam.id, ShareType.withFiles);
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing quiz with files: $e');
      }
      rethrow;
    }
  }

  /// Generate share content for quiz
  static ShareContent _generateShareContent(
      ExamModel exam, String? customMessage, ShareType shareType) {
    final appName = AppConfig.appName;
    final baseMessage = customMessage ?? _getDefaultShareMessage(shareType);
    final appLink = AppConfig.playStoreUrl;

    final text = '''$baseMessage

📚 Quiz: ${exam.name}
📖 Topic: ${exam.examType}
❓ Questions: ${exam.numberOfQuestions}
⏱️ Duration: ${exam.timeLimit} minutes
🎯 Difficulty: ${exam.difficultyLevel}

Perfect for ${exam.suitableRolesText} preparation!

Download $appName and start practicing now! 🚀

📱 Get the app: $appLink

#MCQQuiz #PostOfficeExam #ExamPreparation #${exam.examType.replaceAll(' ', '')}''';

    return ShareContent(
      text: text,
      subject: '📚 Check out this ${exam.examType} quiz on $appName!',
    );
  }

  /// Generate share content for quiz results
  static ShareContent _generateResultShareContent(
    ExamModel exam,
    int score,
    int totalQuestions,
    int percentage,
    String? customMessage,
  ) {
    final appName = AppConfig.appName;
    final baseMessage = customMessage ?? _getDefaultResultMessage(percentage);
    final appLink = AppConfig.playStoreUrl;

    String performanceEmoji = '';
    String performanceText = '';

    if (percentage >= 90) {
      performanceEmoji = '🏆';
      performanceText = 'Excellent!';
    } else if (percentage >= 80) {
      performanceEmoji = '🥇';
      performanceText = 'Great job!';
    } else if (percentage >= 70) {
      performanceEmoji = '🥈';
      performanceText = 'Good work!';
    } else if (percentage >= 60) {
      performanceEmoji = '🥉';
      performanceText = 'Keep practicing!';
    } else {
      performanceEmoji = '💪';
      performanceText = 'Keep going!';
    }

    final text = '''$baseMessage

$performanceEmoji $performanceText

📊 My Quiz Results:
📚 Quiz: ${exam.name}
📖 Topic: ${exam.examType}
✅ Score: $score/$totalQuestions ($percentage%)
⏱️ Duration: ${exam.timeLimit} minutes

Join me on $appName for ${exam.examType} exam preparation! 🎯

📱 Get the app: $appLink

#MCQQuiz #PostOfficeExam #ExamPreparation #QuizResults #${exam.examType.replaceAll(' ', '')}''';

    return ShareContent(
      text: text,
      subject:
          '$performanceEmoji Scored $percentage% in ${exam.examType} quiz!',
    );
  }

  /// Get default share message based on share type
  static String _getDefaultShareMessage(ShareType shareType) {
    switch (shareType) {
      case ShareType.general:
        return '🎯 Found an amazing quiz for exam preparation!';
      case ShareType.invitation:
        return '👥 Hey! Want to practice together? Check out this quiz!';
      case ShareType.recommendation:
        return '💡 I recommend this quiz for your exam preparation!';
      case ShareType.withFiles:
        return '📎 Sharing this quiz with additional resources!';
      case ShareType.result:
        return '🎉 Just completed this quiz!';
    }
  }

  /// Get default result message based on performance
  static String _getDefaultResultMessage(int percentage) {
    if (percentage >= 90) {
      return '🎉 Aced this quiz! Feeling confident about my exam preparation!';
    } else if (percentage >= 80) {
      return '😊 Great score on this quiz! My preparation is going well!';
    } else if (percentage >= 70) {
      return '👍 Good progress on this quiz! Getting better every day!';
    } else if (percentage >= 60) {
      return '📚 Completed this quiz! Time to review and improve!';
    } else {
      return '💪 Attempted this challenging quiz! Learning from every question!';
    }
  }

  /// Track sharing analytics in Firebase
  static Future<void> _trackSharingAnalytics(
      String examId, ShareType shareType) async {
    try {
      final now = DateTime.now();
      final analyticsData = {
        'examId': examId,
        'shareType': shareType.toString(),
        'timestamp': Timestamp.fromDate(now),
        'date': now.toIso8601String().split('T')[0], // YYYY-MM-DD format
      };

      // Add to sharing analytics collection
      await _firestore.collection('sharing_analytics').add(analyticsData);

      // Update exam sharing count
      await _firestore.collection('exams').doc(examId).update({
        'shareCount': FieldValue.increment(1),
        'lastSharedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking sharing analytics: $e');
      }
      // Don't throw error for analytics failure
    }
  }

  /// Get sharing statistics for an exam
  static Future<Map<String, dynamic>> getSharingStats(String examId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sharing_analytics')
          .where('examId', isEqualTo: examId)
          .get();

      final totalShares = querySnapshot.docs.length;
      final sharesByType = <String, int>{};

      for (final doc in querySnapshot.docs) {
        final shareType = doc.data()['shareType'] as String;
        sharesByType[shareType] = (sharesByType[shareType] ?? 0) + 1;
      }

      return {
        'totalShares': totalShares,
        'sharesByType': sharesByType,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sharing stats: $e');
      }
      return {'totalShares': 0, 'sharesByType': <String, int>{}};
    }
  }
}

/// Types of sharing
enum ShareType {
  general,
  invitation,
  recommendation,
  withFiles,
  result,
}

/// Share content model
class ShareContent {
  final String text;
  final String subject;

  const ShareContent({
    required this.text,
    required this.subject,
  });
}
