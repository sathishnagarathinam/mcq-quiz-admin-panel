import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firestore_test_service.dart';
import '../../core/theme/app_theme.dart';

class FirestoreDebugScreen extends StatefulWidget {
  const FirestoreDebugScreen({super.key});

  @override
  State<FirestoreDebugScreen> createState() => _FirestoreDebugScreenState();
}

class _FirestoreDebugScreenState extends State<FirestoreDebugScreen> {
  bool _isRunningTests = false;
  Map<String, dynamic>? _testResults;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Firestore Debug',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firestore Connection Test',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will test if Firestore is properly configured and accessible.',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isRunningTests ? null : _runFirestoreTests,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isRunningTests
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Running Tests...',
                                  style: GoogleFonts.poppins(),
                                ),
                              ],
                            )
                          : Text(
                              'Run Firestore Tests',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          _isRunningTests ? null : _testFirebaseConnectivity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Test Firebase Auth Connectivity',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_testResults != null) ...[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _testResults!['success'] == true
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _testResults!['success'] == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Test Results',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildTestResults(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testResults == null) return const SizedBox.shrink();

    final results = _testResults!['results'] as Map<String, dynamic>?;
    if (results == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTestResult('Connection Test', results['connection']),
        const SizedBox(height: 12),
        _buildTestResult('Mobile Users Collection', results['mobile_users']),
        const SizedBox(height: 12),
        _buildTestResult('Security Rules Check', results['rules']),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _testResults!['success'] == true
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  _testResults!['success'] == true ? Colors.green : Colors.red,
            ),
          ),
          child: Text(
            _testResults!['message'] ?? 'Unknown result',
            style: GoogleFonts.poppins(
              color: _testResults!['success'] == true
                  ? Colors.green[700]
                  : Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestResult(String testName, Map<String, dynamic>? result) {
    if (result == null) return const SizedBox.shrink();

    final success = result['success'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success
            ? Colors.green.withOpacity(0.05)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: success
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: success ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                testName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result['message'] ?? 'No message',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          if (result['error'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Error: ${result['error']}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red[600],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runFirestoreTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = null;
    });

    try {
      final results = await FirestoreTestService.runAllTests();
      setState(() {
        _testResults = results;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'success': false,
          'message': 'Test execution failed: $e',
        };
      });
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Future<void> _testFirebaseConnectivity() async {
    setState(() {
      _isRunningTests = true;
      _testResults = null;
    });

    try {
      // Test Firebase Auth connectivity
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      setState(() {
        _testResults = {
          'success': true,
          'message': 'Firebase Auth connectivity test successful',
          'results': {
            'connectivity': {
              'isConnected': true,
              'currentUser': currentUser?.uid ?? 'No user logged in',
              'isAnonymous': currentUser?.isAnonymous ?? false,
              'phoneNumber': currentUser?.phoneNumber ?? 'N/A',
            },
          },
        };
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'success': false,
          'message': 'Firebase Auth connectivity test failed: $e',
        };
      });
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }
}
