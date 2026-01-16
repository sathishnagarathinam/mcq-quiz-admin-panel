import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/banner_model.dart';

/// Service for managing promotional banners
class BannerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all banners stream (simplified - no indexes required)
  static Stream<List<BannerModel>> getBannersStream() {
    print('🔥 BannerService: Setting up simple banners stream...');
    return _firestore.collection('banners').snapshots().map((snapshot) {
      print(
          '🔥 BannerService: Received ${snapshot.docs.length} banners from Firestore');

      final banners = snapshot.docs.map((doc) {
        print('🔥 BannerService: Processing banner doc: ${doc.id}');
        print('🔥 BannerService: Banner data: ${doc.data()}');
        return BannerModel.fromFirestore(doc);
      }).toList();

      // Sort in memory to avoid index requirements
      banners.sort((a, b) {
        // Sort by priority first (descending), then by createdAt (descending)
        int priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return b.createdAt.compareTo(a.createdAt);
      });

      print(
          '✅ BannerService: Returning ${banners.length} banners (sorted in memory)');
      return banners;
    });
  }

  /// Get active banners stream
  static Stream<List<BannerModel>> getActiveBannersStream() {
    print('🔥 BannerService: Setting up active banners stream...');
    final now = DateTime.now();
    print('🔥 BannerService: Current time: $now');

    // Simplified query to avoid Firestore limitations - just get all banners
    return _firestore.collection('banners').snapshots().map((snapshot) {
      print(
          '🔥 BannerService: Received ${snapshot.docs.length} banners from Firestore');

      final banners = snapshot.docs.map((doc) {
        print('🔥 BannerService: Processing banner doc: ${doc.id}');
        print('🔥 BannerService: Banner data: ${doc.data()}');
        return BannerModel.fromFirestore(doc);
      }).toList();

      // Filter by date in memory to avoid complex Firestore queries
      final activeBanners = banners.where((banner) {
        final isInDateRange =
            banner.startDate.isBefore(now) && banner.endDate.isAfter(now);
        print(
            '🔥 BannerService: Banner ${banner.title} - isActive: ${banner.isActive}, inDateRange: $isInDateRange');
        return banner.isActive && isInDateRange;
      }).toList();

      print(
          '✅ BannerService: Returning ${activeBanners.length} active banners');
      return activeBanners;
    });
  }

  /// Get single banner
  static Future<BannerModel?> getBanner(String bannerId) async {
    try {
      final doc = await _firestore.collection('banners').doc(bannerId).get();
      if (doc.exists) {
        return BannerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting banner: $e');
      return null;
    }
  }

  /// Create new banner
  static Future<String?> createBanner(BannerModel banner) async {
    try {
      final docRef =
          await _firestore.collection('banners').add(banner.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating banner: $e');
      return null;
    }
  }

  /// Update banner
  static Future<bool> updateBanner(String bannerId, BannerModel banner) async {
    try {
      await _firestore
          .collection('banners')
          .doc(bannerId)
          .update(banner.copyWith(updatedAt: DateTime.now()).toFirestore());
      return true;
    } catch (e) {
      print('Error updating banner: $e');
      return false;
    }
  }

  /// Delete banner
  static Future<bool> deleteBanner(String bannerId) async {
    try {
      await _firestore.collection('banners').doc(bannerId).delete();
      return true;
    } catch (e) {
      print('Error deleting banner: $e');
      return false;
    }
  }

  /// Toggle banner active status
  static Future<bool> toggleBannerStatus(String bannerId, bool isActive) async {
    try {
      await _firestore.collection('banners').doc(bannerId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error toggling banner status: $e');
      return false;
    }
  }

  /// Get highest priority banner that's currently active
  static Future<BannerModel?> getCurrentBanner() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('banners')
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('endDate')
          .orderBy('priority', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return BannerModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting current banner: $e');
      return null;
    }
  }
}

/// Provider for all banners
final bannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return BannerService.getBannersStream();
});

/// Provider for active banners only
final activeBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  print('🔥 activeBannersProvider: Creating provider...');
  return BannerService.getActiveBannersStream();
});

/// Provider for current banner (highest priority active banner)
final currentBannerProvider = FutureProvider<BannerModel?>((ref) {
  return BannerService.getCurrentBanner();
});

/// Provider for single banner
final bannerProvider =
    FutureProvider.family<BannerModel?, String>((ref, bannerId) {
  return BannerService.getBanner(bannerId);
});

/// State notifier for banner management
class BannerNotifier extends StateNotifier<AsyncValue<List<BannerModel>>> {
  BannerNotifier() : super(const AsyncValue.loading()) {
    _loadBanners();
  }

  void _loadBanners() {
    BannerService.getBannersStream().listen(
      (banners) {
        state = AsyncValue.data(banners);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  Future<bool> createBanner(BannerModel banner) async {
    final result = await BannerService.createBanner(banner);
    return result != null;
  }

  Future<bool> updateBanner(String bannerId, BannerModel banner) async {
    return await BannerService.updateBanner(bannerId, banner);
  }

  Future<bool> deleteBanner(String bannerId) async {
    return await BannerService.deleteBanner(bannerId);
  }

  Future<bool> toggleBannerStatus(String bannerId, bool isActive) async {
    return await BannerService.toggleBannerStatus(bannerId, isActive);
  }
}

/// Provider for banner management
final bannerNotifierProvider =
    StateNotifierProvider<BannerNotifier, AsyncValue<List<BannerModel>>>((ref) {
  return BannerNotifier();
});
