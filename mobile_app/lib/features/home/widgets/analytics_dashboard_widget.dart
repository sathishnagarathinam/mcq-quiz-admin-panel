import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_analytics_model.dart';
import '../../../core/providers/analytics_provider.dart';
import '../../../core/services/analytics_refresh_service.dart';

/// Analytics dashboard widget for home screen
class AnalyticsDashboardWidget extends ConsumerStatefulWidget {
  const AnalyticsDashboardWidget({super.key});

  @override
  ConsumerState<AnalyticsDashboardWidget> createState() =>
      _AnalyticsDashboardWidgetState();
}

class _AnalyticsDashboardWidgetState
    extends ConsumerState<AnalyticsDashboardWidget> {
  @override
  void initState() {
    super.initState();
    // Force refresh analytics when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugAnalyticsState();
    });
  }

  void _debugAnalyticsState() async {
    try {
      // Get analytics summary
      final summary = await AnalyticsRefreshService.getAnalyticsSummary();
      print('🔍 Debug: Analytics Summary: $summary');

      // Check if refresh is needed
      final needsRefresh =
          await AnalyticsRefreshService.needsAnalyticsRefresh();
      print('🔍 Debug: Needs refresh: $needsRefresh');

      if (needsRefresh) {
        print('🔄 Debug: Triggering analytics refresh...');
        final result =
            await AnalyticsRefreshService.refreshAnalyticsFromQuizAttempts();
        print('✅ Debug: Refresh result: $result');

        // Invalidate provider to force UI refresh
        ref.invalidate(currentUserAnalyticsProvider);
      }
    } catch (e) {
      print('❌ Debug: Error in analytics debug: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use regular analytics provider for now to debug
    final analyticsAsync = ref.watch(currentUserAnalyticsProvider);

    return analyticsAsync.when(
      data: (analytics) {
        if (analytics != null) {
          print(
              '📊 Dashboard: Analytics loaded - Completed: ${analytics.statistics.totalQuizzesCompleted}, Avg Score: ${analytics.performance.averageScore.toStringAsFixed(1)}%');
          return _buildDashboardContent(analytics);
        } else {
          print('⚠️ Dashboard: No analytics data available');
          return _buildEmptyState();
        }
      },
      loading: () {
        print('🔄 Dashboard: Loading analytics...');
        return _buildLoadingState();
      },
      error: (error, stack) {
        print('❌ Dashboard: Error loading analytics: $error');
        return _buildErrorState();
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load analytics',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 48,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Take your first quiz to see analytics',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(UserAnalyticsModel analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📊 Your Progress',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  analytics.progress.currentLevel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  'Quizzes',
                  analytics.statistics.totalQuizzesCompleted.toString(),
                  Icons.quiz,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStat(
                  'Avg Score',
                  '${analytics.performance.averageScore.toStringAsFixed(0)}%',
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStat(
                  'Streak',
                  analytics.statistics.currentStreak.toString(),
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Chart
          if (analytics.performance.recentScores.isNotEmpty) ...[
            Text(
              'Recent Performance',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: LineChart(
                  _buildMiniLineChart(analytics.performance.recentScores)),
            ),
          ] else ...[
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Take more quizzes to see your progress chart',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
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
              fontSize: 10,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildMiniLineChart(List<ScoreHistory> scores) {
    final spots = scores.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.score);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.borderColor.withValues(alpha: 0.5),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (scores.length - 1).toDouble(),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.8),
              AppTheme.primaryColor,
            ],
          ),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: AppTheme.primaryColor,
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.primaryColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
