import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/exam_provider.dart';
import '../../../core/providers/exam_type_provider.dart';
import '../../../core/providers/quiz_attempt_provider.dart';
import '../../../core/services/paid_quiz_access_service.dart';

import '../../../core/models/exam_model.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/router/app_router.dart';

/// Dedicated search screen for exams with suggestions and full quiz list
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSuitability = 'All';

  final List<String> _categories = [
    'All',
    'Postal guide',
    'Postal Volumes',
    'Custom',
  ];

  final List<String> _suitabilityOptions = [
    'All',
    'MTS',
    'Postman',
    'Postal Assistant',
    'Inspector',
    'Group B',
    'Others',
  ];

  // Popular search suggestions
  final List<String> _searchSuggestions = [
    'Postal guide',
    'Postal Volumes',
    'MTS exam',
    'Postman test',
    'Postal Assistant',
    'Inspector exam',
    'Group B',
    'Easy level',
    'Medium level',
    'Hard level',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!
          .toLowerCase(); // Convert to lowercase for case-insensitive search
    }
    // Auto-focus search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _onSearchChanged(suggestion);
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
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

      // Suitability filter
      final matchesSuitability = _selectedSuitability == 'All' ||
          exam.suitableFor.contains(_selectedSuitability) ||
          (_selectedSuitability == 'Postal Assistant' &&
              exam.suitableFor.contains('PA'));

      return matchesSearch && matchesCategory && matchesSuitability;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back navigation
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Navigate to home page when back button is pressed
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          title: Text(
            'Search Exams',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'), // Navigate to home page
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search Field
              Container(
                color: AppTheme.primaryColor,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SearchTextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hint: 'Search for exams, types, or difficulty...',
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                ),
              ),

              // Filters
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCategoryFilter(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSuitabilityFilter(),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _searchQuery.isEmpty
                    ? _buildAllExamsWithSuggestions()
                    : _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          hint: Text(
            'Category',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSuitabilityFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSuitability,
          isExpanded: true,
          hint: Text(
            'Suitable For',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          items: _suitabilityOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSuitability = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAllExamsWithSuggestions() {
    final examsAsync = ref.watch(activeExamsWithLiveTestsStreamProvider);

    return examsAsync.when(
      data: (exams) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search suggestions section
              Text(
                'Popular Searches',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _searchSuggestions.map((suggestion) {
                  return GestureDetector(
                    onTap: () => _onSuggestionTap(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            suggestion,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // All exams section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Tests',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${exams.length} tests available',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // All exams list
              ...exams.map((exam) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildExamCard(exam),
                  )),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading exams',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final examsAsync = ref.watch(activeExamsWithLiveTestsStreamProvider);

    return examsAsync.when(
      data: (exams) {
        final filteredExams = _filterExams(exams);

        if (filteredExams.isEmpty) {
          return _buildNoResultsFound();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Results Section (Top)
              Text(
                'Search Results (${filteredExams.length})',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Display search results
              ...filteredExams.map((exam) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildExamCard(exam),
                  )),

              const SizedBox(height: 32),

              // 2. Popular Searches Section (Middle)
              Text(
                'Popular Searches',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _searchSuggestions.map((suggestion) {
                  return GestureDetector(
                    onTap: () => _onSuggestionTap(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            suggestion,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // 3. All Tests Section (Bottom)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Tests',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${exams.length} tests available',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Display all exams (filtered by category and suitability only, not search)
              ...exams.where((exam) {
                // Category filter (using examType)
                final matchesCategory = _selectedCategory == 'All' ||
                    exam.examType == _selectedCategory;

                // Suitability filter
                final matchesSuitability = _selectedSuitability == 'All' ||
                    exam.suitableFor.contains(_selectedSuitability) ||
                    (_selectedSuitability == 'Postal Assistant' &&
                        exam.suitableFor.contains('PA'));

                return matchesCategory && matchesSuitability;
              }).map((exam) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildExamCard(exam),
                  )),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading search results',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No exams found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filters',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _clearSearch();
                setState(() {
                  _selectedCategory = 'All';
                  _selectedSuitability = 'All';
                });
              },
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
                'Clear Filters',
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

  Widget _buildExamCard(ExamModel exam) {
    return FutureBuilder<bool>(
      future: _hasUserPurchasedQuiz(exam.id),
      builder: (context, purchaseSnapshot) {
        final isPurchased = purchaseSnapshot.data ?? false;
        return Consumer(
          builder: (context, ref, child) {
            // Get exam types for dynamic icon lookup
            final examTypes = ref.watch(examTypesListProvider);

            // Get user's last attempt for this exam
            final lastAttemptAsync =
                ref.watch(userLastAttemptProvider(exam.id));

            // Enhanced color scheme with gradients (same as trending cards)
            List<Color> gradientColors;
            Color accentColor;
            String iconEmoji;

            switch (exam.examType) {
              case 'Postal guide':
                gradientColors = [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6)
                ];
                accentColor = const Color(0xFF6366F1);
                break;
              case 'Postal Volumes':
                gradientColors = [
                  const Color(0xFF10B981),
                  const Color(0xFF059669)
                ];
                accentColor = const Color(0xFF10B981);
                break;
              case 'General Knowledge':
                gradientColors = [
                  const Color(0xFFEF4444),
                  const Color(0xFFDC2626)
                ];
                accentColor = const Color(0xFFEF4444);
                break;
              case 'Current Affairs':
                gradientColors = [
                  const Color(0xFFF59E0B),
                  const Color(0xFFD97706)
                ];
                accentColor = const Color(0xFFF59E0B);
                break;
              case 'Mathematics':
                gradientColors = [
                  const Color(0xFF3B82F6),
                  const Color(0xFF2563EB)
                ];
                accentColor = const Color(0xFF3B82F6);
                break;
              default:
                gradientColors = [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF7C3AED)
                ];
                accentColor = const Color(0xFF8B5CF6);
            }

            iconEmoji =
                ExamTypeUtils.getIconForExamType(exam.examType, examTypes);

            return Container(
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
              child: InkWell(
                onTap: () async {
                  // Always go to instructions first for both free and paid quizzes
                  // The instruction screen will handle payment logic if needed
                  context.goToQuizInstructions(exam.id);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon
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
                              color: accentColor.withValues(alpha: 0.3),
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
                      const SizedBox(width: 16),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    exam.examType,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: accentColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // Purchased badge
                                if (isPurchased)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.green.shade400,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: Colors.green.shade600,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Purchased',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            // Trending badge
                            if (exam.isTrending) ...[
                              const SizedBox(height: 6),
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
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
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

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.quiz,
                                        size: 14,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${exam.numberOfQuestions} questions',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${exam.timeLimit} min',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Previous attempt time
                            lastAttemptAsync.when(
                              data: (lastAttempt) {
                                if (lastAttempt != null) {
                                  final timeAgo =
                                      _getTimeAgo(lastAttempt.attemptedAt);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.history,
                                          size: 14,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Last attempt: $timeAgo',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),

                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: exam.suitableFor.take(3).map((role) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    role,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: accentColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _hasUserPurchasedQuiz(String examId) async {
    try {
      final access = await PaidQuizAccessService.getUserQuizAccess(examId);
      return access != null && access.isValidAccess;
    } catch (e) {
      return false;
    }
  }
}
