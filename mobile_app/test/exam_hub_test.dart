import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mcq_quiz_app/core/models/exam_hub_models.dart';

void main() {
  group('Exam Hub Models Tests', () {
    test('FileAttachment model should serialize and deserialize correctly', () {
      final now = DateTime.now();
      final attachment = FileAttachment(
        id: 'test-id',
        name: 'test-file.pdf',
        originalName: 'Test File.pdf',
        url: 'https://example.com/test.pdf',
        size: 1024,
        type: 'application/pdf',
        uploadedAt: now,
      );

      final json = attachment.toJson();
      expect(json['id'], 'test-id');
      expect(json['name'], 'test-file.pdf');
      expect(json['originalName'], 'Test File.pdf');
      expect(json['url'], 'https://example.com/test.pdf');
      expect(json['size'], 1024);
      expect(json['type'], 'application/pdf');
      expect(json['uploadedAt'], isA<Timestamp>());

      final fromJson = FileAttachment.fromJson({
        'id': 'test-id',
        'name': 'test-file.pdf',
        'originalName': 'Test File.pdf',
        'url': 'https://example.com/test.pdf',
        'size': 1024,
        'type': 'application/pdf',
        'uploadedAt': now.toIso8601String(),
      });

      expect(fromJson.id, 'test-id');
      expect(fromJson.name, 'test-file.pdf');
      expect(fromJson.originalName, 'Test File.pdf');
      expect(fromJson.url, 'https://example.com/test.pdf');
      expect(fromJson.size, 1024);
      expect(fromJson.type, 'application/pdf');
    });

    test('CutoffMarks model should serialize and deserialize correctly', () {
      final cutoff = CutoffMarks(
        general: 85.5,
        obc: 80.0,
        sc: 75.5,
        st: 70.0,
        pwd: 65.5,
      );

      final json = cutoff.toJson();
      expect(json['general'], 85.5);
      expect(json['obc'], 80.0);
      expect(json['sc'], 75.5);
      expect(json['st'], 70.0);
      expect(json['pwd'], 65.5);

      final fromJson = CutoffMarks.fromJson({
        'general': 85.5,
        'obc': 80.0,
        'sc': 75.5,
        'st': 70.0,
        'pwd': 65.5,
      });

      expect(fromJson.general, 85.5);
      expect(fromJson.obc, 80.0);
      expect(fromJson.sc, 75.5);
      expect(fromJson.st, 70.0);
      expect(fromJson.pwd, 65.5);
    });

    test('ExamHubNews model should handle all properties correctly', () {
      final now = DateTime.now();
      final attachment = FileAttachment(
        id: 'att-1',
        name: 'news.pdf',
        originalName: 'News.pdf',
        url: 'https://example.com/news.pdf',
        size: 2048,
        type: 'application/pdf',
        uploadedAt: now,
      );

      // Test that the model can be created with all required properties
      expect(() {
        ExamHubNews(
          id: 'news-1',
          title: 'Test News',
          description: 'Test Description',
          isActive: true,
          priority: 1,
          createdBy: 'admin',
          createdAt: now,
          updatedAt: now,
          tags: ['test', 'news'],
          viewCount: 0,
          category: 'general',
          publishDate: now,
          attachments: [attachment],
          isBreaking: false,
          targetAudience: ['ALL'],
        );
      }, returnsNormally);
    });

    test('ExamHubTips model should handle all properties correctly', () {
      final now = DateTime.now();
      final attachment = FileAttachment(
        id: 'att-1',
        name: 'tips.pdf',
        originalName: 'Tips.pdf',
        url: 'https://example.com/tips.pdf',
        size: 1024,
        type: 'application/pdf',
        uploadedAt: now,
      );

      expect(() {
        ExamHubTips(
          id: 'tips-1',
          title: 'Test Tips',
          description: 'Test Description',
          isActive: true,
          priority: 1,
          createdBy: 'admin',
          createdAt: now,
          updatedAt: now,
          tags: ['test', 'tips'],
          viewCount: 0,
          category: 'study_tips',
          difficulty: 'beginner',
          estimatedReadTime: 5,
          attachments: [attachment],
          relatedExamTypes: ['MTS', 'POSTMAN'],
          isVideoContent: false,
        );
      }, returnsNormally);
    });

    test('ExamHubPapers model should handle all properties correctly', () {
      final now = DateTime.now();
      final attachment = FileAttachment(
        id: 'att-1',
        name: 'paper.pdf',
        originalName: 'Paper.pdf',
        url: 'https://example.com/paper.pdf',
        size: 3072,
        type: 'application/pdf',
        uploadedAt: now,
      );

      expect(() {
        ExamHubPapers(
          id: 'papers-1',
          title: 'Test Paper',
          description: 'Test Description',
          isActive: true,
          priority: 1,
          createdBy: 'admin',
          createdAt: now,
          updatedAt: now,
          tags: ['test', 'paper'],
          viewCount: 0,
          examType: 'MTS',
          examYear: 2023,
          examDate: now,
          paperType: 'question_paper',
          duration: 120,
          totalMarks: 100,
          totalQuestions: 100,
          attachments: [attachment],
          language: ['English', 'Hindi'],
          isOfficial: true,
        );
      }, returnsNormally);
    });

    test('ExamHubResults model should handle all properties correctly', () {
      final now = DateTime.now();
      final attachment = FileAttachment(
        id: 'att-1',
        name: 'result.pdf',
        originalName: 'Result.pdf',
        url: 'https://example.com/result.pdf',
        size: 2048,
        type: 'application/pdf',
        uploadedAt: now,
      );

      final cutoff = CutoffMarks(
        general: 85.0,
        obc: 80.0,
        sc: 75.0,
        st: 70.0,
        pwd: 65.0,
      );

      expect(() {
        ExamHubResults(
          id: 'results-1',
          title: 'Test Result',
          description: 'Test Description',
          isActive: true,
          priority: 1,
          createdBy: 'admin',
          createdAt: now,
          updatedAt: now,
          tags: ['test', 'result'],
          viewCount: 0,
          examType: 'MTS',
          examYear: 2023,
          resultType: 'final_result',
          publishDate: now,
          examDate: now,
          totalCandidates: 1000,
          selectedCandidates: 100,
          cutoffMarks: cutoff,
          attachments: [attachment],
          isOfficial: true,
        );
      }, returnsNormally);
    });
  });
}
