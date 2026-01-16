import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple test script to verify Firebase configuration
/// Run with: flutter run test_firebase_config.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
    
    // Test Firebase Auth instance
    final auth = FirebaseAuth.instance;
    print('✅ Firebase Auth instance created');
    
    // Test with a known test phone number
    print('🧪 Testing with test phone number: +919876543210');
    
    await auth.verifyPhoneNumber(
      phoneNumber: '+919876543210',
      verificationCompleted: (PhoneAuthCredential credential) {
        print('✅ Auto-verification completed');
      },
      verificationFailed: (FirebaseAuthException e) {
        print('❌ Verification failed: ${e.code} - ${e.message}');
        if (e.code == 'app-not-authorized') {
          print('🔧 SOLUTION: Add SHA fingerprints to Firebase Console');
          print('📖 See FIREBASE_AUTH_FIX.md for detailed instructions');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        print('✅ Code sent successfully');
        print('📱 Verification ID: ${verificationId.substring(0, 10)}...');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('⏰ Auto-retrieval timeout');
      },
      timeout: const Duration(seconds: 30),
    );
    
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('🔧 Check your google-services.json configuration');
  }
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Config Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Configuration Test'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.firebase, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Firebase Configuration Test',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Check console output for results',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
