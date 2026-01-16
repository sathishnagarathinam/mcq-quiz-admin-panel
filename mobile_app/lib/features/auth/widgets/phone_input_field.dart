import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_code_picker/country_code_picker.dart';

import '../../../core/theme/app_theme.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<CountryCode>? onCountryChanged;
  final String initialCountryCode;
  final List<String>? favoriteCountries;
  final bool enabled;
  final bool readOnly;
  final TextInputAction textInputAction;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.onCountryChanged,
    this.initialCountryCode = 'IN',
    this.favoriteCountries,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction = TextInputAction.done,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late String _selectedCountryCode;
  late String _selectedDialCode;

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = widget.initialCountryCode;
    _selectedDialCode = '+91'; // Default for India
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? AppTheme.errorColor
                  : AppTheme.borderColor,
              width: widget.errorText != null ? 2 : 1,
            ),
            color: widget.enabled
                ? AppTheme.surfaceColor
                : AppTheme.surfaceColor.withValues(alpha: 0.5),
          ),
          child: Row(
            children: [
              // Country Code Picker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CountryCodePicker(
                  onChanged: (country) {
                    setState(() {
                      _selectedCountryCode = country.code!;
                      _selectedDialCode = country.dialCode!;
                    });
                    widget.onCountryChanged?.call(country);
                  },
                  initialSelection: widget.initialCountryCode,
                  favorite: widget.favoriteCountries ?? ['+91', 'IN'],
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  alignLeft: false,
                  enabled: widget.enabled,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  dialogTextStyle: GoogleFonts.poppins(),
                  searchStyle: GoogleFonts.poppins(),
                  flagDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  dialogBackgroundColor: colorScheme.surface,
                  barrierColor: Colors.black54,
                  dialogSize: Size(
                    MediaQuery.of(context).size.width * 0.9,
                    MediaQuery.of(context).size.height * 0.6,
                  ),
                ),
              ),

              // Divider
              Container(
                height: 30,
                width: 1,
                color: widget.errorText != null
                    ? AppTheme.errorColor.withValues(alpha: 0.5)
                    : AppTheme.borderColor,
              ),

              // Phone Number Field
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  keyboardType: TextInputType.phone,
                  textInputAction: widget.textInputAction,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint ?? '9876543210',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                    PhoneNumberFormatter(),
                  ],
                  onChanged: widget.onChanged,
                  onFieldSubmitted: widget.onSubmitted,
                ),
              ),
            ],
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: AppTheme.errorColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String get selectedDialCode => _selectedDialCode;
  String get selectedCountryCode => _selectedCountryCode;
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Remove any non-digit characters
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 10 digits
    final limitedDigits =
        digitsOnly.length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;

    // Format the number
    String formatted = '';
    for (int i = 0; i < limitedDigits.length; i++) {
      if (i == 5 && limitedDigits.length > 5) {
        formatted += ' ';
      }
      formatted += limitedDigits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AnimatedPhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<CountryCode>? onCountryChanged;
  final String initialCountryCode;
  final bool enabled;
  final Duration animationDuration;

  const AnimatedPhoneInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.onCountryChanged,
    this.initialCountryCode = 'IN',
    this.enabled = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedPhoneInputField> createState() =>
      _AnimatedPhoneInputFieldState();
}

class _AnimatedPhoneInputFieldState extends State<AnimatedPhoneInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  // late Animation<Color?> _colorAnimation; // Unused for now

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    widget.focusNode?.addListener(_onFocusChange);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // _colorAnimation = ColorTween(
    //   begin: AppTheme.borderColor,
    //   end: AppTheme.primaryColor,
    // ).animate(CurvedAnimation(
    //   parent: _animationController,
    //   curve: Curves.easeInOut,
    // )); // Unused for now
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode?.hasFocus ?? false;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: PhoneInputField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              label: widget.label,
              hint: widget.hint,
              errorText: widget.errorText,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onCountryChanged: widget.onCountryChanged,
              initialCountryCode: widget.initialCountryCode,
              enabled: widget.enabled,
            ),
          ),
        );
      },
    );
  }
}
