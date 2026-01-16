import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Simple test to verify Firebase and basic structure works
class TestBuildApp extends StatelessWidget {
  const TestBuildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Test Build',
        home: const TestHomePage(),
      ),
    );
  }
}

class TestHomePage extends ConsumerWidget {
  const TestHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Build'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Testing Firebase Connection'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final snapshot = await FirebaseFirestore.instance
                      .collection('exams')
                      .get();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Found ${snapshot.docs.length} exams'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Test Firebase'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const TestBuildApp());
}
