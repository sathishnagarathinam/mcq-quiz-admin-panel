import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/providers/email_auth_provider.dart';

/// Splash screen that checks authentication state and redirects accordingly
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);

    // Check authentication state after a minimum splash duration
    _checkAuthenticationState();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Check authentication state and navigate accordingly
  Future<void> _checkAuthenticationState() async {
    // Wait for minimum splash duration for better UX
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    try {
      // Check if disclaimer has been accepted first
      final prefs = await SharedPreferences.getInstance();
      final disclaimerAccepted = prefs.getBool('disclaimer_accepted') ?? false;

      if (!disclaimerAccepted) {
        // Show disclaimer first
        debugPrint('  → Navigating to DISCLAIMER');
        if (mounted) {
          context.go('/disclaimer');
        }
        return;
      }

      // For testing: Uncomment the line below to reset onboarding
      // await OnboardingService.resetOnboarding();

      // Check if onboarding has been completed
      final onboardingCompleted =
          await OnboardingService.isOnboardingCompleted();

      // Check if onboarding should be shown for version update
      final shouldShowForUpdate =
          await OnboardingService.shouldShowOnboardingForUpdate(
        AppConfig.appVersion,
      );

      // Listen to auth state and navigate accordingly
      final authState = ref.read(emailAuthProvider);

      // Debug logging
      debugPrint('🔍 Splash Navigation Debug:');
      debugPrint('  - Onboarding completed: $onboardingCompleted');
      debugPrint('  - Should show for update: $shouldShowForUpdate');
      debugPrint('  - Auth state authenticated: ${authState.isAuthenticated}');
      debugPrint('  - Auth state user: ${authState.user != null}');

      if (!onboardingCompleted || shouldShowForUpdate) {
        // First time user or version update, show onboarding
        debugPrint('  → Navigating to ONBOARDING');
        if (mounted) {
          // Add a small delay to ensure the widget is fully mounted
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            debugPrint('  → Actually calling context.go(\'/onboarding\')');
            context.go('/onboarding');
            debugPrint('  → Navigation call completed');
          }
        }
      } else if (authState.isAuthenticated && authState.user != null) {
        // User is authenticated, go to home
        debugPrint('  → Navigating to HOME');
        if (mounted) {
          context.go('/home');
        }
      } else {
        // Check for auto-login credentials before showing login screen
        final autoLoginEnabled =
            await CredentialStorageService.isAutoLoginEnabled();
        final hasStoredCredentials =
            await CredentialStorageService.getStoredCredentials() != null;

        if (autoLoginEnabled && hasStoredCredentials) {
          // Attempt auto-login
          debugPrint('  → Attempting AUTO-LOGIN');
          final success = await _attemptAutoLogin();
          if (success && mounted) {
            context.go('/home');
            return;
          }
        }

        // User is not authenticated or auto-login failed, go to login
        debugPrint('  → Navigating to LOGIN');
        if (mounted) {
          context.go('/auth/email-login');
        }
      }
    } catch (e) {
      // If there's an error checking onboarding state, default to showing onboarding
      debugPrint('Error checking onboarding state: $e');
      if (mounted) {
        context.go('/onboarding');
      }
    }
  }

  /// Attempt automatic login using stored credentials
  Future<bool> _attemptAutoLogin() async {
    try {
      final storedEmail = await CredentialStorageService.getStoredEmail();
      final storedPassword = await CredentialStorageService.getStoredPassword();

      if (storedEmail == null || storedPassword == null) {
        debugPrint('  → No stored credentials found');
        return false;
      }

      debugPrint('  → Found stored credentials, attempting login...');

      // Perform auto-login
      final success = await ref.read(emailAuthProvider.notifier).signInUser(
            email: storedEmail,
            password: storedPassword,
          );

      if (success) {
        // Update last login time
        await CredentialStorageService.updateLastLoginTime();
        debugPrint('  → Auto-login successful');
        return true;
      } else {
        // Auto-login failed, clear stored credentials
        await CredentialStorageService.clearStoredCredentials();
        debugPrint('  → Auto-login failed, credentials cleared');
        return false;
      }
    } catch (e) {
      debugPrint('  → Auto-login error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<EmailAuthState>(emailAuthProvider, (previous, next) {
      // Only navigate if we're still on splash screen
      if (!mounted) return;

      // Check if auth state has been determined
      if (next.isAuthenticated && next.user != null) {
        // User is authenticated, go to home
        context.go('/home');
      } else if (previous?.isAuthenticated != next.isAuthenticated &&
          !next.isAuthenticated) {
        // User is not authenticated, go to login
        context.go('/auth/email-login');
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.accentColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(90),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(90),
                                border: Border.all(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.2),
                                  width: 3,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Image.asset(
                                  'assets/images/DPA.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.school,
                                      size: 80,
                                      color: AppTheme.primaryColor,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // App Name
                    Text(
                      'Dakshin Postal Academy',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // App Tagline
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                            AppTheme.accentColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Diligence to Dak',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading Indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Loading Text
                    Text(
                      'Loading...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
