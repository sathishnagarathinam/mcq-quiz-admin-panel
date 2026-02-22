import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exam_model.dart';
import '../models/live_test_model.dart';
import 'auth_helper_service.dart';
import 'dart:developer' as developer;

class ExamService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'exams';
  static const String _liveTestsCollection = 'live_tests';

  /// Get all active exams
  static Future<List<ExamModel>> getActiveExams() async {
    try {
      final currentUser = _auth.currentUser;
      developer.log('Current user: ${currentUser?.uid ?? 'null'}');
      developer.log('User email: ${currentUser?.email ?? 'null'}');

      // Check for both Firebase Auth and phone auth
      final isAuthenticated = await AuthHelperService.isUserAuthenticated();
      developer.log('User authenticated: $isAuthenticated');

      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in first.');
      }

      developer.log('Querying exams collection for active exams...');
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      developer
          .log('Query completed. Found ${querySnapshot.docs.length} documents');

      final exams = querySnapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .toList();

      developer.log('Successfully parsed ${exams.length} exams');
      return exams;
    } on FirebaseException catch (e) {
      developer.log('Firebase error: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied: Please check your authentication.');
      } else if (e.code == 'unavailable') {
        throw Exception(
            'Service unavailable: Please check your internet connection.');
      }
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      developer.log('General error fetching exams: $e');
      throw Exception('Failed to fetch exams: $e');
    }
  }

  /// Get started live tests and convert them to exam models
  static Future<List<ExamModel>> getStartedLiveTests() async {
    try {
      final now = DateTime.now();
      developer.log('Querying live tests that have started...');

      final querySnapshot = await _firestore
          .collection(_liveTestsCollection)
          .where('isActive', isEqualTo: true)
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      developer.log('Found ${querySnapshot.docs.length} started live tests');

      final liveTestExams = <ExamModel>[];

      for (final doc in querySnapshot.docs) {
        final liveTest = LiveTestModel.fromFirestore(doc);

        // Only include if the live test has an associated exam ID
        if (liveTest.examId.isNotEmpty) {
          try {
            // Get the actual exam data
            final examDoc = await _firestore
                .collection(_collection)
                .doc(liveTest.examId)
                .get();

            if (examDoc.exists) {
              final exam = ExamModel.fromFirestore(examDoc);

              // Create a modified exam model with live test info
              final liveTestExam = ExamModel(
                id: exam.id,
                name: '${liveTest.title} (Live Test)',
                examType: liveTest.examType,
                customName: liveTest.title,
                numberOfQuestions: liveTest.totalQuestions,
                timeLimit: liveTest.durationMinutes,
                suitableFor: liveTest.suitableFor,
                questions: exam.questions,
                createdAt: liveTest.createdAt,
                updatedAt: liveTest.updatedAt,
                isActive: true,
                totalAttempts: exam.totalAttempts,
                isTrending: false,
                trendingPriority: 0,
              );

              liveTestExams.add(liveTestExam);
              developer.log('Added live test exam: ${liveTest.title}');
            }
          } catch (e) {
            developer.log('Error processing live test ${liveTest.id}: $e');
          }
        }
      }

      developer.log(
          'Successfully converted ${liveTestExams.length} live tests to exams');
      return liveTestExams;
    } catch (e) {
      developer.log('Error fetching started live tests: $e');
      return [];
    }
  }

  /// Get all active exams including started live tests
  static Future<List<ExamModel>> getActiveExamsWithLiveTests() async {
    try {
      // Get regular active exams and started live tests in parallel
      final results = await Future.wait([
        getActiveExams(),
        getStartedLiveTests(),
      ]);

      final regularExams = results[0] as List<ExamModel>;
      final liveTestExams = results[1] as List<ExamModel>;

      // Combine and sort by creation date
      final allExams = [...regularExams, ...liveTestExams];
      allExams.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      developer.log(
          'Combined ${regularExams.length} regular exams with ${liveTestExams.length} live test exams');
      return allExams;
    } catch (e) {
      developer.log('Error fetching exams with live tests: $e');
      // Fallback to regular exams only
      return getActiveExams();
    }
  }

  /// Get featured exams (exams with questions)
  static Future<List<ExamModel>> getFeaturedExams() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final exams = querySnapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .where((exam) => exam.questions.isNotEmpty)
          .toList();

      return exams;
    } catch (e) {
      throw Exception('Failed to fetch featured exams: $e');
    }
  }

  /// Get exam by ID
  static Future<ExamModel?> getExamById(String examId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(examId).get();

      if (doc.exists) {
        return ExamModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch exam: $e');
    }
  }

  /// Get exams suitable for specific role
  static Future<List<ExamModel>> getExamsForRole(String role) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('suitableFor', arrayContains: role)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .where((exam) => exam.questions.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch exams for role: $e');
    }
  }

  /// Search exams by name or type
  static Future<List<ExamModel>> searchExams(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final exams = querySnapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .where((exam) =>
              exam.name.toLowerCase().contains(query.toLowerCase()) ||
              exam.examType.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return exams;
    } catch (e) {
      throw Exception('Failed to search exams: $e');
    }
  }

  /// Get exam statistics
  static Future<Map<String, dynamic>> getExamStats() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();

      int totalExams = querySnapshot.docs.length;
      int activeExams = querySnapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;
      int examsWithQuestions = querySnapshot.docs
          .where((doc) =>
              doc.data()['isActive'] == true &&
              (doc.data()['questions'] as List?)?.isNotEmpty == true)
          .length;

      return {
        'totalExams': totalExams,
        'activeExams': activeExams,
        'examsWithQuestions': examsWithQuestions,
      };
    } catch (e) {
      throw Exception('Failed to fetch exam stats: $e');
    }
  }

  /// Stream of active exams (real-time updates)
  static Stream<List<ExamModel>> getActiveExamsStream() {
    final currentUser = _auth.currentUser;
    developer.log('Setting up active exams stream listener');
    developer.log('Stream - Current user: ${currentUser?.uid ?? 'null'}');
    developer.log('Stream - User authenticated: ${currentUser != null}');

    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      developer
          .log('Received ${snapshot.docs.length} active exams from Firestore');

      // Log first few document IDs for debugging
      if (snapshot.docs.isNotEmpty) {
        final firstFewIds =
            snapshot.docs.take(3).map((doc) => doc.id).join(', ');
        developer.log('First few exam IDs: $firstFewIds');
      }

      final exams =
          snapshot.docs.map((doc) => ExamModel.fromFirestore(doc)).toList();
      developer.log('Successfully parsed ${exams.length} exams');
      return exams;
    });
  }

  /// Stream of active exams including started live tests (real-time updates)
  static Stream<List<ExamModel>> getActiveExamsWithLiveTestsStream() {
    developer.log('Setting up combined exams and live tests stream listener');

    // Create a stream controller to manage the combined data
    late StreamController<List<ExamModel>> controller;

    controller = StreamController<List<ExamModel>>.broadcast(
      onListen: () async {
        // Initial load
        try {
          final initialData = await getActiveExamsWithLiveTests();
          if (!controller.isClosed) {
            controller.add(initialData);
          }
        } catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }

        // Set up periodic refresh every minute to check for new live tests
        Timer.periodic(const Duration(minutes: 1), (timer) async {
          if (controller.isClosed) {
            timer.cancel();
            return;
          }

          try {
            final data = await getActiveExamsWithLiveTests();
            if (!controller.isClosed) {
              controller.add(data);
            }
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        });
      },
      onCancel: () {
        controller.close();
      },
    );

    return controller.stream;
  }

  /// Stream of featured exams (real-time updates) - shows recent uploads
  static Stream<List<ExamModel>> getFeaturedExamsStream() {
    developer.log('Setting up featured exams stream listener');
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(5) // Limit to 5 for featured section
        .snapshots()
        .map((snapshot) {
      developer.log(
          'Received ${snapshot.docs.length} featured exams from Firestore');
      final exams =
          snapshot.docs.map((doc) => ExamModel.fromFirestore(doc)).toList();

      // Return only exams with questions for featured section
      final filteredExams =
          exams.where((exam) => exam.questions.isNotEmpty).toList();
      developer.log(
          'Filtered to ${filteredExams.length} featured exams with questions');
      return filteredExams;
    });
  }

  /// Stream of recent exams (for quiz list - all active exams)
  static Stream<List<ExamModel>> getRecentExamsStream({int? limit}) {
    developer.log('Setting up recent exams stream listener with limit: $limit');
    var query = _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      developer
          .log('Received ${snapshot.docs.length} recent exams from Firestore');
      final exams =
          snapshot.docs.map((doc) => ExamModel.fromFirestore(doc)).toList();
      developer.log('Successfully parsed ${exams.length} recent exams');
      return exams;
    });
  }

  /// Test function to manually query Firestore and debug data
  static Future<void> debugFirestoreConnection() async {
    try {
      final currentUser = _auth.currentUser;
      developer.log('=== FIRESTORE DEBUG TEST ===');
      developer.log('Current user: ${currentUser?.uid ?? 'null'}');
      developer.log('User email: ${currentUser?.email ?? 'null'}');
      developer.log('User authenticated: ${currentUser != null}');

      if (currentUser == null) {
        developer.log('ERROR: User not authenticated');
        return;
      }

      // Test 1: Query all documents in exams collection (no filters)
      developer.log('Test 1: Querying ALL documents in exams collection...');
      final allDocsSnapshot = await _firestore.collection(_collection).get();
      developer.log(
          'Found ${allDocsSnapshot.docs.length} total documents in exams collection');

      // Log details of each document
      for (var doc in allDocsSnapshot.docs) {
        final data = doc.data();
        developer.log('Doc ID: ${doc.id}');
        developer.log('  - name: ${data['name']}');
        developer.log('  - examType: ${data['examType']}');
        developer.log('  - isActive: ${data['isActive']}');
        developer.log('  - createdAt: ${data['createdAt']}');
        developer.log('  - numberOfQuestions: ${data['numberOfQuestions']}');
        developer.log(
            '  - questions length: ${(data['questions'] as List?)?.length ?? 0}');
      }

      // Test 2: Query only active documents
      developer.log('Test 2: Querying ACTIVE documents...');
      final activeDocsSnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();
      developer.log('Found ${activeDocsSnapshot.docs.length} active documents');

      // Test 3: Query with ordering
      developer.log('Test 3: Querying with ordering...');
      final orderedDocsSnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      developer
          .log('Found ${orderedDocsSnapshot.docs.length} ordered documents');

      // Test 4: Try to parse documents
      developer.log('Test 4: Parsing documents...');
      int successfullyParsed = 0;
      int failedToParse = 0;

      for (var doc in orderedDocsSnapshot.docs) {
        try {
          final exam = ExamModel.fromFirestore(doc);
          successfullyParsed++;
          developer.log('Successfully parsed: ${exam.name} (${exam.id})');
        } catch (e) {
          failedToParse++;
          developer.log('Failed to parse doc ${doc.id}: $e');
        }
      }

      developer.log(
          'Parsing results: $successfullyParsed successful, $failedToParse failed');
      developer.log('=== END FIRESTORE DEBUG TEST ===');
    } catch (e) {
      developer.log('ERROR in debug test: $e');
    }
  }

  /// Clear Firestore cache and force fresh data fetch
  static Future<void> clearCacheAndRefresh() async {
    try {
      developer.log('=== CLEARING FIRESTORE CACHE ===');

      // Clear Firestore cache
      await _firestore.clearPersistence();
      developer.log('Firestore cache cleared successfully');

      // Wait a moment for cache to clear
      await Future.delayed(const Duration(milliseconds: 500));

      // Force a fresh fetch
      developer.log('Forcing fresh data fetch...');
      final freshData = await getActiveExams();
      developer.log('Fresh fetch completed. Found ${freshData.length} exams');

      developer.log('=== CACHE CLEAR COMPLETE ===');
    } catch (e) {
      developer.log('ERROR clearing cache: $e');
    }
  }

  /// Force network fetch (bypass cache)
  static Future<List<ExamModel>> getActiveExamsFromNetwork() async {
    try {
      developer.log('=== FORCING NETWORK FETCH ===');

      // Disable network first, then re-enable to force fresh fetch
      await _firestore.disableNetwork();
      await Future.delayed(const Duration(milliseconds: 100));
      await _firestore.enableNetwork();

      // Now fetch fresh data
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server)); // Force server fetch

      developer.log(
          'Network fetch completed. Found ${querySnapshot.docs.length} documents');

      final exams = querySnapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .toList();

      developer.log('Successfully parsed ${exams.length} exams from network');
      return exams;
    } catch (e) {
      developer.log('ERROR in network fetch: $e');
      throw Exception('Failed to fetch from network: $e');
    }
  }
}
