import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/paid_quiz_access_service.dart';
import '../../../core/models/paid_quiz_access_model.dart';

/// Widget to display user's purchased quizzes with active 30-day access
class PurchasedQuizzesWidget extends ConsumerWidget {
  const PurchasedQuizzesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    developer.log('👤 PurchasedQuizzesWidget.build() called');
    return FutureBuilder<List<PaidQuizAccessModel>>(
      future: PaidQuizAccessService.getUserAllQuizAccess(),
      builder: (context, snapshot) {
        developer.log(
            '👤 PurchasedQuizzesWidget FutureBuilder state: ${snapshot.connectionState}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          developer.log('👤 Loading purchased quizzes...');
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          developer
              .log('👤 Error loading purchased quizzes: ${snapshot.error}');
          return _buildErrorState(snapshot.error);
        }

        final accessRecords = snapshot.data ?? [];
        developer.log('👤 Received ${accessRecords.length} access records');

        // Filter only active access records
        final activeAccess =
            accessRecords.where((record) => record.isValidAccess).toList();

        developer
            .log('👤 Filtered to ${activeAccess.length} active access records');

        if (activeAccess.isEmpty) {
          developer.log('👤 No active purchased quizzes, hiding section');
          return const SizedBox
              .shrink(); // Don't show section if no purchased quizzes
        }

        developer.log('👤 Showing ${activeAccess.length} purchased quizzes');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              '🎯 Your Quizzes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Quizzes you have purchased (${activeAccess.length})',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // List of purchased quizzes
            ...activeAccess.map((access) => _buildPurchasedQuizCard(
                  context,
                  ref,
                  access,
                )),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
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

  Widget _buildErrorState(Object? error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Text(
          'Error loading purchased quizzes',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasedQuizCard(
    BuildContext context,
    WidgetRef ref,
    PaidQuizAccessModel access,
  ) {
    // Calculate days remaining
    final now = DateTime.now();
    final daysRemaining = access.expiryDate.difference(now).inDays;
    final isExpiringSoon = daysRemaining <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Quiz icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.quiz,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Quiz info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  access.examName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: isExpiringSoon ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      daysRemaining > 0
                          ? '$daysRemaining days remaining'
                          : 'Expired',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isExpiringSoon ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Purchased badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 12,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Purchased',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
