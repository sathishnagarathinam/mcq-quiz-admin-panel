import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/mobile_user_auth_provider.dart';
import '../../core/providers/user_progress_provider.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/models/user_analytics_model.dart';

/// Elevated app bar with gradient background and progress section
class ElevatedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? dropdown;
  final bool showProgress;
  final VoidCallback? onNotificationTap;

  const ElevatedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.dropdown,
    this.showProgress = true,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(showProgress ? 230 : 80);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(mobileUserAuthProvider);
    final user = authState.user;
    final userProgressAsync = ref.watch(userProgressProvider);
    final analyticsAsync = ref.watch(currentUserAnalyticsProvider);

    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5), // Indigo
            Color(0xFF7C3AED), // Purple
            Color(0xFF2563EB), // Blue
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Top app bar section
              Container(
                height: showProgress ? 90 : 80,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Dropdown in left corner if provided
                    if (dropdown != null) ...[
                      dropdown!,
                      const SizedBox(width: 12),
                    ],

                    // Title section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showProgress) ...[
                            Text(
                              'Department of Post',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'MCQ',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Welcome, ${user?.name ?? user?.email.split('@').first ?? 'User'}!',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else ...[
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Notification icon
                    IconButton(
                      onPressed: onNotificationTap,
                      icon: Stack(
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          // Notification badge
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 8,
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Additional actions
                    if (actions != null) ...actions!,
                  ],
                ),
              ),

              // Progress section
              if (showProgress) ...[
                const SizedBox(height: 4),
                Flexible(
                    child: _buildProgressSection(
                        analyticsAsync, userProgressAsync)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(AsyncValue<UserAnalyticsModel?> analyticsAsync,
      AsyncValue<UserProgressModel?> userProgressAsync) {
    // Prioritize analytics data if available
    return analyticsAsync.when(
      data: (analytics) {
        if (analytics != null) {
          return _buildAnalyticsProgress(analytics);
        }
        // Fallback to user progress
        return userProgressAsync.when(
          data: (progress) {
            if (progress == null) {
              return _buildDefaultProgress();
            }
            return _buildUserProgress(progress);
          },
          loading: () => _buildLoadingProgress(),
          error: (_, __) => _buildDefaultProgress(),
        );
      },
      loading: () => _buildLoadingProgress(),
      error: (_, __) {
        // Fallback to user progress on analytics error
        return userProgressAsync.when(
          data: (progress) {
            if (progress == null) {
              return _buildDefaultProgress();
            }
            return _buildUserProgress(progress);
          },
          loading: () => _buildLoadingProgress(),
          error: (_, __) => _buildDefaultProgress(),
        );
      },
    );
  }

  Widget _buildAnalyticsProgress(UserAnalyticsModel analytics) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  analytics.progress.currentLevel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildProgressStat(
                  'Quizzes',
                  analytics.statistics.totalQuizzesCompleted.toString(),
                  Icons.quiz_outlined,
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  'Average',
                  '${analytics.performance.averageScore.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  'Streak',
                  analytics.statistics.currentStreak.toString(),
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProgress(UserProgressModel progress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  progress.progressLevel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildProgressStat(
                  'Exams',
                  progress.totalExamsAttempted.toString(),
                  Icons.quiz_outlined,
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  'Average',
                  '${progress.averageScore.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  'Streak',
                  progress.currentStreak.toString(),
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 18,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProgressStat('Exams', '0', Icons.quiz_outlined),
              ),
              Expanded(
                child: _buildProgressStat('Average', '0%', Icons.trending_up),
              ),
              Expanded(
                child: _buildProgressStat(
                    'Streak', '0', Icons.local_fire_department),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
