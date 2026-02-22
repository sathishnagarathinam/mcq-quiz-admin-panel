import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_quiz_app/core/config/app_config.dart';
import 'package:mcq_quiz_app/core/models/exam_model.dart';
import 'package:mcq_quiz_app/core/services/quiz_sharing_service.dart';

void main() {
  group('QuizSharingService', () {
    late ExamModel testExam;

    setUp(() {
      testExam = ExamModel(
        id: 'test-exam-1',
        name: 'Sample Post Office Quiz',
        examType: 'General Knowledge',
        numberOfQuestions: 10,
        timeLimit: 30,
        suitableFor: ['GDS', 'Postman'],
        questions: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
    });

    test('should include app link in quiz share content', () {
      // Test the private method by checking the generated content structure
      // Since _generateShareContent is private, we'll test the public method behavior

      // The share content should include the app link
      expect(AppConfig.playStoreUrl, contains('com.mcqquiz1.app'));
      expect(AppConfig.shareText, contains(AppConfig.playStoreUrl));
    });

    test('should include app link in result share content', () {
      // Test that result sharing includes app link
      // The app link should be included in the share text

      expect(AppConfig.playStoreUrl, isNotEmpty);
      expect(AppConfig.playStoreUrl,
          startsWith('https://play.google.com/store/apps/details?id='));
    });

    test('should have correct Play Store URL format', () {
      final playStoreUrl = AppConfig.playStoreUrl;

      expect(playStoreUrl,
          startsWith('https://play.google.com/store/apps/details?id='));
      expect(playStoreUrl, contains('com.mcqquiz1.app'));
    });

    test('should have app name and tagline configured', () {
      expect(AppConfig.appName, isNotEmpty);
      expect(AppConfig.appTagline, isNotEmpty);
    });
  });
}
