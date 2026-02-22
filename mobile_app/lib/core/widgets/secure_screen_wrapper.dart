import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/security_service.dart';

/// A wrapper widget that provides comprehensive security protection for sensitive screens
/// Automatically enables/disables screenshot and screen recording prevention
class SecureScreenWrapper extends StatefulWidget {
  final Widget child;
  final bool enableScreenshotPrevention;
  final bool enableScreenRecordingPrevention;
  final bool showWarningOnRecording;
  final VoidCallback? onSecurityBreach;
  final String? customWarningMessage;

  const SecureScreenWrapper({
    Key? key,
    required this.child,
    this.enableScreenshotPrevention = true,
    this.enableScreenRecordingPrevention = true,
    this.showWarningOnRecording = true,
    this.onSecurityBreach,
    this.customWarningMessage,
  }) : super(key: key);

  @override
  State<SecureScreenWrapper> createState() => _SecureScreenWrapperState();
}

class _SecureScreenWrapperState extends State<SecureScreenWrapper>
    with WidgetsBindingObserver {
  Timer? _screenRecordingCheckTimer;
  bool _isScreenRecordingDetected = false;
  bool _isSecurityEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecurity();
    _startSecurityMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableSecurity();
    _stopSecurityMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isSecurityEnabled) {
          _enableSecurity();
        }
        _startSecurityMonitoring();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _stopSecurityMonitoring();
        break;
      case AppLifecycleState.detached:
        _disableSecurity();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _enableSecurity() async {
    try {
      if (widget.enableScreenshotPrevention || widget.enableScreenRecordingPrevention) {
        await SecurityService.enableScreenProtection();
        _isSecurityEnabled = true;
        
        if (kDebugMode) {
          print('DEBUG: 🔒 Security protection enabled for screen');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error enabling security: $e');
      }
    }
  }

  Future<void> _disableSecurity() async {
    try {
      if (_isSecurityEnabled) {
        await SecurityService.disableScreenProtection();
        _isSecurityEnabled = false;
        
        if (kDebugMode) {
          print('DEBUG: 🔓 Security protection disabled for screen');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error disabling security: $e');
      }
    }
  }

  void _startSecurityMonitoring() {
    if (!widget.enableScreenRecordingPrevention) return;

    // Start iOS screen recording monitoring
    SecurityService.startScreenRecordingMonitoring();

    // Periodic check for screen recording (mainly for iOS)
    _screenRecordingCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        try {
          final isRecording = await SecurityService.isScreenRecordingActive();
          
          if (isRecording && !_isScreenRecordingDetected) {
            _handleScreenRecordingDetected();
          } else if (!isRecording && _isScreenRecordingDetected) {
            _handleScreenRecordingStopped();
          }
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: ❌ Error checking screen recording: $e');
          }
        }
      },
    );
  }

  void _stopSecurityMonitoring() {
    _screenRecordingCheckTimer?.cancel();
    _screenRecordingCheckTimer = null;
  }

  void _handleScreenRecordingDetected() {
    setState(() {
      _isScreenRecordingDetected = true;
    });

    if (widget.showWarningOnRecording) {
      _showSecurityWarning();
    }

    if (widget.onSecurityBreach != null) {
      widget.onSecurityBreach!();
    }

    if (kDebugMode) {
      print('DEBUG: ⚠️ Screen recording detected in secure screen');
    }
  }

  void _handleScreenRecordingStopped() {
    setState(() {
      _isScreenRecordingDetected = false;
    });

    if (kDebugMode) {
      print('DEBUG: ✅ Screen recording stopped');
    }
  }

  void _showSecurityWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.red),
            SizedBox(width: 8),
            Text('Security Alert'),
          ],
        ),
        content: Text(
          widget.customWarningMessage ??
              'Screen recording detected! This is not allowed during quiz sessions for security reasons. Please stop recording to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Overlay warning when screen recording is detected
        if (_isScreenRecordingDetected && widget.showWarningOnRecording)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off,
                      size: 64,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Screen Recording Detected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please stop recording to continue',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A specialized wrapper for quiz screens with enhanced security
class QuizSecureWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSecurityBreach;

  const QuizSecureWrapper({
    Key? key,
    required this.child,
    this.onSecurityBreach,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SecureScreenWrapper(
      enableScreenshotPrevention: true,
      enableScreenRecordingPrevention: true,
      showWarningOnRecording: true,
      onSecurityBreach: onSecurityBreach ?? () {
        // Default action: show warning and potentially exit quiz
        _handleQuizSecurityBreach(context);
      },
      customWarningMessage: 
          'Screen recording or screenshots are not allowed during quiz sessions. '
          'This is to maintain the integrity of the examination process.',
      child: child,
    );
  }

  void _handleQuizSecurityBreach(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Quiz Security Violation'),
          ],
        ),
        content: const Text(
          'A security violation has been detected. For the integrity of the examination, '
          'this quiz session may be terminated. Please ensure no screen recording or '
          'screenshot applications are running.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally navigate back to home or exit quiz
              // Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}

/// A specialized wrapper for results screens
class ResultsSecureWrapper extends StatelessWidget {
  final Widget child;

  const ResultsSecureWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SecureScreenWrapper(
      enableScreenshotPrevention: true,
      enableScreenRecordingPrevention: true,
      showWarningOnRecording: false, // Less intrusive for results
      customWarningMessage: 
          'Screenshots and screen recording are not allowed on results screens '
          'to protect sensitive information.',
      child: child,
    );
  }
}
