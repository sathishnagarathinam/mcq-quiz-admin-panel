import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        title: Text(
          'Terms of Service',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(),
              const SizedBox(height: 24),

              // Terms Content
              _buildTermsContent(),
              const SizedBox(height: 24),

              // Acceptance Section
              _buildAcceptanceSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Terms of Service',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Last updated: January 2025',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please read these terms carefully before using our app.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms Overview',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTermItem(
            'Acceptance of Terms',
            'By accessing and using this app, you accept and agree to be bound by these terms and conditions.',
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 12),
          _buildTermItem(
            'User Accounts',
            'You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.',
            Icons.account_circle,
          ),
          const SizedBox(height: 12),
          _buildTermItem(
            'Quiz Content',
            'All quiz content is provided for educational purposes. Unauthorized copying or distribution is prohibited.',
            Icons.quiz,
          ),
          const SizedBox(height: 12),
          _buildTermItem(
            'Payment Terms',
            'Paid quizzes require payment before access. All payments are processed securely through our payment gateway.',
            Icons.payment,
          ),
          const SizedBox(height: 12),
          _buildTermItem(
            'Refund Policy',
            'Refunds are subject to our refund policy. Please review the refund policy for detailed information.',
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 12),
          _buildTermItem(
            'Prohibited Activities',
            'You may not use the app for any illegal purposes, attempt to hack or disrupt the service, or share account credentials.',
            Icons.block,
          ),
          const SizedBox(height: 12),
          _buildTermItem(
            'Intellectual Property',
            'All content, trademarks, and data on this app are the property of Dakshin Postal Academy or its licensors.',
            Icons.copyright,
          ),
          const SizedBox(height: 12),
          _buildTermItem(
            'Limitation of Liability',
            'We are not liable for any indirect, incidental, or consequential damages arising from your use of the app.',
            Icons.gavel,
          ),
          const SizedBox(height: 12),
          _buildTermItem(
            'Changes to Terms',
            'We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of modified terms.',
            Icons.update,
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
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
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptanceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'By using this app, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textPrimaryColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
