import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/exam_provider.dart';
import '../../../core/providers/exam_type_provider.dart';
import '../../../core/providers/quiz_attempt_provider.dart';
import '../../../core/providers/payment_provider.dart';
import '../../../core/models/exam_model.dart';

import '../../../shared/widgets/custom_text_field.dart';
import '../../payment/widgets/payment_status_widget.dart';

import '../widgets/quiz_sharing_widget.dart';

/// Quiz list screen showing available quizzes
class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isSearching = false;

  final List<String> _categories = [
    'All',
    'Postal guide',
    'Postal Volumes',
    'Custom',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Helper method to get time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<ExamModel> _filterExams(List<ExamModel> exams) {
    return exams.where((exam) {
      // Search functionality
      final matchesSearch = _searchQuery.isEmpty ||
          exam.displayName.toLowerCase().contains(_searchQuery) ||
          exam.examType.toLowerCase().contains(_searchQuery) ||
          exam.suitableFor
              .any((suit) => suit.toLowerCase().contains(_searchQuery)) ||
          exam.difficultyLevel.toLowerCase().contains(_searchQuery);

      // Category filter (using examType)
      final matchesCategory =
          _selectedCategory == 'All' || exam.examType == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.goToHome(),
          tooltip: 'Back to Home',
        ),
        title: Text(
          'Quizzes',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Search button with smooth transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              key: ValueKey(_isSearching),
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                if (!_isSearching) {
                  // Navigate to dedicated search screen
                  context.goToSearch();
                } else {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                }
              },
              tooltip: _isSearching ? 'Close Search' : 'Search Quizzes',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced header with visual hierarchy
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Field (when search is active)
                  if (_isSearching)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(16),
                      child: SearchTextField(
                        controller: _searchController,
                        hint: 'Search quizzes by name, type, or difficulty...',
                        onChanged: _onSearchChanged,
                        onClear: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    ),

                  // Category Filter with improved design
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isSearching) ...[
                          // Quick search bar (tappable)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.goToSearch();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: AppTheme.textSecondaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Search quizzes...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildCategoryFilter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quiz List from Firebase with enhanced loading and animations (includes live tests)
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final examsWithLiveTestsAsync =
                      ref.watch(activeExamsWithLiveTestsStreamProvider);

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: examsWithLiveTestsAsync.when(
                      data: (exams) {
                        final filteredExams = _filterExams(exams);

                        if (filteredExams.isEmpty) {
                          return _buildEmptyState();
                        }

                        return _buildQuizList(filteredExams);
                      },
                      loading: () => _buildLoadingState(),
                      error: (error, stack) => _buildErrorState(error, ref),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build enhanced loading state with animation
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading quizzes...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state with retry functionality
  Widget _buildErrorState(Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load quizzes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(recentExamsStreamProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build quiz list with smooth animations
  Widget _buildQuizList(List<ExamModel> exams) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          child: _buildEnhancedExamCard(exams[index], index),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: AppTheme.surfaceColor,
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color:
                    isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, {Color? color}) {
    final chipColor = color ?? AppTheme.textSecondaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: chipColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Build enhanced exam card with animations and visual feedback
  Widget _buildEnhancedExamCard(ExamModel exam, int index) {
    return Consumer(
      builder: (context, ref, child) {
        // Get exam types for dynamic icon lookup
        final examTypes = ref.watch(examTypesListProvider);

        // Get user's last attempt for this exam
        final lastAttemptAsync = ref.watch(userLastAttemptProvider(exam.id));

        // Enhanced color scheme with gradients (same as trending cards)
        List<Color> gradientColors;
        Color accentColor;

        switch (exam.examType) {
          case 'Postal guide':
            gradientColors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
            accentColor = const Color(0xFF6366F1);
            break;
          case 'Postal Volumes':
            gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
            accentColor = const Color(0xFF10B981);
            break;
          case 'General Knowledge':
            gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
            accentColor = const Color(0xFFEF4444);
            break;
          case 'Current Affairs':
            gradientColors = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
            accentColor = const Color(0xFFF59E0B);
            break;
          case 'Mathematics':
            gradientColors = [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
            accentColor = const Color(0xFF3B82F6);
            break;
          default:
            gradientColors = [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
            accentColor = const Color(0xFF8B5CF6);
        }
        final iconEmoji =
            ExamTypeUtils.getIconForExamType(exam.examType, examTypes);

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        gradientColors[0].withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        // Add haptic feedback for better UX
                        HapticFeedback.lightImpact();

                        // Always go to instructions first for both free and paid quizzes
                        // The instruction screen will handle payment logic if needed
                        context.goToQuizInstructions(exam.id);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icon with price badge
                            Stack(
                              children: [
                                // Icon (using emoji like web admin)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: gradientColors,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            accentColor.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    iconEmoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),

                                // Price badge (positioned at top-right of icon)
                                if (!exam.isFree)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade600,
                                            Colors.green.shade800
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '₹${exam.price.toInt()}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  // Free badge for debugging
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade600,
                                            Colors.blue.shade800
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'FREE',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(width: 16),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Exam name and type
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          exam.displayName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        flex: 1,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: accentColor.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            exam.examType,
                                            style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w500,
                                              color: accentColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Trending badge
                                  if (exam.isTrending) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange.shade600,
                                                Colors.orange.shade800
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.trending_up,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Trending #${exam.trendingPriority}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 8),

                                  // Exam details
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // First row with exam info
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: _buildInfoChip(
                                              '${exam.questions.length} Questions',
                                              Icons.quiz,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            flex: 2,
                                            child: _buildInfoChip(
                                              exam.formattedDuration,
                                              Icons.timer,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            flex: 2,
                                            child: _buildDifficultyChip(
                                                exam.difficultyLevel),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Second row with payment status
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          provider.Consumer<PaymentProvider>(
                                            builder: (context, paymentProvider,
                                                child) {
                                              // Load payment status when widget builds
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                paymentProvider
                                                    .loadExamPaymentStatus(
                                                        exam.id);
                                              });

                                              return PaymentStatusWidget(
                                                exam: exam,
                                                hasPaid: paymentProvider
                                                    .hasUserPaidForExam(
                                                        exam.id),
                                                isLoading:
                                                    paymentProvider.isLoading,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Previous attempt time
                                  lastAttemptAsync.when(
                                    data: (lastAttempt) {
                                      if (lastAttempt != null) {
                                        final timeAgo = _getTimeAgo(
                                            lastAttempt.attemptedAt);
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: _buildInfoChip(
                                            'Last: $timeAgo',
                                            Icons.history,
                                            color: Colors.orange,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                                  const SizedBox(height: 8),

                                  // Suitable for tags
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children:
                                        exam.suitableFor.take(3).map((role) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          role,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),

                            // Share and Arrow buttons
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Share button
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    showQuizSharingSheet(
                                      context: context,
                                      exam: exam,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.share,
                                      color: accentColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Arrow
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: AppTheme.textSecondaryColor,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'hard':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        difficulty,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No quizzes found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
