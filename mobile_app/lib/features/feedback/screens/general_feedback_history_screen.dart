import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/general_feedback_model.dart';
import '../../../core/services/general_feedback_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/general_feedback_card.dart';
import 'add_feedback_screen.dart';

/// Screen for viewing general feedback history
class GeneralFeedbackHistoryScreen extends StatefulWidget {
  const GeneralFeedbackHistoryScreen({super.key});

  @override
  State<GeneralFeedbackHistoryScreen> createState() =>
      _GeneralFeedbackHistoryScreenState();
}

class _GeneralFeedbackHistoryScreenState
    extends State<GeneralFeedbackHistoryScreen> {
  List<GeneralFeedbackModel> _feedbacks = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<GeneralFeedbackModel>>? _feedbackSubscription;

  @override
  void initState() {
    super.initState();
    _setupFeedbackStream();
  }

  @override
  void dispose() {
    _feedbackSubscription?.cancel();
    super.dispose();
  }

  void _setupFeedbackStream() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    _feedbackSubscription =
        GeneralFeedbackService.getUserFeedbackStream().listen(
      (feedbacks) {
        if (mounted) {
          setState(() {
            _feedbacks = feedbacks;
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _loadFeedbackHistory() async {
    // This method is kept for manual refresh functionality
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final feedbacks = await GeneralFeedbackService.getUserFeedbackHistory();

      setState(() {
        _feedbacks = feedbacks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddFeedback() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddFeedbackScreen(),
      ),
    );

    if (result == true) {
      // Refresh the list if feedback was submitted
      _loadFeedbackHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'General Feedback History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.goNamed('profile'),
          tooltip: 'Back to Profile',
        ),
        actions: [
          IconButton(
            onPressed: _navigateToAddFeedback,
            icon: const Icon(Icons.add),
            tooltip: 'Add Feedback',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddFeedback,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading feedback',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeedbackHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feedback_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No feedback submitted yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your thoughts and help us improve',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddFeedback,
              icon: const Icon(Icons.add),
              label: const Text('Submit Feedback'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeedbackHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _feedbacks.length,
        itemBuilder: (context, index) {
          final feedback = _feedbacks[index];
          return GeneralFeedbackCard(
            feedback: feedback,
            onTap: () => _showFeedbackDetails(feedback),
          );
        },
      ),
    );
  }

  void _showFeedbackDetails(GeneralFeedbackModel feedback) {
    showDialog(
      context: context,
      builder: (context) => _FeedbackDetailsDialog(feedback: feedback),
    );
  }
}

class _FeedbackDetailsDialog extends StatelessWidget {
  final GeneralFeedbackModel feedback;

  const _FeedbackDetailsDialog({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.feedback,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Feedback Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and Rating
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            'Category',
                            FeedbackCategory
                                    .categoryLabels[feedback.category] ??
                                feedback.category,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildInfoRow('Rating', '${feedback.rating}/5 ⭐'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Subject
                    _buildInfoRow('Subject', feedback.subject),

                    const SizedBox(height: 16),

                    // Message
                    _buildInfoSection('Message', feedback.message),

                    const SizedBox(height: 16),

                    // Status and Date
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                              'Status', _getStatusText(feedback.status)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoRow(
                              'Submitted', _formatDate(feedback.submittedAt)),
                        ),
                      ],
                    ),

                    // Admin Response
                    if (feedback.adminResponse != null) ...[
                      const SizedBox(height: 20),
                      _buildInfoSection(
                          'Admin Response', feedback.adminResponse!),
                      if (feedback.respondedAt != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            'Responded', _formatDate(feedback.respondedAt!)),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return 'Pending Review';
      case FeedbackStatus.reviewed:
        return 'Under Review';
      case FeedbackStatus.responded:
        return 'Responded';
      case FeedbackStatus.archived:
        return 'Archived';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
