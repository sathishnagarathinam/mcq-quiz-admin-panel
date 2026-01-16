import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/email_auth_provider.dart';
import '../../../core/providers/quiz_attempt_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../core/widgets/secure_screen_wrapper.dart';
import '../widgets/user_statistics_widget.dart';
import '../widgets/purchased_quizzes_widget.dart';

/// Profile screen showing user information and stats
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(emailAuthProvider);
    final user = authState.user;

    return SecureScreenWrapper(
      enableScreenshotPrevention: true,
      enableScreenRecordingPrevention: true,
      showWarningOnRecording: true,
      customWarningMessage:
          'Screenshots and screen recording are not allowed in profile section for privacy protection.',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Navigate back to home screen using GoRouter
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // If no previous route, navigate to home using GoRouter
                context.go('/home');
              }
            },
          ),
          title: Text(
            'Profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile header
                _buildProfileHeader(user),

                const SizedBox(height: 24),

                // Your Quizzes (Purchased quizzes with active access)
                const PurchasedQuizzesWidget(),

                const SizedBox(height: 24),

                // User Statistics
                const UserStatisticsWidget(),

                const SizedBox(height: 24),

                // Recent activity
                _buildRecentActivity(ref),

                const SizedBox(height: 24),

                // Settings
                _buildSettingsSection(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(EmailUser? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              (user?.name.isNotEmpty == true
                      ? user!.name[0]
                      : user?.email.isNotEmpty == true
                          ? user!.email[0]
                          : 'U')
                  .toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            user?.name ?? 'User',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),

          // Email
          Text(
            user?.email ?? 'user@example.com',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Edit profile button
          Builder(
            builder: (context) => OutlinedButton(
              onPressed: () {
                // TODO: Implement edit profile
                CustomSnackbar.showInfo(context, 'Edit profile coming soon!');
              },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: const BorderSide(color: AppTheme.primaryColor),
              ),
              child: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // Real recent quiz attempts
          Consumer(
            builder: (context, ref, child) {
              final recentAttemptsAsync =
                  ref.watch(userRecentAttemptsProvider(3));

              return recentAttemptsAsync.when(
                data: (attempts) {
                  if (attempts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No recent quiz attempts',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: attempts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final attempt = entry.value;

                      // Calculate score percentage
                      final scorePercentage = attempt.score != null &&
                              attempt.totalQuestions != null &&
                              attempt.totalQuestions! > 0
                          ? ((attempt.score! / attempt.totalQuestions!) * 100)
                              .round()
                          : 0;

                      // Get time ago
                      final timeAgo = _getTimeAgo(attempt.attemptedAt);

                      // Get icon and color based on exam type
                      final iconData = _getExamIcon(attempt.examType);
                      final iconColor = _getScoreColor(scorePercentage);

                      return Column(
                        children: [
                          if (index > 0) const Divider(),
                          _buildActivityItem(
                            attempt.examName,
                            attempt.isCompleted
                                ? 'Scored $scorePercentage% • $timeAgo'
                                : 'In Progress • $timeAgo',
                            iconData,
                            iconColor,
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading recent activity',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // General Feedback Button
          _buildSettingsItem(
            context,
            'Submit Feedback',
            'Share your thoughts and help us improve',
            Icons.feedback_outlined,
            () => context.goToGeneralFeedbackHistory(),
          ),

          const SizedBox(height: 12),

          // Quiz Feedback History Button
          _buildSettingsItem(
            context,
            'Quiz Feedback History',
            'View your quiz feedback and admin responses',
            Icons.quiz_outlined,
            () => context.goToFeedbackHistory(),
          ),

          const SizedBox(height: 12),

          LoadingButton(
            text: 'Sign Out',
            onPressed: () => _handleSignOut(context, ref),
            backgroundColor: Colors.red,
            expanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) async {
    final authNotifier = ref.read(emailAuthProvider.notifier);
    await authNotifier.signOut();
    if (context.mounted) {
      CustomSnackbar.showSuccess(context, 'Signed out successfully');
      // Navigate to splash screen after successful logout
      // The splash screen will handle redirecting to login
      context.go('/splash');
    }
  }

  /// Helper method to get time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Helper method to get exam icon based on type
  IconData _getExamIcon(String examType) {
    switch (examType.toLowerCase()) {
      case 'postal guide':
        return Icons.local_post_office;
      case 'postal volumes':
        return Icons.inventory;
      case 'general knowledge':
        return Icons.school;
      case 'current affairs':
        return Icons.newspaper;
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      default:
        return Icons.quiz;
    }
  }

  /// Helper method to get color based on score
  Color _getScoreColor(int scorePercentage) {
    if (scorePercentage >= 80) {
      return Colors.green;
    } else if (scorePercentage >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
