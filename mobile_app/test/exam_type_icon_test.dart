import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_quiz_app/core/models/exam_model.dart';
import 'package:mcq_quiz_app/core/providers/exam_type_provider.dart';

void main() {
  group('ExamType Icon Tests', () {
    test('ExamTypeUtils should return correct icons for default exam types', () {
      // Create a list of default exam types
      final examTypes = [
        ExamType(
          id: 'postal-guide',
          name: 'Postal Guide',
          icon: '📮',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        ExamType(
          id: 'postal-volumes',
          name: 'Postal Volumes',
          icon: '📚',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        ExamType(
          id: 'custom-exam',
          name: 'Custom Exam',
          icon: '🎯',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      // Test default exam types
      expect(
        ExamTypeUtils.getIconForExamType('Postal Guide', examTypes),
        equals('📮'),
      );
      
      expect(
        ExamTypeUtils.getIconForExamType('Postal Volumes', examTypes),
        equals('📚'),
      );

      // Test custom exam type
      expect(
        ExamTypeUtils.getIconForExamType('Custom Exam', examTypes),
        equals('🎯'),
      );

      // Test case insensitive matching
      expect(
        ExamTypeUtils.getIconForExamType('postal guide', examTypes),
        equals('📮'),
      );

      expect(
        ExamTypeUtils.getIconForExamType('POSTAL VOLUMES', examTypes),
        equals('📚'),
      );
    });

    test('ExamTypeUtils should return fallback icon for unknown exam types', () {
      final examTypes = <ExamType>[];

      // Test unknown exam type falls back to hardcoded icons
      expect(
        ExamTypeUtils.getIconForExamType('Postal Guide', examTypes),
        equals('📮'),
      );

      expect(
        ExamTypeUtils.getIconForExamType('Unknown Exam', examTypes),
        equals('📝'),
      );
    });

    test('ExamModel should use dynamic icons when exam types are provided', () {
      final examTypes = [
        ExamType(
          id: 'custom-exam',
          name: 'Custom Exam',
          icon: '🎯',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      final exam = ExamModel(
        id: 'test-exam',
        name: 'Test Exam',
        examType: 'Custom Exam',
        numberOfQuestions: 10,
        timeLimit: 30,
        suitableFor: ['MTS'],
        questions: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      // Test dynamic icon method
      expect(
        exam.getTypeIcon(examTypes),
        equals('🎯'),
      );

      // Test fallback to static method when exam type not found
      final emptyExamTypes = <ExamType>[];
      expect(
        exam.getTypeIcon(emptyExamTypes),
        equals('📝'), // Should fall back to static typeIcon method
      );
    });

    test('ExamTypeUtils should handle admin web exam type changes', () {
      // Simulate admin web changing an exam type icon
      final originalExamTypes = [
        ExamType(
          id: 'postal-guide',
          name: 'Postal Guide',
          icon: '📮',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      // Admin changes the icon
      final updatedExamTypes = [
        ExamType(
          id: 'postal-guide',
          name: 'Postal Guide',
          icon: '📬', // Changed icon
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Test original icon
      expect(
        ExamTypeUtils.getIconForExamType('Postal Guide', originalExamTypes),
        equals('📮'),
      );

      // Test updated icon
      expect(
        ExamTypeUtils.getIconForExamType('Postal Guide', updatedExamTypes),
        equals('📬'),
      );
    });

    test('ExamTypeUtils should handle custom exam types from admin', () {
      // Simulate admin creating a new custom exam type
      final examTypes = [
        ExamType(
          id: 'new-custom-type',
          name: 'New Custom Type',
          icon: '🚀',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      expect(
        ExamTypeUtils.getIconForExamType('New Custom Type', examTypes),
        equals('🚀'),
      );
    });

    test('ExamType model should handle Firestore data correctly', () {
      // Test ExamType creation from Firestore-like data
      final examType = ExamType(
        id: 'test-id',
        name: 'Test Exam Type',
        icon: '🧪',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      expect(examType.id, equals('test-id'));
      expect(examType.name, equals('Test Exam Type'));
      expect(examType.icon, equals('🧪'));
      expect(examType.isDefault, equals(false));
      expect(examType.createdAt, isA<DateTime>());
    });
  });
}
