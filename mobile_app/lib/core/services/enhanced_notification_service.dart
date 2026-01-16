import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../models/notification_model.dart';

/// Enhanced notification service for handling notifications from admin panel
class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _notificationRecipientsCollection =
      'notification_recipients';
  static const String _notificationsCollection = 'notifications';

  static bool _isInitialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request basic permissions
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('EnhancedNotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing EnhancedNotificationService: $e');
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    try {
      // Request local notification permission for Android 13+
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        debugPrint('Local notification permission: $status');
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Get notifications for a specific user
  static Future<List<UserNotification>> getUserNotifications(String userId,
      {int limit = 50}) async {
    try {
      debugPrint('🔍 Searching for notifications for userId: $userId');

      // Get notification recipients for this user
      // Use the same query as getUnreadNotificationCount for consistency
      final recipientsQuery = await _firestore
          .collection(_notificationRecipientsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['sent', 'delivered', 'read']).get();

      debugPrint('📊 Found ${recipientsQuery.docs.length} recipient records');

      final List<UserNotification> userNotifications = [];

      for (final recipientDoc in recipientsQuery.docs) {
        final recipientData = recipientDoc.data();
        final notificationId = recipientData['notificationId'] as String?;

        debugPrint(
            '📄 Processing recipient: ${recipientDoc.id}, notificationId: $notificationId');

        if (notificationId != null) {
          // Get the actual notification data
          debugPrint('🔍 Fetching notification document: $notificationId');
          final notificationDoc = await _firestore
              .collection(_notificationsCollection)
              .doc(notificationId)
              .get();

          if (notificationDoc.exists) {
            debugPrint('✅ Notification document exists');
            final notification =
                NotificationModel.fromFirestore(notificationDoc);
            final userNotification =
                UserNotification.fromFirestore(recipientDoc, notification);
            userNotifications.add(userNotification);
            debugPrint('✅ Added notification: ${notification.title}');
          } else {
            debugPrint('❌ Notification document not found: $notificationId');
          }
        } else {
          debugPrint('❌ No notificationId in recipient data');
        }
      }

      // Sort notifications by sentAt date (most recent first)
      userNotifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      // Apply limit after sorting
      final limitedNotifications = userNotifications.take(limit).toList();

      debugPrint(
          '📱 Returning ${limitedNotifications.length} notifications (sorted and limited)');
      return limitedNotifications;
    } catch (e) {
      debugPrint('❌ Error getting user notifications: $e');
      return [];
    }
  }

  /// Get unread notification count for a user
  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      debugPrint('🔢 Getting unread count for userId: $userId');

      final query = await _firestore
          .collection(_notificationRecipientsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['sent', 'delivered']).get();

      debugPrint('🔢 Found ${query.docs.length} recipient records');

      // Count only notifications that actually exist
      int validCount = 0;
      for (final recipientDoc in query.docs) {
        final recipientData = recipientDoc.data();
        final notificationId = recipientData['notificationId'] as String?;

        if (notificationId != null) {
          // Check if the notification document exists
          final notificationDoc = await _firestore
              .collection(_notificationsCollection)
              .doc(notificationId)
              .get();

          if (notificationDoc.exists) {
            validCount++;
          } else {
            debugPrint(
                '⚠️ Orphaned recipient found: ${recipientDoc.id} -> $notificationId');
          }
        }
      }

      debugPrint('🔢 Valid unread notifications: $validCount');
      return validCount;
    } catch (e) {
      debugPrint('❌ Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Get total notification count for a user (including read notifications)
  static Future<int> getTotalNotificationCount(String userId) async {
    try {
      debugPrint('🔢 Getting total count for userId: $userId');
      final query = await _firestore
          .collection(_notificationRecipientsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['sent', 'delivered', 'read']).get();

      debugPrint('📊 Found ${query.docs.length} total notifications');
      return query.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting total notification count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String recipientId) async {
    try {
      await _firestore
          .collection(_notificationRecipientsCollection)
          .doc(recipientId)
          .update({
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Notification marked as read: $recipientId');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark notification as delivered
  static Future<void> markNotificationAsDelivered(String recipientId) async {
    try {
      await _firestore
          .collection(_notificationRecipientsCollection)
          .doc(recipientId)
          .update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Notification marked as delivered: $recipientId');
    } catch (e) {
      debugPrint('Error marking notification as delivered: $e');
    }
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final query = await _firestore
          .collection(_notificationRecipientsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['sent', 'delivered']).get();

      final batch = _firestore.batch();

      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'status': 'read',
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('All notifications marked as read for user: $userId');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Listen to real-time notification updates for a user
  static Stream<List<UserNotification>> listenToUserNotifications(String userId,
      {int limit = 50}) {
    return _firestore
        .collection(_notificationRecipientsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<UserNotification> userNotifications = [];

      for (final recipientDoc in snapshot.docs) {
        final recipientData = recipientDoc.data();
        final notificationId = recipientData['notificationId'] as String?;

        if (notificationId != null) {
          try {
            // Get the actual notification data
            final notificationDoc = await _firestore
                .collection(_notificationsCollection)
                .doc(notificationId)
                .get();

            if (notificationDoc.exists) {
              final notification =
                  NotificationModel.fromFirestore(notificationDoc);
              final userNotification =
                  UserNotification.fromFirestore(recipientDoc, notification);
              userNotifications.add(userNotification);
            }
          } catch (e) {
            debugPrint('Error loading notification $notificationId: $e');
          }
        }
      }

      return userNotifications;
    });
  }

  /// Listen to unread notification count for a user
  static Stream<int> listenToUnreadNotificationCount(String userId) {
    return _firestore
        .collection(_notificationRecipientsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['sent', 'delivered'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete notification for a user (mark as deleted)
  static Future<void> deleteNotificationForUser(String recipientId) async {
    try {
      await _firestore
          .collection(_notificationRecipientsCollection)
          .doc(recipientId)
          .delete();

      debugPrint('Notification deleted for user: $recipientId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Show local notification (minimal version)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    // Local notifications temporarily disabled
    debugPrint('Local notification: $title - $body');
    return;
  }

  /// Handle notification action (navigate to specific screen)
  static void handleNotificationAction(
      UserNotification userNotification, BuildContext context) {
    final notification = userNotification.notification;

    // Mark as read when action is taken
    markNotificationAsRead(userNotification.id);

    if (notification.hasAction) {
      switch (notification.actionType) {
        case 'quiz':
          // Navigate to quiz instructions screen
          debugPrint('Navigate to quiz: ${notification.actionUrl}');
          _navigateToQuiz(context, notification.actionUrl);
          break;
        case 'exam':
          // Navigate to exam screen
          debugPrint('Navigate to exam: ${notification.actionUrl}');
          context.goNamed('exam');
          break;
        case 'news':
          // Navigate to exam hub or news section
          debugPrint('Navigate to news: ${notification.actionUrl}');
          context.goNamed('exam');
          break;
        default:
          // Handle general action
          debugPrint('Handle general action: ${notification.actionUrl}');
          context.goNamed('home');
          break;
      }
    }
  }

  /// Navigate to quiz based on action URL
  static void _navigateToQuiz(BuildContext context, String? actionUrl) {
    if (actionUrl == null || actionUrl.isEmpty) {
      debugPrint('No action URL provided for quiz navigation');
      return;
    }

    try {
      // Extract quiz ID from action URL
      final quizId = _extractQuizIdFromUrl(actionUrl);
      if (quizId != null) {
        debugPrint('Navigating to quiz instructions: $quizId');
        context
            .goNamed('quiz-instructions', pathParameters: {'quizId': quizId});
      } else {
        debugPrint('Could not extract quiz ID from URL: $actionUrl');
        // Fallback to quiz list
        context.goNamed('quiz-list');
      }
    } catch (e) {
      debugPrint('Error navigating to quiz: $e');
      // Fallback to quiz list
      context.goNamed('quiz-list');
    }
  }

  /// Extract quiz ID from action URL
  static String? _extractQuizIdFromUrl(String actionUrl) {
    try {
      // Handle URLs like "/quiz/quiz_id/instructions" or "/quiz/quiz_id"
      final uri = Uri.parse(actionUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 2 && pathSegments[0] == 'quiz') {
        return pathSegments[1];
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting quiz ID from URL: $e');
      return null;
    }
  }

  /// Get notification priority color
  static Color getNotificationPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  /// Get notification category icon
  static IconData getNotificationCategoryIcon(String category) {
    switch (category) {
      case 'announcement':
        return Icons.campaign;
      case 'quiz_update':
        return Icons.quiz;
      case 'exam_alert':
        return Icons.school;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  /// Clean up orphaned notification recipients (recipients without valid notification documents)
  static Future<void> cleanupOrphanedRecipients(String userId) async {
    try {
      debugPrint('🧹 Cleaning up orphaned recipients for user: $userId');

      final recipientsQuery = await _firestore
          .collection(_notificationRecipientsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      int orphanedCount = 0;
      final batch = _firestore.batch();

      for (final recipientDoc in recipientsQuery.docs) {
        final recipientData = recipientDoc.data();
        final notificationId = recipientData['notificationId'] as String?;

        if (notificationId != null) {
          // Check if the notification document exists
          final notificationDoc = await _firestore
              .collection(_notificationsCollection)
              .doc(notificationId)
              .get();

          if (!notificationDoc.exists) {
            // Mark for deletion
            batch.delete(recipientDoc.reference);
            orphanedCount++;
            debugPrint(
                '🗑️ Marking orphaned recipient for deletion: ${recipientDoc.id}');
          }
        }
      }

      if (orphanedCount > 0) {
        await batch.commit();
        debugPrint('✅ Cleaned up $orphanedCount orphaned recipients');
      } else {
        debugPrint('✅ No orphaned recipients found');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up orphaned recipients: $e');
    }
  }
}
