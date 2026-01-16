import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// FCM Service for handling push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  static FirebaseMessaging? _firebaseMessaging;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static bool _isInitialized = false;

  // Store router reference for navigation from notifications
  static GoRouter? _router;

  /// Set the router reference for notification navigation
  static void setRouter(GoRouter router) {
    _router = router;
    debugPrint('🔔 FCMService: Router reference set');
  }

  /// Initialize FCM service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure FCM
      await _configureFCM();

      _isInitialized = true;
      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM Service: $e');
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error requesting FCM permissions: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('Local notifications initialized');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  /// Configure FCM message handlers
  static Future<void> _configureFCM() async {
    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app is terminated
      RemoteMessage? initialMessage =
          await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      debugPrint('FCM configured successfully');
    } catch (e) {
      debugPrint('Error configuring FCM: $e');
    }
  }

  /// Get FCM token for this device
  static Future<String?> getToken() async {
    try {
      if (_firebaseMessaging == null) {
        await initialize();
      }

      String? token = await _firebaseMessaging!.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to user document
  static Future<void> saveTokenToUser(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('mobile_users')
            .doc(userId)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });

        debugPrint('FCM token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Handle notification tap (for background/terminated app scenarios)
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('🔔 FCM Notification tapped (background/terminated)!');
    debugPrint('   Message ID: ${message.messageId}');
    debugPrint('   Data: ${message.data}');
    debugPrint('   Notification title: ${message.notification?.title}');
    debugPrint('   Notification body: ${message.notification?.body}');

    // Handle navigation based on notification data
    if (message.data.containsKey('actionType')) {
      String actionType = message.data['actionType'] ?? '';
      String? actionUrl = message.data['actionUrl'];
      String? quizId = message.data['quizId'];

      debugPrint('📋 Extracted navigation data:');
      debugPrint('   - actionType: $actionType');
      debugPrint('   - actionUrl: $actionUrl');
      debugPrint('   - quizId: $quizId');

      // Navigate based on action type
      await _navigateFromNotification(actionType, actionUrl, quizId);
    } else {
      debugPrint('⚠️ No actionType found in notification data');
      debugPrint('   Available keys: ${message.data.keys.toList()}');
    }
  }

  /// Navigate from notification based on action type
  static Future<void> _navigateFromNotification(
      String actionType, String? actionUrl, String? quizId) async {
    try {
      // Store navigation data for later use when app becomes active
      _pendingNavigation = {
        'actionType': actionType,
        'actionUrl': actionUrl,
        'quizId': quizId,
      };

      debugPrint('✅ Stored pending navigation: $_pendingNavigation');

      // Capture values for the delayed callback (to avoid race conditions)
      final capturedActionType = actionType;
      final capturedActionUrl = actionUrl;
      final capturedQuizId = quizId;

      // Try to navigate with a delay to ensure app is ready
      if (_router != null) {
        debugPrint('🚀 Router available - navigating with delay from FCM tap!');
        // Use Future.delayed to ensure the app is fully ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_router != null) {
            debugPrint('⏰ Delay complete - executing navigation from FCM tap');
            _navigateWithRouter(_router!, capturedActionType, capturedActionUrl,
                capturedQuizId);
          } else {
            debugPrint('❌ Router became null during delay');
          }
        });
      } else {
        debugPrint(
            '⏳ Router not yet available - navigation will happen when app is ready');
      }
    } catch (e) {
      debugPrint('Error storing navigation data: $e');
    }
  }

  // Store pending navigation data
  static Map<String, dynamic>? _pendingNavigation;

  /// Get and clear pending navigation data
  static Map<String, dynamic>? getPendingNavigation() {
    final navigation = _pendingNavigation;
    _pendingNavigation = null;
    return navigation;
  }

  /// Execute pending navigation with context
  static void executePendingNavigation(BuildContext context) {
    final navigation = getPendingNavigation();
    if (navigation == null) return;

    final actionType = navigation['actionType'] as String;
    final actionUrl = navigation['actionUrl'] as String?;
    final quizId = navigation['quizId'] as String?;

    debugPrint('🔔 Executing pending navigation: $actionType');
    debugPrint('   - quizId: $quizId');
    debugPrint('   - actionUrl: $actionUrl');

    try {
      switch (actionType) {
        case 'quiz':
          if (quizId != null && quizId.isNotEmpty) {
            // Navigate to quiz instructions page
            debugPrint('🚀 Navigating to quiz instructions: $quizId');
            context.goNamed('quiz-instructions',
                pathParameters: {'quizId': quizId});
          } else if (actionUrl != null && actionUrl.isNotEmpty) {
            // Parse quiz ID from action URL
            final quizIdFromUrl = _extractQuizIdFromUrl(actionUrl);
            if (quizIdFromUrl != null) {
              debugPrint(
                  '🚀 Navigating to quiz instructions from URL: $quizIdFromUrl');
              context.goNamed('quiz-instructions',
                  pathParameters: {'quizId': quizIdFromUrl});
            } else {
              debugPrint('❌ Could not extract quiz ID from URL: $actionUrl');
              // Fallback to quiz list
              context.goNamed('quiz-list');
            }
          } else {
            debugPrint('❌ No quizId or actionUrl provided, going to quiz list');
            context.goNamed('quiz-list');
          }
          break;
        case 'exam':
          // Navigate to exam screen
          debugPrint('🚀 Navigating to exam screen');
          context.goNamed('exam');
          break;
        case 'news':
          // Navigate to exam hub or news section
          debugPrint('🚀 Navigating to exam hub');
          context.goNamed('exam');
          break;
        case 'app_update':
          // Handle app update notification
          debugPrint('🚀 Handling app update notification');
          _handleAppUpdateNotification(actionUrl);
          break;
        default:
          debugPrint('❓ Unknown action type: $actionType');
          // Navigate to home as fallback
          context.goNamed('home');
          break;
      }
    } catch (e) {
      debugPrint('❌ Error executing pending navigation: $e');
      // Try fallback navigation
      try {
        context.go('/home');
      } catch (e2) {
        debugPrint('❌ Fallback navigation also failed: $e2');
      }
    }
  }

  /// Execute pending navigation with GoRouter directly (for use when context is not available)
  static void executePendingNavigationWithRouter(GoRouter router) {
    final navigation = getPendingNavigation();
    if (navigation == null) return;

    final actionType = navigation['actionType'] as String;
    final actionUrl = navigation['actionUrl'] as String?;
    final quizId = navigation['quizId'] as String?;

    debugPrint('🔔 Executing pending navigation with router: $actionType');
    debugPrint('   - quizId: $quizId');
    debugPrint('   - actionUrl: $actionUrl');

    // Use the shared navigation method
    _navigateWithRouter(router, actionType, actionUrl, quizId);
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

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'mcq_notifications',
        'MCQ Notifications',
        channelDescription: 'Notifications for MCQ Quiz App',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Encode the data as JSON string for proper parsing when tapped
      final payload = jsonEncode(message.data);
      debugPrint('🔔 Showing local notification with payload: $payload');

      await _localNotifications!.show(
        message.hashCode,
        message.notification?.title ?? 'MCQ Quiz',
        message.notification?.body ?? 'You have a new notification',
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Handle notification tap from local notification
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Local notification tapped!');
    debugPrint('   Payload: ${response.payload}');

    if (response.payload == null || response.payload!.isEmpty) {
      debugPrint('❌ No payload in notification');
      return;
    }

    try {
      // Parse the JSON payload
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      debugPrint('📋 Parsed notification data: $data');

      final actionType = data['actionType'] as String?;
      final actionUrl = data['actionUrl'] as String?;
      final quizId = data['quizId'] as String?;

      debugPrint('   actionType: $actionType');
      debugPrint('   actionUrl: $actionUrl');
      debugPrint('   quizId: $quizId');

      if (actionType != null) {
        // Store pending navigation for fallback
        _pendingNavigation = {
          'actionType': actionType,
          'actionUrl': actionUrl,
          'quizId': quizId,
        };
        debugPrint(
            '✅ Stored pending navigation from local notification: $_pendingNavigation');

        // Capture values for the delayed callback (to avoid race conditions)
        final capturedActionType = actionType;
        final capturedActionUrl = actionUrl;
        final capturedQuizId = quizId;

        // Try to navigate with a small delay to ensure app is ready
        if (_router != null) {
          debugPrint('🚀 Router available - navigating with delay!');
          // Use Future.delayed to ensure the app is fully ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_router != null) {
              debugPrint('⏰ Delay complete - executing navigation now');
              _navigateWithRouter(_router!, capturedActionType,
                  capturedActionUrl, capturedQuizId);
            } else {
              debugPrint('❌ Router became null during delay');
            }
          });
        } else {
          debugPrint(
              '⏳ Router not yet available - navigation will happen when app is ready');
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing notification payload: $e');
    }
  }

  /// Navigate using the stored router
  static void _navigateWithRouter(
      GoRouter router, String actionType, String? actionUrl, String? quizId) {
    try {
      debugPrint('🔔 _navigateWithRouter called:');
      debugPrint('   - actionType: $actionType');
      debugPrint('   - quizId: $quizId');
      debugPrint('   - actionUrl: $actionUrl');
      debugPrint('   - router: $router');
      debugPrint('   - router.routerDelegate: ${router.routerDelegate}');

      switch (actionType) {
        case 'quiz':
          if (quizId != null && quizId.isNotEmpty) {
            debugPrint('🚀 Navigating to quiz instructions: $quizId');
            // Use go() with full path instead of goNamed() for more reliable navigation
            final path = '/quiz/$quizId/instructions';
            debugPrint('   - Full path: $path');
            router.go(path);
            // Clear pending navigation since we're navigating now
            _pendingNavigation = null;
            debugPrint('✅ Navigation command sent successfully');
          } else if (actionUrl != null && actionUrl.isNotEmpty) {
            final quizIdFromUrl = _extractQuizIdFromUrl(actionUrl);
            if (quizIdFromUrl != null) {
              debugPrint(
                  '🚀 Navigating to quiz instructions from URL: $quizIdFromUrl');
              final path = '/quiz/$quizIdFromUrl/instructions';
              debugPrint('   - Full path: $path');
              router.go(path);
              _pendingNavigation = null;
              debugPrint('✅ Navigation command sent successfully');
            } else {
              debugPrint('❌ Could not extract quiz ID from URL: $actionUrl');
            }
          }
          break;
        case 'exam':
          debugPrint('🚀 Navigating to exam screen');
          router.go('/exam');
          _pendingNavigation = null;
          break;
        case 'news':
          debugPrint('🚀 Navigating to exam hub');
          router.go('/exam');
          _pendingNavigation = null;
          break;
        default:
          debugPrint('❓ Unknown action type: $actionType - going to home');
          router.go('/home');
          _pendingNavigation = null;
          break;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error navigating with router: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging!.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging!.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging!.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Error checking notification settings: $e');
      return false;
    }
  }

  /// Handle app update notification
  static Future<void> _handleAppUpdateNotification(String? updateUrl) async {
    try {
      if (updateUrl == null || updateUrl.isEmpty) {
        debugPrint('No update URL provided');
        return;
      }

      debugPrint('Opening app update URL: $updateUrl');

      final uri = Uri.parse(updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('Successfully opened update URL');
      } else {
        debugPrint('Cannot launch update URL: $updateUrl');
      }
    } catch (e) {
      debugPrint('Error handling app update notification: $e');
    }
  }

  /// Send app update notification to all users
  static Future<void> sendAppUpdateNotification({
    required String title,
    required String body,
    required String updateUrl,
    String? imageUrl,
  }) async {
    try {
      debugPrint('Sending app update notification to all users');

      // Create notification data
      final notificationData = {
        'actionType': 'app_update',
        'actionUrl': updateUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      // Send to topic 'all_users' - make sure users are subscribed to this topic
      final message = {
        'topic': 'all_users',
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': notificationData,
        'android': {
          'notification': {
            'channel_id': 'app_updates',
            'priority': 'high',
            'default_sound': true,
            'default_vibrate_timings': true,
            'icon': '@mipmap/ic_launcher',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': title,
                'body': body,
              },
              'sound': 'default',
              'badge': 1,
            },
          },
        },
      };

      // Save notification to Firestore for tracking
      await FirebaseFirestore.instance.collection('app_notifications').add({
        'type': 'app_update',
        'title': title,
        'body': body,
        'updateUrl': updateUrl,
        'imageUrl': imageUrl,
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': 'system',
        'targetAudience': 'all_users',
      });

      debugPrint('App update notification data prepared: $message');
      debugPrint('Notification saved to Firestore');
    } catch (e) {
      debugPrint('Error sending app update notification: $e');
    }
  }

  /// Subscribe user to app updates topic
  static Future<void> subscribeToAppUpdates() async {
    try {
      await subscribeToTopic('all_users');
      await subscribeToTopic('app_updates');
      debugPrint('Subscribed to app update topics');
    } catch (e) {
      debugPrint('Error subscribing to app update topics: $e');
    }
  }

  /// Unsubscribe user from app updates topic
  static Future<void> unsubscribeFromAppUpdates() async {
    try {
      await unsubscribeFromTopic('all_users');
      await unsubscribeFromTopic('app_updates');
      debugPrint('Unsubscribed from app update topics');
    } catch (e) {
      debugPrint('Error unsubscribing from app update topics: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
}
