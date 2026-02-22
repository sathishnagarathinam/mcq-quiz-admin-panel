import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/models/paid_quiz_access_model.dart';
import '../../../core/services/exam_service.dart';
import '../../../core/services/paid_quiz_access_service.dart';
import '../../../core/providers/quiz_attempt_provider.dart';
import '../../../core/providers/analytics_provider.dart';
import '../../../core/providers/payment_provider.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../core/widgets/global_security_wrapper.dart';
import '../../../core/widgets/screenshot_blocker.dart';

/// Quiz screen for taking a quiz
class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizScreen({
    super.key,
    required this.quizId,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  int _score = 0;
  ExamModel? _exam;
  List<QuestionModel> _shuffledQuestions = [];
  bool _isLoading = true;
  String? _error;
  String? _currentAttemptId;
  DateTime? _startTime;
  Timer? _timer;
  int _remainingTimeInSeconds = 0;
  final Map<String, dynamic> _userAnswers = {};
  final Set<int> _skippedQuestions = {};

  // Freemium quiz tracking
  int _freeQuestionsCount = 0;
  bool _hasShownPaymentDialog = false;
  bool _hasPaidForFullAccess = false;

  // Razorpay payment
  late Razorpay _razorpay;
  bool _isProcessingPayment = false;
  String? _currentMerchantOrderId;

  // Flag to block all interactions when navigating to result
  bool _isNavigatingToResult = false;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadExam();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    developer.log('✅ Razorpay initialized for freemium quiz');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _razorpay.clear();
    super.dispose();
  }

  /// Shuffle questions and their answers
  List<QuestionModel> _shuffleQuestions(List<QuestionModel> questions) {
    final random = Random();
    final shuffledQuestions = List<QuestionModel>.from(questions);

    // Shuffle the order of questions
    shuffledQuestions.shuffle(random);

    // Shuffle the answers for each question
    return shuffledQuestions.map((question) {
      final shuffledOptions = List<String>.from(question.options);
      final correctAnswer = question.options[question.correctAnswer];

      // Shuffle the options
      shuffledOptions.shuffle(random);

      // Find the new index of the correct answer
      final newCorrectIndex = shuffledOptions.indexOf(correctAnswer);

      return QuestionModel(
        id: question.id,
        question: question.question,
        options: shuffledOptions,
        correctAnswer: newCorrectIndex,
        explanation: question.explanation,
        difficulty: question.difficulty,
        isFree: question.isFree, // Preserve the isFree flag
      );
    }).toList();
  }

  /// Filter questions for freemium quiz - only include free questions
  List<QuestionModel> _filterFreeQuestions(List<QuestionModel> questions) {
    return questions.where((q) => q.isFree).toList();
  }

  /// Check if this is a freemium quiz
  bool get _isFreemiumQuiz {
    if (_exam == null) return false;
    return _exam!.isFreemium;
  }

  /// Start the quiz timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTimeInSeconds > 0) {
        setState(() {
          _remainingTimeInSeconds--;
        });
      } else {
        // Time's up - finish the quiz
        timer.cancel();
        _handleTimeUp();
      }
    });
  }

  /// Handle when time runs out
  Future<void> _handleTimeUp() async {
    // Save current answer if selected
    if (_selectedAnswerIndex != null && _exam != null) {
      final currentQuestion = _shuffledQuestions[_currentQuestionIndex];
      _userAnswers['question_$_currentQuestionIndex'] = {
        'questionId': currentQuestion.id,
        'selectedAnswer': _selectedAnswerIndex,
        'correctAnswer': currentQuestion.correctAnswer,
        'isCorrect': _selectedAnswerIndex == currentQuestion.correctAnswer,
      };

      if (_selectedAnswerIndex == currentQuestion.correctAnswer) {
        _score++;
      }
    }

    // Complete the quiz
    await _completeQuizAttempt();
    if (mounted) {
      context.goToQuizResult(
          widget.quizId, _score, _userAnswers, _shuffledQuestions);
    }
  }

  /// Format time for display
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadExam() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final exam = await ExamService.getExamById(widget.quizId);

      if (exam == null) {
        setState(() {
          _error = 'Exam not found';
          _isLoading = false;
        });
        return;
      }

      if (exam.questions.isEmpty) {
        setState(() {
          _error = 'This exam has no questions';
          _isLoading = false;
        });
        return;
      }

      // Apply discount information if passed from banner navigation
      ExamModel examWithDiscount = exam;
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
              developer.log('💰 Applying discount from banner to quiz:');
              developer.log('   - Discount: $discountPercentage%');
              developer.log('   - Coupon: $couponCode');
              developer.log('   - Banner ID: $bannerRoutedFrom');

              examWithDiscount = ExamModel(
                id: exam.id,
                name: exam.name,
                examType: exam.examType,
                questions: exam.questions,
                numberOfQuestions: exam.numberOfQuestions,
                timeLimit: exam.timeLimit,
                suitableFor: exam.suitableFor,
                isFree: exam.isFree,
                price: exam.price,
                isActive: exam.isActive,
                createdAt: exam.createdAt,
                updatedAt: exam.updatedAt,
                currency: exam.currency,
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
          developer.log('⚠️ Error reading discount data from route: $e');
        }
      }

      // For freemium quizzes, organize questions: free questions first, then paid
      List<QuestionModel> questionsToUse = examWithDiscount.questions;
      int freeCount = 0;

      if (examWithDiscount.isFreemium) {
        // Separate free and paid questions
        final freeQuestions =
            examWithDiscount.questions.where((q) => q.isFree).toList();
        final paidQuestions =
            examWithDiscount.questions.where((q) => !q.isFree).toList();
        freeCount = freeQuestions.length;

        debugPrint(
            '📋 Freemium quiz: ${freeQuestions.length} free questions, ${paidQuestions.length} paid questions');

        if (freeQuestions.isEmpty) {
          setState(() {
            _error =
                'No free questions available for this quiz. Please purchase to access all questions.';
            _isLoading = false;
          });
          return;
        }

        // Shuffle free and paid questions separately, then combine
        final shuffledFree = _shuffleQuestions(freeQuestions);
        final shuffledPaid = _shuffleQuestions(paidQuestions);
        questionsToUse = [...shuffledFree, ...shuffledPaid];
      }

      // Shuffle questions and answers (for non-freemium quizzes)
      final shuffledQuestions = examWithDiscount.isFreemium
          ? questionsToUse // Already shuffled above
          : _shuffleQuestions(questionsToUse);

      // Start quiz attempt tracking
      try {
        final attemptNotifier = ref.read(currentQuizAttemptProvider.notifier);
        final attemptId = await attemptNotifier.startAttempt(examWithDiscount);

        setState(() {
          _exam = examWithDiscount;
          _shuffledQuestions = shuffledQuestions;
          _currentAttemptId = attemptId;
          _startTime = DateTime.now();
          _remainingTimeInSeconds =
              examWithDiscount.timeLimit * 60; // Convert minutes to seconds
          _freeQuestionsCount = freeCount;
          _isLoading = false;
        });

        // Start the timer
        _startTimer();
      } catch (e) {
        debugPrint('Failed to start quiz attempt tracking: $e');
        // Continue with quiz even if attempt tracking fails
        setState(() {
          _exam = examWithDiscount;
          _shuffledQuestions = shuffledQuestions;
          _remainingTimeInSeconds = examWithDiscount.timeLimit * 60;
          _freeQuestionsCount = freeCount;
          _isLoading = false;
        });

        // Start the timer even if attempt tracking fails
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load exam: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenshotBlocker(
      enabled: true,
      child: CriticalSecurityWrapper(
        screenName: 'QuizScreen',
        onSecurityBreach: () {
          // Handle security breach during quiz
          _abandonQuizAttempt();
          Navigator.of(context).pop();
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // Show confirmation dialog before abandoning quiz
            final shouldPop = await _showAbandonDialog();
            if (shouldPop && context.mounted) {
              await _abandonQuizAttempt();
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: Text(
                _exam?.displayName ?? 'Loading Quiz...',
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
                if (_exam != null) ...[
                  // Timer display
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _remainingTimeInSeconds <= 300 // 5 minutes
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: _remainingTimeInSeconds <= 300
                                  ? Colors.red.shade300
                                  : Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(_remainingTimeInSeconds),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _remainingTimeInSeconds <= 300
                                    ? Colors.red.shade300
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Question counter
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        '${_currentQuestionIndex + 1}/${_shuffledQuestions.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            body: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Show loading overlay when navigating to result (blocks all interactions)
    if (_isNavigatingToResult) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Preparing your results...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading exam...'),
          ],
        ),
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
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExam,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_exam == null || _shuffledQuestions.isEmpty) {
      return const Center(
        child: Text('No questions available'),
      );
    }

    final currentQuestion = _shuffledQuestions[_currentQuestionIndex];
    final isLastQuestion =
        _currentQuestionIndex == _shuffledQuestions.length - 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _shuffledQuestions.length,
            backgroundColor: AppTheme.borderColor,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),

          const SizedBox(height: 32),

          // Question
          Text(
            currentQuestion.question,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),

          const SizedBox(height: 32),

          // Options
          Expanded(
            child: ListView.builder(
              itemCount: currentQuestion.options.length,
              itemBuilder: (context, index) {
                return _buildOptionCard(
                  currentQuestion.options[index],
                  index,
                );
              },
            ),
          ),

          // Navigation buttons
          Column(
            children: [
              // Skip button (always visible)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _handleSkip,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.skip_next,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Skip Question',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Main navigation buttons
              Row(
                children: [
                  // Previous button
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handlePrevious,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: AppTheme.primaryColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_back,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Previous',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),

                  // Next/Finish button
                  Expanded(
                    flex: _currentQuestionIndex > 0 ? 1 : 2,
                    child: LoadingButton(
                      text: isLastQuestion ? 'Finish Quiz' : 'Next',
                      onPressed:
                          _selectedAnswerIndex != null ? _handleNext : null,
                      expanded: true,
                      icon: Icon(
                        isLastQuestion
                            ? Icons.check_circle
                            : Icons.arrow_forward,
                        size: 18,
                      ),
                    ),
                  ),

                  // Finish button (always visible for quick completion)
                  if (!isLastQuestion) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showFinishDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.flag,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Finish',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String option, int index) {
    final isSelected = _selectedAnswerIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAnswerIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_selectedAnswerIndex == null || _shuffledQuestions.isEmpty) return;

    final currentQuestion = _shuffledQuestions[_currentQuestionIndex];

    // Store user's answer
    _userAnswers['question_$_currentQuestionIndex'] = {
      'questionId': currentQuestion.id,
      'selectedAnswer': _selectedAnswerIndex,
      'correctAnswer': currentQuestion.correctAnswer,
      'isCorrect': _selectedAnswerIndex == currentQuestion.correctAnswer,
    };

    // Check if answer is correct
    if (_selectedAnswerIndex == currentQuestion.correctAnswer) {
      _score++;
    }

    if (_currentQuestionIndex < _shuffledQuestions.length - 1) {
      final nextIndex = _currentQuestionIndex + 1;

      // Check if this is a freemium quiz and we're about to move to paid questions
      if (_isFreemiumQuiz &&
          !_hasShownPaymentDialog &&
          !_hasPaidForFullAccess &&
          nextIndex >= _freeQuestionsCount) {
        // Check if user has valid paid access from Firestore
        final accessStatus = await PaidQuizAccessService.getQuizAccessStatus(
          examId: widget.quizId,
          exam: _exam!,
        );

        developer.log('🔍 Access status check: $accessStatus');

        // If user has valid paid access or admin-granted free access, allow
        if (accessStatus == QuizAccessStatus.purchased ||
            accessStatus == QuizAccessStatus.free) {
          developer.log(
              '✅ User has valid access ($accessStatus) - allowing access to paid questions');
          _hasPaidForFullAccess = true;
        } else {
          developer.log(
              '❌ No valid access ($accessStatus) - showing payment dialog');
          _showFreemiumPaymentDialog();
          return;
        }
      }

      // Move to next question
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = _userAnswers
                .containsKey('question_$_currentQuestionIndex')
            ? _userAnswers['question_$_currentQuestionIndex']['selectedAnswer']
            : null;
      });
    } else {
      // Quiz finished - complete the attempt
      await _completeQuizAttempt();
      if (mounted) {
        context.goToQuizResult(
            widget.quizId, _score, _userAnswers, _shuffledQuestions);
      }
    }
  }

  Future<void> _handleSkip() async {
    if (_shuffledQuestions.isEmpty) return;

    // Mark question as skipped
    _skippedQuestions.add(_currentQuestionIndex);

    // For freemium quizzes, check if we're at the last free question
    if (_isFreemiumQuiz && !_hasPaidForFullAccess) {
      // Check if current question is the last free question
      if (_currentQuestionIndex >= _freeQuestionsCount - 1) {
        // Check if user has valid paid access from Firestore
        final accessStatus = await PaidQuizAccessService.getQuizAccessStatus(
          examId: widget.quizId,
          exam: _exam!,
        );

        developer.log('🔍 Access status check (skip): $accessStatus');

        // If user has valid paid access or admin-granted free access, allow
        if (accessStatus == QuizAccessStatus.purchased ||
            accessStatus == QuizAccessStatus.free) {
          developer.log(
              '✅ User has valid access ($accessStatus) - allowing skip to paid questions');
          _hasPaidForFullAccess = true;
        } else {
          if (!_hasShownPaymentDialog) {
            _showFreemiumPaymentDialog();
            return;
          } else {
            // Payment dialog was already shown and user didn't pay
            // Finish the quiz with only free questions
            await _completeQuizAttempt();
            final freeQuestionsOnly =
                _shuffledQuestions.take(_freeQuestionsCount).toList();
            if (mounted) {
              context.goToQuizResult(
                  widget.quizId, _score, _userAnswers, freeQuestionsOnly);
            }
            return;
          }
        }
      }
    }

    if (_currentQuestionIndex < _shuffledQuestions.length - 1) {
      final nextIndex = _currentQuestionIndex + 1;

      // For freemium quizzes, prevent skipping beyond free questions if not paid
      if (_isFreemiumQuiz &&
          !_hasPaidForFullAccess &&
          nextIndex >= _freeQuestionsCount) {
        // Check if user has valid paid access from Firestore
        final accessStatus = await PaidQuizAccessService.getQuizAccessStatus(
          examId: widget.quizId,
          exam: _exam!,
        );

        developer.log('🔍 Access status check (skip next): $accessStatus');

        // If user has valid paid access or admin-granted free access, allow
        if (accessStatus == QuizAccessStatus.purchased ||
            accessStatus == QuizAccessStatus.free) {
          developer.log(
              '✅ User has valid access ($accessStatus) - allowing skip to paid questions');
          _hasPaidForFullAccess = true;
        } else {
          if (!_hasShownPaymentDialog) {
            _showFreemiumPaymentDialog();
          } else {
            // Payment dialog was already shown and user didn't pay
            // Finish the quiz with only free questions
            await _completeQuizAttempt();
            final freeQuestionsOnly =
                _shuffledQuestions.take(_freeQuestionsCount).toList();
            if (mounted) {
              context.goToQuizResult(
                  widget.quizId, _score, _userAnswers, freeQuestionsOnly);
            }
          }
          return;
        }
      }

      // Move to next question
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = _userAnswers
                .containsKey('question_$_currentQuestionIndex')
            ? _userAnswers['question_$_currentQuestionIndex']['selectedAnswer']
            : null;
      });
    } else {
      // Last question - finish the quiz
      _completeQuizAttempt();
      context.goToQuizResult(
          widget.quizId, _score, _userAnswers, _shuffledQuestions);
    }
  }

  /// Show payment dialog for freemium quiz when user completes free questions
  Future<void> _showFreemiumPaymentDialog() async {
    setState(() {
      _hasShownPaymentDialog = true;
    });

    final paidQuestionsCount = _shuffledQuestions.length - _freeQuestionsCount;
    final unlockPrice = _exam?.unlockPrice ?? _exam?.price ?? 0.0;

    // Check if discount is available from banner navigation
    final hasDiscount = _exam?.hasDiscount ?? false;
    final discountPercentage = _exam?.discountPercentage ?? 0.0;
    final discountedPrice = hasDiscount
        ? unlockPrice - (unlockPrice * discountPercentage / 100)
        : unlockPrice;

    debugPrint('💳 Freemium Unlock Dialog:');
    debugPrint('   - Unlock Price: ₹$unlockPrice');
    debugPrint('   - Has Discount: $hasDiscount');
    debugPrint('   - Discount: $discountPercentage%');
    debugPrint('   - Discounted Price: ₹$discountedPrice');

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_open, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Unlock Full Quiz',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have completed all $_freeQuestionsCount free questions!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.quiz, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$paidQuestionsCount more questions available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Show discount information if available
            if (hasDiscount) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₹${unlockPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${discountPercentage.toStringAsFixed(0)}% OFF',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              hasDiscount
                  ? 'Pay ₹${discountedPrice.toStringAsFixed(0)} to unlock all questions and continue the quiz.'
                  : 'Pay ₹${unlockPrice.toStringAsFixed(0)} to unlock all questions and continue the quiz.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Finish Quiz',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              hasDiscount
                  ? 'Pay ₹${discountedPrice.toStringAsFixed(0)}'
                  : 'Pay ₹${unlockPrice.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      // User wants to pay - start Razorpay payment flow
      await _startFreemiumPayment();
    } else {
      // User chose to finish quiz with free questions only
      // Calculate score for only the free questions
      int freeQuestionsScore = 0;
      for (int i = 0; i < _freeQuestionsCount; i++) {
        final answerKey = 'question_$i';
        if (_userAnswers.containsKey(answerKey)) {
          final answer = _userAnswers[answerKey];
          if (answer['isCorrect'] == true) {
            freeQuestionsScore++;
          }
        }
      }

      await _completeQuizAttempt();
      if (mounted) {
        // Only pass the free questions that were answered
        final freeQuestionsOnly =
            _shuffledQuestions.take(_freeQuestionsCount).toList();
        context.goToQuizResult(
            widget.quizId, freeQuestionsScore, _userAnswers, freeQuestionsOnly);
      }
    }
  }

  /// Start Razorpay payment for freemium quiz unlock
  Future<void> _startFreemiumPayment() async {
    if (_exam == null) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      developer.log('🚀 Starting Razorpay payment for freemium quiz unlock...');

      // Get user details from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('authenticated_phone_number') ?? '';
      final userId = userPhone.replaceAll('+', '');
      final userEmail = prefs.getString('user_email') ?? '$userId@mcqquiz.app';

      // Get payment provider
      final paymentProvider =
          provider.Provider.of<PaymentProvider>(context, listen: false);

      // Calculate unlock price with discount if available
      final baseUnlockPrice =
          _exam!.unlockPrice > 0 ? _exam!.unlockPrice : _exam!.price;
      final hasDiscount = _exam!.hasDiscount;
      final discountPercentage = _exam!.discountPercentage;
      final unlockPrice = hasDiscount
          ? baseUnlockPrice - (baseUnlockPrice * discountPercentage / 100)
          : baseUnlockPrice;

      developer.log('💳 Freemium Payment:');
      developer.log('   - Base Price: ₹$baseUnlockPrice');
      developer.log('   - Has Discount: $hasDiscount');
      developer.log('   - Discount: $discountPercentage%');
      developer.log('   - Final Price: ₹$unlockPrice');

      // Create a temporary exam model with unlock price for payment
      // Include discount info so payment provider can use it
      final examForPayment = ExamModel(
        id: _exam!.id,
        name: _exam!.name,
        customName: '${_exam!.displayName} - Unlock Full Quiz',
        examType: _exam!.examType,
        questions: _exam!.questions,
        numberOfQuestions: _exam!.numberOfQuestions,
        timeLimit: _exam!.timeLimit,
        suitableFor: _exam!.suitableFor,
        isFree: false,
        price: unlockPrice, // Use discounted price
        isActive: _exam!.isActive,
        createdAt: _exam!.createdAt,
        updatedAt: _exam!.updatedAt,
        discountPercentage: discountPercentage,
        bannerRoutedFrom: _exam!.bannerRoutedFrom,
        couponCode: _exam!.couponCode,
      );

      developer
          .log('⏳ Creating Razorpay order for unlock price: ₹$unlockPrice');

      final orderResponse = await paymentProvider.createRazorpayOrder(
        exam: examForPayment,
        userEmail: userEmail,
        userPhone: userPhone,
        userId: userId,
      );

      if (!mounted) return;

      if (!orderResponse.success || orderResponse.data == null) {
        developer.log('❌ Failed to create order: ${orderResponse.message}');
        setState(() {
          _isProcessingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Payment failed: ${orderResponse.message ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final orderData = orderResponse.data!;
      _currentMerchantOrderId = orderData.merchantOrderId;

      developer.log('✅ Order created, opening Razorpay checkout...');
      developer.log('   Order ID: ${orderData.orderId}');
      developer.log('   Amount: ${orderData.amount}');

      // Open Razorpay checkout
      final options = {
        'key': orderData.keyId,
        'amount': orderData.amount,
        'currency': orderData.currency,
        'order_id': orderData.orderId,
        'name': 'MCQ Quiz App',
        'description': 'Unlock Full Quiz - ${_exam!.displayName}',
        'prefill': {
          'email': userEmail,
          'contact': userPhone,
        },
        'external': {
          'wallets': ['paytm'],
        },
        'theme': {
          'color': '#1976D2',
        },
        'notes': {
          'merchantOrderId': orderData.merchantOrderId,
          'examId': _exam!.id,
          'userId': userId,
          'type': 'freemium_unlock',
        },
      };

      developer.log('📱 Opening Razorpay with options...');
      _razorpay.open(options);
    } catch (e) {
      developer.log('❌ Payment error: $e');
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle successful Razorpay payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    developer.log('✅ Razorpay payment success for freemium unlock!');
    developer.log('   Payment ID: ${response.paymentId}');
    developer.log('   Order ID: ${response.orderId}');

    if (!mounted) return;

    // Verify payment with backend
    try {
      final paymentProvider =
          provider.Provider.of<PaymentProvider>(context, listen: false);
      final verified = await paymentProvider.verifyRazorpayPayment(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
        merchantOrderId: _currentMerchantOrderId ?? '',
      );

      if (!mounted) return;

      if (verified) {
        developer.log('✅ Payment verified successfully!');

        // Create access record
        try {
          await PaidQuizAccessService.createAccessRecord(
            examId: _exam!.id,
            examName: _exam!.displayName,
            paymentId: response.paymentId ?? '',
          );
          developer.log('✅ Access record created');
        } catch (e) {
          developer.log('⚠️ Error creating access record: $e');
        }

        // Payment successful - unlock full quiz
        setState(() {
          _hasPaidForFullAccess = true;
          _isProcessingPayment = false;
          _currentQuestionIndex++;
          _selectedAnswerIndex = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Full quiz unlocked.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        developer.log('❌ Payment verification failed');
        setState(() {
          _isProcessingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Payment verification failed. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Verification error: $e');
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle Razorpay payment error
  void _handlePaymentError(PaymentFailureResponse response) async {
    developer.log('❌ Razorpay payment failed');
    developer.log('   Code: ${response.code}');
    developer.log('   Message: ${response.message}');

    if (!mounted) return;

    // IMPORTANT: For freemium quizzes, payment cancellation/failure means
    // the user cannot continue to paid questions. Force quiz completion.
    // Set this flag IMMEDIATELY to block all user interactions
    if (_isFreemiumQuiz && !_hasPaidForFullAccess) {
      setState(() {
        _isProcessingPayment = false;
        _isNavigatingToResult = true; // Block all interactions immediately
      });

      developer.log(
          '🔒 Payment cancelled/failed for freemium quiz - forcing quiz completion');

      String errorMessage = 'Payment failed';
      switch (response.code) {
        case Razorpay.NETWORK_ERROR:
          errorMessage =
              'Network error. Please check your internet connection.';
          break;
        case Razorpay.INVALID_OPTIONS:
          errorMessage = 'Invalid payment configuration.';
          break;
        case Razorpay.PAYMENT_CANCELLED:
          errorMessage = 'Payment was cancelled. Showing your results...';
          break;
        default:
          errorMessage =
              response.message ?? 'Payment failed. Showing your results...';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      // Calculate score for only the free questions
      int freeQuestionsScore = 0;
      for (int i = 0; i < _freeQuestionsCount; i++) {
        final answerKey = 'question_$i';
        if (_userAnswers.containsKey(answerKey)) {
          final answer = _userAnswers[answerKey];
          if (answer['isCorrect'] == true) {
            freeQuestionsScore++;
          }
        }
      }

      // Complete the quiz attempt with only free questions
      await _completeQuizAttemptWithTotalQuestions(
          freeQuestionsScore, _freeQuestionsCount);

      if (mounted) {
        // Navigate to result screen with only free questions
        final freeQuestionsOnly =
            _shuffledQuestions.take(_freeQuestionsCount).toList();
        context.goToQuizResult(
            widget.quizId, freeQuestionsScore, _userAnswers, freeQuestionsOnly);
      }
    } else {
      // Non-freemium quiz or already paid - just show error
      setState(() {
        _isProcessingPayment = false;
      });

      String errorMessage = 'Payment failed';
      switch (response.code) {
        case Razorpay.NETWORK_ERROR:
          errorMessage =
              'Network error. Please check your internet connection.';
          break;
        case Razorpay.INVALID_OPTIONS:
          errorMessage = 'Invalid payment configuration.';
          break;
        case Razorpay.PAYMENT_CANCELLED:
          errorMessage = 'Payment was cancelled.';
          break;
        default:
          errorMessage =
              response.message ?? 'Payment failed. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    developer.log('📱 External wallet selected: ${response.walletName}');
    // External wallet flow will be handled by Razorpay
  }

  void _handlePrevious() {
    if (_currentQuestionIndex > 0) {
      // Save current answer before moving
      if (_selectedAnswerIndex != null) {
        final currentQuestion = _shuffledQuestions[_currentQuestionIndex];
        _userAnswers['question_$_currentQuestionIndex'] = {
          'questionId': currentQuestion.id,
          'selectedAnswer': _selectedAnswerIndex,
          'correctAnswer': currentQuestion.correctAnswer,
          'isCorrect': _selectedAnswerIndex == currentQuestion.correctAnswer,
        };
      }

      setState(() {
        _currentQuestionIndex--;
        // Restore previous answer if it exists
        _selectedAnswerIndex = _userAnswers
                .containsKey('question_$_currentQuestionIndex')
            ? _userAnswers['question_$_currentQuestionIndex']['selectedAnswer']
            : null;
      });
    }
  }

  Future<void> _showFinishDialog() async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Finish Quiz Early?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You have answered ${_userAnswers.length} out of ${_exam!.questions.length} questions. Are you sure you want to finish the quiz now?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Continue Quiz',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(
              'Finish Now',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldFinish == true) {
      // Save current answer if selected
      if (_selectedAnswerIndex != null) {
        final currentQuestion = _shuffledQuestions[_currentQuestionIndex];
        _userAnswers['question_$_currentQuestionIndex'] = {
          'questionId': currentQuestion.id,
          'selectedAnswer': _selectedAnswerIndex,
          'correctAnswer': currentQuestion.correctAnswer,
          'isCorrect': _selectedAnswerIndex == currentQuestion.correctAnswer,
        };

        if (_selectedAnswerIndex == currentQuestion.correctAnswer) {
          _score++;
        }
      }

      // Complete the quiz
      await _completeQuizAttempt();
      if (mounted) {
        context.goToQuizResult(
            widget.quizId, _score, _userAnswers, _shuffledQuestions);
      }
    }
  }

  /// Complete quiz attempt with optional totalQuestions override (for freemium quizzes)
  Future<void> _completeQuizAttemptWithTotalQuestions(
      int score, int totalQuestions) async {
    if (_currentAttemptId == null || _startTime == null || _exam == null) {
      return;
    }

    try {
      final timeSpent = DateTime.now().difference(_startTime!).inSeconds;
      final attemptNotifier = ref.read(currentQuizAttemptProvider.notifier);

      developer.log(
          '🎯 Completing freemium quiz attempt: $_currentAttemptId with score: $score/$totalQuestions');

      await attemptNotifier.completeAttempt(
        score: score,
        correctAnswers: score,
        timeSpent: timeSpent,
        answers: _userAnswers,
        totalQuestions: totalQuestions,
      );

      developer.log('✅ Freemium quiz attempt completed successfully');
    } catch (e) {
      developer.log('❌ Error completing freemium quiz attempt: $e');
      rethrow;
    }
  }

  Future<void> _completeQuizAttempt() async {
    if (_currentAttemptId == null || _startTime == null || _exam == null) {
      return;
    }

    try {
      final timeSpent = DateTime.now().difference(_startTime!).inSeconds;
      final attemptNotifier = ref.read(currentQuizAttemptProvider.notifier);

      print('🎯 Completing quiz attempt: $_currentAttemptId');
      print('📊 Score: $_score/${_exam!.questions.length}');
      print('⏱️ Time spent: ${timeSpent}s');

      await attemptNotifier.completeAttempt(
        score: _score,
        correctAnswers: _score,
        timeSpent: timeSpent,
        answers: _userAnswers,
      );

      print('✅ Quiz attempt completed successfully');

      // Force refresh analytics and recent attempts
      try {
        // Wait a moment for Firestore to propagate
        await Future.delayed(const Duration(milliseconds: 500));

        // Invalidate all analytics and quiz-related providers to force refresh
        ref.invalidate(userAnalyticsProvider);
        ref.invalidate(userRecentAttemptsProvider);
        ref.invalidate(currentUserAnalyticsProvider);
        ref.invalidate(analyticsStatsSummaryProvider);
        ref.invalidate(analyticsDashboardProvider);

        // Also invalidate any family providers that might be cached
        ref.invalidate(userAnalyticsProvider);

        print(
            '✅ All analytics and recent attempts providers refreshed successfully');
      } catch (refreshError) {
        print('⚠️ Failed to refresh analytics: $refreshError');
        // Don't block navigation if refresh fails
      }
    } catch (e) {
      print('❌ Failed to complete quiz attempt: $e');
      // Still continue to result screen even if tracking fails
    }
  }

  Future<bool> _showAbandonDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Abandon Quiz?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to leave this quiz? Your progress will be lost.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Continue Quiz',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Abandon',
                  style: GoogleFonts.poppins(
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _abandonQuizAttempt() async {
    if (_currentAttemptId == null) return;

    try {
      final attemptNotifier = ref.read(currentQuizAttemptProvider.notifier);
      await attemptNotifier.abandonAttempt();
    } catch (e) {
      print('Failed to abandon quiz attempt: $e');
    }
  }
}
