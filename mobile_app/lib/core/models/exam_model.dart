import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class ExamType {
  final String id;
  final String name;
  final String icon;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ExamType({
    required this.id,
    required this.name,
    required this.icon,
    required this.isDefault,
    required this.createdAt,
    this.updatedAt,
  });

  factory ExamType.fromJson(Map<String, dynamic> json) {
    return ExamType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '📝',
      isDefault: json['isDefault'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  factory ExamType.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime createdAt = DateTime.now();
    DateTime? updatedAt;

    // Handle Firestore Timestamp conversion
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt']);
      }
    }

    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is String) {
        updatedAt = DateTime.parse(data['updatedAt']);
      }
    }

    return ExamType(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '📝',
      isDefault: data['isDefault'] ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ExamType copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamType(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExamType &&
        other.id == id &&
        other.name == name &&
        other.icon == icon &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ icon.hashCode ^ isDefault.hashCode;
  }

  @override
  String toString() {
    return 'ExamType(id: $id, name: $name, icon: $icon, isDefault: $isDefault)';
  }
}

class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String? explanation;
  final String difficulty; // Easy, Medium, Hard
  final bool isFree; // Whether this question is free in freemium model

  const QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.difficulty = 'Medium', // Default to Medium
    this.isFree = false, // Default to paid (not free)
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      explanation: json['explanation'],
      difficulty: json['difficulty'] ?? 'Medium',
      isFree: json['isFree'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'isFree': isFree,
    };
  }
}

class ExamModel {
  final String id;
  final String name;
  final String examType;
  final String? customName;
  final int numberOfQuestions;
  final int timeLimit;
  final List<String> suitableFor;
  final List<QuestionModel> questions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int totalAttempts;
  final bool isTrending;
  final int trendingPriority;
  final double price;
  final String currency;
  final bool isFree;
  final int shareCount;
  final DateTime? lastSharedAt;
  final double discountPercentage; // Discount percentage (0-100)
  final String? bannerRoutedFrom; // Banner ID if routed from banner
  final String? couponCode; // Coupon code applied
  final int
      freeQuestionsLimit; // Number of free questions in freemium model (-1 = fully free, 0 = fully paid, >0 = freemium)
  final double
      unlockPrice; // Price to unlock remaining questions in freemium model

  const ExamModel({
    required this.id,
    required this.name,
    required this.examType,
    this.customName,
    required this.numberOfQuestions,
    required this.timeLimit,
    required this.suitableFor,
    required this.questions,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.totalAttempts = 0,
    this.isTrending = false,
    this.trendingPriority = 0,
    this.price = 0.0,
    this.currency = 'INR',
    this.isFree = true,
    this.shareCount = 0,
    this.lastSharedAt,
    this.discountPercentage = 0.0,
    this.bannerRoutedFrom,
    this.couponCode,
    this.freeQuestionsLimit = -1, // Default to fully free
    this.unlockPrice = 0.0,
  });

  /// Check if this is a freemium quiz (has some free questions but not all)
  bool get isFreemium =>
      freeQuestionsLimit > 0 && freeQuestionsLimit < numberOfQuestions;

  /// Get count of free questions (based on isFree flag in questions)
  int get freeQuestionCount => questions.where((q) => q.isFree).length;

  /// Get count of paid questions
  int get paidQuestionCount => questions.where((q) => !q.isFree).length;

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    final questionsData = json['questions'] as List<dynamic>? ?? [];
    final questions = questionsData
        .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
        .toList();

    return ExamModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      examType: json['examType'] ?? 'Custom',
      customName: json['customName'],
      numberOfQuestions: json['numberOfQuestions'] ?? 0,
      timeLimit: json['timeLimit'] ?? 30,
      suitableFor: List<String>.from(json['suitableFor'] ?? []),
      questions: questions,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      totalAttempts: json['totalAttempts'] ?? 0,
      isTrending: json['isTrending'] ?? false,
      trendingPriority: json['trendingPriority'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'INR',
      isFree: json['isFree'] ?? true,
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      bannerRoutedFrom: json['bannerRoutedFrom'],
      couponCode: json['couponCode'],
      shareCount: json['shareCount'] ?? 0,
      lastSharedAt: json['lastSharedAt'] != null
          ? DateTime.parse(json['lastSharedAt'])
          : null,
      freeQuestionsLimit: json['freeQuestionsLimit'] ?? -1,
      unlockPrice: (json['unlockPrice'] ?? 0.0).toDouble(),
    );
  }

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Parse questions
      final questionsData = data['questions'] as List<dynamic>? ?? [];
      final questions = questionsData
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList();

      // Parse timestamps with better error handling
      DateTime createdAt;
      DateTime updatedAt;

      try {
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          createdAt = DateTime.parse(data['createdAt']);
        } else {
          createdAt = DateTime.now();
        }
      } catch (e) {
        developer.log('Error parsing createdAt for exam ${doc.id}: $e');
        createdAt = DateTime.now();
      }

      try {
        if (data['updatedAt'] is Timestamp) {
          updatedAt = (data['updatedAt'] as Timestamp).toDate();
        } else if (data['updatedAt'] is String) {
          updatedAt = DateTime.parse(data['updatedAt']);
        } else {
          updatedAt = DateTime.now();
        }
      } catch (e) {
        developer.log('Error parsing updatedAt for exam ${doc.id}: $e');
        updatedAt = DateTime.now();
      }

      // Debug logging for price fields
      developer
          .log('🔍 ExamModel.fromFirestore Debug for exam: ${data['name']}');
      developer.log(
          '  - Raw price data: ${data['price']} (type: ${data['price'].runtimeType})');
      developer.log('  - Raw currency data: ${data['currency']}');
      developer.log(
          '  - Raw isFree data: ${data['isFree']} (type: ${data['isFree'].runtimeType})');

      final price = (data['price'] ?? 0.0).toDouble();
      final currency = data['currency'] ?? 'INR';
      final isFree = data['isFree'] ?? true;

      developer.log('  - Parsed price: $price');
      developer.log('  - Parsed currency: $currency');
      developer.log('  - Parsed isFree: $isFree');

      return ExamModel(
        id: doc.id,
        name: data['name'] ?? '',
        examType: data['examType'] ?? 'Custom',
        customName: data['customName'],
        numberOfQuestions: data['numberOfQuestions'] ?? 0,
        timeLimit: data['timeLimit'] ?? 30,
        suitableFor: List<String>.from(data['suitableFor'] ?? []),
        questions: questions,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isActive: data['isActive'] ?? true,
        totalAttempts: data['totalAttempts'] ?? 0,
        isTrending: data['isTrending'] ?? false,
        trendingPriority: data['trendingPriority'] ?? 0,
        price: price,
        currency: currency,
        isFree: isFree,
        shareCount: data['shareCount'] ?? 0,
        lastSharedAt: data['lastSharedAt'] != null
            ? (data['lastSharedAt'] is Timestamp
                ? (data['lastSharedAt'] as Timestamp).toDate()
                : DateTime.parse(data['lastSharedAt']))
            : null,
        discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
        bannerRoutedFrom: data['bannerRoutedFrom'],
        couponCode: data['couponCode'],
        freeQuestionsLimit: data['freeQuestionsLimit'] ?? -1,
        unlockPrice: (data['unlockPrice'] ?? 0.0).toDouble(),
      );
    } catch (e) {
      developer.log('Error parsing exam document ${doc.id}: $e');
      // Return a default exam model to prevent crashes
      return ExamModel(
        id: doc.id,
        name: 'Error Loading Exam',
        examType: 'Custom',
        numberOfQuestions: 0,
        timeLimit: 30,
        suitableFor: [],
        questions: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: false,
        totalAttempts: 0,
        isTrending: false,
        trendingPriority: 0,
        shareCount: 0,
        lastSharedAt: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'examType': examType,
      'customName': customName,
      'numberOfQuestions': numberOfQuestions,
      'timeLimit': timeLimit,
      'suitableFor': suitableFor,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'totalAttempts': totalAttempts,
      'isTrending': isTrending,
      'trendingPriority': trendingPriority,
      'price': price,
      'currency': currency,
      'isFree': isFree,
      'shareCount': shareCount,
      'lastSharedAt': lastSharedAt?.toIso8601String(),
      'discountPercentage': discountPercentage,
      'bannerRoutedFrom': bannerRoutedFrom,
      'couponCode': couponCode,
      'freeQuestionsLimit': freeQuestionsLimit,
      'unlockPrice': unlockPrice,
    };
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'examType': examType,
      'customName': customName,
      'numberOfQuestions': numberOfQuestions,
      'timeLimit': timeLimit,
      'suitableFor': suitableFor,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'totalAttempts': totalAttempts,
      'isTrending': isTrending,
      'trendingPriority': trendingPriority,
      'price': price,
      'currency': currency,
      'isFree': isFree,
      'shareCount': shareCount,
      'lastSharedAt':
          lastSharedAt != null ? Timestamp.fromDate(lastSharedAt!) : null,
      'discountPercentage': discountPercentage,
      'bannerRoutedFrom': bannerRoutedFrom,
      'couponCode': couponCode,
      'freeQuestionsLimit': freeQuestionsLimit,
      'unlockPrice': unlockPrice,
    };
  }
}

// Extension methods for ExamModel
extension ExamModelExtension on ExamModel {
  /// Get display name
  String get displayName => name;

  /// Calculate discounted price based on discount percentage
  double get discountedPrice {
    if (discountPercentage <= 0 || discountPercentage > 100) {
      return price;
    }
    final discountAmount = price * (discountPercentage / 100);
    return price - discountAmount;
  }

  /// Get discount amount in rupees
  double get discountAmount {
    if (discountPercentage <= 0 || discountPercentage > 100) {
      return 0;
    }
    return price * (discountPercentage / 100);
  }

  /// Check if discount is applicable
  bool get hasDiscount => discountPercentage > 0 && discountPercentage <= 100;

  /// Get exam type icon (fallback method - use ExamTypeUtils.getIconForExamType for dynamic icons)
  String get typeIcon {
    // This is a fallback method for backward compatibility
    // For dynamic icons, use ExamTypeUtils.getIconForExamType(examType, examTypes)
    switch (examType) {
      case 'Postal Guide':
      case 'Postal guide':
        return '📮';
      case 'Postal Volumes':
        return '📚';
      case 'Railway Exam':
        return '🚂';
      case 'Banking Exam':
        return '🏦';
      case 'Police Exam':
        return '👮';
      case 'Legal Exam':
        return '⚖️';
      case 'Medical Exam':
        return '🏥';
      case 'Academic Exam':
        return '🎓';
      case 'Corporate Exam':
        return '💼';
      case 'Science Exam':
        return '🔬';
      case 'Technology Exam':
        return '💻';
      default:
        return '📝'; // Default icon for custom exam types
    }
  }

  /// Get exam type icon dynamically from exam types list
  String getTypeIcon(List<ExamType> examTypes) {
    try {
      final examType = examTypes.firstWhere(
        (type) => type.name.toLowerCase() == this.examType.toLowerCase(),
      );
      return examType.icon;
    } catch (e) {
      // Fallback to static method
      return typeIcon;
    }
  }

  /// Get difficulty level based on number of questions and time
  String get difficultyLevel {
    final questionsPerMinute = numberOfQuestions / timeLimit;
    if (questionsPerMinute > 1.5) {
      return 'Hard';
    } else if (questionsPerMinute > 1.0) {
      return 'Medium';
    } else {
      return 'Easy';
    }
  }

  /// Get completion percentage (questions added vs target)
  double get completionPercentage {
    if (numberOfQuestions == 0) return 0.0;
    return (questions.length / numberOfQuestions).clamp(0.0, 1.0);
  }

  /// Check if exam is ready (has questions)
  bool get isReady => questions.isNotEmpty;

  /// Get formatted duration
  String get formattedDuration {
    if (timeLimit < 60) {
      return '${timeLimit}m';
    } else {
      final hours = timeLimit ~/ 60;
      final minutes = timeLimit % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  /// Get suitable roles as formatted string
  String get suitableRolesText => suitableFor.join(', ');

  /// Check if exam is suitable for a specific role
  bool isSuitableFor(String role) => suitableFor.contains(role);

  /// Get exam status
  ExamStatus get status {
    if (!isActive) return ExamStatus.inactive;
    if (questions.isEmpty) return ExamStatus.draft;
    if (questions.length < numberOfQuestions) return ExamStatus.incomplete;
    return ExamStatus.ready;
  }
}

enum ExamStatus {
  draft,
  incomplete,
  ready,
  inactive,
}

extension ExamStatusExtension on ExamStatus {
  String get displayName {
    switch (this) {
      case ExamStatus.draft:
        return 'Draft';
      case ExamStatus.incomplete:
        return 'Incomplete';
      case ExamStatus.ready:
        return 'Ready';
      case ExamStatus.inactive:
        return 'Inactive';
    }
  }

  String get description {
    switch (this) {
      case ExamStatus.draft:
        return 'No questions added yet';
      case ExamStatus.incomplete:
        return 'More questions needed';
      case ExamStatus.ready:
        return 'Ready for students';
      case ExamStatus.inactive:
        return 'Not available to students';
    }
  }
}
