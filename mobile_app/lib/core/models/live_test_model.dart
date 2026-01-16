import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for live tests managed from admin
class LiveTestModel {
  final String id;
  final String title;
  final String description;
  final String examType;
  final List<String> suitableFor;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final int totalQuestions;
  final bool isActive;
  final bool isLive;
  final String status; // upcoming, live, completed, cancelled
  final int maxParticipants;
  final int currentParticipants;
  final String instructorName;
  final String instructorImage;
  final List<String> tags;
  final String difficulty; // easy, medium, hard
  final double passingScore;
  final bool showResults;
  final String examId; // Reference to actual exam questions
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const LiveTestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.examType,
    required this.suitableFor,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.isActive,
    required this.isLive,
    required this.status,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.instructorName,
    required this.instructorImage,
    required this.tags,
    required this.difficulty,
    required this.passingScore,
    required this.showResults,
    required this.examId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory LiveTestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiveTestModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      examType: data['examType'] ?? '',
      suitableFor: List<String>.from(data['suitableFor'] ?? []),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 2)),
      durationMinutes: data['durationMinutes'] ?? 60,
      totalQuestions: data['totalQuestions'] ?? 50,
      isActive: data['isActive'] ?? false,
      isLive: data['isLive'] ?? false,
      status: data['status'] ?? 'upcoming',
      maxParticipants: data['maxParticipants'] ?? 1000,
      currentParticipants: data['currentParticipants'] ?? 0,
      instructorName: data['instructorName'] ?? '',
      instructorImage: data['instructorImage'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      difficulty: data['difficulty'] ?? 'medium',
      passingScore: (data['passingScore'] ?? 60.0).toDouble(),
      showResults: data['showResults'] ?? true,
      examId: data['examId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  factory LiveTestModel.fromJson(Map<String, dynamic> json) {
    return LiveTestModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      examType: json['examType'] ?? '',
      suitableFor: List<String>.from(json['suitableFor'] ?? []),
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(json['endTime'] ?? DateTime.now().add(const Duration(hours: 2)).toIso8601String()),
      durationMinutes: json['durationMinutes'] ?? 60,
      totalQuestions: json['totalQuestions'] ?? 50,
      isActive: json['isActive'] ?? false,
      isLive: json['isLive'] ?? false,
      status: json['status'] ?? 'upcoming',
      maxParticipants: json['maxParticipants'] ?? 1000,
      currentParticipants: json['currentParticipants'] ?? 0,
      instructorName: json['instructorName'] ?? '',
      instructorImage: json['instructorImage'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: json['difficulty'] ?? 'medium',
      passingScore: (json['passingScore'] ?? 60.0).toDouble(),
      showResults: json['showResults'] ?? true,
      examId: json['examId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'examType': examType,
      'suitableFor': suitableFor,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'totalQuestions': totalQuestions,
      'isActive': isActive,
      'isLive': isLive,
      'status': status,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'instructorName': instructorName,
      'instructorImage': instructorImage,
      'tags': tags,
      'difficulty': difficulty,
      'passingScore': passingScore,
      'showResults': showResults,
      'examId': examId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'examType': examType,
      'suitableFor': suitableFor,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'totalQuestions': totalQuestions,
      'isActive': isActive,
      'isLive': isLive,
      'status': status,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'instructorName': instructorName,
      'instructorImage': instructorImage,
      'tags': tags,
      'difficulty': difficulty,
      'passingScore': passingScore,
      'showResults': showResults,
      'examId': examId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// Check if test is currently live
  bool get isCurrentlyLive {
    final now = DateTime.now();
    return isActive && 
           isLive && 
           status == 'live' &&
           now.isAfter(startTime) && 
           now.isBefore(endTime);
  }

  /// Check if test is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    return isActive && 
           status == 'upcoming' &&
           now.isBefore(startTime);
  }

  /// Get time remaining until start
  Duration get timeUntilStart {
    final now = DateTime.now();
    if (now.isBefore(startTime)) {
      return startTime.difference(now);
    }
    return Duration.zero;
  }

  /// Get time remaining in test
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isBefore(endTime) && now.isAfter(startTime)) {
      return endTime.difference(now);
    }
    return Duration.zero;
  }

  LiveTestModel copyWith({
    String? id,
    String? title,
    String? description,
    String? examType,
    List<String>? suitableFor,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? totalQuestions,
    bool? isActive,
    bool? isLive,
    String? status,
    int? maxParticipants,
    int? currentParticipants,
    String? instructorName,
    String? instructorImage,
    List<String>? tags,
    String? difficulty,
    double? passingScore,
    bool? showResults,
    String? examId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return LiveTestModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      examType: examType ?? this.examType,
      suitableFor: suitableFor ?? this.suitableFor,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      isActive: isActive ?? this.isActive,
      isLive: isLive ?? this.isLive,
      status: status ?? this.status,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      instructorName: instructorName ?? this.instructorName,
      instructorImage: instructorImage ?? this.instructorImage,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      passingScore: passingScore ?? this.passingScore,
      showResults: showResults ?? this.showResults,
      examId: examId ?? this.examId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
