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
  QuerySnapshot,
  QueryDocumentSnapshot,
])
import 'device_binding_test.mocks.dart';

void main() {
  group('Device Binding on First Login Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockDocumentSnapshot mockDocumentSnapshot;
    late MockQuerySnapshot mockQuerySnapshot;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockDocumentSnapshot = MockDocumentSnapshot();
      mockQuerySnapshot = MockQuerySnapshot();

      // Setup basic mocks
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_id');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.emailVerified).thenReturn(true);
      when(mockFirestore.collection('mobile_users')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
    });

    test('should bind device on first login - new user', () async {
      // Mock new user without device bound
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': false,
        'registeredDeviceId': null,
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Mock empty query for device binding check (no existing device)
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockCollection.where('registeredDeviceId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.where('isDeviceBound', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Test device validation (should trigger binding)
      final result = await DeviceAuthService.validateDeviceForUser('test_user_id');

      expect(result.isValid, isTrue);
      expect(result.action, DeviceValidationAction.bindDevice);
      expect(result.reason, contains('Device not bound yet'));
    });

    test('should bind device successfully', () async {
      // Mock successful device binding
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Mock empty query for device binding check
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockCollection.where('registeredDeviceId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.where('isDeviceBound', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Test device binding
      final result = await DeviceAuthService.bindDeviceToUser('test_user_id');

      expect(result, isTrue);

      // Verify Firestore update was called with correct data
      verify(mockDocument.update(argThat(allOf([
        contains('registeredDeviceId'),
        contains('deviceInfo'),
        contains('deviceRegisteredAt'),
        contains('isDeviceBound'),
        contains('securityEvents'),
      ])))).called(1);
    });

    test('should log device binding security event', () async {
      // Mock successful device binding
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Mock empty query for device binding check
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockCollection.where('registeredDeviceId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.where('isDeviceBound', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Test device binding
      await DeviceAuthService.bindDeviceToUser('test_user_id');

      // Verify security event was logged
      final capturedUpdate = verify(mockDocument.update(captureAny)).captured.first;
      final securityEvents = capturedUpdate['securityEvents'];
      
      expect(securityEvents, isNotNull);
      expect(securityEvents.toString(), contains('device_bound'));
    });

    test('should prevent binding device already bound to another user', () async {
      // Mock existing device binding to another user
      final existingDoc = MockQueryDocumentSnapshot();
      when(existingDoc.id).thenReturn('other_user_id');
      when(existingDoc.data()).thenReturn({
        'email': 'other@example.com',
        'name': 'Other User',
      });

      when(mockQuerySnapshot.docs).thenReturn([existingDoc]);
      when(mockCollection.where('registeredDeviceId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.where('isDeviceBound', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Test device binding should fail
      expect(
        () => DeviceAuthService.bindDeviceToUser('test_user_id'),
        throwsA(predicate((e) => 
          e is Exception && 
          e.toString().contains('already registered to another account')
        )),
      );
    });

    test('should handle device binding in authentication flow', () async {
      // Mock successful authentication
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock user document without device bound
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': false,
        'registeredDeviceId': null,
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Mock empty query for device binding check
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockCollection.where('registeredDeviceId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.where('isDeviceBound', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Create auth provider and test sign in
      final authNotifier = FirebaseMobileUserAuthNotifier();
      
      // This would normally trigger device binding
      final result = await authNotifier.signInUser(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isTrue);

      // Verify device binding was attempted
      verify(mockDocument.update(argThat(contains('registeredDeviceId')))).called(1);
    });

    test('should continue login even if device binding fails', () async {
      // Mock successful authentication
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock user document without device bound
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': false,
        'registeredDeviceId': null,
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);

      // Mock device binding failure
      when(mockDocument.update(argThat(contains('registeredDeviceId'))))
          .thenThrow(Exception('Firestore error'));
      
      // Mock successful last login update
      when(mockDocument.update(argThat(contains('lastLoginAt'))))
          .thenAnswer((_) async => {});

      // Mock empty query for device binding check
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockCollection.where('registeredDeviceId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.where('isDeviceBound', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Create auth provider and test sign in
      final authNotifier = FirebaseMobileUserAuthNotifier();
      
      // Login should still succeed even if device binding fails
      final result = await authNotifier.signInUser(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isTrue);

      // Verify last login was still updated
      verify(mockDocument.update(argThat(contains('lastLoginAt')))).called(1);
    });

    test('should store comprehensive device information', () async {
      // Mock successful device binding
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Mock empty query for device binding check
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockCollection.where('registeredDeviceId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.where('isDeviceBound', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Test device binding
      await DeviceAuthService.bindDeviceToUser('test_user_id');

      // Verify comprehensive device info was stored
      final capturedUpdate = verify(mockDocument.update(captureAny)).captured.first;
      
      expect(capturedUpdate['registeredDeviceId'], isNotNull);
      expect(capturedUpdate['deviceInfo'], isNotNull);
      expect(capturedUpdate['deviceRegisteredAt'], isNotNull);
      expect(capturedUpdate['isDeviceBound'], isTrue);
      expect(capturedUpdate['securityEvents'], isNotNull);
    });

    test('should handle concurrent device binding attempts', () async {
      // This test simulates race conditions where multiple binding attempts occur
      
      // Mock successful device binding
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Mock empty query for device binding check
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockCollection.where('registeredDeviceId', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.where('isDeviceBound', isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Simulate concurrent binding attempts
      final futures = List.generate(3, (_) => 
        DeviceAuthService.bindDeviceToUser('test_user_id')
      );

      final results = await Future.wait(futures);

      // All should succeed (idempotent operation)
      expect(results.every((result) => result == true), isTrue);
    });
  });
}
