import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/exam_model.dart';
import '../services/exam_type_service.dart';

/// State class for exam types
class ExamTypeState {
  final List<ExamType> examTypes;
  final bool isLoading;
  final String? error;

  const ExamTypeState({
    this.examTypes = const [],
    this.isLoading = false,
    this.error,
  });

  ExamTypeState copyWith({
    List<ExamType>? examTypes,
    bool? isLoading,
    String? error,
  }) {
    return ExamTypeState(
      examTypes: examTypes ?? this.examTypes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExamTypeState &&
        other.examTypes == examTypes &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return examTypes.hashCode ^ isLoading.hashCode ^ error.hashCode;
  }

  @override
  String toString() {
    return 'ExamTypeState(examTypes: ${examTypes.length}, isLoading: $isLoading, error: $error)';
  }
}

/// Exam type notifier
class ExamTypeNotifier extends StateNotifier<ExamTypeState> {
  ExamTypeNotifier() : super(const ExamTypeState()) {
    // Load exam types on initialization
    loadExamTypes();
  }

  /// Load all exam types
  Future<void> loadExamTypes() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      developer.log('Loading exam types...');
      final examTypes = await ExamTypeService.getAllExamTypes();
      developer.log('Loaded ${examTypes.length} exam types');

      state = state.copyWith(
        examTypes: examTypes,
        isLoading: false,
      );
    } catch (e) {
      developer.log('Error loading exam types: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh exam types
  Future<void> refreshExamTypes() async {
    await loadExamTypes();
  }

  /// Get exam type by name
  ExamType? getExamTypeByName(String name) {
    try {
      return state.examTypes.firstWhere(
        (type) => type.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      developer.log('Exam type not found: $name');
      return null;
    }
  }

  /// Get icon for exam type name
  String getIconForExamType(String examTypeName) {
    final examType = getExamTypeByName(examTypeName);
    return examType?.icon ?? '📝';
  }

  /// Check if exam type exists
  bool examTypeExists(String name) {
    return state.examTypes.any(
      (type) => type.name.toLowerCase() == name.toLowerCase(),
    );
  }

  /// Get default exam types
  List<ExamType> get defaultExamTypes {
    return state.examTypes.where((type) => type.isDefault).toList();
  }

  /// Get custom exam types
  List<ExamType> get customExamTypes {
    return state.examTypes.where((type) => !type.isDefault).toList();
  }
}

/// Main exam type provider
final examTypeProvider =
    StateNotifierProvider<ExamTypeNotifier, ExamTypeState>((ref) {
  return ExamTypeNotifier();
});

/// Stream provider for real-time exam types updates
final examTypesStreamProvider = StreamProvider<List<ExamType>>((ref) {
  return ExamTypeService.getExamTypesStream();
});

/// Provider for exam types list
final examTypesListProvider = Provider<List<ExamType>>((ref) {
  final examTypeState = ref.watch(examTypeProvider);
  return examTypeState.examTypes;
});

/// Provider for loading state
final examTypesLoadingProvider = Provider<bool>((ref) {
  final examTypeState = ref.watch(examTypeProvider);
  return examTypeState.isLoading;
});

/// Provider for error state
final examTypesErrorProvider = Provider<String?>((ref) {
  final examTypeState = ref.watch(examTypeProvider);
  return examTypeState.error;
});

/// Provider for default exam types
final defaultExamTypesProvider = Provider<List<ExamType>>((ref) {
  final examTypeState = ref.watch(examTypeProvider);
  return examTypeState.examTypes.where((type) => type.isDefault).toList();
});

/// Provider for custom exam types
final customExamTypesProvider = Provider<List<ExamType>>((ref) {
  final examTypeState = ref.watch(examTypeProvider);
  return examTypeState.examTypes.where((type) => !type.isDefault).toList();
});

/// Family provider for getting exam type by name
final examTypeByNameProvider = Provider.family<ExamType?, String>((ref, name) {
  final examTypeState = ref.watch(examTypeProvider);
  try {
    return examTypeState.examTypes.firstWhere(
      (type) => type.name.toLowerCase() == name.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
});

/// Family provider for getting icon by exam type name
final examTypeIconProvider =
    Provider.family<String, String>((ref, examTypeName) {
  final examType = ref.watch(examTypeByNameProvider(examTypeName));
  return examType?.icon ?? '📝';
});

/// Provider for exam type statistics
final examTypeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ExamTypeService.getExamTypeStats();
});

/// Extension for easy access to exam type functionality
extension ExamTypeProviderExtension on WidgetRef {
  /// Load exam types
  Future<void> loadExamTypes() =>
      read(examTypeProvider.notifier).loadExamTypes();

  /// Refresh exam types
  Future<void> refreshExamTypes() =>
      read(examTypeProvider.notifier).refreshExamTypes();

  /// Get exam type by name
  ExamType? getExamTypeByName(String name) =>
      read(examTypeProvider.notifier).getExamTypeByName(name);

  /// Get icon for exam type
  String getIconForExamType(String examTypeName) =>
      read(examTypeProvider.notifier).getIconForExamType(examTypeName);

  /// Check if exam type exists
  bool examTypeExists(String name) =>
      read(examTypeProvider.notifier).examTypeExists(name);
}

/// Helper class for exam type utilities
class ExamTypeUtils {
  /// Get icon for exam type name (static method for use without provider)
  static String getIconForExamType(
      String examTypeName, List<ExamType> examTypes) {
    try {
      final examType = examTypes.firstWhere(
        (type) => type.name.toLowerCase() == examTypeName.toLowerCase(),
      );
      return examType.icon;
    } catch (e) {
      // Fallback to hardcoded icons for backward compatibility
      switch (examTypeName.toLowerCase()) {
        case 'postal guide':
          return '📮';
        case 'postal volumes':
          return '📚';
        case 'railway exam':
          return '🚂';
        case 'banking exam':
          return '🏦';
        case 'police exam':
          return '👮';
        case 'legal exam':
          return '⚖️';
        case 'medical exam':
          return '🏥';
        case 'academic exam':
          return '🎓';
        case 'corporate exam':
          return '💼';
        case 'science exam':
          return '🔬';
        case 'technology exam':
          return '💻';
        default:
          return '📝';
      }
    }
  }

  /// Get color for exam type (for UI consistency)
  static String getColorForExamType(String examTypeName) {
    switch (examTypeName.toLowerCase()) {
      case 'postal guide':
        return '#6366F1'; // Indigo
      case 'postal volumes':
        return '#10B981'; // Emerald
      case 'railway exam':
        return '#F59E0B'; // Amber
      case 'banking exam':
        return '#3B82F6'; // Blue
      case 'police exam':
        return '#EF4444'; // Red
      case 'legal exam':
        return '#8B5CF6'; // Violet
      case 'medical exam':
        return '#06B6D4'; // Cyan
      case 'academic exam':
        return '#84CC16'; // Lime
      case 'corporate exam':
        return '#F97316'; // Orange
      case 'science exam':
        return '#14B8A6'; // Teal
      case 'technology exam':
        return '#A855F7'; // Purple
      default:
        return '#6B7280'; // Gray
    }
  }
}
