import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/email_auth_provider.dart';
import '../../../core/services/firebase_email_auth_service.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/services/demo_account_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/secure_screen_wrapper.dart';
import '../../../core/widgets/custom_snackbar.dart';

/// Custom clipper for curved top edges (for bottom app bar)
class CurvedTopClipper extends CustomClipper<Path> {
  final double offset;

  CurvedTopClipper({this.offset = 0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 60 + offset);

    // Create curved top edge
    final firstControlPoint = Offset(size.width * 0.25, 30 + offset);
    final firstEndPoint = Offset(size.width * 0.5, 40 + offset);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, 50 + offset);
    final secondEndPoint = Offset(size.width, 20 + offset);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // State variables
  bool _obscurePassword = true;
  bool _rememberMe = true; // Default to true for one-time login experience

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadStoredCredentials();
  }

  /// Load stored credentials if remember me was enabled
  Future<void> _loadStoredCredentials() async {
    try {
      final rememberMeEnabled =
          await CredentialStorageService.isRememberMeEnabled();
      final storedEmail = await CredentialStorageService.getStoredEmail();

      if (rememberMeEnabled && storedEmail != null) {
        setState(() {
          _rememberMe = true;
          _emailController.text = storedEmail;
        });

        // Check if auto-login is enabled
        final autoLoginEnabled =
            await CredentialStorageService.isAutoLoginEnabled();
        if (autoLoginEnabled) {
          // Attempt auto-login after a short delay to allow UI to render
          Future.delayed(const Duration(milliseconds: 500), () {
            _attemptAutoLogin();
          });
        }
      }
    } catch (e) {
      // Handle error silently, user can still login manually
      print('DEBUG: ⚠️ Error loading stored credentials: $e');
    }
  }

  /// Attempt automatic login using stored credentials
  Future<void> _attemptAutoLogin() async {
    try {
      final storedEmail = await CredentialStorageService.getStoredEmail();
      final storedPassword = await CredentialStorageService.getStoredPassword();

      if (storedEmail == null || storedPassword == null) {
        return;
      }

      // Show loading indicator
      if (mounted) {
        CustomSnackbar.showInfo(context, 'Welcome back! Signing you in...');
      }

      // Perform auto-login
      final success = await ref.read(emailAuthProvider.notifier).signInUser(
            email: storedEmail,
            password: storedPassword,
          );

      if (mounted) {
        if (success) {
          // Update last login time
          await CredentialStorageService.updateLastLoginTime();

          // Check if there's a quiz to return to
          if (mounted) {
            final extra = GoRouterState.of(context).extra;
            String? returnToQuizId;

            if (extra is Map && extra.containsKey('returnToQuizId')) {
              returnToQuizId = extra['returnToQuizId'] as String?;
            }

            if (returnToQuizId != null && returnToQuizId.isNotEmpty) {
              // Navigate back to quiz instructions
              context.goNamed('quiz-instructions',
                  pathParameters: {'quizId': returnToQuizId});
            } else {
              // Navigate to home
              context.go('/home');
            }
          }
        } else {
          // Auto-login failed, clear stored credentials and let user login manually
          await CredentialStorageService.clearStoredCredentials();
          if (mounted) {
            CustomSnackbar.showWarning(
                context, 'Auto-login failed. Please sign in manually.');
          }
        }
      }
    } catch (e) {
      print('DEBUG: ❌ Auto-login error: $e');
      if (mounted) {
        CustomSnackbar.showWarning(context, 'Please sign in manually.');
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(emailAuthProvider);

    return SecureScreenWrapper(
      enableScreenshotPrevention: true,
      enableScreenRecordingPrevention: true,
      showWarningOnRecording: true,
      customWarningMessage:
          'Screenshots and screen recording are not allowed during login for security purposes.',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 24.0,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48.0,
                      ),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 60),
                              _buildHeader(),
                              const SizedBox(height: 40),
                              _buildLoginForm(),
                              const SizedBox(height: 16),
                              _buildRememberMeAndForgotPassword(),
                              const SizedBox(height: 32),
                              _buildLoginButton(authState),
                              const SizedBox(height: 24),
                              _buildRegisterLink(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildCurvedBottomBar(),
      ),
    );
  }

  Widget _buildCurvedBottomBar() {
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          // First layer (background) - Darker gradient
          ClipPath(
            clipper: CurvedTopClipper(offset: 10),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                    AppTheme.primaryColor.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          // Second layer (foreground) - Brighter gradient
          ClipPath(
            clipper: CurvedTopClipper(),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.9),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'Secure Login',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: Image.asset(
            'assets/images/DPA.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.login_rounded,
                size: 48,
                color: AppTheme.primaryColor,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to Dakshin Postal Academy',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!FirebaseEmailAuthService.isValidEmail(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: AppTheme.textSecondaryColor,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.poppins(
        color: AppTheme.textPrimaryColor,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        suffixIcon: suffixIcon,
        labelStyle: GoogleFonts.poppins(
          color: AppTheme.textSecondaryColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        filled: true,
        fillColor: AppTheme.cardColor,
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            Text(
              'Remember me',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: _showForgotPasswordDialog,
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.poppins(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(EmailAuthState authState) {
    return ElevatedButton(
      onPressed: authState.isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: authState.isLoggingIn
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Signing In...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Text(
              'Sign In',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: GoogleFonts.poppins(
            color: AppTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/auth/email-register'),
          child: Text(
            'Create Account',
            style: GoogleFonts.poppins(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.lightImpact();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(emailAuthProvider.notifier).signInUser(
          email: email,
          password: password,
        );

    if (mounted) {
      if (success) {
        // Store credentials if remember me is checked
        if (_rememberMe) {
          try {
            await CredentialStorageService.storeCredentials(
              email: email,
              password: password,
              rememberMe: true,
              enableAutoLogin:
                  true, // Enable auto-login for one-time login experience
            );
            if (kDebugMode) {
              print('DEBUG: ✅ Credentials stored for auto-login');
            }
          } catch (e) {
            // Handle credential storage error silently
            if (kDebugMode) {
              print('DEBUG: ⚠️ Failed to store credentials: $e');
            }
          }
        } else {
          // Clear stored credentials if remember me is unchecked
          await CredentialStorageService.clearStoredCredentials();
        }

        // Check if there's a quiz to return to
        if (mounted) {
          final extra = GoRouterState.of(context).extra;
          String? returnToQuizId;

          if (extra is Map && extra.containsKey('returnToQuizId')) {
            returnToQuizId = extra['returnToQuizId'] as String?;
          }

          if (returnToQuizId != null && returnToQuizId.isNotEmpty) {
            // Navigate back to quiz instructions
            context.goNamed('quiz-instructions',
                pathParameters: {'quizId': returnToQuizId});
          } else {
            // Navigate to home screen
            context.go('/home');
          }
        }
      } else {
        final authState = ref.read(emailAuthProvider);
        if (authState.error != null) {
          // Check if error is due to email not verified
          if (authState.error!.contains('verify your email')) {
            // Navigate to email verification screen
            context.go('/auth/email-verification', extra: {
              'email': email,
            });
          } else {
            _showErrorSnackbar(authState.error!);
          }
        }
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty &&
                  FirebaseEmailAuthService.isValidEmail(email)) {
                Navigator.of(context).pop();
                try {
                  final result =
                      await FirebaseEmailAuthService.sendPasswordReset(email);
                  if (mounted) {
                    if (result['success'] == true) {
                      _showSuccessSnackbar(
                          'Password reset email sent to $email');
                    } else {
                      _showErrorSnackbar(result['message'] ??
                          'Failed to send password reset email');
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackbar(
                        'Failed to send password reset email: ${e.toString()}');
                  }
                }
              } else {
                _showErrorSnackbar('Please enter a valid email address');
              }
            },
            child: Text(
              'Send Reset Link',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
