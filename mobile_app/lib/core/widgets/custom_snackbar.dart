import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Custom Snackbar utility class for consistent messaging
class CustomSnackbar {
  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle_outline,
    );
  }

  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: AppTheme.errorColor,
      icon: Icons.error_outline,
    );
  }

  /// Show warning snackbar
  static void showWarning(BuildContext context, String message) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning_outlined,
    );
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: AppTheme.primaryColor,
      icon: Icons.info_outline,
    );
  }

  /// Internal method to show snackbar
  static void _showSnackbar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Remove any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
