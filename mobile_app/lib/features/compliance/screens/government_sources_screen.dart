import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

/// Screen displaying official government sources for compliance with Google Play Misleading Claims policy
class GovernmentSourcesScreen extends StatelessWidget {
  const GovernmentSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Official Government Sources',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Educational Content Sources',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Official sources section
            Text(
              'Official Government Sources',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Department of Posts - Main Website
            _buildSourceCard(
              title: 'Department of Posts - Official Website',
              url: 'https://www.indiapost.gov.in',
              description: 'Main government portal for postal services and information',
              icon: Icons.language,
              color: Colors.green,
            ),

            const SizedBox(height: 12),

            // India Post Recruitment Portal
            _buildSourceCard(
              title: 'India Post Recruitment Portal',
              url: 'https://www.indiapost.gov.in/VAS/Pages/IndiaPostRecruitment.aspx',
              description: 'Official recruitment notifications and exam updates',
              icon: Icons.work,
              color: Colors.orange,
            ),

            const SizedBox(height: 12),

            // Postal Manual Online
            _buildSourceCard(
              title: 'Postal Manual Online',
              url: 'https://www.indiapost.gov.in/VAS/Pages/PostalManual.aspx',
              description: 'Official postal rules, regulations, and procedures',
              icon: Icons.menu_book,
              color: Colors.purple,
            ),

            const SizedBox(height: 12),

            // Department of Posts - Recruitment Section
            _buildSourceCard(
              title: 'Department of Posts - Recruitment Section',
              url: 'https://www.indiapost.gov.in/VAS/Pages/recruitment.aspx',
              description: 'Latest job openings and examination announcements',
              icon: Icons.assignment,
              color: Colors.blue,
            ),

            const SizedBox(height: 12),

            // India Post Results Portal
            _buildSourceCard(
              title: 'India Post Results Portal',
              url: 'https://www.indiapost.gov.in/VAS/Pages/results.aspx',
              description: 'Official examination results and merit lists',
              icon: Icons.assessment,
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            // India Post News & Updates
            _buildSourceCard(
              title: 'India Post News & Updates',
              url: 'https://www.indiapost.gov.in/VAS/Pages/news.aspx',
              description: 'Official news and announcements from Department of Posts',
              icon: Icons.newspaper,
              color: Colors.teal,
            ),

            const SizedBox(height: 32),

            // Disclaimer section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Important Disclaimer',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This app is NOT affiliated with, endorsed by, or representing any government entity, including the Department of Posts, Government of India. This is an independent educational tool created to help students prepare for Post Office departmental exams.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All content is sourced from publicly available materials and is intended for educational purposes only. For official information, always refer to the government sources listed above.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard({
    required String title,
    required String url,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _launchURL(url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.open_in_new, color: color, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Visit Official Source',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Usage:
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const GovernmentSourcesScreen()),
/// )
