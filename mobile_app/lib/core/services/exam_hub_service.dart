import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/exam_hub_models.dart';

/// Service class for managing exam hub data
class ExamHubService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String _newsCollection = 'exam_hub_news';
  static const String _tipsCollection = 'exam_hub_tips';
  static const String _papersCollection = 'exam_hub_papers';
  static const String _resultsCollection = 'exam_hub_results';

  // ==================== NEWS OPERATIONS ====================

  /// Get all active news items
  static Future<List<ExamHubNews>> getActiveNews({int? limit}) async {
    try {
      developer.log('Fetching active news items...');

      // First try with compound query, fallback to simple query if index doesn't exist
      Query query;
      try {
        query = _firestore
            .collection(_newsCollection)
            .where('isActive', isEqualTo: true)
            .orderBy('publishDate', descending: true);
      } catch (e) {
        developer.log('Compound query failed, using simple query: $e');
        // Fallback to simple query without ordering
        query = _firestore
            .collection(_newsCollection)
            .where('isActive', isEqualTo: true);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      developer.log('Found ${querySnapshot.docs.length} news items');

      var newsList = querySnapshot.docs
          .map((doc) => ExamHubNews.fromFirestore(doc))
          .toList();

      // Sort manually if we couldn't use orderBy
      newsList.sort((a, b) => b.publishDate.compareTo(a.publishDate));

      return newsList;
    } catch (e) {
      developer.log('Error fetching news: $e');
      throw Exception('Failed to fetch news items: $e');
    }
  }

  /// Get news by ID
  static Future<ExamHubNews?> getNewsById(String id) async {
    try {
      developer.log('Fetching news item with ID: $id');

      final docSnapshot =
          await _firestore.collection(_newsCollection).doc(id).get();

      if (docSnapshot.exists) {
        return ExamHubNews.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      developer.log('Error fetching news by ID: $e');
      throw Exception('Failed to fetch news item: $e');
    }
  }

  /// Stream of active news items
  static Stream<List<ExamHubNews>> getActiveNewsStream({int? limit}) {
    developer.log('Setting up news stream...');

    // Use simple query for streams to avoid index issues
    var query = _firestore
        .collection(_newsCollection)
        .where('isActive', isEqualTo: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      developer.log('Received ${snapshot.docs.length} news items from stream');
      var newsList =
          snapshot.docs.map((doc) => ExamHubNews.fromFirestore(doc)).toList();

      // Sort manually
      newsList.sort((a, b) => b.publishDate.compareTo(a.publishDate));

      return newsList;
    });
  }

  /// Increment view count for news
  static Future<void> incrementNewsViewCount(String id) async {
    try {
      await _firestore
          .collection(_newsCollection)
          .doc(id)
          .update({'viewCount': FieldValue.increment(1)});
      developer.log('Incremented view count for news: $id');
    } catch (e) {
      developer.log('Error incrementing news view count: $e');
    }
  }

  // ==================== TIPS OPERATIONS ====================

  /// Get all active tips items
  static Future<List<ExamHubTips>> getActiveTips({int? limit}) async {
    try {
      developer.log('Fetching active tips items...');

      // First try with compound query, fallback to simple query if index doesn't exist
      Query query;
      try {
        query = _firestore
            .collection(_tipsCollection)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true);
      } catch (e) {
        developer.log('Compound query failed, using simple query: $e');
        // Fallback to simple query without ordering
        query = _firestore
            .collection(_tipsCollection)
            .where('isActive', isEqualTo: true);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      developer.log('Found ${querySnapshot.docs.length} tips items');

      var tipsList = querySnapshot.docs
          .map((doc) => ExamHubTips.fromFirestore(doc))
          .toList();

      // Sort manually if we couldn't use orderBy
      tipsList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tipsList;
    } catch (e) {
      developer.log('Error fetching tips: $e');
      throw Exception('Failed to fetch tips items: $e');
    }
  }

  /// Get tips by ID
  static Future<ExamHubTips?> getTipsById(String id) async {
    try {
      developer.log('Fetching tips item with ID: $id');

      final docSnapshot =
          await _firestore.collection(_tipsCollection).doc(id).get();

      if (docSnapshot.exists) {
        return ExamHubTips.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      developer.log('Error fetching tips by ID: $e');
      throw Exception('Failed to fetch tips item: $e');
    }
  }

  /// Stream of active tips items
  static Stream<List<ExamHubTips>> getActiveTipsStream({int? limit}) {
    developer.log('Setting up tips stream...');

    var query = _firestore
        .collection(_tipsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      developer.log('Received ${snapshot.docs.length} tips items from stream');
      return snapshot.docs
          .map((doc) => ExamHubTips.fromFirestore(doc))
          .toList();
    });
  }

  /// Increment view count for tips
  static Future<void> incrementTipsViewCount(String id) async {
    try {
      await _firestore
          .collection(_tipsCollection)
          .doc(id)
          .update({'viewCount': FieldValue.increment(1)});
      developer.log('Incremented view count for tips: $id');
    } catch (e) {
      developer.log('Error incrementing tips view count: $e');
    }
  }

  // ==================== PAPERS OPERATIONS ====================

  /// Get all active papers items
  static Future<List<ExamHubPapers>> getActivePapers({int? limit}) async {
    try {
      developer.log('Fetching active papers items...');

      // First try with compound query, fallback to simple query if index doesn't exist
      Query query;
      try {
        query = _firestore
            .collection(_papersCollection)
            .where('isActive', isEqualTo: true)
            .orderBy('examDate', descending: true);
      } catch (e) {
        developer.log('Compound query failed, using simple query: $e');
        // Fallback to simple query without ordering
        query = _firestore
            .collection(_papersCollection)
            .where('isActive', isEqualTo: true);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      developer.log('Found ${querySnapshot.docs.length} papers items');

      var papersList = querySnapshot.docs
          .map((doc) => ExamHubPapers.fromFirestore(doc))
          .toList();

      // Sort manually if we couldn't use orderBy
      papersList.sort((a, b) => b.examDate.compareTo(a.examDate));

      return papersList;
    } catch (e) {
      developer.log('Error fetching papers: $e');
      throw Exception('Failed to fetch papers items: $e');
    }
  }

  /// Get papers by ID
  static Future<ExamHubPapers?> getPapersById(String id) async {
    try {
      developer.log('Fetching papers item with ID: $id');

      final docSnapshot =
          await _firestore.collection(_papersCollection).doc(id).get();

      if (docSnapshot.exists) {
        return ExamHubPapers.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      developer.log('Error fetching papers by ID: $e');
      throw Exception('Failed to fetch papers item: $e');
    }
  }

  /// Stream of active papers items
  static Stream<List<ExamHubPapers>> getActivePapersStream({int? limit}) {
    developer.log('Setting up papers stream...');

    var query = _firestore
        .collection(_papersCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('examDate', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      developer
          .log('Received ${snapshot.docs.length} papers items from stream');
      return snapshot.docs
          .map((doc) => ExamHubPapers.fromFirestore(doc))
          .toList();
    });
  }

  /// Increment view count for papers
  static Future<void> incrementPapersViewCount(String id) async {
    try {
      await _firestore
          .collection(_papersCollection)
          .doc(id)
          .update({'viewCount': FieldValue.increment(1)});
      developer.log('Incremented view count for papers: $id');
    } catch (e) {
      developer.log('Error incrementing papers view count: $e');
    }
  }

  // ==================== RESULTS OPERATIONS ====================

  /// Get all active results items
  static Future<List<ExamHubResults>> getActiveResults({int? limit}) async {
    try {
      developer.log('Fetching active results items...');

      // First try with compound query, fallback to simple query if index doesn't exist
      Query query;
      try {
        query = _firestore
            .collection(_resultsCollection)
            .where('isActive', isEqualTo: true)
            .orderBy('publishDate', descending: true);
      } catch (e) {
        developer.log('Compound query failed, using simple query: $e');
        // Fallback to simple query without ordering
        query = _firestore
            .collection(_resultsCollection)
            .where('isActive', isEqualTo: true);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      developer.log('Found ${querySnapshot.docs.length} results items');

      var resultsList = querySnapshot.docs
          .map((doc) => ExamHubResults.fromFirestore(doc))
          .toList();

      // Sort manually if we couldn't use orderBy
      resultsList.sort((a, b) => b.publishDate.compareTo(a.publishDate));

      return resultsList;
    } catch (e) {
      developer.log('Error fetching results: $e');
      throw Exception('Failed to fetch results items: $e');
    }
  }

  /// Get results by ID
  static Future<ExamHubResults?> getResultsById(String id) async {
    try {
      developer.log('Fetching results item with ID: $id');

      final docSnapshot =
          await _firestore.collection(_resultsCollection).doc(id).get();

      if (docSnapshot.exists) {
        return ExamHubResults.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      developer.log('Error fetching results by ID: $e');
      throw Exception('Failed to fetch results item: $e');
    }
  }

  /// Stream of active results items
  static Stream<List<ExamHubResults>> getActiveResultsStream({int? limit}) {
    developer.log('Setting up results stream...');

    var query = _firestore
        .collection(_resultsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('publishDate', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      developer
          .log('Received ${snapshot.docs.length} results items from stream');
      return snapshot.docs
          .map((doc) => ExamHubResults.fromFirestore(doc))
          .toList();
    });
  }

  /// Increment view count for results
  static Future<void> incrementResultsViewCount(String id) async {
    try {
      await _firestore
          .collection(_resultsCollection)
          .doc(id)
          .update({'viewCount': FieldValue.increment(1)});
      developer.log('Incremented view count for results: $id');
    } catch (e) {
      developer.log('Error incrementing results view count: $e');
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Increment download count for any exam hub item
  static Future<void> incrementDownloadCount(
      String collection, String id) async {
    try {
      await _firestore
          .collection(collection)
          .doc(id)
          .update({'downloadCount': FieldValue.increment(1)});
      developer.log('Incremented download count for $collection: $id');
    } catch (e) {
      developer.log('Error incrementing download count: $e');
    }
  }

  /// Get exam hub statistics
  static Future<Map<String, int>> getExamHubStats() async {
    try {
      developer.log('Fetching exam hub statistics...');

      final results = await Future.wait([
        _firestore
            .collection(_newsCollection)
            .where('isActive', isEqualTo: true)
            .get(),
        _firestore
            .collection(_tipsCollection)
            .where('isActive', isEqualTo: true)
            .get(),
        _firestore
            .collection(_papersCollection)
            .where('isActive', isEqualTo: true)
            .get(),
        _firestore
            .collection(_resultsCollection)
            .where('isActive', isEqualTo: true)
            .get(),
      ]);

      return {
        'news': results[0].docs.length,
        'tips': results[1].docs.length,
        'papers': results[2].docs.length,
        'results': results[3].docs.length,
      };
    } catch (e) {
      developer.log('Error fetching exam hub stats: $e');
      return {
        'news': 0,
        'tips': 0,
        'papers': 0,
        'results': 0,
      };
    }
  }
}
