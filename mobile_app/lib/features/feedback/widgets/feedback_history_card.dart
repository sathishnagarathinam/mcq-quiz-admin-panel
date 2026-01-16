import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/feedback_model.dart';
import '../../../core/theme/app_theme.dart';

class FeedbackHistoryCard extends StatelessWidget {
  final FeedbackModel feedback;
  final VoidCallback? onTap;

  const FeedbackHistoryCard({
    super.key,
    required this.feedback,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with exam name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      feedback.examName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Score and rating row
              Row(
                children: [
                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${feedback.userScore}/${feedback.totalQuestions}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getScoreColor(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Rating
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < feedback.rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        '${feedback.rating}/5',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Date
                  Text(
                    _formatDate(feedback.submittedAt),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              
              // Comment preview (if exists)
              if (feedback.comment.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  feedback.comment,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Admin response indicator
              if (feedback.adminResponse != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Admin has responded to your feedback',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      if (feedback.respondedAt != null)
                        Text(
                          _formatDate(feedback.respondedAt!),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.primaryColor.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              // Tap to view indicator
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to view details',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.textSecondaryColor.withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;
    
    switch (feedback.status) {
      case FeedbackStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case FeedbackStatus.reviewed:
        color = Colors.blue;
        text = 'Reviewing';
        break;
      case FeedbackStatus.responded:
        color = Colors.green;
        text = 'Responded';
        break;
      case FeedbackStatus.archived:
        color = Colors.grey;
        text = 'Archived';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getScoreColor() {
    final percentage = feedback.percentage;
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
