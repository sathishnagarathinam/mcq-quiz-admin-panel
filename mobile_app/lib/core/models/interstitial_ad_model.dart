import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for interstitial advertisements managed from admin
/// These ads are displayed as full-screen overlays in the mobile app
class InterstitialAdModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String primaryColor;
  final String secondaryColor;
  final String iconName;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final String? targetUrl;
  final String? examId; // ID of the exam to navigate to when ad is tapped
  final String? examName; // Name of the exam for display purposes
  final int displayDurationSeconds; // How long to show the ad
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const InterstitialAdModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.iconName,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    this.targetUrl,
    this.examId,
    this.examName,
    this.displayDurationSeconds = 5,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  /// Parse a date field from Firestore that could be a Timestamp, String, or null
  static DateTime _parseDate(dynamic value, DateTime fallback) {
    if (value == null) return fallback;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  factory InterstitialAdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    return InterstitialAdModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      primaryColor: data['primaryColor'] ?? '#E91E63',
      secondaryColor: data['secondaryColor'] ?? '#9C27B0',
      iconName: data['iconName'] ?? 'campaign',
      isActive: data['isActive'] == true,
      startDate: _parseDate(data['startDate'], now),
      endDate: _parseDate(data['endDate'], now.add(const Duration(days: 30))),
      targetUrl: data['targetUrl'],
      examId: data['examId'],
      examName: data['examName'],
      displayDurationSeconds: data['displayDurationSeconds'] ?? 5,
      priority: data['priority'] ?? 0,
      createdAt: _parseDate(data['createdAt'], now),
      updatedAt: _parseDate(data['updatedAt'], now),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'iconName': iconName,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetUrl': targetUrl,
      'examId': examId,
      'examName': examName,
      'displayDurationSeconds': displayDurationSeconds,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// Check if ad is currently active and within date range
  bool get isCurrentlyActive {
    final now = DateTime.now();
    // Use inclusive date range: startDate <= now <= endDate + 1 day
    // The +1 day buffer ensures ads display throughout the entire end date
    final startOk = now.isAfter(startDate) || now.isAtSameMomentAs(startDate);
    final endOk = now.isBefore(endDate.add(const Duration(days: 1)));
    return isActive && startOk && endOk;
  }

  InterstitialAdModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? primaryColor,
    String? secondaryColor,
    String? iconName,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? targetUrl,
    String? examId,
    String? examName,
    int? displayDurationSeconds,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return InterstitialAdModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetUrl: targetUrl ?? this.targetUrl,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      displayDurationSeconds:
          displayDurationSeconds ?? this.displayDurationSeconds,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
