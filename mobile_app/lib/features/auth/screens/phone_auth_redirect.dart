import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// Redirect screen for phone authentication
/// Since we migrated to Supabase which uses email auth, 
/// this screen redirects users to email authentication
class PhoneAuthRedirectScreen extends StatefulWidget {
  const PhoneAuthRedirectScreen({super.key});

  @override
  State<PhoneAuthRedirectScreen> createState() => _PhoneAuthRedirectScreenState();
}

class _PhoneAuthRedirectScreenState extends State<PhoneAuthRedirectScreen> {
  @override
  void initState() {
    super.initState();
    // Redirect to email auth after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/auth/email-register');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 50,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Authentication Updated',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message
              Text(
                'We\'ve upgraded to email-based authentication for better security and reliability.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Loading indicator
              const CircularProgressIndicator(),
              
              const SizedBox(height: 16),
              
              Text(
                'Redirecting to email registration...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Manual redirect button
              ElevatedButton(
                onPressed: () => context.go('/auth/email-register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continue with Email',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
