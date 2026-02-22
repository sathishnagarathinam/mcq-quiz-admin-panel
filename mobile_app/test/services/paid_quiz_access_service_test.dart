import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_quiz_app/core/models/paid_quiz_access_model.dart';
import 'package:mcq_quiz_app/core/models/exam_model.dart';

void main() {
  group('PaidQuizAccessModel', () {
    late PaidQuizAccessModel testAccess;
    late ExamModel testExam;

    setUp(() {
      final now = DateTime.now();
      testAccess = PaidQuizAccessModel(
        id: 'test-access-1',
        userId: 'user-123',
        examId: 'exam-456',
        examName: 'Test Quiz',
        paymentId: 'payment-789',
        purchaseDate: now,
        expiryDate: now.add(const Duration(days: 30)),
        isActive: true,
        attemptCount: 5,
        lastAttemptDate: now.subtract(const Duration(hours: 2)),
      );

      testExam = ExamModel(
        id: 'exam-456',
        name: 'Test Quiz',
        examType: 'General Knowledge',
        numberOfQuestions: 10,
        timeLimit: 30,
        suitableFor: ['GDS', 'Postman'],
        questions: [],
        createdAt: now,
        updatedAt: now,
        isActive: true,
        isFree: false,
        price: 99.0,
        currency: 'INR',
      );
    });

    test('should correctly identify valid access', () {
      expect(testAccess.isValidAccess, isTrue);
      expect(testAccess.remainingDays, greaterThan(25));
    });

    test('should correctly identify expired access', () {
      final expiredAccess = testAccess.copyWith(
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(expiredAccess.isValidAccess, isFalse);
      expect(expiredAccess.remainingDays, equals(0));
    });

    test('should correctly identify expiring soon access', () {
      final now = DateTime.now();
      final expiringSoonAccess = testAccess.copyWith(
        expiryDate: now.add(const Duration(days: 2, hours: 12)),
      );

      expect(expiringSoonAccess.isExpiringSoon, isTrue);
      expect(expiringSoonAccess.remainingDays, greaterThanOrEqualTo(1));
      expect(expiringSoonAccess.remainingDays, lessThanOrEqualTo(3));
    });

    test('should create access from payment correctly', () {
      final accessFromPayment = PaidQuizAccessModel.fromPayment(
        userId: 'user-123',
        examId: 'exam-456',
        examName: 'Test Quiz',
        paymentId: 'payment-789',
      );

      expect(accessFromPayment.userId, equals('user-123'));
      expect(accessFromPayment.examId, equals('exam-456'));
      expect(accessFromPayment.paymentId, equals('payment-789'));
      expect(accessFromPayment.isActive, isTrue);
      expect(accessFromPayment.attemptCount, equals(0));

      // Should expire in 30 days
      final daysDiff = accessFromPayment.expiryDate
          .difference(accessFromPayment.purchaseDate)
          .inDays;
      expect(daysDiff, equals(30));
    });

    test('should handle copyWith correctly', () {
      final updatedAccess = testAccess.copyWith(
        attemptCount: 10,
        isActive: false,
      );

      expect(updatedAccess.attemptCount, equals(10));
      expect(updatedAccess.isActive, isFalse);
      expect(updatedAccess.userId, equals(testAccess.userId)); // Unchanged
      expect(updatedAccess.examId, equals(testAccess.examId)); // Unchanged
    });
  });

  group('QuizAccessStatus', () {
    test('should have correct display names', () {
      expect(QuizAccessStatus.free.displayName, equals('Free'));
      expect(QuizAccessStatus.purchased.displayName, equals('Purchased'));
      expect(QuizAccessStatus.expired.displayName, equals('Expired'));
      expect(
          QuizAccessStatus.notPurchased.displayName, equals('Not Purchased'));
    });

    test('should have correct descriptions', () {
      expect(QuizAccessStatus.free.description, contains('free to attempt'));
      expect(QuizAccessStatus.purchased.description,
          contains('access to this quiz'));
      expect(QuizAccessStatus.expired.description, contains('expired'));
      expect(QuizAccessStatus.notPurchased.description,
          contains('30 days access'));
    });

    test('should correctly identify attempt permissions', () {
      expect(QuizAccessStatus.free.canAttempt, isTrue);
      expect(QuizAccessStatus.purchased.canAttempt, isTrue);
      expect(QuizAccessStatus.expired.canAttempt, isFalse);
      expect(QuizAccessStatus.notPurchased.canAttempt, isFalse);
    });

    test('should correctly identify payment requirements', () {
      expect(QuizAccessStatus.free.requiresPayment, isFalse);
      expect(QuizAccessStatus.purchased.requiresPayment, isFalse);
      expect(QuizAccessStatus.expired.requiresPayment, isTrue);
      expect(QuizAccessStatus.notPurchased.requiresPayment, isTrue);
    });
  });

  group('Access Duration Logic', () {
    test('should calculate remaining time correctly', () {
      final now = DateTime.now();
      final access = PaidQuizAccessModel(
        id: 'test',
        userId: 'user',
        examId: 'exam',
        examName: 'Test',
        paymentId: 'payment',
        purchaseDate: now.subtract(const Duration(days: 10)),
        expiryDate: now.add(const Duration(days: 20, hours: 12)),
        isActive: true,
      );

      expect(access.remainingDays, greaterThanOrEqualTo(19));
      expect(access.remainingDays, lessThanOrEqualTo(21));
      expect(access.remainingHours,
          greaterThan(450)); // Approximately 20 days * 24 hours
    });

    test('should handle expired access time calculations', () {
      final now = DateTime.now();
      final expiredAccess = PaidQuizAccessModel(
        id: 'test',
        userId: 'user',
        examId: 'exam',
        examName: 'Test',
        paymentId: 'payment',
        purchaseDate: now.subtract(const Duration(days: 40)),
        expiryDate: now.subtract(const Duration(days: 10)),
        isActive: true,
      );

      expect(expiredAccess.remainingDays, equals(0));
      expect(expiredAccess.remainingHours, equals(0));
      expect(expiredAccess.isValidAccess, isFalse);
    });
  });

  group('30-Day Access Policy', () {
    test('should enforce 30-day access period', () {
      final purchaseDate = DateTime.now();
      final access = PaidQuizAccessModel.fromPayment(
        userId: 'user-123',
        examId: 'exam-456',
        examName: 'Test Quiz',
        paymentId: 'payment-789',
        purchaseDate: purchaseDate,
      );

      final expectedExpiry = purchaseDate.add(const Duration(days: 30));
      expect(access.expiryDate.day, equals(expectedExpiry.day));
      expect(access.expiryDate.month, equals(expectedExpiry.month));
      expect(access.expiryDate.year, equals(expectedExpiry.year));
    });

    test('should require new payment after expiry', () {
      final now = DateTime.now();
      final expiredAccess = PaidQuizAccessModel(
        id: 'test',
        userId: 'user',
        examId: 'exam',
        examName: 'Test',
        paymentId: 'payment',
        purchaseDate: now.subtract(const Duration(days: 35)),
        expiryDate: now.subtract(const Duration(days: 5)),
        isActive: true,
      );

      expect(expiredAccess.isValidAccess, isFalse);
      expect(expiredAccess.remainingDays, equals(0));
    });
  });
}
