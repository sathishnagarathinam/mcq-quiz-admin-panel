import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/services/exam_service.dart';
import '../../../core/services/paid_quiz_access_service.dart';
import '../../../core/services/auth_helper_service.dart';
import '../../../core/services/quiz_statistics_service.dart';
import '../../../core/models/paid_quiz_access_model.dart';
import '../../payment/widgets/payment_confirmation_dialog.dart';
import '../widgets/quiz_sharing_widget.dart';
import 'quiz_ratings_page.dart';

/// Quiz instruction screen that shows before starting the quiz
class QuizInstructionScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizInstructionScreen({
    super.key,
    required this.quizId,
  });

  @override
  ConsumerState<QuizInstructionScreen> createState() =>
      _QuizInstructionScreenState();
}

class _QuizInstructionScreenState extends ConsumerState<QuizInstructionScreen> {
  ExamModel? _exam;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _accessDetails;

  // Quiz statistics
  Map<String, dynamic>? _quizStatistics;
  int? _userHighestScore;
  int? _userAttemptCount;
  bool _hasUserAttempted = false;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndLoadExam();
  }

  /// Check if user is authenticated before loading exam
  Future<void> _checkAuthenticationAndLoadExam() async {
    try {
      // Check for both Firebase Auth and phone auth
      final isAuthenticated = await AuthHelperService.isUserAuthenticated();

      // If user is not authenticated, redirect to login
      if (!isAuthenticated) {
        debugPrint('⚠️ User not authenticated, redirecting to login');
        if (mounted) {
          // Store the quiz ID to return after login
          context.go('/auth/login', extra: {'returnToQuizId': widget.quizId});
        }
        return;
      }

      // User is authenticated, load exam
      await _loadExam();
    } catch (e) {
      debugPrint('❌ Error checking authentication: $e');
      if (mounted) {
        setState(() {
          _error = 'Authentication error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadExam() async {
    try {
      debugPrint('📚 Loading exam data for quiz: ${widget.quizId}');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final exam = await ExamService.getExamById(widget.quizId);

      if (exam == null) {
        debugPrint('❌ Exam not found');
        setState(() {
          _error = 'Exam not found';
          _isLoading = false;
        });
        return;
      }

      debugPrint('✅ Exam loaded: ${exam.name}');
      debugPrint('   - exam.isFree: ${exam.isFree}');
      debugPrint('   - exam.price: ${exam.price}');
      debugPrint('   - exam.currency: ${exam.currency}');

      // Apply discount information if passed from banner navigation
      ExamModel examWithDiscount = exam;

      // Get extra data from GoRouter state
      if (mounted) {
        try {
          final state = GoRouterState.of(context);
          final extra = state.extra as Map<String, dynamic>?;

          if (extra != null) {
            final discountPercentage =
                extra['discountPercentage'] as double? ?? 0.0;
            final couponCode = extra['couponCode'] as String?;
            final bannerRoutedFrom = extra['bannerRoutedFrom'] as String?;

            if (discountPercentage > 0) {
              debugPrint('💰 Applying discount from banner:');
              debugPrint('   - Discount: $discountPercentage%');
              debugPrint('   - Coupon: $couponCode');
              debugPrint('   - Banner ID: $bannerRoutedFrom');

              examWithDiscount = ExamModel(
                id: exam.id,
                name: exam.name,
                examType: exam.examType,
                customName: exam.customName,
                numberOfQuestions: exam.numberOfQuestions,
                timeLimit: exam.timeLimit,
                suitableFor: exam.suitableFor,
                questions: exam.questions,
                createdAt: exam.createdAt,
                updatedAt: exam.updatedAt,
                isActive: exam.isActive,
                totalAttempts: exam.totalAttempts,
                isTrending: exam.isTrending,
                trendingPriority: exam.trendingPriority,
                price: exam.price,
                currency: exam.currency,
                isFree: exam.isFree,
                shareCount: exam.shareCount,
                lastSharedAt: exam.lastSharedAt,
                discountPercentage: discountPercentage,
                bannerRoutedFrom: bannerRoutedFrom,
                couponCode: couponCode,
                freeQuestionsLimit: exam.freeQuestionsLimit,
                unlockPrice: exam.unlockPrice,
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error reading discount data from route: $e');
        }
      }

      // Step 2: Get user ID early so we can parallelize user-specific queries
      final userId = await AuthHelperService.getCurrentUserId();

      // Step 3: Load all remaining data in parallel
      // These can all be fetched at the same time
      final results = await Future.wait([
        PaidQuizAccessService.getAccessDetails(
          examId: widget.quizId,
          exam: examWithDiscount,
        ),
        QuizStatisticsService.getQuizStatistics(widget.quizId),
        if (userId != null)
          QuizStatisticsService.getUserQuizAttempts(userId, widget.quizId)
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);

      final accessDetails = results[0] as Map<String, dynamic>;
      final quizStats = results[1] as Map<String, dynamic>;
      final userAttempts =
          results[2] as List<Map<String, dynamic>>? ?? <Map<String, dynamic>>[];

      debugPrint('📋 Access details loaded:');
      debugPrint('   - Status: ${accessDetails['status']}');
      debugPrint('   - Can Attempt: ${accessDetails['canAttempt']}');
      debugPrint('   - Show Payment: ${accessDetails['showPayment']}');
      debugPrint('   - Message: ${accessDetails['message']}');

      debugPrint('📊 Quiz statistics loaded:');
      debugPrint('   - Total Attempts: ${quizStats['totalAttempts']}');
      debugPrint('   - Average Rating: ${quizStats['averageRating']}');
      debugPrint('   - Total Ratings: ${quizStats['totalRatings']}');

      // Calculate user statistics from attempts
      int userAttemptCount = userAttempts.length;
      bool hasUserAttempted = userAttemptCount > 0;
      int? userHighestScore;

      if (hasUserAttempted) {
        final scores =
            userAttempts.map((a) => a['score'] as int? ?? 0).toList();
        userHighestScore =
            scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b);

        debugPrint('👤 User statistics loaded:');
        debugPrint('   - User Attempts: $userAttemptCount');
        debugPrint('   - User Highest Score: $userHighestScore');
      }

      setState(() {
        _exam = examWithDiscount;
        _accessDetails = accessDetails;
        _quizStatistics = quizStats;
        _userHighestScore = userHighestScore;
        _userAttemptCount = userAttemptCount;
        _hasUserAttempted = hasUserAttempted;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading exam: $e');
      setState(() {
        _error = 'Failed to load exam: $e';
        _isLoading = false;
      });
    }
  }

  void _shareQuiz() {
    if (_exam == null) return;

    showQuizSharingSheet(
      context: context,
      exam: _exam!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Quiz Instructions',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _shareQuiz,
              icon: const Icon(Icons.share),
              tooltip: 'Share Quiz',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
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
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadExam,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_exam == null) {
      return const Center(
        child: Text('No exam data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiz Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _exam!.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _exam!.examType,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Access Status Card
          _buildAccessStatusCard(),

          const SizedBox(height: 24),

          // Quiz Statistics Card (above details)
          _buildStatisticsCard(),

          const SizedBox(height: 24),

          // Quiz Details
          _buildDetailCard(),

          const SizedBox(height: 24),

          // Instructions
          _buildInstructionsCard(),

          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAccessStatusCard() {
    if (_accessDetails == null) {
      return const SizedBox.shrink();
    }

    final status = _accessDetails!['status'] as QuizAccessStatus;
    final canAttempt = _accessDetails!['canAttempt'] as bool;
    final message = _accessDetails!['message'] as String;
    final showPayment = _accessDetails!['showPayment'] as bool? ?? false;

    Color cardColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case QuizAccessStatus.free:
        cardColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case QuizAccessStatus.purchased:
        cardColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue.shade700;
        icon = Icons.verified;
        break;
      case QuizAccessStatus.expired:
        cardColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
        icon = Icons.access_time;
        break;
      case QuizAccessStatus.notPurchased:
        cardColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade700;
        icon = Icons.lock;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                status.displayName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (showPayment) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PAID',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getAccessMessage(status, message),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textColor,
            ),
          ),
          // Show freemium info if applicable
          if (_exam != null &&
              _exam!.isFreemium &&
              status == QuizAccessStatus.free) ...[
            const SizedBox(height: 8),
            _buildFreemiumInfo(),
          ],
          if (status == QuizAccessStatus.purchased) ...[
            const SizedBox(height: 8),
            _buildAccessDetails(),
          ],
          if (showPayment && _exam != null) ...[
            const SizedBox(height: 12),
            _buildPriceInfo(),
          ],
        ],
      ),
    );
  }

  /// Get access message, customized for freemium quizzes
  String _getAccessMessage(QuizAccessStatus status, String defaultMessage) {
    if (_exam == null) return defaultMessage;

    if (status == QuizAccessStatus.free && _exam!.isFreemium) {
      final freeCount = _exam!.freeQuestionCount;
      final totalCount = _exam!.numberOfQuestions;
      return '$freeCount out of $totalCount questions are free to attempt';
    }

    return defaultMessage;
  }

  /// Build freemium info widget showing free vs paid questions
  Widget _buildFreemiumInfo() {
    if (_exam == null) return const SizedBox.shrink();

    final freeCount = _exam!.freeQuestionCount;
    final paidCount = _exam!.paidQuestionCount;
    final unlockPrice =
        _exam!.unlockPrice > 0 ? _exam!.unlockPrice : _exam!.price;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Freemium Quiz',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFreemiumStat(
                  Icons.check_circle,
                  Colors.green,
                  '$freeCount Free',
                ),
              ),
              Expanded(
                child: _buildFreemiumStat(
                  Icons.lock,
                  Colors.orange,
                  '$paidCount Paid',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Pay ',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  TextSpan(
                    text: '₹${unlockPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  TextSpan(
                    text: ' after free questions to unlock all',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreemiumStat(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessDetails() {
    if (_accessDetails == null) return const SizedBox.shrink();

    final remainingDays = _accessDetails!['remainingDays'] as int? ?? 0;
    final attemptCount = _accessDetails!['attemptCount'] as int? ?? 0;
    final isExpiringSoon = _accessDetails!['isExpiringSoon'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: isExpiringSoon ? Colors.orange : Colors.blue.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              '$remainingDays days remaining',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isExpiringSoon ? Colors.orange : Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.quiz,
              size: 16,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              '$attemptCount attempts',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        if (isExpiringSoon) ...[
          const SizedBox(height: 4),
          Text(
            '⚠️ Access expiring soon!',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceInfo() {
    if (_exam == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Show original price with strikethrough if discount exists
            if (_exam!.hasDiscount) ...[
              Text(
                '₹${_exam!.price.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryColor,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_exam!.discountPercentage.toStringAsFixed(0)}% OFF',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Show final price
            Icon(
              Icons.currency_rupee,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            Text(
              _exam!.hasDiscount
                  ? _exam!.discountedPrice.toStringAsFixed(2)
                  : _exam!.price.toStringAsFixed(2),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '• 30 days unlimited access',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// Build statistics card with column layout - displayed above quiz details
  Widget _buildStatisticsCard() {
    final totalAttempts = _quizStatistics?['totalAttempts'] ?? 0;
    final highestScore = _quizStatistics?['highestScore'] ?? 0;
    final averageRating = (_quizStatistics?['averageRating'] ?? 0.0) as double;
    final totalRatings = _quizStatistics?['totalRatings'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Statistics in column layout
          _buildStatRow(
            Icons.emoji_events,
            Colors.amber,
            'Highest Score',
            '$highestScore/${_exam?.numberOfQuestions ?? 0}',
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            Icons.group,
            Colors.blue,
            'Total Attempts',
            '$totalAttempts',
          ),
          const SizedBox(height: 12),

          // Rating row - clickable to see all reviews
          _buildClickableRatingRow(averageRating, totalRatings),

          // User-specific statistics
          if (_hasUserAttempted) ...[
            const SizedBox(height: 16),
            Divider(color: AppTheme.borderColor),
            const SizedBox(height: 16),
            Text(
              'Your Performance',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              Icons.replay,
              Colors.purple,
              'Your Attempts',
              '$_userAttemptCount',
            ),
            if (_userHighestScore != null) ...[
              const SizedBox(height: 12),
              _buildStatRow(
                Icons.star,
                Colors.green,
                'Your Best Score',
                '$_userHighestScore/${_exam?.numberOfQuestions ?? 0}',
              ),
            ],
          ],

          // Show "Not attempted yet" if user hasn't attempted
          if (!_hasUserAttempted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.grey.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'You haven\'t attempted this quiz yet',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  /// Clickable rating row that navigates to ratings page
  Widget _buildClickableRatingRow(double averageRating, int totalRatings) {
    return InkWell(
      onTap: () => _navigateToRatingsPage(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ...List.generate(5, (index) {
                        if (index < averageRating.floor()) {
                          return const Icon(Icons.star,
                              size: 14, color: Colors.amber);
                        } else if (index < averageRating) {
                          return const Icon(Icons.star_half,
                              size: 14, color: Colors.amber);
                        } else {
                          return Icon(Icons.star_border,
                              size: 14, color: Colors.grey[400]);
                        }
                      }),
                    ],
                  ),
                  Text(
                    '$totalRatings ${totalRatings == 1 ? 'review' : 'reviews'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.amber.shade700,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to ratings page
  void _navigateToRatingsPage() {
    if (_exam == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizRatingsPage(
          examId: _exam!.id,
          examName: _exam!.name,
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
              Icons.quiz, 'Number of Questions', '${_exam!.numberOfQuestions}'),
          const SizedBox(height: 12),
          _buildDetailRow(
              Icons.access_time, 'Time Limit', '${_exam!.timeLimit} minutes'),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.topic, 'Topic', _exam!.examType),
          const SizedBox(height: 12),
          _buildDetailRow(
              Icons.people, 'Suitable For', _exam!.suitableRolesText),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildInstructionItem(
              '1. Read each question carefully before selecting an answer'),
          _buildInstructionItem(
              '2. You can navigate between questions using Previous/Next buttons'),
          _buildInstructionItem(
              '3. You can skip questions and return to them later'),
          _buildInstructionItem('4. A timer will show your remaining time'),
          _buildInstructionItem(
              '5. Questions and answers will be shuffled for each attempt'),
          _buildInstructionItem(
              '6. Click "Finish Quiz" when you\'re done or time runs out'),
          _buildInstructionItem(
              '7. Review your answers before final submission'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textSecondaryColor,
          height: 1.5,
        ),
      ),
    );
  }

  /// Build action buttons based on quiz type (free, paid, freemium)
  Widget _buildActionButtons() {
    final isFreemium = _exam?.isFreemium ?? false;
    final unlockPrice = _exam?.unlockPrice ?? 0.0;

    // Check if user has already purchased access for this freemium quiz
    final accessStatus = _accessDetails?['status'] as QuizAccessStatus?;
    final hasAlreadyPaid = accessStatus == QuizAccessStatus.purchased;

    // For freemium quizzes, show Start Quiz and optionally Pay Now button
    if (isFreemium) {
      return Column(
        children: [
          // Row with Close and Start Quiz buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _startQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start Quiz',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Only show Pay button if user has NOT already paid
          if (!hasAlreadyPaid) ...[
            const SizedBox(height: 12),
            // Pay Now button for freemium quizzes
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _payToUnlockFullQuiz,
                icon: const Icon(Icons.lock_open, size: 20),
                label: Text(
                  'Pay ₹${unlockPrice.toStringAsFixed(0)} to Unlock All Questions',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // For regular quizzes (free or paid)
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _startQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _getButtonText(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Pay to unlock full quiz (for freemium quizzes)
  void _payToUnlockFullQuiz() async {
    if (_exam == null) return;

    // Show payment dialog with unlock price
    _showFreemiumPaymentDialog();
  }

  /// Show payment dialog for freemium quiz unlock
  void _showFreemiumPaymentDialog() async {
    if (_exam == null) return;

    // Use AuthHelperService to get user details (supports both Firebase Auth and phone auth)
    final isAuthenticated = await AuthHelperService.isUserAuthenticated();
    if (!isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to proceed with payment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = await AuthHelperService.getCurrentUserId();
    final userEmail = await AuthHelperService.getCurrentEmail() ?? '';
    final userPhone = await AuthHelperService.getCurrentPhoneNumber();

    debugPrint(
        '🔐 Freemium Payment - userId: $userId, email: $userEmail, phone: $userPhone');

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to proceed with payment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userPhone == null || userPhone.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please update your profile with a valid mobile number before making payment.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Create a modified exam with unlock price for payment
    // Include discount information from banner if available
    final freemiumExam = ExamModel(
      id: _exam!.id,
      name: _exam!.name,
      examType: _exam!.examType,
      customName: _exam!.customName,
      numberOfQuestions: _exam!.numberOfQuestions,
      timeLimit: _exam!.timeLimit,
      suitableFor: _exam!.suitableFor,
      questions: _exam!.questions,
      createdAt: _exam!.createdAt,
      updatedAt: _exam!.updatedAt,
      isActive: _exam!.isActive,
      totalAttempts: _exam!.totalAttempts,
      isTrending: _exam!.isTrending,
      trendingPriority: _exam!.trendingPriority,
      price: _exam!.unlockPrice, // Use unlock price for payment
      currency: _exam!.currency,
      isFree: false,
      shareCount: _exam!.shareCount,
      lastSharedAt: _exam!.lastSharedAt,
      freeQuestionsLimit: _exam!.freeQuestionsLimit,
      unlockPrice: _exam!.unlockPrice,
      discountPercentage:
          _exam!.discountPercentage, // Apply discount from banner
      bannerRoutedFrom: _exam!.bannerRoutedFrom,
      couponCode: _exam!.couponCode,
    );

    debugPrint('💳 Freemium Payment Dialog:');
    debugPrint('   - Unlock Price: ₹${freemiumExam.price}');
    debugPrint('   - Discount: ${freemiumExam.discountPercentage}%');
    debugPrint('   - Has Discount: ${freemiumExam.hasDiscount}');
    debugPrint('   - Discounted Price: ₹${freemiumExam.discountedPrice}');

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PaymentConfirmationDialog(
        exam: freemiumExam,
        onCancel: () {
          if (mounted) {
            _loadExam();
          }
        },
        userId: userId,
        userEmail: userEmail,
        userPhone: userPhone,
      ),
    ).then((result) {
      if (result == true && mounted) {
        debugPrint('💳 Freemium payment successful');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadExam();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Full quiz unlocked! You can now access all questions.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    });
  }

  /// Get button text based on quiz access status
  String _getButtonText() {
    if (_exam == null || _accessDetails == null) return 'Start Quiz';

    final canAttempt = _accessDetails!['canAttempt'] as bool;

    if (_exam!.isFree) {
      return 'Start Quiz';
    }

    if (canAttempt) {
      return 'Start Quiz';
    } else {
      return 'Make Payment';
    }
  }

  /// Get button color based on quiz access status
  Color _getButtonColor() {
    if (_exam == null || _accessDetails == null) return AppTheme.primaryColor;

    final canAttempt = _accessDetails!['canAttempt'] as bool;

    if (_exam!.isFree || canAttempt) {
      return AppTheme.primaryColor; // Green for start quiz
    } else {
      return Colors.orange; // Orange for payment required
    }
  }

  void _startQuiz() async {
    if (_exam == null) return;

    // Check access using the new paid quiz access service
    final canAttempt = await PaidQuizAccessService.canUserAttemptQuiz(
      examId: widget.quizId,
      exam: _exam!,
    );

    if (!canAttempt) {
      // Show payment confirmation dialog for payment required
      if (mounted) {
        _showPaymentDialog();
      }
      return;
    }

    // Record the quiz attempt for paid quizzes
    if (!_exam!.isFree) {
      await PaidQuizAccessService.recordQuizAttempt(widget.quizId);
    }

    // Start the quiz with discount info if available
    if (mounted) {
      context.goToQuiz(
        widget.quizId,
        discountPercentage: _exam!.discountPercentage,
        couponCode: _exam!.couponCode,
        bannerRoutedFrom: _exam!.bannerRoutedFrom,
      );
    }
  }

  /// Show payment confirmation dialog
  void _showPaymentDialog() async {
    if (_exam == null) return;

    // Use AuthHelperService to get user details (supports both Firebase Auth and phone auth)
    final isAuthenticated = await AuthHelperService.isUserAuthenticated();
    if (!isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to proceed with payment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = await AuthHelperService.getCurrentUserId();
    final userEmail = await AuthHelperService.getCurrentEmail() ?? '';
    final userPhone = await AuthHelperService.getCurrentPhoneNumber();

    debugPrint(
        '🔐 Payment Dialog - userId: $userId, email: $userEmail, phone: $userPhone');

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to proceed with payment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that we have a non-empty phone number before proceeding
    if (userPhone == null || userPhone.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please update your profile with a valid mobile number before making payment.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PaymentConfirmationDialog(
        exam: _exam!,
        onCancel: () {
          // Don't pop here - the dialog handles its own dismissal
          // Just refresh the screen state if needed
          if (mounted) {
            _loadExam(); // Refresh to check if access was granted
          }
        },
        userId: userId,
        userEmail: userEmail,
        userPhone: userPhone,
      ),
    ).then((result) {
      // Handle dialog result
      if (result == true && mounted) {
        // Payment was successful, wait a moment for Firestore to sync, then refresh
        debugPrint('💳 Payment dialog closed with success result');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            debugPrint('🔄 Refreshing exam data after payment');
            _loadExam();
          }
        });
      }
    });
  }
}
