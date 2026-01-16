import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for promotional banners managed from admin
class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String couponCode;
  final String discount;
  final String primaryColor;
  final String secondaryColor;
  final String iconName;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final String targetUrl;
  final String? examId; // ID of the exam to navigate to when banner is tapped
  final String? examName; // Name of the exam for display purposes
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.couponCode,
    required this.discount,
    required this.primaryColor,
    required this.secondaryColor,
    required this.iconName,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.targetUrl,
    this.examId,
    this.examName,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      couponCode: data['couponCode'] ?? '',
      discount: data['discount'] ?? '',
      primaryColor: data['primaryColor'] ?? '#E91E63',
      secondaryColor: data['secondaryColor'] ?? '#9C27B0',
      iconName: data['iconName'] ?? 'lightbulb',
      isActive: data['isActive'] ?? false,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      targetUrl: data['targetUrl'] ?? '',
      examId: data['examId'],
      examName: data['examName'],
      priority: data['priority'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      couponCode: json['couponCode'] ?? '',
      discount: json['discount'] ?? '',
      primaryColor: json['primaryColor'] ?? '#E91E63',
      secondaryColor: json['secondaryColor'] ?? '#9C27B0',
      iconName: json['iconName'] ?? 'lightbulb',
      isActive: json['isActive'] ?? false,
      startDate:
          DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ??
          DateTime.now().add(const Duration(days: 30)).toIso8601String()),
      targetUrl: json['targetUrl'] ?? '',
      examId: json['examId'],
      examName: json['examName'],
      priority: json['priority'] ?? 0,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'couponCode': couponCode,
      'discount': discount,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'iconName': iconName,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetUrl': targetUrl,
      'examId': examId,
      'examName': examName,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'couponCode': couponCode,
      'discount': discount,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'iconName': iconName,
      'isActive': isActive,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'targetUrl': targetUrl,
      'examId': examId,
      'examName': examName,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// Check if banner is currently active and within date range
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  BannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? couponCode,
    String? discount,
    String? primaryColor,
    String? secondaryColor,
    String? iconName,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? targetUrl,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      couponCode: couponCode ?? this.couponCode,
      discount: discount ?? this.discount,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetUrl: targetUrl ?? this.targetUrl,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
