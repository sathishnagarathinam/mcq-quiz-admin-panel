import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/exam_model.dart';

/// Service for managing exam types
class ExamTypeService {
  static const String _collection = 'examTypes';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get default exam types with current timestamp
  static List<ExamType> get defaultExamTypes {
    final now = DateTime.now();
    return [
      ExamType(
        id: 'postal-guide',
        name: 'Postal Guide',
        icon: '📮',
        isDefault: true,
        createdAt: now,
      ),
      ExamType(
        id: 'postal-volumes',
        name: 'Postal Volumes',
        icon: '📚',
        isDefault: true,
        createdAt: now,
      ),
      ExamType(
        id: 'railway-exam',
        name: 'Railway Exam',
        icon: '🚂',
        isDefault: true,
        createdAt: now,
      ),
      ExamType(
        id: 'banking-exam',
        name: 'Banking Exam',
        icon: '🏦',
        isDefault: true,
        createdAt: now,
      ),
      ExamType(
        id: 'police-exam',
        name: 'Police Exam',
        icon: '👮',
        isDefault: true,
        createdAt: now,
      ),
      ExamType(
        id: 'legal-exam',
        name: 'Legal Exam',
        icon: '⚖️',
        isDefault: true,
        createdAt: now,
      ),
      ExamType(
        id: 'medical-exam',
        name: 'Medical Exam',
        icon: '🏥',
        isDefault: true,
        createdAt: now,
      ),
      ExamType(
        id: 'academic-exam',
        name: 'Academic Exam',
        icon: '🎓',
        isDefault: true,
        createdAt: now,
      ),
      ExamType(
        id: 'corporate-exam',
        name: 'Corporate Exam',
        icon: '💼',
        isDefault: true,
        createdAt: now,
      ),
      ExamType(
        id: 'science-exam',
        name: 'Science Exam',
        icon: '🔬',
        isDefault: true,
        createdAt: now,
      ),
      ExamType(
        id: 'technology-exam',
        name: 'Technology Exam',
        icon: '💻',
        isDefault: true,
        createdAt: now,
      ),
    ];
  }

  /// Get all exam types (default + custom from Firestore)
  static Future<List<ExamType>> getAllExamTypes() async {
    try {
      developer.log('Fetching exam types from Firestore...');

      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: false)
          .get();

      developer.log('Found ${querySnapshot.docs.length} custom exam types');

      final customTypes =
          querySnapshot.docs.map((doc) => ExamType.fromFirestore(doc)).toList();

      // Combine default types with custom types
      final allTypes = <ExamType>[
        ...defaultExamTypes,
        ...customTypes,
      ];

      developer.log('Total exam types: ${allTypes.length}');
      return allTypes;
    } catch (e) {
      developer.log('Error fetching exam types: $e');
      // Return default types as fallback
      return defaultExamTypes;
    }
  }

  /// Get exam types stream for real-time updates
  static Stream<List<ExamType>> getExamTypesStream() {
    developer.log('Setting up exam types stream listener');

    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      developer.log(
          'Received ${snapshot.docs.length} custom exam types from stream');

      final customTypes =
          snapshot.docs.map((doc) => ExamType.fromFirestore(doc)).toList();

      // Combine default types with custom types
      final allTypes = <ExamType>[
        ...defaultExamTypes,
        ...customTypes,
      ];

      developer.log('Total exam types in stream: ${allTypes.length}');
      return allTypes;
    }).handleError((error) {
      developer.log('Error in exam types stream: $error');
      // Return default types as fallback
      return defaultExamTypes;
    });
  }

  /// Get exam type by name
  static Future<ExamType?> getExamTypeByName(String name) async {
    try {
      final allTypes = await getAllExamTypes();
      return allTypes.firstWhere(
        (type) => type.name.toLowerCase() == name.toLowerCase(),
        orElse: () => ExamType(
          id: 'custom',
          name: name,
          icon: '📝',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      developer.log('Error getting exam type by name: $e');
      return null;
    }
  }

  /// Get icon for exam type name
  static Future<String> getIconForExamType(String examTypeName) async {
    try {
      final examType = await getExamTypeByName(examTypeName);
      return examType?.icon ?? '📝';
    } catch (e) {
      developer.log('Error getting icon for exam type: $e');
      return '📝'; // Default icon
    }
  }

  /// Check if exam type exists
  static Future<bool> examTypeExists(String name) async {
    try {
      final allTypes = await getAllExamTypes();
      return allTypes
          .any((type) => type.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      developer.log('Error checking if exam type exists: $e');
      return false;
    }
  }

  /// Get exam type statistics
  static Future<Map<String, dynamic>> getExamTypeStats() async {
    try {
      final allTypes = await getAllExamTypes();
      final customTypes = allTypes.where((type) => !type.isDefault).toList();

      return {
        'totalTypes': allTypes.length,
        'defaultTypes': allTypes.where((type) => type.isDefault).length,
        'customTypes': customTypes.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('Error getting exam type stats: $e');
      final defaults = defaultExamTypes;
      return {
        'totalTypes': defaults.length,
        'defaultTypes': defaults.length,
        'customTypes': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
}
