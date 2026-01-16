import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom loading button widget
class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final EdgeInsetsGeometry? padding;
  final Size? minimumSize;
  final Size? maximumSize;
  final BorderRadius? borderRadius;
  final Widget? icon;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool expanded;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.padding,
    this.minimumSize,
    this.maximumSize,
    this.borderRadius,
    this.icon,
    this.fontSize,
    this.fontWeight,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isDisabled = !enabled || isLoading || onPressed == null;

    Widget button = ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? colorScheme.primary,
        foregroundColor: foregroundColor ?? colorScheme.onPrimary,
        disabledBackgroundColor: disabledBackgroundColor ?? 
            colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: disabledForegroundColor ?? 
            colorScheme.onSurface.withOpacity(0.38),
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        minimumSize: minimumSize ?? const Size(120, 48),
        maximumSize: maximumSize,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        elevation: isDisabled ? 0 : 2,
        shadowColor: colorScheme.shadow.withOpacity(0.3),
      ),
      child: _buildButtonContent(context),
    );

    if (expanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading...',
            style: GoogleFonts.poppins(
              fontSize: fontSize ?? 16,
              fontWeight: fontWeight ?? FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: fontSize ?? 16,
              fontWeight: fontWeight ?? FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: fontSize ?? 16,
        fontWeight: fontWeight ?? FontWeight.w600,
      ),
    );
  }
}

/// Outlined loading button
class OutlinedLoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Color? borderColor;
  final Color? foregroundColor;
  final Color? disabledBorderColor;
  final Color? disabledForegroundColor;
  final EdgeInsetsGeometry? padding;
  final Size? minimumSize;
  final Size? maximumSize;
  final BorderRadius? borderRadius;
  final Widget? icon;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool expanded;

  const OutlinedLoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.borderColor,
    this.foregroundColor,
    this.disabledBorderColor,
    this.disabledForegroundColor,
    this.padding,
    this.minimumSize,
    this.maximumSize,
    this.borderRadius,
    this.icon,
    this.fontSize,
    this.fontWeight,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isDisabled = !enabled || isLoading || onPressed == null;

    Widget button = OutlinedButton(
      onPressed: isDisabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? colorScheme.primary,
        disabledForegroundColor: disabledForegroundColor ?? 
            colorScheme.onSurface.withOpacity(0.38),
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        minimumSize: minimumSize ?? const Size(120, 48),
        maximumSize: maximumSize,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: isDisabled 
              ? (disabledBorderColor ?? colorScheme.onSurface.withOpacity(0.12))
              : (borderColor ?? colorScheme.primary),
          width: 1,
        ),
      ),
      child: _buildButtonContent(context),
    );

    if (expanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading...',
            style: GoogleFonts.poppins(
              fontSize: fontSize ?? 16,
              fontWeight: fontWeight ?? FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: fontSize ?? 16,
              fontWeight: fontWeight ?? FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: fontSize ?? 16,
        fontWeight: fontWeight ?? FontWeight.w600,
      ),
    );
  }
}

/// Text loading button
class TextLoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Color? foregroundColor;
  final Color? disabledForegroundColor;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final double? fontSize;
  final FontWeight? fontWeight;

  const TextLoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.foregroundColor,
    this.disabledForegroundColor,
    this.padding,
    this.icon,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isDisabled = !enabled || isLoading || onPressed == null;

    return TextButton(
      onPressed: isDisabled ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor ?? colorScheme.primary,
        disabledForegroundColor: disabledForegroundColor ?? 
            colorScheme.onSurface.withOpacity(0.38),
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading...',
            style: GoogleFonts.poppins(
              fontSize: fontSize ?? 14,
              fontWeight: fontWeight ?? FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: fontSize ?? 14,
              fontWeight: fontWeight ?? FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.w500,
      ),
    );
  }
}
