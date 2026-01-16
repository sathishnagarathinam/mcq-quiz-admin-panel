import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/services/exam_service.dart';
import '../../../core/services/paid_quiz_access_service.dart';
import '../../../core/models/paid_quiz_access_model.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../core/providers/payment_provider.dart';
import '../../../core/providers/mobile_user_auth_provider.dart';
import '../../payment/widgets/payment_confirmation_dialog.dart';
import '../widgets/quiz_sharing_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndLoadExam();
  }

  /// Check if user is authenticated before loading exam
  Future<void> _checkAuthenticationAndLoadExam() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // If user is not authenticated, redirect to login
      if (user == null) {
        debugPrint('⚠️ User not authenticated, redirecting to login');
        if (mounted) {
          // Store the quiz ID to return after login
          context.go('/auth/email-login',
              extra: {'returnToQuizId': widget.quizId});
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
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error reading discount data from route: $e');
        }
      }

      // Load access details for paid quizzes
      final accessDetails = await PaidQuizAccessService.getAccessDetails(
        examId: widget.quizId,
        exam: examWithDiscount,
      );

      debugPrint('📋 Access details loaded:');
      debugPrint('   - Status: ${accessDetails['status']}');
      debugPrint('   - Can Attempt: ${accessDetails['canAttempt']}');
      debugPrint('   - Show Payment: ${accessDetails['showPayment']}');
      debugPrint('   - Message: ${accessDetails['message']}');

      setState(() {
        _exam = examWithDiscount;
        _accessDetails = accessDetails;
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

          // Quiz Details
          _buildDetailCard(),

          const SizedBox(height: 24),

          // Instructions
          _buildInstructionsCard(),

          const SizedBox(height: 32),

          // Action Buttons
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
          ),

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
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textColor,
            ),
          ),
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

    // Start the quiz
    if (mounted) {
      context.goToQuiz(widget.quizId);
    }
  }

  /// Show payment confirmation dialog
  void _showPaymentDialog() async {
    if (_exam == null) return;

    String? userId;
    String userEmail = '';
    String? userPhone;

    // Always check Firebase Auth first as it's the source of truth
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Debug logging
    debugPrint('🔐 Payment Dialog - Firebase User: ${firebaseUser?.uid}');

    // Prefer MobileUser from Riverpod provider (loaded from Firestore)
    final authState = ref.read(mobileUserAuthProvider);
    final currentUser = authState.user;

    debugPrint('🔐 Payment Dialog - MobileUser: ${currentUser?.uid}');
    debugPrint(
        '🔐 Payment Dialog - isAuthenticated: ${authState.isAuthenticated}');

    if (currentUser != null) {
      userId = currentUser.uid;
      userEmail = currentUser.email;
      userPhone = currentUser.phoneNumber;
    } else if (firebaseUser != null) {
      // Fallback to Firebase Auth if Riverpod provider doesn't have user yet
      userId = firebaseUser.uid;
      userEmail = firebaseUser.email ?? '';

      try {
        final mobileUserDoc = await FirebaseFirestore.instance
            .collection('mobile_users')
            .doc(firebaseUser.uid)
            .get();
        final data = mobileUserDoc.data();
        userPhone =
            (data?['phoneNumber'] as String?) ?? firebaseUser.phoneNumber;
      } catch (e) {
        // If Firestore lookup fails, fall back to Firebase Auth phoneNumber (may be null)
        debugPrint('Error loading user phone number for payment: $e');
        userPhone = firebaseUser.phoneNumber;
      }

      if (!mounted) return;
    } else {
      // Neither Riverpod nor Firebase Auth has the user - truly not logged in
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
        userId: userId!,
        userEmail: userEmail,
        userPhone: userPhone!,
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
