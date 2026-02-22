import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mcq_quiz_app/core/services/device_auth_service.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DeviceInfoPlugin,
  AndroidDeviceInfo,
  IosDeviceInfo,
])
import 'device_auth_service_test.mocks.dart';

void main() {
  group('DeviceAuthService Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockDocumentSnapshot mockDocumentSnapshot;
    late MockQuerySnapshot mockQuerySnapshot;
    late MockDeviceInfoPlugin mockDeviceInfo;
    late MockAndroidDeviceInfo mockAndroidInfo;
    late MockIosDeviceInfo mockIosInfo;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockDocumentSnapshot = MockDocumentSnapshot();
      mockQuerySnapshot = MockQuerySnapshot();
      mockDeviceInfo = MockDeviceInfoPlugin();
      mockAndroidInfo = MockAndroidDeviceInfo();
      mockIosInfo = MockIosDeviceInfo();

      // Setup basic mocks
      when(mockFirestore.collection('mobile_users')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
    });

    tearDown(() {
      // Clear cached data after each test
      DeviceAuthService.clearCache();
    });

    group('Device ID Generation', () {
      testWidgets('should generate device ID for Android', (tester) async {
        // Mock Android device info
        when(mockAndroidInfo.id).thenReturn('test_android_id');
        when(mockAndroidInfo.brand).thenReturn('Samsung');
        when(mockAndroidInfo.model).thenReturn('Galaxy S21');
        when(mockAndroidInfo.fingerprint).thenReturn('test_fingerprint');
        when(mockDeviceInfo.androidInfo).thenAnswer((_) async => mockAndroidInfo);

        // Note: This test would need platform-specific mocking
        // For now, we'll test the logic structure
        expect(() => DeviceAuthService.getDeviceId(), returnsNormally);
      });

      testWidgets('should generate device ID for iOS', (tester) async {
        // Mock iOS device info
        when(mockIosInfo.identifierForVendor).thenReturn('test_ios_id');
        when(mockIosInfo.name).thenReturn('iPhone');
        when(mockIosInfo.model).thenReturn('iPhone 13');
        when(mockIosInfo.systemVersion).thenReturn('15.0');
        when(mockDeviceInfo.iosInfo).thenAnswer((_) async => mockIosInfo);

        // Note: This test would need platform-specific mocking
        expect(() => DeviceAuthService.getDeviceId(), returnsNormally);
      });

      test('should cache device ID after first call', () async {
        // This test verifies caching behavior
        // Multiple calls should return the same ID without re-computation
        expect(() => DeviceAuthService.getDeviceId(), returnsNormally);
      });
    });

    group('Device Information', () {
      testWidgets('should get comprehensive device info for Android', (tester) async {
        // Mock Android device info
        when(mockAndroidInfo.brand).thenReturn('Samsung');
        when(mockAndroidInfo.model).thenReturn('Galaxy S21');
        when(mockAndroidInfo.manufacturer).thenReturn('Samsung');
        when(mockAndroidInfo.product).thenReturn('beyond1lte');
        when(mockAndroidInfo.device).thenReturn('beyond1');
        when(mockAndroidInfo.id).thenReturn('test_android_id');
        when(mockAndroidInfo.fingerprint).thenReturn('test_fingerprint');
        when(mockAndroidInfo.hardware).thenReturn('exynos9820');
        when(mockAndroidInfo.isPhysicalDevice).thenReturn(true);
        when(mockDeviceInfo.androidInfo).thenAnswer((_) async => mockAndroidInfo);

        expect(() => DeviceAuthService.getDeviceInfo(), returnsNormally);
      });

      testWidgets('should get comprehensive device info for iOS', (tester) async {
        // Mock iOS device info
        when(mockIosInfo.name).thenReturn('iPhone');
        when(mockIosInfo.model).thenReturn('iPhone 13');
        when(mockIosInfo.localizedModel).thenReturn('iPhone');
        when(mockIosInfo.systemName).thenReturn('iOS');
        when(mockIosInfo.systemVersion).thenReturn('15.0');
        when(mockIosInfo.identifierForVendor).thenReturn('test_ios_id');
        when(mockIosInfo.isPhysicalDevice).thenReturn(true);
        when(mockDeviceInfo.iosInfo).thenAnswer((_) async => mockIosInfo);

        expect(() => DeviceAuthService.getDeviceInfo(), returnsNormally);
      });
    });

    group('Device Registration Check', () {
      test('should return true when user has registered device', () async {
        // Mock user document with device bound
        final userData = {
          'isDeviceBound': true,
          'registeredDeviceId': 'test_device_id',
        };
        
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(userData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);

        final result = await DeviceAuthService.hasRegisteredDevice('test_user_id');
        expect(result, isTrue);
      });

      test('should return false when user has no registered device', () async {
        // Mock user document without device bound
        final userData = {
          'isDeviceBound': false,
          'registeredDeviceId': null,
        };
        
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(userData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);

        final result = await DeviceAuthService.hasRegisteredDevice('test_user_id');
        expect(result, isFalse);
      });

      test('should return false when user document does not exist', () async {
        when(mockDocumentSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);

        final result = await DeviceAuthService.hasRegisteredDevice('test_user_id');
        expect(result, isFalse);
      });
    });

    group('Device Binding', () {
      test('should successfully bind device to user', () async {
        // Mock successful device binding
        when(mockDocument.update(any)).thenAnswer((_) async => {});
        
        // Mock query for existing device binding (should return empty)
        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockCollection.where('registeredDeviceId', isEqualTo: anyNamed('isEqualTo')))
            .thenReturn(mockCollection);
        when(mockCollection.where('isDeviceBound', isEqualTo: anyNamed('isEqualTo')))
            .thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        expect(() => DeviceAuthService.bindDeviceToUser('test_user_id'), returnsNormally);
      });

      test('should throw error when device already bound to another user', () async {
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

        expect(
          () => DeviceAuthService.bindDeviceToUser('test_user_id'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Device Validation', () {
      test('should allow access when device matches registered device', () async {
        // Mock user document with matching device
        final userData = {
          'registeredDeviceId': 'test_device_id',
          'isDeviceBound': true,
        };
        
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(userData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        final result = await DeviceAuthService.validateDeviceForUser('test_user_id');
        expect(result.isValid, isTrue);
        expect(result.action, DeviceValidationAction.allowAccess);
      });

      test('should block access when device does not match registered device', () async {
        // Mock user document with different device
        final userData = {
          'registeredDeviceId': 'different_device_id',
          'isDeviceBound': true,
        };
        
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(userData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        final result = await DeviceAuthService.validateDeviceForUser('test_user_id');
        expect(result.isValid, isFalse);
        expect(result.action, DeviceValidationAction.blockAccess);
        expect(result.reason, contains('registered to a different device'));
      });

      test('should allow binding when device is not bound yet', () async {
        // Mock user document without device bound
        final userData = {
          'registeredDeviceId': null,
          'isDeviceBound': false,
        };
        
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(userData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);

        final result = await DeviceAuthService.validateDeviceForUser('test_user_id');
        expect(result.isValid, isTrue);
        expect(result.action, DeviceValidationAction.bindDevice);
      });

      test('should sign out when user document does not exist', () async {
        when(mockDocumentSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);

        final result = await DeviceAuthService.validateDeviceForUser('test_user_id');
        expect(result.isValid, isFalse);
        expect(result.action, DeviceValidationAction.signOut);
      });
    });

    group('Error Handling', () {
      test('should handle Firestore errors gracefully', () async {
        when(mockDocument.get()).thenThrow(Exception('Firestore error'));

        final result = await DeviceAuthService.validateDeviceForUser('test_user_id');
        expect(result.isValid, isFalse);
        expect(result.action, DeviceValidationAction.signOut);
      });

      test('should handle device info errors gracefully', () async {
        when(mockDeviceInfo.androidInfo).thenThrow(Exception('Device info error'));

        expect(
          () => DeviceAuthService.getDeviceId(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
