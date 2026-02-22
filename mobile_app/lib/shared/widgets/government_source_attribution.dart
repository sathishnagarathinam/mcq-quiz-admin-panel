import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

/// Widget to display government source attribution for compliance with Google Play Misleading Claims policy
class GovernmentSourceAttribution extends StatelessWidget {
  final bool showFullDisclaimer;
  final String? customTitle;
  final List<OfficialSource>? customSources;

  const GovernmentSourceAttribution({
    super.key,
    this.showFullDisclaimer = false,
    this.customTitle,
    this.customSources,
  });

  @override
  Widget build(BuildContext context) {
    if (showFullDisclaimer) {
      return _buildFullDisclaimer();
    } else {
      return _buildCompactAttribution();
    }
  }

  Widget _buildCompactAttribution() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Content sourced from official government publications. For latest updates, visit indiapost.gov.in',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textSecondaryColor,
                height: 1.3,
              ),
            ),
          ),
          InkWell(
            onTap: () => _launchURL('https://www.indiapost.gov.in'),
            child: const Icon(Icons.open_in_new, color: Colors.blue, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFullDisclaimer() {
    final sources = customSources ?? _getDefaultSources();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  customTitle ?? 'Official Government Sources',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This app provides educational content based on official government publications. For the most current and authoritative information, please refer to these official sources:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...sources.map((source) => _buildSourceItem(source)),
        ],
      ),
    );
  }

  Widget _buildSourceItem(OfficialSource source) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _launchURL(source.url),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(source.icon, color: Colors.green, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    if (source.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        source.description,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, color: Colors.green, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  List<OfficialSource> _getDefaultSources() {
    return [
      OfficialSource(
        title: 'Department of Posts - Official Website',
        url: 'https://www.indiapost.gov.in',
        description: 'Main government portal for postal services and information',
        icon: Icons.language,
      ),
      OfficialSource(
        title: 'India Post Recruitment Portal',
        url: 'https://www.indiapost.gov.in/VAS/Pages/IndiaPostRecruitment.aspx',
        description: 'Official recruitment notifications and exam updates',
        icon: Icons.work,
      ),
      OfficialSource(
        title: 'Postal Manual Online',
        url: 'https://www.indiapost.gov.in/VAS/Pages/PostalManual.aspx',
        description: 'Official postal rules, regulations, and procedures',
        icon: Icons.menu_book,
      ),
      OfficialSource(
        title: 'Department of Posts - Recruitment Section',
        url: 'https://www.indiapost.gov.in/VAS/Pages/recruitment.aspx',
        description: 'Latest job openings and examination announcements',
        icon: Icons.assignment,
      ),
    ];
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Model for official government sources
class OfficialSource {
  final String title;
  final String url;
  final String description;
  final IconData icon;

  const OfficialSource({
    required this.title,
    required this.url,
    required this.description,
    required this.icon,
  });
}

/// Specific attribution widgets for different content types

class ExamContentAttribution extends StatelessWidget {
  const ExamContentAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return GovernmentSourceAttribution(
      customTitle: 'Exam Information Sources',
      customSources: [
        OfficialSource(
          title: 'India Post Recruitment Portal',
          url: 'https://www.indiapost.gov.in/VAS/Pages/IndiaPostRecruitment.aspx',
          description: 'Official exam notifications and recruitment updates',
          icon: Icons.school,
        ),
        OfficialSource(
          title: 'Department of Posts - Recruitment',
          url: 'https://www.indiapost.gov.in/VAS/Pages/recruitment.aspx',
          description: 'Latest examination announcements and job openings',
          icon: Icons.assignment,
        ),
      ],
    );
  }
}

class PostalRulesAttribution extends StatelessWidget {
  const PostalRulesAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return GovernmentSourceAttribution(
      customTitle: 'Postal Rules & Regulations Sources',
      customSources: [
        OfficialSource(
          title: 'Postal Manual Online',
          url: 'https://www.indiapost.gov.in/VAS/Pages/PostalManual.aspx',
          description: 'Official postal manual with complete rules and procedures',
          icon: Icons.gavel,
        ),
        OfficialSource(
          title: 'Department of Posts - Official Website',
          url: 'https://www.indiapost.gov.in',
          description: 'Main government portal for postal services',
          icon: Icons.language,
        ),
      ],
    );
  }
}

class NewsAttribution extends StatelessWidget {
  const NewsAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return GovernmentSourceAttribution(
      customTitle: 'News & Updates Sources',
      customSources: [
        OfficialSource(
          title: 'Department of Posts - News & Updates',
          url: 'https://www.indiapost.gov.in/VAS/Pages/news.aspx',
          description: 'Official news and announcements from Department of Posts',
          icon: Icons.newspaper,
        ),
        OfficialSource(
          title: 'India Post Recruitment Portal',
          url: 'https://www.indiapost.gov.in/VAS/Pages/IndiaPostRecruitment.aspx',
          description: 'Latest recruitment news and exam updates',
          icon: Icons.notifications,
        ),
      ],
    );
  }
}

class ResultsAttribution extends StatelessWidget {
  const ResultsAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return GovernmentSourceAttribution(
      customTitle: 'Results & Merit Lists Sources',
      customSources: [
        OfficialSource(
          title: 'India Post Results Portal',
          url: 'https://www.indiapost.gov.in/VAS/Pages/results.aspx',
          description: 'Official examination results and merit lists',
          icon: Icons.assessment,
        ),
        OfficialSource(
          title: 'Department of Posts - Recruitment Results',
          url: 'https://www.indiapost.gov.in/VAS/Pages/recruitment.aspx',
          description: 'Latest recruitment results and selections',
          icon: Icons.emoji_events,
        ),
      ],
    );
  }
}

/// Usage examples:
/// 
/// // Compact attribution for quiz screens
/// GovernmentSourceAttribution()
/// 
/// // Full disclaimer for main screens
/// GovernmentSourceAttribution(showFullDisclaimer: true)
/// 
/// // Specific content attribution
/// ExamContentAttribution()
/// PostalRulesAttribution()
/// NewsAttribution()
/// ResultsAttribution()
