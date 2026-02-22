import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/interstitial_ad_model.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Full-screen interstitial ad dialog
class InterstitialAdDialog extends StatefulWidget {
  final InterstitialAdModel ad;
  final VoidCallback? onClose;

  const InterstitialAdDialog({
    super.key,
    required this.ad,
    this.onClose,
  });

  /// Show the interstitial ad dialog
  static Future<void> show(BuildContext context, InterstitialAdModel ad) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => InterstitialAdDialog(ad: ad),
    );
  }

  @override
  State<InterstitialAdDialog> createState() => _InterstitialAdDialogState();
}

class _InterstitialAdDialogState extends State<InterstitialAdDialog>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.ad.displayDurationSeconds;
    _startTimer();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  void _handleTap() {
    Navigator.of(context).pop();
    widget.onClose?.call();

    // Navigate to exam if examId is provided
    if (widget.ad.examId != null && widget.ad.examId!.isNotEmpty) {
      context.goToQuizInstructions(widget.ad.examId!);
    }
  }

  void _handleClose() {
    Navigator.of(context).pop();
    widget.onClose?.call();
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'campaign':
        return Icons.campaign;
      case 'star':
        return Icons.star;
      case 'celebration':
        return Icons.celebration;
      case 'local_offer':
        return Icons.local_offer;
      case 'quiz':
        return Icons.quiz;
      case 'school':
        return Icons.school;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'flash_on':
        return Icons.flash_on;
      case 'new_releases':
        return Icons.new_releases;
      default:
        return Icons.campaign;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _parseColor(widget.ad.primaryColor);
    final secondaryColor = _parseColor(widget.ad.secondaryColor);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: _buildDialogContent(primaryColor, secondaryColor),
      ),
    );
  }

  Widget _buildDialogContent(Color primaryColor, Color secondaryColor) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: _buildDialogBody(primaryColor),
    );
  }

  Widget _buildDialogBody(Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close button row
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_remainingSeconds > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Skip in $_remainingSeconds',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: _handleClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: GestureDetector(
            onTap: _handleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconData(widget.ad.iconName),
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    widget.ad.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    widget.ad.description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  // CTA Button
                  if (widget.ad.examId != null && widget.ad.examId!.isNotEmpty)
                    ElevatedButton(
                      onPressed: _handleTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Check it out!',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
