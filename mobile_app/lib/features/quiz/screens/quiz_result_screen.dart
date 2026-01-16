import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/widgets/secure_screen_wrapper.dart';

import '../../../core/services/exam_service.dart';
import '../../../core/services/feedback_service.dart';

import '../../../shared/widgets/loading_button.dart';
import '../widgets/feedback_dialog.dart';
import '../widgets/quiz_sharing_widget.dart';

/// Quiz result screen showing score and all questions with answers
class QuizResultScreen extends ConsumerStatefulWidget {
  final String quizId;
  final int score;
  final Map<String, dynamic> userAnswers;
  final List<dynamic> shuffledQuestions;

  const QuizResultScreen({
    super.key,
    required this.quizId,
    required this.score,
    this.userAnswers = const {},
    this.shuffledQuestions = const [],
  });

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  ExamModel? _exam;
  bool _isLoading = true;
  String? _error;
  bool _hasFeedbackSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadExam();
    _checkFeedbackStatus();
  }

  Future<void> _checkFeedbackStatus() async {
    if (_exam != null) {
      final hasSubmitted =
          await FeedbackService.hasUserSubmittedFeedback(_exam!.id);
      if (mounted) {
        setState(() {
          _hasFeedbackSubmitted = hasSubmitted;
        });
      }
    }
  }

  void _showFeedbackDialog() {
    if (_exam == null) return;

    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(
        exam: _exam!,
        userScore: widget.score,
        totalQuestions: widget.shuffledQuestions.isNotEmpty
            ? widget.shuffledQuestions.length
            : _exam!.questions.length,
        onFeedbackSubmitted: () {
          setState(() {
            _hasFeedbackSubmitted = true;
          });
        },
      ),
    );
  }

  void _shareQuizResult() {
    if (_exam == null) return;

    final totalQuestions = widget.shuffledQuestions.isNotEmpty
        ? widget.shuffledQuestions.length
        : _exam!.questions.length;

    showQuizSharingSheet(
      context: context,
      exam: _exam!,
      score: widget.score,
      totalQuestions: totalQuestions,
      isResultSharing: true,
    );
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

      setState(() {
        _exam = exam;
        _isLoading = false;
      });

      // Check feedback status after loading exam
      _checkFeedbackStatus();
    } catch (e) {
      setState(() {
        _error = 'Failed to load exam: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResultsSecureWrapper(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          // Prevent going back to quiz - redirect to quiz list instead
          context.goToQuizList();
        },
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              'Quiz Results',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false, // Remove back button
            actions: [
              IconButton(
                onPressed: _shareQuizResult,
                icon: const Icon(Icons.share),
                tooltip: 'Share Result',
              ),
            ],
          ),
          body: _buildBody(),
          floatingActionButton: _exam != null
              ? FloatingActionButton.extended(
                  onPressed: _shareQuizResult,
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.share),
                  label: Text(
                    'Share Result',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
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
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            LoadingButton(
              onPressed: _loadExam,
              text: 'Retry',
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

    // Use shuffled questions if available, otherwise fall back to original questions
    final questionsToShow = widget.shuffledQuestions.isNotEmpty
        ? widget.shuffledQuestions
        : _exam!.questions;

    final totalQuestions = questionsToShow.length;
    final percentage =
        totalQuestions > 0 ? (widget.score / totalQuestions * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score summary card
          _buildScoreSummaryCard(widget.score, totalQuestions, percentage),

          const SizedBox(height: 24),

          // Questions header
          Text(
            'Questions & Answers',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // All questions with answers (in the same order as during quiz)
          ...questionsToShow.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildQuestionCard(question, index + 1);
          }),

          const SizedBox(height: 32),

          // Feedback section
          if (!_hasFeedbackSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.feedback_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Share Your Feedback',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us improve by sharing your experience with this quiz',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showFeedbackDialog,
                      icon: const Icon(Icons.star_rate, size: 18),
                      label: Text(
                        'Give Feedback',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thank you for your feedback!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          Center(
            child: SizedBox(
              width: double.infinity,
              child: LoadingButton(
                onPressed: () => context.goToQuizList(),
                text: 'Back to Quizzes',
                icon: const Icon(
                  Icons.arrow_back,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSummaryCard(int score, int totalQuestions, int percentage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          // Score circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getScoreColor(percentage).withValues(alpha: 0.1),
              border: Border.all(
                color: _getScoreColor(percentage),
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$percentage%',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _getScoreColor(percentage),
                    ),
                  ),
                  Text(
                    'Score',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Performance message
          Text(
            _getPerformanceMessage(percentage),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'You answered $score out of $totalQuestions questions correctly',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Correct',
                score.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                'Wrong',
                (totalQuestions - score).toString(),
                Icons.cancel,
                Colors.red,
              ),
              _buildStatItem(
                'Accuracy',
                '$percentage%',
                Icons.track_changes,
                _getScoreColor(percentage),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, int questionNumber) {
    // Get user's answer for this question
    final userAnswer = widget.userAnswers['question_${questionNumber - 1}'];
    final userSelectedIndex = userAnswer?['selectedAnswer'] as int?;
    final isUserCorrect = userAnswer?['isCorrect'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUserCorrect
              ? Colors.green.withValues(alpha: 0.3)
              : userSelectedIndex != null
                  ? Colors.red.withValues(alpha: 0.3)
                  : AppTheme.borderColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header with number and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUserCorrect
                      ? Colors.green
                      : userSelectedIndex != null
                          ? Colors.red
                          : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isUserCorrect
                    ? Icons.check_circle
                    : userSelectedIndex != null
                        ? Icons.cancel
                        : Icons.help_outline,
                color: isUserCorrect
                    ? Colors.green
                    : userSelectedIndex != null
                        ? Colors.red
                        : Colors.grey,
                size: 20,
              ),
              const Spacer(),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUserCorrect
                      ? Colors.green.withValues(alpha: 0.15)
                      : userSelectedIndex != null
                          ? Colors.red.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isUserCorrect
                        ? Colors.green
                        : userSelectedIndex != null
                            ? Colors.red
                            : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUserCorrect
                          ? Icons.check_circle
                          : userSelectedIndex != null
                              ? Icons.cancel
                              : Icons.help_outline,
                      size: 12,
                      color: isUserCorrect
                          ? Colors.green.shade700
                          : userSelectedIndex != null
                              ? Colors.red.shade700
                              : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUserCorrect
                          ? 'Correct'
                          : userSelectedIndex != null
                              ? 'Wrong Answer'
                              : 'Not Answered',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isUserCorrect
                            ? Colors.green.shade700
                            : userSelectedIndex != null
                                ? Colors.red.shade700
                                : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Question text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              question.question,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Options with user selection and correct answer highlighted
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isCorrectAnswer = index == question.correctAnswer;
            final isUserSelected = userSelectedIndex == index;

            Color backgroundColor = AppTheme.backgroundColor;
            Color borderColor = AppTheme.borderColor;
            Color textColor = AppTheme.textPrimaryColor;
            Color circleColor = AppTheme.borderColor;
            IconData? icon;
            double borderWidth = 1.0;

            if (isCorrectAnswer) {
              backgroundColor = Colors.green.withValues(alpha: 0.1);
              borderColor = Colors.green;
              textColor = Colors.green.shade700;
              circleColor = Colors.green;
              icon = Icons.check_circle;
              borderWidth = 2.0;
            } else if (isUserSelected && !isUserCorrect) {
              backgroundColor = Colors.red.withValues(alpha: 0.1);
              borderColor = Colors.red;
              textColor = Colors.red.shade700;
              circleColor = Colors.red;
              icon = Icons.cancel;
              borderWidth = 2.0;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor,
                    ),
                    child: Center(
                      child: icon != null
                          ? Icon(
                              icon,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        option,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Explanation
          if (question.explanation != null &&
              question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
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
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Explanation',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.explanation!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textPrimaryColor,
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

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getPerformanceMessage(int percentage) {
    if (percentage >= 90) return 'Excellent!';
    if (percentage >= 80) return 'Great Job!';
    if (percentage >= 70) return 'Good Work!';
    if (percentage >= 60) return 'Not Bad!';
    return 'Keep Trying!';
  }
}
