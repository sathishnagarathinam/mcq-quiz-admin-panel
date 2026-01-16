import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exam_model.dart';
import '../services/exam_service.dart';

// State classes
class ExamState {
  final List<ExamModel> exams;
  final List<ExamModel> featuredExams;
  final bool isLoading;
  final String? error;

  const ExamState({
    this.exams = const [],
    this.featuredExams = const [],
    this.isLoading = false,
    this.error,
  });

  ExamState copyWith({
    List<ExamModel>? exams,
    List<ExamModel>? featuredExams,
    bool? isLoading,
    String? error,
  }) {
    return ExamState(
      exams: exams ?? this.exams,
      featuredExams: featuredExams ?? this.featuredExams,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Exam provider
class ExamNotifier extends StateNotifier<ExamState> {
  ExamNotifier() : super(const ExamState());

  /// Load all active exams
  Future<void> loadExams() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final exams = await ExamService.getActiveExams();
      state = state.copyWith(
        exams: exams,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load featured exams
  Future<void> loadFeaturedExams() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final featuredExams = await ExamService.getFeaturedExams();
      state = state.copyWith(
        featuredExams: featuredExams,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load exams for specific role
  Future<void> loadExamsForRole(String role) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final exams = await ExamService.getExamsForRole(role);
      state = state.copyWith(
        exams: exams,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search exams
  Future<void> searchExams(String query) async {
    if (query.isEmpty) {
      await loadExams();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final exams = await ExamService.searchExams(query);
      state = state.copyWith(
        exams: exams,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh data
  Future<void> refresh() async {
    await Future.wait([
      loadExams(),
      loadFeaturedExams(),
    ]);
  }
}

// Providers
final examProvider = StateNotifierProvider<ExamNotifier, ExamState>((ref) {
  return ExamNotifier();
});

// Featured exams stream provider (recent uploads for home screen)
final featuredExamsStreamProvider = StreamProvider<List<ExamModel>>((ref) {
  return ExamService.getFeaturedExamsStream();
});

// Active exams stream provider (all active exams)
final activeExamsStreamProvider = StreamProvider<List<ExamModel>>((ref) {
  return ExamService.getActiveExamsStream();
});

// Recent exams stream provider (for quiz list - sorted by creation date)
final recentExamsStreamProvider = StreamProvider<List<ExamModel>>((ref) {
  return ExamService.getRecentExamsStream();
});

// Active exams with live tests stream provider (includes started live tests)
final activeExamsWithLiveTestsStreamProvider =
    StreamProvider<List<ExamModel>>((ref) {
  return ExamService.getActiveExamsWithLiveTestsStream();
});

// Individual exam provider
final examByIdProvider =
    FutureProvider.family<ExamModel?, String>((ref, examId) {
  return ExamService.getExamById(examId);
});

// Exam stats provider
final examStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ExamService.getExamStats();
});

// Filtered exams providers
final examsByRoleProvider =
    FutureProvider.family<List<ExamModel>, String>((ref, role) {
  return ExamService.getExamsForRole(role);
});

// Search provider
final searchExamsProvider =
    FutureProvider.family<List<ExamModel>, String>((ref, query) {
  if (query.isEmpty) return Future.value([]);
  return ExamService.searchExams(query);
});

// Helper providers for UI
final featuredExamsProvider = Provider<List<ExamModel>>((ref) {
  final examState = ref.watch(examProvider);
  return examState.featuredExams;
});

final isLoadingExamsProvider = Provider<bool>((ref) {
  final examState = ref.watch(examProvider);
  return examState.isLoading;
});

final examErrorProvider = Provider<String?>((ref) {
  final examState = ref.watch(examProvider);
  return examState.error;
});

// Computed providers
final readyExamsProvider = Provider<List<ExamModel>>((ref) {
  final examState = ref.watch(examProvider);
  return examState.exams.where((exam) => exam.isReady).toList();
});

final examsByTypeProvider =
    Provider.family<List<ExamModel>, String>((ref, type) {
  final examState = ref.watch(examProvider);
  return examState.exams.where((exam) => exam.examType == type).toList();
});

final examCountProvider = Provider<int>((ref) {
  final examState = ref.watch(examProvider);
  return examState.exams.length;
});

final featuredExamCountProvider = Provider<int>((ref) {
  final examState = ref.watch(examProvider);
  return examState.featuredExams.length;
});

// Extension for easy access
extension ExamProviderExtension on WidgetRef {
  /// Load exams
  Future<void> loadExams() => read(examProvider.notifier).loadExams();

  /// Load featured exams
  Future<void> loadFeaturedExams() =>
      read(examProvider.notifier).loadFeaturedExams();

  /// Search exams
  Future<void> searchExams(String query) =>
      read(examProvider.notifier).searchExams(query);

  /// Refresh exam data
  Future<void> refreshExams() => read(examProvider.notifier).refresh();

  /// Clear exam error
  void clearExamError() => read(examProvider.notifier).clearError();
}
