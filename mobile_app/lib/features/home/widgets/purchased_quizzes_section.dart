import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/paid_quiz_access_service.dart';
import '../../../core/services/exam_service.dart';
import '../../../core/models/paid_quiz_access_model.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/router/app_router.dart';

/// Widget to display user's purchased quizzes on home screen
class PurchasedQuizzesSection extends ConsumerWidget {
  const PurchasedQuizzesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    developer.log('🏠 PurchasedQuizzesSection.build() called');
    return FutureBuilder<List<PaidQuizAccessModel>>(
      future: PaidQuizAccessService.getUserAllQuizAccess(),
      builder: (context, snapshot) {
        developer.log(
            '🏠 PurchasedQuizzesSection FutureBuilder state: ${snapshot.connectionState}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          developer.log('🏠 Loading purchased quizzes...');
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          developer
              .log('🏠 Error loading purchased quizzes: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        final accessRecords = snapshot.data ?? [];
        developer.log('🏠 Received ${accessRecords.length} access records');

        // Filter only active access records
        final activeAccess =
            accessRecords.where((record) => record.isValidAccess).toList();

        developer
            .log('🏠 Filtered to ${activeAccess.length} active access records');

        if (activeAccess.isEmpty) {
          developer.log('🏠 No active purchased quizzes, hiding section');
          return const SizedBox
              .shrink(); // Don't show section if no purchased quizzes
        }

        developer.log('🏠 Showing ${activeAccess.length} purchased quizzes');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Purchased Quizzes',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () => context.goNamed('profile'),
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Horizontal list of purchased quizzes
            SizedBox(
              height: 145,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: activeAccess.length,
                itemBuilder: (context, index) {
                  final access = activeAccess[index];
                  return _PurchasedQuizCard(access: access);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 145,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Stateful widget for purchased quiz card that fetches exam details if needed
class _PurchasedQuizCard extends StatefulWidget {
  final PaidQuizAccessModel access;

  const _PurchasedQuizCard({required this.access});

  @override
  State<_PurchasedQuizCard> createState() => _PurchasedQuizCardState();
}

class _PurchasedQuizCardState extends State<_PurchasedQuizCard> {
  String? _examName;
  Color? _cardColor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamDetails();
  }

  Future<void> _loadExamDetails() async {
    // If examName is already available, use it
    if (widget.access.examName.isNotEmpty) {
      setState(() {
        _examName = widget.access.examName;
        _isLoading = false;
      });
      // Still fetch exam for color
      _fetchExamColor();
      return;
    }

    // Fetch exam details from Firestore
    try {
      final exam = await ExamService.getExamById(widget.access.examId);
      if (exam != null && mounted) {
        setState(() {
          _examName = exam.displayName;
          _cardColor = _getColorForExamType(exam.examType);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _examName = 'Quiz ${widget.access.examId.substring(0, 6)}...';
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error fetching exam details: $e');
      if (mounted) {
        setState(() {
          _examName = 'Quiz ${widget.access.examId.substring(0, 6)}...';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchExamColor() async {
    try {
      final exam = await ExamService.getExamById(widget.access.examId);
      if (exam != null && mounted) {
        setState(() {
          _cardColor = _getColorForExamType(exam.examType);
        });
      }
    } catch (e) {
      developer.log('Error fetching exam color: $e');
    }
  }

  Color _getColorForExamType(String examType) {
    switch (examType.toUpperCase()) {
      case 'MTS':
        return Colors.blue;
      case 'POSTMAN':
        return Colors.orange;
      case 'POSTAL_ASSISTANT':
        return Colors.purple;
      case 'IPO':
        return Colors.teal;
      case 'GROUP_B':
        return Colors.indigo;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate days remaining
    final now = DateTime.now();
    final daysRemaining = widget.access.expiryDate.difference(now).inDays;
    final isExpiringSoon = daysRemaining <= 3;

    final cardColor = _cardColor ?? AppTheme.primaryColor;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withValues(alpha: 0.1),
            AppTheme.surfaceColor,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => context.goToQuizInstructions(widget.access.examId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purchased badge with color
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 10,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Purchased',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Quiz name
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        _examName ?? 'Unknown Quiz',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(height: 8),

              // Days remaining
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 10,
                    color: isExpiringSoon ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      daysRemaining > 0 ? '$daysRemaining days' : 'Expired',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isExpiringSoon ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
