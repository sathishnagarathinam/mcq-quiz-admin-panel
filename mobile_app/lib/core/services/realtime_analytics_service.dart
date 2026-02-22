import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_analytics_model.dart';
import '../models/platform_analytics_model.dart';
import '../models/quiz_attempt_model.dart';

// Key for storing authenticated phone number
const String _authPhoneKey = 'authenticated_phone_number';

/// Service for real-time analytics data synchronization
class RealtimeAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream controllers for real-time updates
  final StreamController<UserAnalyticsModel?> _userAnalyticsController =
      StreamController<UserAnalyticsModel?>.broadcast();
  final StreamController<PlatformAnalyticsModel?> _platformAnalyticsController =
      StreamController<PlatformAnalyticsModel?>.broadcast();
  final StreamController<List<QuizAttemptModel>> _recentAttemptsController =
      StreamController<List<QuizAttemptModel>>.broadcast();

  // Cache for performance optimization
  final Map<String, UserAnalyticsModel> _userAnalyticsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  PlatformAnalyticsModel? _platformAnalyticsCache;
  DateTime? _platformCacheTimestamp;

  // Firestore listeners
  StreamSubscription<DocumentSnapshot>? _userAnalyticsListener;
  StreamSubscription<DocumentSnapshot>? _platformAnalyticsListener;
  StreamSubscription<QuerySnapshot>? _recentAttemptsListener;

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Current user ID (cached)
  String? _currentUserId;

  /// Get current user ID (supports both Firebase Auth and phone auth)
  String? get currentUserId {
    // If already cached, return it
    if (_currentUserId != null) {
      return _currentUserId;
    }

    // Check Firebase Auth first
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _currentUserId = firebaseUser.uid;
      return _currentUserId;
    }

    // For phone auth users, we need to get it from SharedPreferences
    // This is a sync getter, so we can't use async. The user ID should be
    // set via setCurrentUserId() method when the user logs in.
    return _currentUserId;
  }

  /// Set current user ID (call this when user logs in via phone auth)
  Future<void> setCurrentUserId() async {
    // Check Firebase Auth first
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _currentUserId = firebaseUser.uid;
      return;
    }

    // Check phone auth via SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString(_authPhoneKey);
      if (savedPhone != null && savedPhone.isNotEmpty) {
        // Return phone number without + as user ID (matches Firestore document ID)
        _currentUserId = savedPhone.replaceAll('+', '');
      }
    } catch (e) {
      print('Error getting phone user ID: $e');
    }
  }

  /// Clear cached user ID (call this on sign out)
  void clearCachedUserId() {
    _currentUserId = null;
  }

  /// Stream for user analytics updates
  Stream<UserAnalyticsModel?> get userAnalyticsStream =>
      _userAnalyticsController.stream;

  /// Stream for platform analytics updates
  Stream<PlatformAnalyticsModel?> get platformAnalyticsStream =>
      _platformAnalyticsController.stream;

  /// Stream for recent attempts updates
  Stream<List<QuizAttemptModel>> get recentAttemptsStream =>
      _recentAttemptsController.stream;

  /// Start listening to user analytics for current user
  void startUserAnalyticsListener() {
    if (currentUserId == null) return;

    _userAnalyticsListener?.cancel();

    _userAnalyticsListener = _firestore
        .collection('user_analytics')
        .doc(currentUserId!)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          if (snapshot.exists) {
            final analytics = UserAnalyticsModel.fromFirestore(snapshot);
            _userAnalyticsCache[currentUserId!] = analytics;
            _cacheTimestamps[currentUserId!] = DateTime.now();
            _userAnalyticsController.add(analytics);
          } else {
            _userAnalyticsController.add(null);
          }
        } catch (e) {
          print('Error in user analytics listener: $e');
          _userAnalyticsController.addError(e);
        }
      },
      onError: (error) {
        print('User analytics listener error: $error');
        _userAnalyticsController.addError(error);
      },
    );
  }

  /// Start listening to platform analytics
  void startPlatformAnalyticsListener() {
    _platformAnalyticsListener?.cancel();

    _platformAnalyticsListener = _firestore
        .collection('platform_analytics')
        .doc('global')
        .snapshots()
        .listen(
      (snapshot) {
        try {
          if (snapshot.exists) {
            final analytics = PlatformAnalyticsModel.fromFirestore(snapshot);
            _platformAnalyticsCache = analytics;
            _platformCacheTimestamp = DateTime.now();
            _platformAnalyticsController.add(analytics);
          } else {
            _platformAnalyticsController.add(null);
          }
        } catch (e) {
          print('Error in platform analytics listener: $e');
          _platformAnalyticsController.addError(e);
        }
      },
      onError: (error) {
        print('Platform analytics listener error: $error');
        _platformAnalyticsController.addError(error);
      },
    );
  }

  /// Start listening to recent quiz attempts
  void startRecentAttemptsListener({String? userId, int limit = 20}) {
    _recentAttemptsListener?.cancel();

    Query query = _firestore.collection('quiz_attempts');

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    query = query.orderBy('attemptedAt', descending: true).limit(limit);

    _recentAttemptsListener = query.snapshots().listen(
      (snapshot) {
        try {
          final attempts = snapshot.docs
              .map((doc) => QuizAttemptModel.fromFirestore(doc))
              .toList();
          _recentAttemptsController.add(attempts);
        } catch (e) {
          print('Error in recent attempts listener: $e');
          _recentAttemptsController.addError(e);
        }
      },
      onError: (error) {
        print('Recent attempts listener error: $error');
        _recentAttemptsController.addError(error);
      },
    );
  }

  /// Get user analytics with caching
  Future<UserAnalyticsModel?> getUserAnalytics(String userId,
      {bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _isUserAnalyticsCacheValid(userId)) {
      return _userAnalyticsCache[userId];
    }

    try {
      final doc =
          await _firestore.collection('user_analytics').doc(userId).get();

      if (doc.exists) {
        final analytics = UserAnalyticsModel.fromFirestore(doc);
        _userAnalyticsCache[userId] = analytics;
        _cacheTimestamps[userId] = DateTime.now();
        return analytics;
      }
      return null;
    } catch (e) {
      print('Error getting user analytics: $e');
      return null;
    }
  }

  /// Get platform analytics with caching
  Future<PlatformAnalyticsModel?> getPlatformAnalytics(
      {bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _isPlatformAnalyticsCacheValid()) {
      return _platformAnalyticsCache;
    }

    try {
      final doc =
          await _firestore.collection('platform_analytics').doc('global').get();

      if (doc.exists) {
        final analytics = PlatformAnalyticsModel.fromFirestore(doc);
        _platformAnalyticsCache = analytics;
        _platformCacheTimestamp = DateTime.now();
        return analytics;
      }
      return null;
    } catch (e) {
      print('Error getting platform analytics: $e');
      return null;
    }
  }

  /// Update user analytics with real-time sync
  Future<void> updateUserAnalytics(
      String userId, UserAnalyticsModel analytics) async {
    try {
      await _firestore
          .collection('user_analytics')
          .doc(userId)
          .set(analytics.toFirestore(), SetOptions(merge: true));

      // Update cache
      _userAnalyticsCache[userId] = analytics;
      _cacheTimestamps[userId] = DateTime.now();
    } catch (e) {
      print('Error updating user analytics: $e');
      rethrow;
    }
  }

  /// Update platform analytics with real-time sync
  Future<void> updatePlatformAnalytics(PlatformAnalyticsModel analytics) async {
    try {
      await _firestore
          .collection('platform_analytics')
          .doc('global')
          .set(analytics.toFirestore(), SetOptions(merge: true));

      // Update cache
      _platformAnalyticsCache = analytics;
      _platformCacheTimestamp = DateTime.now();
    } catch (e) {
      print('Error updating platform analytics: $e');
      rethrow;
    }
  }

  /// Batch update multiple user analytics
  Future<void> batchUpdateUserAnalytics(
      Map<String, UserAnalyticsModel> analyticsMap) async {
    try {
      final batch = _firestore.batch();

      analyticsMap.forEach((userId, analytics) {
        final docRef = _firestore.collection('user_analytics').doc(userId);
        batch.set(docRef, analytics.toFirestore(), SetOptions(merge: true));

        // Update cache
        _userAnalyticsCache[userId] = analytics;
        _cacheTimestamps[userId] = DateTime.now();
      });

      await batch.commit();
    } catch (e) {
      print('Error batch updating user analytics: $e');
      rethrow;
    }
  }

  /// Invalidate cache for specific user
  void invalidateUserCache(String userId) {
    _userAnalyticsCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Invalidate platform analytics cache
  void invalidatePlatformCache() {
    _platformAnalyticsCache = null;
    _platformCacheTimestamp = null;
  }

  /// Clear all caches
  void clearAllCaches() {
    _userAnalyticsCache.clear();
    _cacheTimestamps.clear();
    _platformAnalyticsCache = null;
    _platformCacheTimestamp = null;
  }

  /// Check if user analytics cache is valid
  bool _isUserAnalyticsCacheValid(String userId) {
    if (!_userAnalyticsCache.containsKey(userId) ||
        !_cacheTimestamps.containsKey(userId)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[userId]!;
    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  /// Check if platform analytics cache is valid
  bool _isPlatformAnalyticsCacheValid() {
    if (_platformAnalyticsCache == null || _platformCacheTimestamp == null) {
      return false;
    }

    return DateTime.now().difference(_platformCacheTimestamp!) < _cacheDuration;
  }

  /// Start all listeners for current user
  void startAllListeners() {
    startUserAnalyticsListener();
    startPlatformAnalyticsListener();
    startRecentAttemptsListener(userId: currentUserId);
  }

  /// Stop all listeners
  void stopAllListeners() {
    _userAnalyticsListener?.cancel();
    _platformAnalyticsListener?.cancel();
    _recentAttemptsListener?.cancel();

    _userAnalyticsListener = null;
    _platformAnalyticsListener = null;
    _recentAttemptsListener = null;
  }

  /// Dispose of all resources
  void dispose() {
    stopAllListeners();
    _userAnalyticsController.close();
    _platformAnalyticsController.close();
    _recentAttemptsController.close();
    clearAllCaches();
  }

  /// Preload analytics data for better performance
  Future<void> preloadAnalytics() async {
    try {
      // Preload current user analytics
      if (currentUserId != null) {
        await getUserAnalytics(currentUserId!);
      }

      // Preload platform analytics
      await getPlatformAnalytics();
    } catch (e) {
      print('Error preloading analytics: $e');
    }
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'userAnalyticsCacheSize': _userAnalyticsCache.length,
      'platformAnalyticsCached': _platformAnalyticsCache != null,
      'cacheTimestamps': _cacheTimestamps.length,
      'activeListeners': {
        'userAnalytics': _userAnalyticsListener != null,
        'platformAnalytics': _platformAnalyticsListener != null,
        'recentAttempts': _recentAttemptsListener != null,
      },
    };
  }
}
