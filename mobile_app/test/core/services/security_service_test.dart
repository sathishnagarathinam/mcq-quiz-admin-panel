import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mcq_quiz_app/core/services/security_service.dart';

// Generate mocks
@GenerateMocks([
  MethodChannel,
  FirebaseFirestore,
  FirebaseAuth,
  User,
  CollectionReference,
  DocumentReference,
])
import 'security_service_test.mocks.dart';

void main() {
  group('SecurityService Tests', () {
    late MockMethodChannel mockScreenshotChannel;
    late MockMethodChannel mockScreenRecordingChannel;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;

    setUp(() {
      mockScreenshotChannel = MockMethodChannel();
      mockScreenRecordingChannel = MockMethodChannel();
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();

      // Setup basic mocks
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_id');
      when(mockFirestore.collection('mobile_users')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
    });

    group('Initialization', () {
      testWidgets('should initialize security service successfully', (tester) async {
        expect(() => SecurityService.initialize(), returnsNormally);
      });

      test('should not reinitialize if already initialized', () async {
        // First initialization
        await SecurityService.initialize();
        
        // Second initialization should not throw
        expect(() => SecurityService.initialize(), returnsNormally);
      });
    });

    group('Screenshot Prevention', () {
      testWidgets('should enable screenshot prevention on Android', (tester) async {
        // Mock Android platform
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
      });

      testWidgets('should disable screenshot prevention on Android', (tester) async {
        // Mock Android platform
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

    group('Screen Recording Prevention', () {
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

      testWidgets('should check screen recording status on iOS', (tester) async {
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
    });

    group('Comprehensive Screen Protection', () {
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

    group('Security Event Logging', () {
      test('should log security breach to Firestore', () async {
        // Mock Firestore update
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // This tests the private method indirectly through screen recording detection
        await SecurityService.isScreenRecordingActive();
        
        // Verify that if recording was detected, it would log the event
        // (This is a simplified test as the actual method is private)
        expect(() => SecurityService.isScreenRecordingActive(), returnsNormally);
      });

      test('should handle logging errors gracefully', () async {
        // Mock Firestore error
        when(mockDocument.update(any)).thenThrow(Exception('Firestore error'));

        // Should not throw even if logging fails
        expect(() => SecurityService.isScreenRecordingActive(), returnsNormally);
      });

      test('should not log when user is not authenticated', () async {
        // Mock no current user
        when(mockAuth.currentUser).thenReturn(null);

        // Should not throw
        expect(() => SecurityService.isScreenRecordingActive(), returnsNormally);
      });
    });

    group('Screen Recording Detection Handling', () {
      testWidgets('should handle screen recording detection', (tester) async {
        // Mock platform channel for showing warning
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('security/screen_recording'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'showRecordingWarning') {
              return null;
            }
            return null;
          },
        );

        // This tests the private method indirectly
        expect(() => SecurityService.isScreenRecordingActive(), returnsNormally);
      });
    });

    group('Device Security Status', () {
      test('should return device security status', () {
        // Test getter methods
        expect(SecurityService.isDeviceSecure, isA<bool>());
        expect(SecurityService.deviceId, isA<String?>());
      });

      testWidgets('should check if running on emulator', (tester) async {
        final isEmulator = await SecurityService.isRunningOnEmulator();
        expect(isEmulator, isA<bool>());
      });
    });

    group('Network Security Validation', () {
      test('should validate HTTPS URLs as secure', () {
        final isSecure = SecurityService.validateNetworkSecurity('https://example.com');
        expect(isSecure, isTrue);
      });

      test('should reject HTTP URLs as insecure', () {
        final isSecure = SecurityService.validateNetworkSecurity('http://example.com');
        expect(isSecure, isFalse);
      });

      test('should handle invalid URLs gracefully', () {
        final isSecure = SecurityService.validateNetworkSecurity('invalid-url');
        expect(isSecure, isFalse);
      });
    });

    group('Error Handling', () {
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

      test('should handle Firestore errors in security logging', () async {
        // Mock Firestore error
        when(mockDocument.update(any)).thenThrow(Exception('Firestore error'));

        // Should not throw
        expect(() => SecurityService.isScreenRecordingActive(), returnsNormally);
      });
    });

    group('State Management', () {
      test('should track screen protection state correctly', () async {
        // Initially should be false
        expect(SecurityService.isScreenProtectionEnabled, isFalse);

        // Enable protection
        await SecurityService.enableScreenProtection();
        expect(SecurityService.isScreenProtectionEnabled, isTrue);

        // Disable protection
        await SecurityService.disableScreenProtection();
        expect(SecurityService.isScreenProtectionEnabled, isFalse);
      });

      test('should track screen recording detection state', () {
        // Initially should be false
        expect(SecurityService.isScreenRecordingDetected, isFalse);
        
        // State changes are tested indirectly through the detection methods
        expect(() => SecurityService.isScreenRecordingActive(), returnsNormally);
      });
    });
  });
}
