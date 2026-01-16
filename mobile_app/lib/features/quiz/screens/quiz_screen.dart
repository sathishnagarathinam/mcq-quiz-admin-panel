import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/services/exam_service.dart';
import '../../../core/providers/quiz_attempt_provider.dart';
import '../../../core/providers/analytics_provider.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/government_source_attribution.dart';
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

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      );
    }).toList();
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
  void _handleTimeUp() {
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
    _completeQuizAttempt();
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

      // Shuffle questions and answers
      final shuffledQuestions = _shuffleQuestions(exam.questions);

      // Start quiz attempt tracking
      try {
        final attemptNotifier = ref.read(currentQuizAttemptProvider.notifier);
        final attemptId = await attemptNotifier.startAttempt(exam);

        setState(() {
          _exam = exam;
          _shuffledQuestions = shuffledQuestions;
          _currentAttemptId = attemptId;
          _startTime = DateTime.now();
          _remainingTimeInSeconds =
              exam.timeLimit * 60; // Convert minutes to seconds
          _isLoading = false;
        });

        // Start the timer
        _startTimer();
      } catch (e) {
        print('Failed to start quiz attempt tracking: $e');
        // Continue with quiz even if attempt tracking fails
        setState(() {
          _exam = exam;
          _shuffledQuestions = shuffledQuestions;
          _remainingTimeInSeconds = exam.timeLimit * 60;
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

  void _handleNext() {
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
      _completeQuizAttempt();
      context.goToQuizResult(
          widget.quizId, _score, _userAnswers, _shuffledQuestions);
    }
  }

  void _handleSkip() {
    if (_shuffledQuestions.isEmpty) return;

    // Mark question as skipped
    _skippedQuestions.add(_currentQuestionIndex);

    if (_currentQuestionIndex < _shuffledQuestions.length - 1) {
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
      _completeQuizAttempt();
      if (mounted) {
        context.goToQuizResult(
            widget.quizId, _score, _userAnswers, _shuffledQuestions);
      }
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
