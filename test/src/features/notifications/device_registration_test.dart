import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/features/notifications/data/models/register_device_request.dart';
import 'package:wonder_souls/src/features/notifications/data/models/user_device_response.dart';
import 'package:wonder_souls/src/features/notifications/data/services/device_registration_service.dart';
import 'package:wonder_souls/src/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/register_device_usecase.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/unregister_device_usecase.dart';

class MockNotificationsRepo implements NotificationsRepository {
  String? registeredToken;
  String? registeredPlatform;
  String? unregisteredId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, UserDeviceResponse>> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    registeredToken = fcmToken;
    registeredPlatform = platform;
    return Right(
      UserDeviceResponse(
        id: 'device-abc-123',
        platform: platform,
        isActive: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Either<Failure, void>> unregisterDevice(String deviceId) async {
    unregisteredId = deviceId;
    return const Right(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegisterDeviceRequest & UserDeviceResponse Models', () {
    test('RegisterDeviceRequest serializes to json', () {
      const req = RegisterDeviceRequest(
        fcmToken: 'fcm-token-xyz',
        platform: 'android',
      );

      final json = req.toJson();
      expect(json['fcmToken'], 'fcm-token-xyz');
      expect(json['platform'], 'android');

      final fromJson = RegisterDeviceRequest.fromJson(json);
      expect(fromJson.fcmToken, 'fcm-token-xyz');
      expect(fromJson.platform, 'android');
    });

    test('UserDeviceResponse parses from json', () {
      final json = {
        'id': 'device-001',
        'platform': 'android',
        'isActive': true,
        'updatedAt': '2026-10-26T12:00:00.000Z',
      };

      final response = UserDeviceResponse.fromJson(json);
      expect(response.id, 'device-001');
      expect(response.platform, 'android');
      expect(response.isActive, true);
      expect(response.updatedAt, isNotNull);
    });
  });

  group('DeviceRegistrationService', () {
    late MockNotificationsRepo repo;
    late RegisterDeviceUseCase registerUseCase;
    late UnregisterDeviceUseCase unregisterUseCase;
    late SharedPreferences prefs;
    late DeviceRegistrationService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = MockNotificationsRepo();
      registerUseCase = RegisterDeviceUseCase(repo);
      unregisterUseCase = UnregisterDeviceUseCase(repo);
      service = DeviceRegistrationService(
        registerDeviceUseCase: registerUseCase,
        unregisterDeviceUseCase: unregisterUseCase,
        sharedPreferences: prefs,
      );
    });

    test('registerToken registers device and saves deviceId to prefs', () async {
      final success = await service.registerToken('sample-fcm-token');

      expect(success, true);
      expect(repo.registeredToken, 'sample-fcm-token');
      expect(service.registeredDeviceId, 'device-abc-123');
      expect(service.registeredToken, 'sample-fcm-token');
    });

    test('unregisterCurrentDevice deletes device and clears prefs', () async {
      await service.registerToken('sample-fcm-token');
      expect(service.registeredDeviceId, isNotNull);

      final success = await service.unregisterCurrentDevice();

      expect(success, true);
      expect(repo.unregisteredId, 'device-abc-123');
      expect(service.registeredDeviceId, isNull);
      expect(service.registeredToken, isNull);
    });
  });
}
