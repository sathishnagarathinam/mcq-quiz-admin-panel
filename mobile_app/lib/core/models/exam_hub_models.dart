import 'package:cloud_firestore/cloud_firestore.dart';

/// File attachment model for exam hub items
class FileAttachment {
  final String id;
  final String name;
  final String originalName;
  final String url;
  final int size;
  final String type; // MIME type
  final DateTime uploadedAt;

  const FileAttachment({
    required this.id,
    required this.name,
    required this.originalName,
    required this.url,
    required this.size,
    required this.type,
    required this.uploadedAt,
  });

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      originalName: json['originalName'] ?? '',
      url: json['url'] ?? '',
      size: json['size'] ?? 0,
      type: json['type'] ?? '',
      uploadedAt: json['uploadedAt'] is Timestamp
          ? (json['uploadedAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['uploadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'originalName': originalName,
      'url': url,
      'size': size,
      'type': type,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

/// Base interface for all exam hub items
abstract class BaseExamHubItem {
  final String id;
  final String title;
  final String description;
  final String? content; // Optional rich text content
  final bool isActive;
  final int priority; // For ordering items
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final int viewCount;
  final int? downloadCount; // For items with downloadable content

  const BaseExamHubItem({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    required this.isActive,
    required this.priority,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.viewCount,
    this.downloadCount,
  });
}

/// News model for exam hub
class ExamHubNews extends BaseExamHubItem {
  final String
      category; // 'general', 'exam_notification', 'result_announcement', 'important_update'
  final DateTime publishDate;
  final DateTime? expiryDate; // Optional expiry for time-sensitive news
  final String? imageUrl; // Optional featured image
  final List<FileAttachment> attachments; // PDF attachments
  final bool isBreaking; // For urgent/breaking news
  final List<String> targetAudience; // e.g., ['MTS', 'POSTMAN', 'ALL']

  const ExamHubNews({
    required super.id,
    required super.title,
    required super.description,
    super.content,
    required super.isActive,
    required super.priority,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    required super.tags,
    required super.viewCount,
    super.downloadCount,
    required this.category,
    required this.publishDate,
    this.expiryDate,
    this.imageUrl,
    required this.attachments,
    required this.isBreaking,
    required this.targetAudience,
  });

  factory ExamHubNews.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ExamHubNews(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'],
      isActive: data['isActive'] ?? true,
      priority: data['priority'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              data['updatedAt'] ?? DateTime.now().toIso8601String()),
      tags: List<String>.from(data['tags'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      downloadCount: data['downloadCount'],
      category: data['category'] ?? 'general',
      publishDate: data['publishDate'] is Timestamp
          ? (data['publishDate'] as Timestamp).toDate()
          : DateTime.parse(
              data['publishDate'] ?? DateTime.now().toIso8601String()),
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] is Timestamp
              ? (data['expiryDate'] as Timestamp).toDate()
              : DateTime.parse(data['expiryDate']))
          : null,
      imageUrl: data['imageUrl'],
      attachments: (data['attachments'] as List<dynamic>? ?? [])
          .map((attachment) =>
              FileAttachment.fromJson(attachment as Map<String, dynamic>))
          .toList(),
      isBreaking: data['isBreaking'] ?? false,
      targetAudience: List<String>.from(data['targetAudience'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'isActive': isActive,
      'priority': priority,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'viewCount': viewCount,
      'downloadCount': downloadCount,
      'category': category,
      'publishDate': Timestamp.fromDate(publishDate),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'imageUrl': imageUrl,
      'attachments':
          attachments.map((attachment) => attachment.toJson()).toList(),
      'isBreaking': isBreaking,
      'targetAudience': targetAudience,
    };
  }
}

/// Tips and Shortcuts model for exam hub
class ExamHubTips extends BaseExamHubItem {
  final String
      category; // 'study_tips', 'exam_strategy', 'time_management', 'shortcuts', 'memory_techniques'
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final int estimatedReadTime; // in minutes
  final List<FileAttachment> attachments; // PDF guides, cheat sheets
  final List<String> relatedExamTypes; // e.g., ['MTS', 'POSTMAN', 'IPO']
  final bool isVideoContent;
  final String? videoUrl; // Optional video link

  const ExamHubTips({
    required super.id,
    required super.title,
    required super.description,
    super.content,
    required super.isActive,
    required super.priority,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    required super.tags,
    required super.viewCount,
    super.downloadCount,
    required this.category,
    required this.difficulty,
    required this.estimatedReadTime,
    required this.attachments,
    required this.relatedExamTypes,
    required this.isVideoContent,
    this.videoUrl,
  });

  factory ExamHubTips.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ExamHubTips(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'],
      isActive: data['isActive'] ?? true,
      priority: data['priority'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              data['updatedAt'] ?? DateTime.now().toIso8601String()),
      tags: List<String>.from(data['tags'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      downloadCount: data['downloadCount'],
      category: data['category'] ?? 'study_tips',
      difficulty: data['difficulty'] ?? 'beginner',
      estimatedReadTime: data['estimatedReadTime'] ?? 5,
      attachments: (data['attachments'] as List<dynamic>? ?? [])
          .map((attachment) =>
              FileAttachment.fromJson(attachment as Map<String, dynamic>))
          .toList(),
      relatedExamTypes: List<String>.from(data['relatedExamTypes'] ?? []),
      isVideoContent: data['isVideoContent'] ?? false,
      videoUrl: data['videoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'isActive': isActive,
      'priority': priority,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'viewCount': viewCount,
      'downloadCount': downloadCount,
      'category': category,
      'difficulty': difficulty,
      'estimatedReadTime': estimatedReadTime,
      'attachments':
          attachments.map((attachment) => attachment.toJson()).toList(),
      'relatedExamTypes': relatedExamTypes,
      'isVideoContent': isVideoContent,
      'videoUrl': videoUrl,
    };
  }
}

/// Previous Year Papers model for exam hub
class ExamHubPapers extends BaseExamHubItem {
  final String
      examType; // 'MTS', 'POSTMAN', 'POSTAL_ASSISTANT', 'IPO', 'GROUP_B', 'OTHER'
  final int examYear;
  final DateTime examDate;
  final String
      paperType; // 'question_paper', 'answer_key', 'solution', 'analysis'
  final String? subject; // Optional subject classification
  final int duration; // Exam duration in minutes
  final int totalMarks;
  final int totalQuestions;
  final List<FileAttachment> attachments; // PDF files
  final List<String> language; // e.g., ['English', 'Hindi']
  final bool isOfficial; // Official vs unofficial papers

  const ExamHubPapers({
    required super.id,
    required super.title,
    required super.description,
    super.content,
    required super.isActive,
    required super.priority,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    required super.tags,
    required super.viewCount,
    super.downloadCount,
    required this.examType,
    required this.examYear,
    required this.examDate,
    required this.paperType,
    this.subject,
    required this.duration,
    required this.totalMarks,
    required this.totalQuestions,
    required this.attachments,
    required this.language,
    required this.isOfficial,
  });

  factory ExamHubPapers.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ExamHubPapers(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'],
      isActive: data['isActive'] ?? true,
      priority: data['priority'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              data['updatedAt'] ?? DateTime.now().toIso8601String()),
      tags: List<String>.from(data['tags'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      downloadCount: data['downloadCount'],
      examType: data['examType'] ?? 'OTHER',
      examYear: data['examYear'] ?? DateTime.now().year,
      examDate: data['examDate'] is Timestamp
          ? (data['examDate'] as Timestamp).toDate()
          : DateTime.parse(
              data['examDate'] ?? DateTime.now().toIso8601String()),
      paperType: data['paperType'] ?? 'question_paper',
      subject: data['subject'],
      duration: data['duration'] ?? 120,
      totalMarks: data['totalMarks'] ?? 100,
      totalQuestions: data['totalQuestions'] ?? 100,
      attachments: (data['attachments'] as List<dynamic>? ?? [])
          .map((attachment) =>
              FileAttachment.fromJson(attachment as Map<String, dynamic>))
          .toList(),
      language: List<String>.from(data['language'] ?? ['English']),
      isOfficial: data['isOfficial'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'isActive': isActive,
      'priority': priority,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'viewCount': viewCount,
      'downloadCount': downloadCount,
      'examType': examType,
      'examYear': examYear,
      'examDate': Timestamp.fromDate(examDate),
      'paperType': paperType,
      'subject': subject,
      'duration': duration,
      'totalMarks': totalMarks,
      'totalQuestions': totalQuestions,
      'attachments':
          attachments.map((attachment) => attachment.toJson()).toList(),
      'language': language,
      'isOfficial': isOfficial,
    };
  }
}

/// Cutoff marks model for exam results
class CutoffMarks {
  final double general;
  final double obc;
  final double sc;
  final double st;
  final double pwd;

  const CutoffMarks({
    required this.general,
    required this.obc,
    required this.sc,
    required this.st,
    required this.pwd,
  });

  factory CutoffMarks.fromJson(Map<String, dynamic> json) {
    return CutoffMarks(
      general: (json['general'] ?? 0.0).toDouble(),
      obc: (json['obc'] ?? 0.0).toDouble(),
      sc: (json['sc'] ?? 0.0).toDouble(),
      st: (json['st'] ?? 0.0).toDouble(),
      pwd: (json['pwd'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'general': general,
      'obc': obc,
      'sc': sc,
      'st': st,
      'pwd': pwd,
    };
  }
}

/// Results model for exam hub
class ExamHubResults extends BaseExamHubItem {
  final String
      examType; // 'MTS', 'POSTMAN', 'POSTAL_ASSISTANT', 'IPO', 'GROUP_B', 'OTHER'
  final int examYear;
  final String
      resultType; // 'final_result', 'merit_list', 'cutoff_marks', 'answer_key', 'provisional_result'
  final DateTime publishDate;
  final DateTime examDate;
  final int? totalCandidates;
  final int? selectedCandidates;
  final CutoffMarks? cutoffMarks;
  final List<FileAttachment> attachments; // PDF result files
  final bool isOfficial;
  final String? resultUrl; // External result link

  const ExamHubResults({
    required super.id,
    required super.title,
    required super.description,
    super.content,
    required super.isActive,
    required super.priority,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    required super.tags,
    required super.viewCount,
    super.downloadCount,
    required this.examType,
    required this.examYear,
    required this.resultType,
    required this.publishDate,
    required this.examDate,
    this.totalCandidates,
    this.selectedCandidates,
    this.cutoffMarks,
    required this.attachments,
    required this.isOfficial,
    this.resultUrl,
  });

  factory ExamHubResults.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ExamHubResults(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'],
      isActive: data['isActive'] ?? true,
      priority: data['priority'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              data['updatedAt'] ?? DateTime.now().toIso8601String()),
      tags: List<String>.from(data['tags'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      downloadCount: data['downloadCount'],
      examType: data['examType'] ?? 'OTHER',
      examYear: data['examYear'] ?? DateTime.now().year,
      resultType: data['resultType'] ?? 'final_result',
      publishDate: data['publishDate'] is Timestamp
          ? (data['publishDate'] as Timestamp).toDate()
          : DateTime.parse(
              data['publishDate'] ?? DateTime.now().toIso8601String()),
      examDate: data['examDate'] is Timestamp
          ? (data['examDate'] as Timestamp).toDate()
          : DateTime.parse(
              data['examDate'] ?? DateTime.now().toIso8601String()),
      totalCandidates: data['totalCandidates'],
      selectedCandidates: data['selectedCandidates'],
      cutoffMarks: data['cutoffMarks'] != null
          ? CutoffMarks.fromJson(data['cutoffMarks'] as Map<String, dynamic>)
          : null,
      attachments: (data['attachments'] as List<dynamic>? ?? [])
          .map((attachment) =>
              FileAttachment.fromJson(attachment as Map<String, dynamic>))
          .toList(),
      isOfficial: data['isOfficial'] ?? true,
      resultUrl: data['resultUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'isActive': isActive,
      'priority': priority,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'viewCount': viewCount,
      'downloadCount': downloadCount,
      'examType': examType,
      'examYear': examYear,
      'resultType': resultType,
      'publishDate': Timestamp.fromDate(publishDate),
      'examDate': Timestamp.fromDate(examDate),
      'totalCandidates': totalCandidates,
      'selectedCandidates': selectedCandidates,
      'cutoffMarks': cutoffMarks?.toJson(),
      'attachments':
          attachments.map((attachment) => attachment.toJson()).toList(),
      'isOfficial': isOfficial,
      'resultUrl': resultUrl,
    };
  }
}
