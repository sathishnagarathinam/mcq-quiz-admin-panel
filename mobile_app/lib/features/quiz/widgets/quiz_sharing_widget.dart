import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/services/quiz_sharing_service.dart';
import '../../../shared/widgets/custom_snackbar.dart';

/// Widget for quiz sharing with multiple options
class QuizSharingWidget extends StatefulWidget {
  final ExamModel exam;
  final int? score;
  final int? totalQuestions;
  final String? customMessage;
  final bool isResultSharing;
  final VoidCallback? onShareComplete;

  const QuizSharingWidget({
    super.key,
    required this.exam,
    this.score,
    this.totalQuestions,
    this.customMessage,
    this.isResultSharing = false,
    this.onShareComplete,
  });

  @override
  State<QuizSharingWidget> createState() => _QuizSharingWidgetState();
}

class _QuizSharingWidgetState extends State<QuizSharingWidget> {
  final TextEditingController _messageController = TextEditingController();
  ShareType _selectedShareType = ShareType.general;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = widget.customMessage ?? '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildQuizInfo(),
          const SizedBox(height: 20),
          if (!widget.isResultSharing) _buildShareTypeSelector(),
          if (!widget.isResultSharing) const SizedBox(height: 20),
          _buildCustomMessageField(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          widget.isResultSharing ? Icons.celebration : Icons.share,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.isResultSharing ? 'Share Your Achievement!' : 'Share Quiz',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          color: AppTheme.textSecondaryColor,
        ),
      ],
    );
  }

  Widget _buildQuizInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exam.name,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                '${widget.exam.numberOfQuestions} Questions',
                Icons.quiz,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                '${widget.exam.timeLimit} min',
                Icons.timer,
              ),
            ],
          ),
          if (widget.isResultSharing && widget.score != null && widget.totalQuestions != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getScoreColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getScoreColor().withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getScoreIcon(),
                    color: _getScoreColor(),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Score: ${widget.score}/${widget.totalQuestions} (${_getPercentage()}%)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(),
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

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Type',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildShareTypeChip(ShareType.general, 'General', Icons.share),
            _buildShareTypeChip(ShareType.invitation, 'Invite Friends', Icons.group_add),
            _buildShareTypeChip(ShareType.recommendation, 'Recommend', Icons.thumb_up),
          ],
        ),
      ],
    );
  }

  Widget _buildShareTypeChip(ShareType type, String label, IconData icon) {
    final isSelected = _selectedShareType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedShareType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Message (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Add a personal message...',
            hintStyle: GoogleFonts.poppins(
              color: AppTheme.textSecondaryColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppTheme.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSharing ? null : _handleShare,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSharing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Share',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);

    try {
      final customMessage = _messageController.text.trim().isEmpty 
          ? null 
          : _messageController.text.trim();

      if (widget.isResultSharing && widget.score != null && widget.totalQuestions != null) {
        await QuizSharingService.shareQuizResult(
          exam: widget.exam,
          score: widget.score!,
          totalQuestions: widget.totalQuestions!,
          customMessage: customMessage,
        );
      } else {
        await QuizSharingService.shareQuiz(
          exam: widget.exam,
          customMessage: customMessage,
          shareType: _selectedShareType,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        CustomSnackbar.showSuccess(
          context,
          'Quiz shared successfully!',
        );
        widget.onShareComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context,
          'Failed to share quiz. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Color _getScoreColor() {
    if (widget.score == null || widget.totalQuestions == null) return Colors.grey;
    final percentage = _getPercentage();
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon() {
    if (widget.score == null || widget.totalQuestions == null) return Icons.quiz;
    final percentage = _getPercentage();
    if (percentage >= 80) return Icons.emoji_events;
    if (percentage >= 60) return Icons.thumb_up;
    return Icons.trending_up;
  }

  int _getPercentage() {
    if (widget.score == null || widget.totalQuestions == null) return 0;
    return ((widget.score! / widget.totalQuestions!) * 100).round();
  }
}

/// Show quiz sharing bottom sheet
void showQuizSharingSheet({
  required BuildContext context,
  required ExamModel exam,
  int? score,
  int? totalQuestions,
  String? customMessage,
  bool isResultSharing = false,
  VoidCallback? onShareComplete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: QuizSharingWidget(
        exam: exam,
        score: score,
        totalQuestions: totalQuestions,
        customMessage: customMessage,
        isResultSharing: isResultSharing,
        onShareComplete: onShareComplete,
      ),
    ),
  );
}
