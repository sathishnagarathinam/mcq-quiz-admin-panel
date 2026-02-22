import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';

/// Test app to verify payment success screen navigation
class TestPaymentSuccessApp extends StatelessWidget {
  const TestPaymentSuccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Payment Success Test',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const TestPaymentSuccessScreen(),
      ),
    );
  }
}

class TestPaymentSuccessScreen extends StatelessWidget {
  const TestPaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Success Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test Payment Success Screen Navigation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to payment success test screen
                context.goToPaymentSuccessTest(
                  examId: 'test_exam_123',
                  transactionId: 'txn_test_456',
                  orderId: 'order_test_789',
                );
              },
              child: const Text('Test Payment Success Screen'),
            ),
            const SizedBox(height: 20),
            const Text(
              'This will open the payment success test screen\nwith sample data to verify the UI and navigation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const TestPaymentSuccessApp());
}
