import 'package:flutter/foundation.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/api_result.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import 'package:wonder_souls/src/features/notifications/data/models/notification_inbox_item.dart';
import 'package:wonder_souls/src/features/notifications/data/models/register_device_request.dart';
import 'package:wonder_souls/src/features/notifications/data/models/user_device_response.dart';

abstract interface class NotificationsRemoteDataSource {
  Future<ApiResult<List<NotificationInboxItem>>> getMyNotifications();
  Future<ApiResult<void>> markAsRead(String notificationId);
  Future<ApiResult<UserDeviceResponse>> registerDevice({
    required String fcmToken,
    required String platform,
  });
  Future<ApiResult<void>> unregisterDevice(String deviceId);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final ApiService apiService;

  NotificationsRemoteDataSourceImpl({required this.apiService});

  @override
  Future<ApiResult<List<NotificationInboxItem>>> getMyNotifications() async {
    try {
      final result = await apiService.get<List<NotificationInboxItem>>(
        ApiConstants.myNotifications,
        fromJson: (json) {
          List<dynamic> list = [];
          if (json is List) {
            list = json;
          } else if (json is Map<String, dynamic>) {
            if (json['data'] is List) {
              list = json['data'] as List;
            } else if (json['items'] is List) {
              list = json['items'] as List;
            }
          }

          final notifications = <NotificationInboxItem>[];
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              try {
                notifications.add(NotificationInboxItem.fromJson(item));
              } catch (e) {
                debugPrint("Error parsing notification item: $e");
              }
            }
          }
          return notifications;
        },
      );

      return result;
    } catch (e) {
      return Failure(message: e.toString());
    }
  }

  @override
  Future<ApiResult<void>> markAsRead(String notificationId) async {
    try {
      final result = await apiService.post<void>(
        ApiConstants.markNotificationAsRead(notificationId),
        fromJson: (_) {},
      );
      return result;
    } catch (e) {
      return Failure(message: e.toString());
    }
  }

  @override
  Future<ApiResult<UserDeviceResponse>> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      final result = await apiService.post<UserDeviceResponse>(
        ApiConstants.registerDevice,
        data: RegisterDeviceRequest(
          fcmToken: fcmToken,
          platform: platform,
        ).toJson(),
        fromJson: (json) {
          final data = json is Map<String, dynamic>
              ? (json['data'] ?? json)
              : json;
          return UserDeviceResponse.fromJson(data as Map<String, dynamic>);
        },
      );
      return result;
    } catch (e) {
      return Failure(message: e.toString());
    }
  }

  @override
  Future<ApiResult<void>> unregisterDevice(String deviceId) async {
    try {
      final result = await apiService.delete<void>(
        ApiConstants.deleteDevice(deviceId),
        fromJson: (_) {},
      );
      return result;
    } catch (e) {
      return Failure(message: e.toString());
    }
  }
}
