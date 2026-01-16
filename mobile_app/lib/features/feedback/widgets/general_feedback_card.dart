import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/general_feedback_model.dart';
import '../../../core/theme/app_theme.dart';

/// Card widget for displaying general feedback in a list
class GeneralFeedbackCard extends StatelessWidget {
  final GeneralFeedbackModel feedback;
  final VoidCallback? onTap;

  const GeneralFeedbackCard({
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
              // Header with category and status
              Row(
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(feedback.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getCategoryColor(feedback.category).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      FeedbackCategory.categoryLabels[feedback.category] ?? feedback.category,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(feedback.category),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(feedback.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getStatusColor(feedback.status).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(feedback.status),
                          size: 12,
                          color: _getStatusColor(feedback.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(feedback.status),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(feedback.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Subject
              Text(
                feedback.subject,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Message preview
              Text(
                feedback.message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer with rating and date
              Row(
                children: [
                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${feedback.rating}/5',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(feedback.submittedAt),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Admin response indicator
              if (feedback.adminResponse != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Admin has responded',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case FeedbackCategory.bugReport:
        return Colors.red;
      case FeedbackCategory.featureRequest:
        return Colors.blue;
      case FeedbackCategory.appPerformance:
        return Colors.orange;
      case FeedbackCategory.contentQuality:
        return Colors.purple;
      case FeedbackCategory.userExperience:
        return Colors.teal;
      case FeedbackCategory.general:
      case FeedbackCategory.other:
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getStatusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return Colors.orange;
      case FeedbackStatus.reviewed:
        return Colors.blue;
      case FeedbackStatus.responded:
        return Colors.green;
      case FeedbackStatus.archived:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return Icons.schedule;
      case FeedbackStatus.reviewed:
        return Icons.visibility;
      case FeedbackStatus.responded:
        return Icons.check_circle;
      case FeedbackStatus.archived:
        return Icons.archive;
    }
  }

  String _getStatusText(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return 'Pending';
      case FeedbackStatus.reviewed:
        return 'Reviewed';
      case FeedbackStatus.responded:
        return 'Responded';
      case FeedbackStatus.archived:
        return 'Archived';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
