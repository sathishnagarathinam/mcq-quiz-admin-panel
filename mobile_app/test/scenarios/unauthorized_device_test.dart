import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mcq_quiz_app/core/services/device_auth_service.dart';
import 'package:mcq_quiz_app/core/providers/mobile_user_auth_provider.dart';

// Generate mocks
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  User,
  UserCredential,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
import 'unauthorized_device_test.mocks.dart';

void main() {
  group('Unauthorized Device Access Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockDocumentSnapshot mockDocumentSnapshot;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockDocumentSnapshot = MockDocumentSnapshot();

      // Setup basic mocks
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_id');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.emailVerified).thenReturn(true);
      when(mockFirestore.collection('mobile_users')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
    });

    test('should block access from unauthorized device', () async {
      // Mock user document with device bound to different device
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': true,
        'registeredDeviceId': 'different_device_id_12345',
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Test device validation
      final result = await DeviceAuthService.validateDeviceForUser('test_user_id');

      expect(result.isValid, isFalse);
      expect(result.action, DeviceValidationAction.blockAccess);
      expect(result.reason, contains('registered to a different device'));
    });

    test('should log unauthorized access attempt', () async {
      // Mock user document with device bound to different device
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': true,
        'registeredDeviceId': 'different_device_id_12345',
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Test device validation
      await DeviceAuthService.validateDeviceForUser('test_user_id');

      // Verify security event was logged
      verify(mockDocument.update(argThat(contains('securityEvents')))).called(1);
      
      final capturedUpdate = verify(mockDocument.update(captureAny)).captured.first;
      final securityEvents = capturedUpdate['securityEvents'];
      
      expect(securityEvents.toString(), contains('unauthorized_device_access'));
    });

    test('should sign out user on unauthorized device access in auth flow', () async {
      // Mock successful Firebase authentication
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock sign out
      when(mockAuth.signOut()).thenAnswer((_) async => {});

      // Mock user document with device bound to different device
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': true,
        'registeredDeviceId': 'different_device_id_12345',
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Create auth provider and test sign in
      final authNotifier = FirebaseMobileUserAuthNotifier();
      
      final result = await authNotifier.signInUser(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isFalse);

      // Verify user was signed out
      verify(mockAuth.signOut()).called(1);
    });

    test('should return appropriate error message for unauthorized device', () async {
      // Mock successful Firebase authentication
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock sign out
      when(mockAuth.signOut()).thenAnswer((_) async => {});

      // Mock user document with device bound to different device
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': true,
        'registeredDeviceId': 'different_device_id_12345',
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Create auth provider and test sign in
      final authNotifier = FirebaseMobileUserAuthNotifier();
      
      await authNotifier.signInUser(
        email: 'test@example.com',
        password: 'password123',
      );

      // Check error state
      final authState = authNotifier.state;
      expect(authState.error, isNotNull);
      expect(authState.error, contains('registered to a different device'));
    });

    test('should handle multiple unauthorized access attempts', () async {
      // Mock user document with device bound to different device
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': true,
        'registeredDeviceId': 'different_device_id_12345',
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Simulate multiple unauthorized access attempts
      final futures = List.generate(3, (_) => 
        DeviceAuthService.validateDeviceForUser('test_user_id')
      );

      final results = await Future.wait(futures);

      // All should be blocked
      expect(results.every((result) => !result.isValid), isTrue);
      expect(results.every((result) => 
        result.action == DeviceValidationAction.blockAccess), isTrue);

      // Multiple security events should be logged
      verify(mockDocument.update(argThat(contains('securityEvents')))).called(3);
    });

    test('should differentiate between device IDs correctly', () async {
      // Test with various device ID scenarios
      final testCases = [
        {
          'registeredDeviceId': 'device_123',
          'currentDeviceId': 'device_456',
          'shouldBlock': true,
        },
        {
          'registeredDeviceId': 'device_123',
          'currentDeviceId': 'device_123',
          'shouldBlock': false,
        },
        {
          'registeredDeviceId': 'DEVICE_123',
          'currentDeviceId': 'device_123',
          'shouldBlock': true, // Case sensitive
        },
      ];

      for (final testCase in testCases) {
        // Mock user document
        final userData = {
          'uid': 'test_user_id',
          'email': 'test@example.com',
          'name': 'Test User',
          'isDeviceBound': true,
          'registeredDeviceId': testCase['registeredDeviceId'],
        };

        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(userData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Test device validation
        final result = await DeviceAuthService.validateDeviceForUser('test_user_id');

        if (testCase['shouldBlock'] as bool) {
          expect(result.isValid, isFalse, 
            reason: 'Should block ${testCase['currentDeviceId']} when registered is ${testCase['registeredDeviceId']}');
          expect(result.action, DeviceValidationAction.blockAccess);
        } else {
          expect(result.isValid, isTrue,
            reason: 'Should allow ${testCase['currentDeviceId']} when registered is ${testCase['registeredDeviceId']}');
          expect(result.action, DeviceValidationAction.allowAccess);
        }
      }
    });

    test('should handle empty or null device IDs', () async {
      final testCases = [
        {
          'registeredDeviceId': null,
          'isDeviceBound': false,
          'expectedAction': DeviceValidationAction.bindDevice,
        },
        {
          'registeredDeviceId': '',
          'isDeviceBound': false,
          'expectedAction': DeviceValidationAction.bindDevice,
        },
        {
          'registeredDeviceId': null,
          'isDeviceBound': true,
          'expectedAction': DeviceValidationAction.bindDevice,
        },
      ];

      for (final testCase in testCases) {
        // Mock user document
        final userData = {
          'uid': 'test_user_id',
          'email': 'test@example.com',
          'name': 'Test User',
          'isDeviceBound': testCase['isDeviceBound'],
          'registeredDeviceId': testCase['registeredDeviceId'],
        };

        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(userData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);

        // Test device validation
        final result = await DeviceAuthService.validateDeviceForUser('test_user_id');

        expect(result.action, testCase['expectedAction']);
      }
    });

    test('should handle Firestore errors during unauthorized access logging', () async {
      // Mock user document with device bound to different device
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': true,
        'registeredDeviceId': 'different_device_id_12345',
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      
      // Mock Firestore error during security event logging
      when(mockDocument.update(any)).thenThrow(Exception('Firestore error'));

      // Test device validation should still work despite logging error
      final result = await DeviceAuthService.validateDeviceForUser('test_user_id');

      expect(result.isValid, isFalse);
      expect(result.action, DeviceValidationAction.blockAccess);
      expect(result.reason, contains('registered to a different device'));
    });

    test('should provide detailed security event information', () async {
      // Mock user document with device bound to different device
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': true,
        'registeredDeviceId': 'registered_device_12345',
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Test device validation
      await DeviceAuthService.validateDeviceForUser('test_user_id');

      // Verify detailed security event was logged
      final capturedUpdate = verify(mockDocument.update(captureAny)).captured.first;
      final securityEventsUpdate = capturedUpdate['securityEvents'];
      
      expect(securityEventsUpdate.toString(), contains('unauthorized_device_access'));
      expect(securityEventsUpdate.toString(), contains('attemptedDeviceId'));
      expect(securityEventsUpdate.toString(), contains('registeredDeviceId'));
      expect(securityEventsUpdate.toString(), contains('registered_device_12345'));
    });
  });
}
