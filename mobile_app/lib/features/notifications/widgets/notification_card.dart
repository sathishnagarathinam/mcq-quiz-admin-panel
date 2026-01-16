import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/enhanced_notification_service.dart';

class NotificationCard extends StatelessWidget {
  final UserNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final notificationData = notification.notification;
    final isRead = notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.grey[200]! : Colors.blue[100]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Category icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: EnhancedNotificationService
                            .getNotificationPriorityColor(
                          notificationData.priority,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        EnhancedNotificationService.getNotificationCategoryIcon(
                          notificationData.category,
                        ),
                        color: EnhancedNotificationService
                            .getNotificationPriorityColor(
                          notificationData.priority,
                        ),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and priority
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notificationData.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: isRead
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color: isRead
                                        ? Colors.grey[700]
                                        : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              // Priority chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: EnhancedNotificationService
                                      .getNotificationPriorityColor(
                                    notificationData.priority,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  notificationData.priorityDisplayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: EnhancedNotificationService
                                        .getNotificationPriorityColor(
                                      notificationData.priority,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Category
                              Text(
                                notificationData.categoryDisplayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Delete button
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Message body
                Text(
                  notificationData.body,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isRead ? Colors.grey[600] : Colors.grey[800],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Image if available (prioritize test image over regular image)
                if ((notificationData.testImageUrl != null &&
                        notificationData.testImageUrl!.isNotEmpty) ||
                    (notificationData.imageUrl != null &&
                        notificationData.imageUrl!.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl:
                          notificationData.testImageUrl?.isNotEmpty == true
                              ? notificationData.testImageUrl!
                              : notificationData.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 120,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 120,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  // Add test image label if it's a test image
                  if (notificationData.testImageUrl != null &&
                      notificationData.testImageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 14,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Test Image',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],

                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    // Timestamp
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(notification.sentAt),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),

                    const Spacer(),

                    // Action button if available
                    if (notificationData.hasAction)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getActionIcon(notificationData.actionType),
                              size: 14,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getActionText(notificationData.actionType),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  IconData _getActionIcon(String? actionType) {
    switch (actionType) {
      case 'quiz':
        return Icons.quiz;
      case 'exam':
        return Icons.school;
      case 'news':
        return Icons.article;
      default:
        return Icons.open_in_new;
    }
  }

  String _getActionText(String? actionType) {
    switch (actionType) {
      case 'quiz':
        return 'Take Quiz';
      case 'exam':
        return 'View Exam';
      case 'news':
        return 'Read More';
      default:
        return 'View';
    }
  }
}
