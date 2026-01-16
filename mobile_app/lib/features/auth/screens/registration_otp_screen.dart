import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider_minimal.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../widgets/animated_background.dart';

class RegistrationOtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final String name;
  final String email;
  final String officeName;
  final String designation;

  const RegistrationOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    required this.name,
    required this.email,
    required this.officeName,
    required this.designation,
  });

  @override
  ConsumerState<RegistrationOtpScreen> createState() =>
      _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends ConsumerState<RegistrationOtpScreen>
    with TickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _timer;
  int _remainingTime = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startTimer();

    // Auto focus on OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _otpController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Verify Registration',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildOtpForm(authState),
                    const SizedBox(height: 30),
                    _buildResendSection(),
                    const SizedBox(height: 40),
                    _buildRegistrationInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Registration Icon with Animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentColor,
                      AppTheme.primaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          'Complete Registration',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Subtitle with phone number
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'We sent a verification code to\n'),
              TextSpan(
                text: widget.phoneNumber,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpForm(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Enter Verification Code',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // OTP Input
          Pinput(
            controller: _otpController,
            focusNode: _focusNode,
            length: 6,
            defaultPinTheme: _defaultPinTheme,
            focusedPinTheme: _focusedPinTheme,
            submittedPinTheme: _submittedPinTheme,
            errorPinTheme: _errorPinTheme,
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            onCompleted: (pin) => _verifyRegistrationOTP(pin),
            onChanged: (value) {
              if (authState.error != null) {
                ref.read(authProvider.notifier).clearError();
              }
            },
          ),

          if (authState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authState.error!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Verify Button
          LoadingButton(
            text: 'Complete Registration',
            isLoading: authState.isLoading,
            onPressed: () => _verifyRegistrationOTP(_otpController.text),
            expanded: true,
            icon: const Icon(Icons.check_circle, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        if (!_canResend) ...[
          Text(
            'Resend code in ${_remainingTime}s',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the code? ",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              TextButton(
                onPressed: _resendOTP,
                child: Text(
                  'Resend',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: _showTroubleshootingDialog,
          child: Text(
            'Not receiving OTP? Get help',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Registration Details',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Name', widget.name),
          _buildInfoRow('Email', widget.email),
          _buildInfoRow('Office', widget.officeName),
          _buildInfoRow('Designation', widget.designation),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pin themes (same as OTP verification screen)
  PinTheme get _defaultPinTheme => PinTheme(
        width: 56,
        height: 56,
        textStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
        decoration: BoxDecoration(
          color: AppTheme.secondaryLightColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
      );

  PinTheme get _focusedPinTheme => _defaultPinTheme.copyWith(
        decoration: _defaultPinTheme.decoration!.copyWith(
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );

  PinTheme get _submittedPinTheme => _defaultPinTheme.copyWith(
        decoration: _defaultPinTheme.decoration!.copyWith(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 1,
          ),
        ),
      );

  PinTheme get _errorPinTheme => _defaultPinTheme.copyWith(
        decoration: _defaultPinTheme.decoration!.copyWith(
          border: Border.all(
            color: AppTheme.errorColor,
            width: 2,
          ),
        ),
      );

  Future<void> _verifyRegistrationOTP(String otp) async {
    if (otp.length != 6) {
      CustomSnackbar.showError(context, 'Please enter a valid 6-digit OTP');
      return;
    }

    HapticFeedback.lightImpact();

    // Use the dedicated registration OTP verification method
    final userData = {
      'name': widget.name,
      'email': widget.email,
      'officeName': widget.officeName,
      'designation': widget.designation,
    };
    final success = await ref
        .read(authProvider.notifier)
        .verifyRegistrationOTP(otp, userData);

    if (success && mounted) {
      // Show success message
      CustomSnackbar.showSuccess(
          context, 'Registration completed successfully! Welcome to MCQ Quiz!');

      // Navigate to login screen
      context.go('/auth/login');
    } else if (mounted) {
      // Show error message if available
      final authState = ref.read(authProvider);
      if (authState.error != null) {
        if (authState.error!.contains('session expired') ||
            authState.error!.contains('Verification session expired')) {
          _showSessionExpiredDialog();
        } else {
          CustomSnackbar.showError(context, authState.error!);
        }
      }

      // Clear OTP field on error
      _otpController.clear();
      _focusNode.requestFocus();
    }
  }

  Future<void> _resendOTP() async {
    HapticFeedback.lightImpact();

    final phoneNumber = '${widget.countryCode}${widget.phoneNumber}';
    final success = await ref
        .read(authProvider.notifier)
        .resendRegistrationOTP(phoneNumber);

    if (success && mounted) {
      setState(() {
        _remainingTime = 60;
        _canResend = false;
      });
      _startTimer();

      CustomSnackbar.showSuccess(
        context,
        'OTP resent successfully! Please check your SMS.',
      );
    } else if (mounted) {
      // Show error message if available
      final authState = ref.read(authProvider);
      if (authState.error != null) {
        if (authState.error!.contains('session expired') ||
            authState.error!.contains('Verification session expired')) {
          _showSessionExpiredDialog();
        } else {
          CustomSnackbar.showError(context, authState.error!);
        }
      } else {
        CustomSnackbar.showError(
            context, 'Failed to resend OTP. Please try again.');
      }
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Session Expired',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        content: Text(
          'Your verification session has expired. Please restart the registration process.',
          style: GoogleFonts.poppins(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/register');
            },
            child: Text(
              'Restart Registration',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTroubleshootingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'OTP Troubleshooting',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'If you\'re not receiving the OTP, try these steps:',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _buildTroubleshootingStep('1. Check your SMS/Messages app'),
              _buildTroubleshootingStep('2. Check spam/junk folder'),
              _buildTroubleshootingStep('3. Ensure stable internet connection'),
              _buildTroubleshootingStep(
                  '4. Try switching between WiFi and mobile data'),
              _buildTroubleshootingStep(
                  '5. Wait 2-3 minutes and try resending'),
              _buildTroubleshootingStep('6. Restart the app if needed'),
              const SizedBox(height: 12),
              Text(
                'Still having issues? Contact support or try registering again.',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/register');
            },
            child: Text(
              'Start Over',
              style: GoogleFonts.poppins(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingStep(String step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              step,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondaryColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
