import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_analytics_model.dart';

/// Performance charts widget for user analytics
class PerformanceChartsWidget extends StatelessWidget {
  final UserAnalyticsModel analytics;

  const PerformanceChartsWidget({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          '📈 Performance Charts',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Recent Scores Line Chart
        _buildRecentScoresChart(),
        
        const SizedBox(height: 20),
        
        // Category Performance Bar Chart
        _buildCategoryPerformanceChart(),
        
        const SizedBox(height: 20),
        
        // Progress Pie Chart
        _buildProgressPieChart(),
      ],
    );
  }

  Widget _buildRecentScoresChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Quiz Scores',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: analytics.performance.recentScores.isNotEmpty
                ? LineChart(_buildLineChartData())
                : _buildEmptyChart('No recent scores available'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformanceChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Performance',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: analytics.performance.categoryScores.isNotEmpty
                ? BarChart(_buildBarChartData())
                : _buildEmptyChart('No category data available'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPieChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Completion Status',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(_buildPieChartData()),
                ),
                Expanded(
                  child: _buildPieChartLegend(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final scores = analytics.performance.recentScores;
    final spots = scores.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.score);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.borderColor,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value.toInt() < scores.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${value.toInt() + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 40,
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                '${value.toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppTheme.textSecondaryColor,
                ),
              );
            },
          ),
        ),
      ),
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
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppTheme.primaryColor,
                strokeWidth: 2,
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

  BarChartData _buildBarChartData() {
    final categories = analytics.performance.categoryScores.entries.toList();
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 100,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value.toInt() < categories.length) {
                final category = categories[value.toInt()].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    category.length > 8 ? '${category.substring(0, 8)}...' : category,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 20,
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                '${value.toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppTheme.textSecondaryColor,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: categories.asMap().entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value.value,
              color: colors[entry.key % colors.length],
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      }).toList(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.borderColor,
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  PieChartData _buildPieChartData() {
    final completed = analytics.statistics.totalQuizzesCompleted.toDouble();
    final attempted = analytics.statistics.totalQuizzesAttempted.toDouble();
    final incomplete = attempted - completed;

    return PieChartData(
      pieTouchData: PieTouchData(enabled: false),
      borderData: FlBorderData(show: false),
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      sections: [
        PieChartSectionData(
          color: Colors.green,
          value: completed,
          title: '',
          radius: 30,
        ),
        if (incomplete > 0)
          PieChartSectionData(
            color: Colors.orange,
            value: incomplete,
            title: '',
            radius: 30,
          ),
      ],
    );
  }

  Widget _buildPieChartLegend() {
    final completed = analytics.statistics.totalQuizzesCompleted;
    final attempted = analytics.statistics.totalQuizzesAttempted;
    final incomplete = attempted - completed;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(
          color: Colors.green,
          label: 'Completed',
          value: completed.toString(),
        ),
        const SizedBox(height: 8),
        if (incomplete > 0)
          _buildLegendItem(
            color: Colors.orange,
            label: 'Incomplete',
            value: incomplete.toString(),
          ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
