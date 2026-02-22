import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/security_service.dart';

/// Simple test app to verify screenshot protection
class ScreenshotProtectionTestApp extends StatelessWidget {
  const ScreenshotProtectionTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screenshot Protection Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ScreenshotTestScreen(),
    );
  }
}

class ScreenshotTestScreen extends StatefulWidget {
  const ScreenshotTestScreen({super.key});

  @override
  State<ScreenshotTestScreen> createState() => _ScreenshotTestScreenState();
}

class _ScreenshotTestScreenState extends State<ScreenshotTestScreen> {
  bool _isProtectionEnabled = false;
  String _statusMessage = 'Screenshot protection is OFF';

  @override
  void initState() {
    super.initState();
    _enableProtectionOnStart();
  }

  Future<void> _enableProtectionOnStart() async {
    try {
      await SecurityService.enableScreenProtection();
      setState(() {
        _isProtectionEnabled = true;
        _statusMessage = 'Screenshot protection is ON - Try taking a screenshot!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error enabling protection: $e';
      });
    }
  }

  Future<void> _toggleProtection() async {
    try {
      if (_isProtectionEnabled) {
        await SecurityService.disableScreenProtection();
        setState(() {
          _isProtectionEnabled = false;
          _statusMessage = 'Screenshot protection is OFF - Screenshots allowed';
        });
      } else {
        await SecurityService.enableScreenProtection();
        setState(() {
          _isProtectionEnabled = true;
          _statusMessage = 'Screenshot protection is ON - Try taking a screenshot!';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error toggling protection: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot Protection Test'),
        backgroundColor: _isProtectionEnabled ? Colors.green : Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isProtectionEnabled ? Icons.security : Icons.no_encryption,
              size: 100,
              color: _isProtectionEnabled ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 30),
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue),
              ),
              child: const Column(
                children: [
                  Text(
                    'CONFIDENTIAL CONTENT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'This content should NOT appear in screenshots when protection is enabled.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '🔒 Secret Quiz Questions 🔒',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _toggleProtection,
              icon: Icon(_isProtectionEnabled ? Icons.lock_open : Icons.lock),
              label: Text(_isProtectionEnabled ? 'Disable Protection' : 'Enable Protection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isProtectionEnabled ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Instructions:\n'
              '1. Enable protection using the button above\n'
              '2. Try taking a screenshot (Power + Volume Down)\n'
              '3. Check if the screenshot is blocked or shows black screen\n'
              '4. Toggle protection off and try again',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Main function for testing screenshot protection
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize security service
  try {
    await SecurityService.initialize();
    debugPrint('Security service initialized for testing');
  } catch (e) {
    debugPrint('Error initializing security service: $e');
  }
  
  runApp(const ScreenshotProtectionTestApp());
}
