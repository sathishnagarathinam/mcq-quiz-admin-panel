import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mcq_quiz_app/core/providers/mobile_user_auth_provider.dart';
import 'package:mcq_quiz_app/core/services/device_auth_service.dart';
import 'package:mcq_quiz_app/features/auth/screens/email_login_screen.dart';
import 'package:mcq_quiz_app/features/auth/widgets/device_status_widget.dart';

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
])
import 'auth_flow_integration_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
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

    testWidgets('Complete first login flow with device binding', (tester) async {
      // Mock successful authentication
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock user document without device bound (first login)
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
      when(mockCollection.where(any, isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Create test app
      final app = ProviderScope(
        child: MaterialApp(
          home: EmailLoginScreen(),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Find and fill email field
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      // Find and fill password field
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');

      // Find and tap login button
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify that device binding was attempted
      verify(mockDocument.update(argThat(contains('registeredDeviceId')))).called(1);
      verify(mockDocument.update(argThat(contains('isDeviceBound')))).called(1);
    });

    testWidgets('Subsequent login with valid device', (tester) async {
      // Mock successful authentication
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock user document with device already bound
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': true,
        'registeredDeviceId': 'test_device_id', // This should match current device
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Create test app
      final app = ProviderScope(
        child: MaterialApp(
          home: EmailLoginScreen(),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Fill login form
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');

      // Tap login button
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify successful login (no device binding update should occur)
      verify(mockDocument.update(argThat(contains('lastLoginAt')))).called(1);
    });

    testWidgets('Login blocked for unauthorized device', (tester) async {
      // Mock successful authentication
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock sign out for unauthorized device
      when(mockAuth.signOut()).thenAnswer((_) async => {});

      // Mock user document with different device bound
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': true,
        'registeredDeviceId': 'different_device_id', // Different from current device
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocument.update(any)).thenAnswer((_) async => {});

      // Create test app
      final app = ProviderScope(
        child: MaterialApp(
          home: EmailLoginScreen(),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Fill login form
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');

      // Tap login button
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify that user was signed out due to device mismatch
      verify(mockAuth.signOut()).called(1);

      // Verify error message is shown
      expect(find.textContaining('registered to a different device'), findsOneWidget);
    });

    testWidgets('Device status widget shows correct information', (tester) async {
      // Mock user with device bound
      final userData = {
        'uid': 'test_user_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'isDeviceBound': true,
        'registeredDeviceId': 'test_device_id',
        'deviceRegisteredAt': Timestamp.now(),
      };

      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);

      // Create test app with device status widget
      final app = ProviderScope(
        overrides: [
          currentMobileUserProvider.overrideWith((ref) {
            return MobileUser.fromFirestore(userData);
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeviceStatusWidget(),
          ),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Verify device status information is displayed
      expect(find.text('Device Security Status'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.textContaining('securely bound'), findsOneWidget);
    });

    testWidgets('Device binding error handling', (tester) async {
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
      when(mockDocument.update(any)).thenThrow(Exception('Firestore error'));

      // Mock empty query for device binding check
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockCollection.where(any, isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Create test app
      final app = ProviderScope(
        child: MaterialApp(
          home: EmailLoginScreen(),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Fill login form
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');

      // Tap login button
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Login should still succeed even if device binding fails
      // (This tests the graceful error handling)
      verify(mockDocument.update(argThat(contains('lastLoginAt')))).called(1);
    });

    testWidgets('Device already bound to another user error', (tester) async {
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

      // Mock existing device binding to another user
      final existingDoc = MockQueryDocumentSnapshot();
      when(existingDoc.id).thenReturn('other_user_id');
      when(existingDoc.data()).thenReturn({
        'email': 'other@example.com',
        'name': 'Other User',
      });

      when(mockQuerySnapshot.docs).thenReturn([existingDoc]);
      when(mockCollection.where(any, isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Create test app
      final app = ProviderScope(
        child: MaterialApp(
          home: EmailLoginScreen(),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Fill login form
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');

      // Tap login button
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Login should still succeed (device binding error is handled gracefully)
      verify(mockDocument.update(argThat(contains('lastLoginAt')))).called(1);
    });
  });
}

// Mock class for QueryDocumentSnapshot
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
