import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';

/// Global Security Wrapper that applies security measures to the entire app
/// This wrapper ensures screenshot prevention and other security features are active globally
class GlobalSecurityWrapper extends StatefulWidget {
  final Widget child;

  const GlobalSecurityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<GlobalSecurityWrapper> createState() => _GlobalSecurityWrapperState();
}

class _GlobalSecurityWrapperState extends State<GlobalSecurityWrapper>
    with WidgetsBindingObserver {
  bool _isSecurityEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableGlobalSecurity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableGlobalSecurity();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // Re-enable security when app comes to foreground
        _enableGlobalSecurity();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Keep security enabled even when app is paused/inactive
        break;
      case AppLifecycleState.detached:
        _disableGlobalSecurity();
        break;
      case AppLifecycleState.hidden:
        // Keep security enabled when app is hidden
        break;
    }
  }

  Future<void> _enableGlobalSecurity() async {
    if (_isSecurityEnabled) return;

    try {
      debugPrint('🛡️ Attempting to enable global security...');

      // Enable screenshot prevention globally
      await SecurityService.enableScreenProtection();

      // Log security activation
      SecurityService.logSecurityEvent(
        'global_security_enabled',
        {'timestamp': DateTime.now().toIso8601String()},
      );

      setState(() {
        _isSecurityEnabled = true;
      });

      debugPrint(
          '🛡️ Global security enabled successfully - Screenshots should now be blocked');
    } catch (e) {
      debugPrint('❌ Error enabling global security: $e');
    }
  }

  Future<void> _disableGlobalSecurity() async {
    if (!_isSecurityEnabled) return;

    try {
      // Disable screenshot prevention
      await SecurityService.preventScreenshots(false);
      await SecurityService.preventScreenRecording(false);

      setState(() {
        _isSecurityEnabled = false;
      });

      debugPrint('🛡️ Global security disabled');
    } catch (e) {
      debugPrint('❌ Error disabling global security: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Security status indicator (only in debug mode)
        if (kDebugMode && _isSecurityEnabled)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.security,
                    size: 12,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'SECURE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Enhanced Security Wrapper for critical screens (quiz, payment, etc.)
class CriticalSecurityWrapper extends StatefulWidget {
  final Widget child;
  final String screenName;
  final VoidCallback? onSecurityBreach;

  const CriticalSecurityWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.onSecurityBreach,
  });

  @override
  State<CriticalSecurityWrapper> createState() =>
      _CriticalSecurityWrapperState();
}

class _CriticalSecurityWrapperState extends State<CriticalSecurityWrapper>
    with WidgetsBindingObserver {
  bool _isScreenRecordingDetected = false;
  int _securityViolations = 0;
  static const int _maxViolations = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSecurityMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Log potential security risk when app is backgrounded during critical operations
      SecurityService.logSecurityEvent(
        'app_backgrounded_during_critical_operation',
        {
          'screen': widget.screenName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  void _startSecurityMonitoring() {
    // Enhanced security monitoring for critical screens
    SecurityService.logSecurityEvent(
      'critical_screen_accessed',
      {
        'screen': widget.screenName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void _handleSecurityViolation(String violationType) {
    _securityViolations++;

    SecurityService.logSecurityEvent(
      'security_violation',
      {
        'type': violationType,
        'screen': widget.screenName,
        'violationCount': _securityViolations,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (_securityViolations >= _maxViolations) {
      // Trigger security breach protocol
      widget.onSecurityBreach?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Security violation overlay
        if (_isScreenRecordingDetected)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security,
                      size: 64,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Security Violation Detected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Screen recording or unauthorized access detected.\nPlease stop recording to continue.',
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
