import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/exam_hub_models.dart';
import '../../../core/services/exam_hub_service.dart';
import 'pdf_viewer_screen.dart';

enum ExamHubItemType { news, tips, papers, results }

class ExamHubDetailScreen extends StatefulWidget {
  final BaseExamHubItem item;
  final ExamHubItemType type;

  const ExamHubDetailScreen({
    super.key,
    required this.item,
    required this.type,
  });

  @override
  State<ExamHubDetailScreen> createState() => _ExamHubDetailScreenState();
}

class _ExamHubDetailScreenState extends State<ExamHubDetailScreen> {
  @override
  void initState() {
    super.initState();
    _incrementViewCount();
  }

  void _incrementViewCount() {
    switch (widget.type) {
      case ExamHubItemType.news:
        ExamHubService.incrementNewsViewCount(widget.item.id);
        break;
      case ExamHubItemType.tips:
        ExamHubService.incrementTipsViewCount(widget.item.id);
        break;
      case ExamHubItemType.papers:
        ExamHubService.incrementPapersViewCount(widget.item.id);
        break;
      case ExamHubItemType.results:
        ExamHubService.incrementResultsViewCount(widget.item.id);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _getScreenTitle(),
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _getThemeColor(),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildContent(),
            const SizedBox(height: 24),
            _buildAttachments(),
            const SizedBox(height: 24),
            _buildMetadata(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryBadges(),
            const SizedBox(height: 16),
            Text(
              widget.item.title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.item.description,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildDateInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadges() {
    List<Widget> badges = [];

    if (widget.item is ExamHubNews) {
      final news = widget.item as ExamHubNews;
      badges.add(_buildBadge(
        _getCategoryDisplayName(news.category),
        _getCategoryColor(news.category),
      ));
      if (news.isBreaking) {
        badges.add(_buildBadge('BREAKING', Colors.red));
      }
    } else if (widget.item is ExamHubTips) {
      final tips = widget.item as ExamHubTips;
      badges.add(_buildBadge(
        _getTipsCategoryDisplayName(tips.category),
        Colors.orange,
      ));
      badges.add(_buildBadge(
        tips.difficulty.toUpperCase(),
        _getDifficultyColor(tips.difficulty),
      ));
    } else if (widget.item is ExamHubPapers) {
      final papers = widget.item as ExamHubPapers;
      badges.add(_buildBadge(papers.examType, Colors.green));
      badges.add(_buildBadge(
        _getPaperTypeDisplayName(papers.paperType),
        Colors.blue,
      ));
      if (papers.isOfficial) {
        badges.add(_buildBadge('OFFICIAL', Colors.purple));
      }
    } else if (widget.item is ExamHubResults) {
      final results = widget.item as ExamHubResults;
      badges.add(_buildBadge(results.examType, Colors.purple));
      badges.add(_buildBadge(
        _getResultTypeDisplayName(results.resultType),
        Colors.green,
      ));
      if (results.isOfficial) {
        badges.add(_buildBadge('OFFICIAL', Colors.blue));
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges,
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDateInfo() {
    List<Widget> dateWidgets = [];

    if (widget.item is ExamHubNews) {
      final news = widget.item as ExamHubNews;
      dateWidgets.add(_buildDateItem(
        'Published',
        DateFormat('MMM dd, yyyy').format(news.publishDate),
        Icons.calendar_today,
      ));
      if (news.expiryDate != null) {
        dateWidgets.add(_buildDateItem(
          'Expires',
          DateFormat('MMM dd, yyyy').format(news.expiryDate!),
          Icons.schedule,
        ));
      }
    } else if (widget.item is ExamHubPapers) {
      final papers = widget.item as ExamHubPapers;
      dateWidgets.add(_buildDateItem(
        'Exam Date',
        DateFormat('MMM dd, yyyy').format(papers.examDate),
        Icons.event,
      ));
      dateWidgets.add(_buildDateItem(
        'Year',
        papers.examYear.toString(),
        Icons.date_range,
      ));
    } else if (widget.item is ExamHubResults) {
      final results = widget.item as ExamHubResults;
      dateWidgets.add(_buildDateItem(
        'Published',
        DateFormat('MMM dd, yyyy').format(results.publishDate),
        Icons.calendar_today,
      ));
      dateWidgets.add(_buildDateItem(
        'Exam Date',
        DateFormat('MMM dd, yyyy').format(results.examDate),
        Icons.event,
      ));
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: dateWidgets,
    );
  }

  Widget _buildDateItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (widget.item.content == null || widget.item.content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.item.content!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments() {
    List<FileAttachment> attachments = [];

    if (widget.item is ExamHubNews) {
      attachments = (widget.item as ExamHubNews).attachments;
    } else if (widget.item is ExamHubTips) {
      attachments = (widget.item as ExamHubTips).attachments;
    } else if (widget.item is ExamHubPapers) {
      attachments = (widget.item as ExamHubPapers).attachments;
    } else if (widget.item is ExamHubResults) {
      attachments = (widget.item as ExamHubResults).attachments;
    }

    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attachments',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...attachments
                .map((attachment) => _buildAttachmentItem(attachment)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(FileAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(attachment.type),
            color: _getThemeColor(),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.originalName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  _formatFileSize(attachment.size),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.download,
              color: _getThemeColor(),
            ),
            onPressed: () => _downloadAttachment(attachment),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildMetadataRow('Views', '${widget.item.viewCount}'),
            if (widget.item.downloadCount != null)
              _buildMetadataRow('Downloads', '${widget.item.downloadCount}'),
            _buildMetadataRow(
              'Created',
              DateFormat('MMM dd, yyyy').format(widget.item.createdAt),
            ),
            if (widget.item.tags.isNotEmpty) _buildTagsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.item.tags
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getScreenTitle() {
    switch (widget.type) {
      case ExamHubItemType.news:
        return 'News Details';
      case ExamHubItemType.tips:
        return 'Tips & Shortcuts';
      case ExamHubItemType.papers:
        return 'Previous Papers';
      case ExamHubItemType.results:
        return 'Results';
    }
  }

  Color _getThemeColor() {
    switch (widget.type) {
      case ExamHubItemType.news:
        return const Color(0xFF6366F1);
      case ExamHubItemType.tips:
        return const Color(0xFF10B981);
      case ExamHubItemType.papers:
        return const Color(0xFFF59E0B);
      case ExamHubItemType.results:
        return const Color(0xFF9C27B0);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'exam_notification':
        return Colors.blue;
      case 'result_announcement':
        return Colors.green;
      case 'important_update':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'exam_notification':
        return 'Exam Notification';
      case 'result_announcement':
        return 'Result';
      case 'important_update':
        return 'Important';
      default:
        return 'General';
    }
  }

  String _getTipsCategoryDisplayName(String category) {
    switch (category) {
      case 'study_tips':
        return 'Study Tips';
      case 'exam_strategy':
        return 'Exam Strategy';
      case 'time_management':
        return 'Time Management';
      case 'shortcuts':
        return 'Shortcuts';
      case 'memory_techniques':
        return 'Memory Techniques';
      default:
        return 'Tips';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaperTypeDisplayName(String paperType) {
    switch (paperType) {
      case 'question_paper':
        return 'Question Paper';
      case 'answer_key':
        return 'Answer Key';
      case 'solution':
        return 'Solution';
      case 'analysis':
        return 'Analysis';
      default:
        return 'Paper';
    }
  }

  String _getResultTypeDisplayName(String resultType) {
    switch (resultType) {
      case 'final_result':
        return 'Final Result';
      case 'merit_list':
        return 'Merit List';
      case 'cutoff_marks':
        return 'Cutoff Marks';
      case 'answer_key':
        return 'Answer Key';
      case 'provisional_result':
        return 'Provisional Result';
      default:
        return 'Result';
    }
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('image')) {
      return Icons.image;
    } else if (mimeType.contains('video')) {
      return Icons.video_file;
    } else if (mimeType.contains('audio')) {
      return Icons.audio_file;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _downloadAttachment(FileAttachment attachment) async {
    try {
      // Check if it's a PDF file
      if (attachment.type.toLowerCase().contains('pdf')) {
        // Open PDF in the built-in viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(
              attachment: attachment,
              title: attachment.originalName,
            ),
          ),
        );
      } else {
        // For non-PDF files, open externally
        final uri = Uri.parse(attachment.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      // Increment download count
      String collection;
      switch (widget.type) {
        case ExamHubItemType.news:
          collection = 'exam_hub_news';
          break;
        case ExamHubItemType.tips:
          collection = 'exam_hub_tips';
          break;
        case ExamHubItemType.papers:
          collection = 'exam_hub_papers';
          break;
        case ExamHubItemType.results:
          collection = 'exam_hub_results';
          break;
      }

      ExamHubService.incrementDownloadCount(collection, widget.item.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareItem() {
    final appName = AppConfig.appName;
    final appLink = AppConfig.playStoreUrl;

    String typeText = '';
    switch (widget.type) {
      case ExamHubItemType.news:
        typeText = 'News';
        break;
      case ExamHubItemType.tips:
        typeText = 'Tips & Shortcuts';
        break;
      case ExamHubItemType.papers:
        typeText = 'Previous Year Paper';
        break;
      case ExamHubItemType.results:
        typeText = 'Result';
        break;
    }

    final shareText = '''📚 Check out this $typeText from $appName!

📄 ${widget.item.title}
${widget.item.description}

Perfect for Post Office exam preparation! 🎯

📱 Get the app: $appLink

#PostOfficeExam #ExamPreparation #StudyMaterial''';

    Share.share(
      shareText,
      subject: '$typeText: ${widget.item.title}',
    );
  }
}
