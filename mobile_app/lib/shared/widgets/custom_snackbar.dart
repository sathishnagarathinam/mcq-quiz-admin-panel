import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom snackbar utility class
class CustomSnackbar {
  /// Show success snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
      action: action,
    );
  }

  /// Show error snackbar
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: duration,
      action: action,
    );
  }

  /// Show warning snackbar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: duration,
      action: action,
    );
  }

  /// Show info snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      duration: duration,
      action: action,
    );
  }

  /// Show custom snackbar
  static void showCustom(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
      duration: duration,
      action: action,
    );
  }

  /// Internal method to show snackbar
  static void _showSnackbar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
  }) {
    // Remove any existing snackbar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final snackBar = SnackBar(
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Snackbar with custom widget content
class CustomWidgetSnackbar {
  /// Show snackbar with custom widget
  static void show(
    BuildContext context, {
    required Widget content,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    // Remove any existing snackbar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final snackBar = SnackBar(
      content: content,
      backgroundColor: backgroundColor ?? colorScheme.inverseSurface,
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: margin ?? const EdgeInsets.all(16),
      padding: padding,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Loading snackbar
class LoadingSnackbar {
  /// Show loading snackbar
  static void show(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    // Remove any existing snackbar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
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
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[800],
      duration: duration ?? const Duration(days: 1), // Long duration for loading
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Hide loading snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }
}

/// Snackbar with action button
class ActionSnackbar {
  /// Show snackbar with action
  static void show(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onActionPressed,
    Color? backgroundColor,
    Color? actionColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Remove any existing snackbar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? colorScheme.inverseSurface,
      duration: duration,
      action: SnackBarAction(
        label: actionLabel,
        textColor: actionColor ?? colorScheme.primary,
        onPressed: onActionPressed,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Persistent snackbar that stays until dismissed
class PersistentSnackbar {
  /// Show persistent snackbar
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    IconData? icon,
    bool showCloseButton = true,
  }) {
    // Remove any existing snackbar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          if (showCloseButton)
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
      backgroundColor: backgroundColor ?? colorScheme.inverseSurface,
      duration: const Duration(days: 1), // Very long duration
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Hide persistent snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }
}
