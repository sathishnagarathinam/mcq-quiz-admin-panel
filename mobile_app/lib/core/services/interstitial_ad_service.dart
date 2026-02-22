import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/interstitial_ad_model.dart';

/// Service for managing interstitial advertisements
class InterstitialAdService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'interstitial_ads';

  /// Get all active interstitial ads
  static Future<List<InterstitialAdModel>> getActiveAds() async {
    try {
      developer.log('📢 Fetching active interstitial ads...');
      developer.log('📢 Collection: $_collection');

      // Simple query without orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      developer.log(
          '📢 Firestore returned ${snapshot.docs.length} docs with isActive=true');

      if (snapshot.docs.isEmpty) {
        // Fallback: fetch ALL documents in case isActive field doesn't exist or has different type
        developer
            .log('📢 No docs with isActive=true, trying to fetch all docs...');
        final allSnapshot = await _firestore.collection(_collection).get();
        developer
            .log('📢 Total docs in collection: ${allSnapshot.docs.length}');

        for (final doc in allSnapshot.docs) {
          final data = doc.data();
          developer.log(
              '📢 Doc ${doc.id}: isActive=${data['isActive']} (type: ${data['isActive'].runtimeType}), title=${data['title']}');
        }

        final allAds = allSnapshot.docs
            .map((doc) {
              try {
                return InterstitialAdModel.fromFirestore(doc);
              } catch (e) {
                developer.log('❌ Error parsing doc ${doc.id}: $e');
                return null;
              }
            })
            .whereType<InterstitialAdModel>()
            .where((ad) => ad.isCurrentlyActive)
            .toList();

        allAds.sort((a, b) => b.priority.compareTo(a.priority));

        developer.log(
            '📢 Found ${allAds.length} active interstitial ads (from all docs)');
        return allAds;
      }

      final ads = snapshot.docs
          .map((doc) {
            try {
              return InterstitialAdModel.fromFirestore(doc);
            } catch (e) {
              developer.log('❌ Error parsing doc ${doc.id}: $e');
              return null;
            }
          })
          .whereType<InterstitialAdModel>()
          .where((ad) => ad.isCurrentlyActive)
          .toList();

      // Sort by priority descending in-memory
      ads.sort((a, b) => b.priority.compareTo(a.priority));

      developer.log('📢 Found ${ads.length} active interstitial ads');
      return ads;
    } catch (e, stackTrace) {
      developer.log('❌ Error fetching interstitial ads: $e');
      developer.log('❌ Stack trace: $stackTrace');

      try {
        developer.log('📢 Attempting fallback: fetch all docs without filter');
        final allSnapshot = await _firestore.collection(_collection).get();
        developer.log(
            '📢 Fallback: Total docs in collection: ${allSnapshot.docs.length}');

        final allAds = allSnapshot.docs
            .map((doc) {
              try {
                return InterstitialAdModel.fromFirestore(doc);
              } catch (e) {
                developer.log('❌ Error parsing doc ${doc.id}: $e');
                return null;
              }
            })
            .whereType<InterstitialAdModel>()
            .where((ad) => ad.isCurrentlyActive)
            .toList();

        allAds.sort((a, b) => b.priority.compareTo(a.priority));

        developer
            .log('📢 Fallback found ${allAds.length} active interstitial ads');
        return allAds;
      } catch (fallbackError) {
        developer.log('❌ Fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Stream of active interstitial ads for real-time updates
  static Stream<List<InterstitialAdModel>> streamActiveAds() {
    developer.log('📢 Starting interstitial ads stream...');
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final ads = snapshot.docs
          .map((doc) {
            try {
              return InterstitialAdModel.fromFirestore(doc);
            } catch (e) {
              developer.log('❌ Error parsing doc ${doc.id}: $e');
              return null;
            }
          })
          .whereType<InterstitialAdModel>()
          .where((ad) => ad.isCurrentlyActive)
          .toList();

      ads.sort((a, b) => b.priority.compareTo(a.priority));

      developer.log('📢 Stream update: ${ads.length} active interstitial ads');
      return ads;
    });
  }

  /// Get the highest priority active ad to display
  static Future<InterstitialAdModel?> getNextAdToShow() async {
    try {
      developer.log('📢 getNextAdToShow called...');
      final ads = await getActiveAds();
      developer.log('📢 getNextAdToShow: got ${ads.length} ads');
      if (ads.isEmpty) {
        developer.log('📢 getNextAdToShow: No active ads found');
        return null;
      }
      developer.log(
          '📢 getNextAdToShow: Returning ad "${ads.first.title}" (priority: ${ads.first.priority})');
      return ads.first;
    } catch (e) {
      developer.log('❌ Error getting next ad to show: $e');
      return null;
    }
  }

  /// Get ad by ID
  static Future<InterstitialAdModel?> getAdById(String adId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(adId).get();
      if (!doc.exists) return null;
      return InterstitialAdModel.fromFirestore(doc);
    } catch (e) {
      developer.log('❌ Error fetching ad by ID: $e');
      return null;
    }
  }
}
