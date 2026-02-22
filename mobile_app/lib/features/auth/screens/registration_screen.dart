import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider_minimal.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../widgets/animated_background.dart';
import '../widgets/phone_input_field.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final String? phoneNumber;
  final String? countryCode;

  const RegistrationScreen({
    super.key,
    this.phoneNumber,
    this.countryCode,
  });

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _officeNameController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _officeNameFocusNode = FocusNode();

  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedDesignation = 'GDS';
  String _countryCode = '+91';

  final List<String> _designations = [
    'GDS',
    'MTS',
    'Postman',
    'Postal Assistant',
    'Inspector',
    'ASP',
    'SP',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // If phone number is passed from login flow, populate it
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      // Extract phone number without country code
      String phoneWithoutCode = widget.phoneNumber!;
      if (widget.countryCode != null) {
        phoneWithoutCode =
            widget.phoneNumber!.replaceFirst(widget.countryCode!, '');
      }
      _phoneController.text = phoneWithoutCode;
      _countryCode = widget.countryCode ?? '+91';
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
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _officeNameController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _officeNameFocusNode.dispose();
    super.dispose();
  }

  /// Validate phone number format
  bool _isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it starts with + and has country code
    if (!cleanNumber.startsWith('+')) return false;

    // Check if it has at least 10 digits after country code
    final digitsOnly = cleanNumber.substring(1); // Remove +
    if (digitsOnly.length < 10 || digitsOnly.length > 15) return false;

    // Check if all characters after + are digits
    return RegExp(r'^\d+$').hasMatch(digitsOnly);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Account',
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildRegistrationForm(authState),
                        const SizedBox(height: 30),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Lottie Animation
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(75),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/DPA.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person_add,
                      size: 60,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Welcome Text
            Text(
              'Join Dak-shin Postal Academy',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Create your account to start learning',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(AuthState authState) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name Field
                CustomTextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  onSubmitted: (_) => _emailFocusNode.requestFocus(),
                ),
                const SizedBox(height: 20),

                // Email Field
                EmailTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                ),
                const SizedBox(height: 20),

                // Phone Number Field
                PhoneInputField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  label: 'Phone Number',
                  hint: '9876543210',
                  onCountryChanged: (country) {
                    setState(() {
                      _countryCode = country.dialCode!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Office Name Field
                CustomTextField(
                  controller: _officeNameController,
                  focusNode: _officeNameFocusNode,
                  label: 'Office Name',
                  hint: 'Enter your office name',
                  prefixIcon: const Icon(Icons.business_outlined),
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Office name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Designation Dropdown
                _buildDesignationDropdown(),

                if (authState.error != null) ...[
                  const SizedBox(height: 20),
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

                const SizedBox(height: 30),

                // Register Button
                LoadingButton(
                  text: 'Create Account',
                  isLoading: authState.isLoading,
                  onPressed: _register,
                  expanded: true,
                  icon: const Icon(Icons.person_add, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Designation',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
            color: AppTheme.surfaceColor,
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedDesignation,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.work_outline),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textPrimaryColor,
            ),
            dropdownColor: AppTheme.surfaceColor,
            items: _designations.map((designation) {
              return DropdownMenuItem<String>(
                value: designation,
                child: Text(
                  designation,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDesignation = value!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a designation';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/auth/login'),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'By creating an account, you agree to our',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  // Navigate to terms
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  'Terms of Service',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              Text(
                ' and ',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to privacy policy
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  'Privacy Policy',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phoneNumber =
        '$_countryCode${_phoneController.text.trim().replaceAll(' ', '')}';

    // Validate phone number format
    if (!_isValidPhoneNumber(phoneNumber)) {
      CustomSnackbar.showError(
        context,
        'Please enter a valid phone number with country code (e.g., +919876543210)',
      );
      return;
    }

    // Haptic feedback
    HapticFeedback.lightImpact();

    final userData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'officeName': _officeNameController.text.trim(),
      'designation': _selectedDesignation,
      'phoneNumber': phoneNumber,
    };
    final success = await ref
        .read(authProvider.notifier)
        .registerWithPhone(phoneNumber, userData);

    if (success && mounted) {
      // Show success message
      CustomSnackbar.showSuccess(
        context,
        'Registration successful! Please verify your phone number.',
      );

      // Navigate to OTP screen for registration verification
      context.pushReplacement('/auth/registration-otp', extra: {
        'phoneNumber': phoneNumber,
        'countryCode': _countryCode,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'officeName': _officeNameController.text.trim(),
        'designation': _selectedDesignation,
      });
    } else if (mounted) {
      // Show error snackbar
      final error = ref.read(authProvider).error ?? 'Registration failed';
      if (error.contains('not authorized') ||
          error.contains('Invalid app info')) {
        _showFirebaseConfigDialog();
      } else {
        CustomSnackbar.showError(context, error);
      }
    }
  }

  void _showFirebaseConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '🔧 Firebase Configuration Issue',
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
                'Your app is not authorized for Firebase Authentication.',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🚀 IMMEDIATE SOLUTION:',
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use these test phone numbers:\n• +919876543210 → OTP: 123456\n• +911234567890 → OTP: 654321\n• +919999999999 → OTP: 111111',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🔧 TO FIX PERMANENTLY:',
                style: GoogleFonts.poppins(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Get your app\'s SHA-1 fingerprint\n2. Add it to Firebase Console\n3. Download new google-services.json\n4. Rebuild the app\n\nSee FIREBASE_AUTH_FIX.md for details.',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 13,
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
        ],
      ),
    );
  }
}
