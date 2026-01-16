import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static const String _usersCollection = 'mobile_users';

  /// Create user document in Firestore
  static Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
    required String phoneNumber,
    required String officeName,
    required String designation,
  }) async {
    try {
      final userDoc = {
        'uid': uid,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'officeName': officeName,
        'designation': designation,
        'userType': 'mobile_user',
        'role': 'user',
        'isActive': true,
        'emailVerified': false,
        'profileComplete': true,
        'quizzesTaken': 0,
        'totalScore': 0,
        'averageScore': 0.0,
        'stats': {
          'totalQuizzes': 0,
          'totalScore': 0,
          'averageScore': 0.0,
          'currentStreak': 0,
          'longestStreak': 0,
          'totalTimeSpent': 0,
        },
        'preferences': {
          'darkMode': false,
          'notifications': true,
          'language': 'en',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_usersCollection).doc(uid).set(userDoc);
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  /// Get user document from Firestore
  static Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get user document: $e');
    }
  }

  /// Update user document in Firestore
  static Future<void> updateUserDocument(
      String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_usersCollection).doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user document: $e');
    }
  }

  /// Update last login time
  static Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last login: $e');
    }
  }

  /// Update user stats
  static Future<void> updateUserStats(
      String uid, Map<String, dynamic> stats) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'stats': stats,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user stats: $e');
    }
  }

  /// Update user preferences
  static Future<void> updateUserPreferences(
      String uid, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user preferences: $e');
    }
  }

  /// Check if user document exists
  static Future<bool> userDocumentExists(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Delete user document
  static Future<void> deleteUserDocument(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user document: $e');
    }
  }

  /// Get users by designation
  static Future<List<Map<String, dynamic>>> getUsersByDesignation(
      String designation) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('designation', isEqualTo: designation)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get users by designation: $e');
    }
  }

  /// Get users by office
  static Future<List<Map<String, dynamic>>> getUsersByOffice(
      String officeName) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('officeName', isEqualTo: officeName)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get users by office: $e');
    }
  }

  /// Search users by name
  static Future<List<Map<String, dynamic>>> searchUsersByName(
      String name) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThanOrEqualTo: '$name\uf8ff')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
