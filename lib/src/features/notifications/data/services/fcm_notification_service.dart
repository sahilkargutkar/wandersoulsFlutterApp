import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:wonder_souls/src/features/notifications/data/services/device_registration_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background FCM message: ${message.messageId}");
}

class FcmNotificationService {
  final DeviceRegistrationService deviceRegistrationService;
  VoidCallback? onNotificationReceived;
  bool _isInitialized = false;

  FcmNotificationService({required this.deviceRegistrationService});

  /// Initializes Firebase and sets up foreground message and token refresh listeners.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;

      // Request permission for push notifications
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint("FCM Permission status: ${settings.authorizationStatus}");

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          "FCM Foreground Message received: title=${message.notification?.title}, body=${message.notification?.body}",
        );
        onNotificationReceived?.call();
      });

      // Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Listen for token updates from Firebase
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen((String newToken) {
        debugPrint("FCM Token refreshed: $newToken");
        deviceRegistrationService.registerToken(newToken);
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint("Firebase/FCM setup note: $e");
    }
  }

  /// Called after successful login to fetch the FCM token and register with backend.
  Future<bool> registerDeviceAfterLogin() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;
      // ignore: deprecated_member_use
      final token = await messaging.getToken();

      if (token != null && token.isNotEmpty) {
        debugPrint("FCM Token acquired for logged in user: $token");
        return await deviceRegistrationService.registerToken(token);
      } else {
        debugPrint("FCM Token was null or empty");
        return false;
      }
    } catch (e) {
      debugPrint("Could not register FCM token after login: $e");
      return false;
    }
  }

  /// Unregister device on logout.
  Future<bool> unregisterOnLogout() async {
    try {
      return await deviceRegistrationService.unregisterCurrentDevice();
    } catch (e) {
      debugPrint("Could not unregister FCM device on logout: $e");
      return false;
    }
  }
}
