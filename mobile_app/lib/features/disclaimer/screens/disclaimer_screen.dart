import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class DisclaimerScreen extends StatelessWidget {
  final bool showButtons;

  const DisclaimerScreen({
    super.key,
    this.showButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: !showButtons
          ? AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Important Disclaimer',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Header
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 80,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Important Disclaimer',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Main disclaimer
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border:
                              Border.all(color: Colors.red.shade300, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning,
                                    color: Colors.red.shade600, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'NOT A GOVERNMENT APP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This app is NOT affiliated with, endorsed by, or representing any government entity, including the Department of Posts, Government of India.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.red.shade700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // What this app is
                      _buildInfoSection(
                        'What is this app?',
                        'This is an independent educational tool created to help students prepare for Post Office departmental exams. All content is sourced from publicly available materials.',
                        Icons.school,
                        AppTheme.primaryColor,
                      ),

                      const SizedBox(height: 20),

                      // Content source
                      _buildInfoSection(
                        'Content Source',
                        'All questions, study materials, and exam information are compiled from publicly available sources and are intended for educational purposes only.',
                        Icons.library_books,
                        Colors.orange,
                      ),

                      const SizedBox(height: 20),

                      // Official information with source links
                      _buildOfficialSourcesSection(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Buttons (only show during first-time setup)
              if (showButtons)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _acceptAndContinue(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'I Understand & Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _exitApp(context),
                      child: Text(
                        'Exit App',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
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

  Widget _buildInfoSection(
      String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textPrimaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialSourcesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Text(
                'Official Government Sources',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'For official exam notifications, results, and government services, please visit:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildSourceLink(
            'Department of Posts - Official Website',
            'https://www.indiapost.gov.in',
            'Main government portal for postal services',
          ),
          const SizedBox(height: 8),
          _buildSourceLink(
            'India Post Recruitment Portal',
            'https://www.indiapost.gov.in/VAS/Pages/IndiaPostRecruitment.aspx',
            'Official recruitment notifications and updates',
          ),
          const SizedBox(height: 8),
          _buildSourceLink(
            'Department of Posts - Recruitment',
            'https://www.indiapost.gov.in/VAS/Pages/recruitment.aspx',
            'Latest job openings and exam announcements',
          ),
          const SizedBox(height: 8),
          _buildSourceLink(
            'Postal Manual Online',
            'https://www.indiapost.gov.in/VAS/Pages/PostalManual.aspx',
            'Official postal rules and regulations',
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLink(String title, String url, String description) {
    return InkWell(
      onTap: () => _launchURL(url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.open_in_new, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Future<void> _acceptAndContinue(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted', true);

    if (context.mounted) {
      context.go('/onboarding');
    }
  }

  void _exitApp(BuildContext context) {
    // Close the app properly
    SystemNavigator.pop();
  }
}
