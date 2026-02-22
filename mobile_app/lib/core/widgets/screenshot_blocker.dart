import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/security_service.dart';

/// A comprehensive screenshot blocker widget that applies multiple layers of protection
class ScreenshotBlocker extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const ScreenshotBlocker({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ScreenshotBlocker> createState() => _ScreenshotBlockerState();
}

class _ScreenshotBlockerState extends State<ScreenshotBlocker>
    with WidgetsBindingObserver {
  Timer? _protectionTimer;
  bool _isProtectionActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enabled) {
      _enableProtection();
      _startProtectionTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _protectionTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (widget.enabled) {
      switch (state) {
        case AppLifecycleState.resumed:
        case AppLifecycleState.inactive:
          _enableProtection();
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
          _enableProtection(); // Keep protection even when paused
          break;
        case AppLifecycleState.hidden:
          _enableProtection();
          break;
      }
    }
  }

  void _startProtectionTimer() {
    // Re-enable protection every 5 seconds to ensure it stays active
    _protectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (widget.enabled && mounted) {
        _enableProtection();
      }
    });
  }

  Future<void> _enableProtection() async {
    if (!widget.enabled) return;
    
    try {
      await SecurityService.enableScreenProtection();
      
      // Additional platform-specific protection
      if (Platform.isAndroid) {
        await _enableAndroidProtection();
      } else if (Platform.isIOS) {
        await _enableIOSProtection();
      }
      
      setState(() {
        _isProtectionActive = true;
      });
      
      if (kDebugMode) {
        print('🛡️ ScreenshotBlocker: Protection enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ScreenshotBlocker: Error enabling protection: $e');
      }
    }
  }

  Future<void> _enableAndroidProtection() async {
    try {
      // Force enable screenshot prevention
      const platform = MethodChannel('security/screenshots');
      await platform.invokeMethod('preventScreenshots', true);
      
      // Additional Android-specific calls
      await platform.invokeMethod('preventScreenRecording', true);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Android protection error: $e');
      }
    }
  }

  Future<void> _enableIOSProtection() async {
    try {
      // iOS-specific protection
      const platform = MethodChannel('security/screenshots');
      await platform.invokeMethod('preventScreenshots', true);
    } catch (e) {
      if (kDebugMode) {
        print('❌ iOS protection error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        // Main content
        widget.child,
        
        // Invisible security overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.transparent,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        
        // Debug indicator (only in debug mode)
        if (kDebugMode)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _isProtectionActive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _isProtectionActive ? Icons.security : Icons.warning,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// Extension to easily wrap any widget with screenshot protection
extension ScreenshotProtection on Widget {
  Widget withScreenshotProtection({bool enabled = true}) {
    return ScreenshotBlocker(
      enabled: enabled,
      child: this,
    );
  }
}
