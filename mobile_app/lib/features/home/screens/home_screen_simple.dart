import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider_minimal.dart';
import '../../../core/providers/exam_provider.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/router/app_router.dart';

/// Simple Home screen for testing - main dashboard
class HomeScreenSimple extends ConsumerWidget {
  const HomeScreenSimple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Department of Post',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'MCQ',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back, ${user?.displayName ?? user?.email ?? 'User'}!',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Quizzes Section
            Text(
              'Featured Quizzes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Featured Exams from Firebase with Debug Info
            Consumer(
              builder: (context, ref, child) {
                final featuredExamsAsync =
                    ref.watch(featuredExamsStreamProvider);

                return featuredExamsAsync.when(
                  data: (exams) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Debug info

                        if (exams.isEmpty) ...[
                          Container(
                            height: 160,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.quiz_outlined,
                                    size: 48,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No featured quizzes available',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                  Text(
                                    'Firebase connected but no exams with questions found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => ref
                                        .refresh(featuredExamsStreamProvider),
                                    child: const Text('Refresh'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: exams.length,
                              itemBuilder: (context, index) {
                                final exam = exams[index];
                                return _buildExamCard(
                                    exam, () => context.goToQuiz(exam.id));
                              },
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 160,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Loading exams from Firebase...'),
                        ],
                      ),
                    ),
                  ),
                  error: (error, stack) => Container(
                    height: 200,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.errorColor),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load quizzes',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Error: ${error.toString()}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.errorColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () =>
                                ref.refresh(featuredExamsStreamProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Add some bottom padding to prevent overflow
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam, VoidCallback onTap) {
    // Get color based on exam type
    Color getExamColor(String examType) {
      switch (examType) {
        case 'Postal guide':
          return Colors.blue;
        case 'Postal Volumes':
          return Colors.green;
        default:
          return Colors.purple;
      }
    }

    final color = getExamColor(exam.examType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exam name
            Text(
              exam.displayName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Exam details
            Row(
              children: [
                const Icon(
                  Icons.quiz,
                  size: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${exam.questions.length} Questions',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  exam.formattedDuration,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
