import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'lib/core/services/firebase_realtime_auth_service.dart';

/// Test script to verify test phone numbers work without Firebase
void main() {
  runApp(const TestAuthApp());
}

class TestAuthApp extends StatelessWidget {
  const TestAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Test',
      home: const TestAuthScreen(),
    );
  }
}

class TestAuthScreen extends StatefulWidget {
  const TestAuthScreen({super.key});

  @override
  State<TestAuthScreen> createState() => _TestAuthScreenState();
}

class _TestAuthScreenState extends State<TestAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _status = 'Ready to test';
  bool _otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Phone Numbers (Bypass Firebase):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• +919876543210 → OTP: 123456'),
            const Text('• +911234567890 → OTP: 654321'),
            const Text('• +919999999999 → OTP: 111111'),
            const SizedBox(height: 24),
            
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+919876543210',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _otpSent ? null : _sendOTP,
              child: const Text('Send OTP'),
            ),
            const SizedBox(height: 16),
            
            if (_otpSent) ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifyOTP,
                child: const Text('Verify OTP'),
              ),
            ],
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Status: $_status',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _status = 'Please enter a phone number';
      });
      return;
    }

    setState(() {
      _status = 'Sending OTP...';
    });

    try {
      await FirebaseRealtimeAuthService.sendRegistrationOTP(
        phoneNumber: phone,
        name: 'Test User',
        email: 'test@example.com',
        officeName: 'Test Office',
        designation: 'Tester',
        onCodeSent: (message) {
          setState(() {
            _status = 'SUCCESS: $message';
            _otpSent = true;
          });
        },
        onVerificationFailed: (error) {
          setState(() {
            _status = 'ERROR: $error';
          });
        },
        onVerificationCompleted: () {
          setState(() {
            _status = 'Auto-verification completed';
          });
        },
        onRegistrationSuccess: (user) {
          setState(() {
            _status = 'Registration successful: ${user.uid}';
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Exception: $e';
      });
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() {
        _status = 'Please enter OTP';
      });
      return;
    }

    setState(() {
      _status = 'Verifying OTP...';
    });

    try {
      final user = await FirebaseRealtimeAuthService.verifyRegistrationOTP(otp);
      if (user != null) {
        setState(() {
          _status = 'SUCCESS: OTP verified! User: ${user.uid}';
        });
      } else {
        setState(() {
          _status = 'OTP verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Verification error: $e';
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
