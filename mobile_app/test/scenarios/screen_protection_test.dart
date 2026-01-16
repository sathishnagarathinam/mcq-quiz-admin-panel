import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mcq_quiz_app/core/services/security_service.dart';
import 'package:mcq_quiz_app/core/widgets/secure_screen_wrapper.dart';

// Generate mocks
@GenerateMocks([MethodChannel])
import 'screen_protection_test.mocks.dart';

void main() {
  group('Screen Protection Features Tests', () {
    late MockMethodChannel mockScreenshotChannel;
    late MockMethodChannel mockScreenRecordingChannel;

    setUp(() {
      mockScreenshotChannel = MockMethodChannel();
      mockScreenRecordingChannel = MockMethodChannel();
    });

    group('Screenshot Prevention Tests', () {
      testWidgets('should enable screenshot prevention on Android', (tester) async {
        // Mock Android platform channel
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'preventScreenshots') {
              expect(methodCall.arguments, isTrue);
              return null;
            }
            return null;
          },
        );

        await SecurityService.preventScreenshots(true);
        
        // Verify method was called
        // Note: In a real test, we'd verify the native implementation
      });

      testWidgets('should disable screenshot prevention on Android', (tester) async {
        // Mock Android platform channel
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'preventScreenshots') {
              expect(methodCall.arguments, isFalse);
              return null;
            }
            return null;
          },
        );

        await SecurityService.preventScreenshots(false);
      });

      testWidgets('should handle screenshot prevention errors gracefully', (tester) async {
        // Mock platform error
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            throw PlatformException(code: 'ERROR', message: 'Platform error');
          },
        );

        // Should not throw
        expect(() => SecurityService.preventScreenshots(true), returnsNormally);
      });
    });

    group('Screen Recording Prevention Tests', () {
      testWidgets('should enable screen recording prevention', (tester) async {
        // Mock platform channels
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'preventScreenRecording') {
              expect(methodCall.arguments, isTrue);
              return null;
            }
            return null;
          },
        );

        await SecurityService.preventScreenRecording(true);
      });

      testWidgets('should disable screen recording prevention', (tester) async {
        // Mock platform channels
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'preventScreenRecording') {
              expect(methodCall.arguments, isFalse);
              return null;
            }
            return null;
          },
        );

        await SecurityService.preventScreenRecording(false);
      });

      testWidgets('should detect screen recording on iOS', (tester) async {
        // Mock iOS platform
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isScreenRecordingActive') {
              return true; // Simulate recording active
            }
            return null;
          },
        );

        final isRecording = await SecurityService.isScreenRecordingActive();
        expect(isRecording, isTrue);
      });

      testWidgets('should start screen recording monitoring on iOS', (tester) async {
        // Mock iOS platform
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'startMonitoring') {
              return null;
            }
            return null;
          },
        );

        expect(() => SecurityService.startScreenRecordingMonitoring(), returnsNormally);
      });

      testWidgets('should handle screen recording status changes', (tester) async {
        bool callbackCalled = false;
        
        // Mock iOS platform with callback
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'startMonitoring') {
              // Simulate callback after monitoring starts
              Future.delayed(Duration(milliseconds: 100), () {
                tester.binding.defaultBinaryMessenger.handlePlatformMessage(
                  'security/screen_recording',
                  const StandardMethodCodec().encodeMethodCall(
                    const MethodCall('screenRecordingStatusChanged', {
                      'isRecording': true,
                    }),
                  ),
                  (data) {
                    callbackCalled = true;
                  },
                );
              });
              return null;
            }
            return null;
          },
        );

        await SecurityService.startScreenRecordingMonitoring();
        await tester.pump(Duration(milliseconds: 200));
        
        expect(callbackCalled, isTrue);
      });
    });

    group('Comprehensive Screen Protection Tests', () {
      testWidgets('should enable comprehensive screen protection', (tester) async {
        // Mock both channels
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'preventScreenshots') {
              expect(methodCall.arguments, isTrue);
              return null;
            }
            return null;
          },
        );

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'preventScreenRecording') {
              expect(methodCall.arguments, isTrue);
              return null;
            }
            return null;
          },
        );

        await SecurityService.enableScreenProtection();
        expect(SecurityService.isScreenProtectionEnabled, isTrue);
      });

      testWidgets('should disable comprehensive screen protection', (tester) async {
        // First enable protection
        await SecurityService.enableScreenProtection();

        // Mock both channels for disabling
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'preventScreenshots') {
              expect(methodCall.arguments, isFalse);
              return null;
            }
            return null;
          },
        );

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'preventScreenRecording') {
              expect(methodCall.arguments, isFalse);
              return null;
            }
            return null;
          },
        );

        await SecurityService.disableScreenProtection();
        expect(SecurityService.isScreenProtectionEnabled, isFalse);
      });
    });

    group('Secure Screen Wrapper Tests', () {
      testWidgets('should enable security when widget is mounted', (tester) async {
        bool securityEnabled = false;
        
        // Mock security service calls
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'preventScreenshots' && methodCall.arguments == true) {
              securityEnabled = true;
            }
            return null;
          },
        );

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            return null;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SecureScreenWrapper(
              child: Scaffold(
                body: Text('Protected Content'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(securityEnabled, isTrue);
      });

      testWidgets('should disable security when widget is disposed', (tester) async {
        bool securityDisabled = false;
        
        // Mock security service calls
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'preventScreenshots' && methodCall.arguments == false) {
              securityDisabled = true;
            }
            return null;
          },
        );

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            return null;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SecureScreenWrapper(
              child: Scaffold(
                body: Text('Protected Content'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Remove the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Text('Unprotected Content'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(securityDisabled, isTrue);
      });

      testWidgets('should show warning overlay when screen recording detected', (tester) async {
        // Mock screen recording detection
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isScreenRecordingActive') {
              return true; // Simulate recording active
            }
            return null;
          },
        );

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            return null;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SecureScreenWrapper(
              child: Scaffold(
                body: Text('Protected Content'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Trigger screen recording check
        await tester.pump(Duration(seconds: 3));

        // Should show warning overlay
        expect(find.text('Screen Recording Detected'), findsOneWidget);
        expect(find.text('Please stop recording to continue'), findsOneWidget);
      });

      testWidgets('should call security breach callback when recording detected', (tester) async {
        bool breachCallbackCalled = false;

        // Mock screen recording detection
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isScreenRecordingActive') {
              return true; // Simulate recording active
            }
            return null;
          },
        );

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            return null;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SecureScreenWrapper(
              onSecurityBreach: () {
                breachCallbackCalled = true;
              },
              child: Scaffold(
                body: Text('Protected Content'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Trigger screen recording check
        await tester.pump(Duration(seconds: 3));

        expect(breachCallbackCalled, isTrue);
      });
    });

    group('Quiz Secure Wrapper Tests', () {
      testWidgets('should show quiz-specific security warning', (tester) async {
        // Mock screen recording detection
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isScreenRecordingActive') {
              return true; // Simulate recording active
            }
            return null;
          },
        );

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            return null;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: QuizSecureWrapper(
              child: Scaffold(
                body: Text('Quiz Content'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Trigger screen recording check
        await tester.pump(Duration(seconds: 3));

        // Should show quiz-specific warning
        expect(find.textContaining('integrity of the examination'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle platform channel errors gracefully', (tester) async {
        // Mock platform error
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            throw PlatformException(code: 'ERROR', message: 'Platform error');
          },
        );

        // Should not throw
        expect(() => SecurityService.preventScreenRecording(true), returnsNormally);
        expect(() => SecurityService.isScreenRecordingActive(), returnsNormally);
      });

      testWidgets('should continue functioning when one platform feature fails', (tester) async {
        // Mock screenshot prevention success but screen recording failure
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screenshots'),
          (MethodCall methodCall) async {
            return null; // Success
          },
        );

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            throw PlatformException(code: 'ERROR', message: 'Platform error');
          },
        );

        // Should not throw and should still enable what it can
        expect(() => SecurityService.enableScreenProtection(), returnsNormally);
      });
    });
  });
}
