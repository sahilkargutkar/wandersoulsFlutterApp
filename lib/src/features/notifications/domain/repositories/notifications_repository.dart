import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/features/notifications/data/models/notification_inbox_item.dart';
import 'package:wonder_souls/src/features/notifications/data/models/user_device_response.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<NotificationInboxItem>>> getMyNotifications();
  Future<Either<Failure, void>> markAsRead(String notificationId);
  Future<Either<Failure, UserDeviceResponse>> registerDevice({
    required String fcmToken,
    required String platform,
  });
  Future<Either<Failure, void>> unregisterDevice(String deviceId);
}
