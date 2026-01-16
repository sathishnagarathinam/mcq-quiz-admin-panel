import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/live_test_model.dart';

/// Service for managing live tests
class LiveTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all live tests stream (simplified - no indexes required)
  static Stream<List<LiveTestModel>> getLiveTestsStream() {
    print('🔥 LiveTestService: Setting up simple live tests stream...');
    return _firestore.collection('live_tests').snapshots().map((snapshot) {
      print(
          '🔥 LiveTestService: Received ${snapshot.docs.length} live tests from Firestore');

      final liveTests = snapshot.docs.map((doc) {
        print('🔥 LiveTestService: Processing live test doc: ${doc.id}');
        print('🔥 LiveTestService: Live test data: ${doc.data()}');
        return LiveTestModel.fromFirestore(doc);
      }).toList();

      // Sort in memory to avoid index requirements
      liveTests.sort((a, b) => a.startTime.compareTo(b.startTime));

      print(
          '✅ LiveTestService: Returning ${liveTests.length} live tests (sorted in memory)');
      return liveTests;
    });
  }

  /// Get active live tests stream
  static Stream<List<LiveTestModel>> getActiveLiveTestsStream() {
    return _firestore
        .collection('live_tests')
        .where('isActive', isEqualTo: true)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LiveTestModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get upcoming live tests
  static Stream<List<LiveTestModel>> getUpcomingLiveTestsStream() {
    print('🔥 LiveTestService: Setting up upcoming live tests stream...');
    final now = DateTime.now();
    print('🔥 LiveTestService: Current time: $now');

    // Simplified query to avoid Firestore limitations - just get all live tests
    return _firestore.collection('live_tests').snapshots().map((snapshot) {
      print(
          '🔥 LiveTestService: Received ${snapshot.docs.length} live tests from Firestore');

      final liveTests = snapshot.docs.map((doc) {
        print('🔥 LiveTestService: Processing live test doc: ${doc.id}');
        print('🔥 LiveTestService: Live test data: ${doc.data()}');
        return LiveTestModel.fromFirestore(doc);
      }).toList();

      // Filter in memory to avoid complex Firestore queries
      final upcomingTests = liveTests
          .where((test) {
            final isUpcoming =
                test.status == 'upcoming' && test.startTime.isAfter(now);
            print(
                '🔥 LiveTestService: Test ${test.title} - status: ${test.status}, isUpcoming: $isUpcoming');
            return test.isActive && isUpcoming;
          })
          .take(5)
          .toList();

      print(
          '✅ LiveTestService: Returning ${upcomingTests.length} upcoming tests');
      return upcomingTests;
    });
  }

  /// Get currently live tests
  static Stream<List<LiveTestModel>> getCurrentlyLiveTestsStream() {
    final now = DateTime.now();
    return _firestore
        .collection('live_tests')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'live')
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LiveTestModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get single live test
  static Future<LiveTestModel?> getLiveTest(String testId) async {
    try {
      final doc = await _firestore.collection('live_tests').doc(testId).get();
      if (doc.exists) {
        return LiveTestModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting live test: $e');
      return null;
    }
  }

  /// Create new live test
  static Future<String?> createLiveTest(LiveTestModel liveTest) async {
    try {
      final docRef =
          await _firestore.collection('live_tests').add(liveTest.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating live test: $e');
      return null;
    }
  }

  /// Update live test
  static Future<bool> updateLiveTest(
      String testId, LiveTestModel liveTest) async {
    try {
      await _firestore
          .collection('live_tests')
          .doc(testId)
          .update(liveTest.copyWith(updatedAt: DateTime.now()).toFirestore());
      return true;
    } catch (e) {
      print('Error updating live test: $e');
      return false;
    }
  }

  /// Delete live test
  static Future<bool> deleteLiveTest(String testId) async {
    try {
      await _firestore.collection('live_tests').doc(testId).delete();
      return true;
    } catch (e) {
      print('Error deleting live test: $e');
      return false;
    }
  }

  /// Update live test status
  static Future<bool> updateLiveTestStatus(String testId, String status) async {
    try {
      await _firestore.collection('live_tests').doc(testId).update({
        'status': status,
        'isLive': status == 'live',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error updating live test status: $e');
      return false;
    }
  }

  /// Join live test (increment participant count)
  static Future<bool> joinLiveTest(String testId) async {
    try {
      await _firestore.collection('live_tests').doc(testId).update({
        'currentParticipants': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error joining live test: $e');
      return false;
    }
  }

  /// Leave live test (decrement participant count)
  static Future<bool> leaveLiveTest(String testId) async {
    try {
      await _firestore.collection('live_tests').doc(testId).update({
        'currentParticipants': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error leaving live test: $e');
      return false;
    }
  }

  /// Get next upcoming live test
  static Future<LiveTestModel?> getNextLiveTest() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('live_tests')
          .where('isActive', isEqualTo: true)
          .where('startTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startTime', descending: false)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return LiveTestModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting next live test: $e');
      return null;
    }
  }
}

/// Provider for all live tests
final liveTestsProvider = StreamProvider<List<LiveTestModel>>((ref) {
  return LiveTestService.getLiveTestsStream();
});

/// Provider for active live tests
final activeLiveTestsProvider = StreamProvider<List<LiveTestModel>>((ref) {
  return LiveTestService.getActiveLiveTestsStream();
});

/// Provider for upcoming live tests
final upcomingLiveTestsProvider = StreamProvider<List<LiveTestModel>>((ref) {
  print('🔥 upcomingLiveTestsProvider: Creating provider...');
  return LiveTestService.getUpcomingLiveTestsStream();
});

/// Provider for currently live tests
final currentlyLiveTestsProvider = StreamProvider<List<LiveTestModel>>((ref) {
  return LiveTestService.getCurrentlyLiveTestsStream();
});

/// Provider for next live test
final nextLiveTestProvider = FutureProvider<LiveTestModel?>((ref) {
  return LiveTestService.getNextLiveTest();
});

/// Provider for single live test
final liveTestProvider =
    FutureProvider.family<LiveTestModel?, String>((ref, testId) {
  return LiveTestService.getLiveTest(testId);
});

/// State notifier for live test management
class LiveTestNotifier extends StateNotifier<AsyncValue<List<LiveTestModel>>> {
  LiveTestNotifier() : super(const AsyncValue.loading()) {
    _loadLiveTests();
  }

  void _loadLiveTests() {
    LiveTestService.getLiveTestsStream().listen(
      (liveTests) {
        state = AsyncValue.data(liveTests);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  Future<bool> createLiveTest(LiveTestModel liveTest) async {
    final result = await LiveTestService.createLiveTest(liveTest);
    return result != null;
  }

  Future<bool> updateLiveTest(String testId, LiveTestModel liveTest) async {
    return await LiveTestService.updateLiveTest(testId, liveTest);
  }

  Future<bool> deleteLiveTest(String testId) async {
    return await LiveTestService.deleteLiveTest(testId);
  }

  Future<bool> updateStatus(String testId, String status) async {
    return await LiveTestService.updateLiveTestStatus(testId, status);
  }

  Future<bool> joinTest(String testId) async {
    return await LiveTestService.joinLiveTest(testId);
  }

  Future<bool> leaveTest(String testId) async {
    return await LiveTestService.leaveLiveTest(testId);
  }
}

/// Provider for live test management
final liveTestNotifierProvider =
    StateNotifierProvider<LiveTestNotifier, AsyncValue<List<LiveTestModel>>>(
        (ref) {
  return LiveTestNotifier();
});
