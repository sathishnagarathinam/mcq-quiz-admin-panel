import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionType;
  final String? testImageUrl; // For test-related notifications with image links
  final String priority;
  final String category;
  final String deliveryMethod; // 'push_only', 'in_app_only', 'both'
  final DateTime createdAt;
  final DateTime? sentAt;
  final bool isRead;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionUrl,
    this.actionType,
    this.testImageUrl,
    required this.priority,
    required this.category,
    this.deliveryMethod = 'both',
    required this.createdAt,
    this.sentAt,
    this.isRead = false,
    this.readAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
      actionType: data['actionType'],
      testImageUrl: data['testImageUrl'],
      priority: data['priority'] ?? 'normal',
      category: data['category'] ?? 'general',
      deliveryMethod: data['deliveryMethod'] ?? 'both',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionType': actionType,
      'testImageUrl': testImageUrl,
      'priority': priority,
      'category': category,
      'deliveryMethod': deliveryMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? actionUrl,
    String? actionType,
    String? testImageUrl,
    String? priority,
    String? category,
    String? deliveryMethod,
    DateTime? createdAt,
    DateTime? sentAt,
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionType: actionType ?? this.actionType,
      testImageUrl: testImageUrl ?? this.testImageUrl,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'high':
        return 'High';
      case 'normal':
        return 'Normal';
      case 'low':
        return 'Low';
      default:
        return 'Normal';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case 'announcement':
        return 'Announcement';
      case 'quiz_update':
        return 'Quiz Update';
      case 'exam_alert':
        return 'Exam Alert';
      case 'general':
        return 'General';
      case 'system':
        return 'System';
      default:
        return 'General';
    }
  }

  bool get isUrgent => priority == 'urgent';
  bool get isHigh => priority == 'high';

  bool get hasAction => actionUrl != null && actionUrl!.isNotEmpty;
}

class UserNotification {
  final String id;
  final String notificationId;
  final String userId;
  final NotificationModel notification;
  final String status; // 'sent', 'delivered', 'read'
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  const UserNotification({
    required this.id,
    required this.notificationId,
    required this.userId,
    required this.notification,
    required this.status,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
  });

  factory UserNotification.fromFirestore(
      DocumentSnapshot doc, NotificationModel notification) {
    final data = doc.data() as Map<String, dynamic>;
    return UserNotification(
      id: doc.id,
      notificationId: data['notificationId'] ?? '',
      userId: data['userId'] ?? '',
      notification: notification,
      status: data['status'] ?? 'sent',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'status': status,
      'sentAt': Timestamp.fromDate(sentAt),
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  UserNotification copyWith({
    String? id,
    String? notificationId,
    String? userId,
    NotificationModel? notification,
    String? status,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return UserNotification(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      notification: notification ?? this.notification,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }

  bool get isRead => status == 'read' || readAt != null;
  bool get isDelivered => status == 'delivered' || deliveredAt != null;
}
