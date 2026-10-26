import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/register_device_usecase.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/unregister_device_usecase.dart';

class DeviceRegistrationService {
  final RegisterDeviceUseCase registerDeviceUseCase;
  final UnregisterDeviceUseCase unregisterDeviceUseCase;
  final SharedPreferences sharedPreferences;

  static const String _prefRegisteredDeviceId = "registered_fcm_device_id";
  static const String _prefRegisteredToken = "registered_fcm_token";

  DeviceRegistrationService({
    required this.registerDeviceUseCase,
    required this.unregisterDeviceUseCase,
    required this.sharedPreferences,
  });

  static String get currentPlatform {
    if (kIsWeb) return "web";
    try {
      if (Platform.isAndroid) return "android";
      if (Platform.isIOS) return "ios";
      if (Platform.isMacOS) return "macos";
      if (Platform.isWindows) return "windows";
      if (Platform.isLinux) return "linux";
    } catch (_) {}
    return "mobile";
  }

  String? get registeredDeviceId =>
      sharedPreferences.getString(_prefRegisteredDeviceId);

  String? get registeredToken =>
      sharedPreferences.getString(_prefRegisteredToken);

  /// Registers the device with backend using the provided FCM token.
  Future<bool> registerToken(String fcmToken) async {
    if (fcmToken.isEmpty) return false;

    // Skip if already registered with the same token
    if (registeredToken == fcmToken && registeredDeviceId != null) {
      debugPrint("FCM token already registered on device: $registeredDeviceId");
      return true;
    }

    final platform = currentPlatform;
    final result = await registerDeviceUseCase(
      RegisterDeviceParams(fcmToken: fcmToken, platform: platform),
    );

    return result.fold(
      (failure) {
        debugPrint("Failed to register device for FCM: ${failure.message}");
        return false;
      },
      (deviceResponse) async {
        if (deviceResponse.id != null && deviceResponse.id!.isNotEmpty) {
          await sharedPreferences.setString(
            _prefRegisteredDeviceId,
            deviceResponse.id!,
          );
        }
        await sharedPreferences.setString(_prefRegisteredToken, fcmToken);
        debugPrint(
          "Successfully registered FCM device: id=${deviceResponse.id}, platform=$platform",
        );
        return true;
      },
    );
  }

  /// Unregisters this device from backend (typically on logout).
  Future<bool> unregisterCurrentDevice() async {
    final deviceId = registeredDeviceId;
    if (deviceId == null || deviceId.isEmpty) {
      return true;
    }

    final result = await unregisterDeviceUseCase(deviceId);
    return result.fold(
      (failure) {
        debugPrint("Failed to unregister device: ${failure.message}");
        return false;
      },
      (_) async {
        await sharedPreferences.remove(_prefRegisteredDeviceId);
        await sharedPreferences.remove(_prefRegisteredToken);
        debugPrint("Successfully unregistered FCM device $deviceId");
        return true;
      },
    );
  }
}
