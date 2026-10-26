import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:wonder_souls/src/features/notifications/data/models/notification_inbox_item.dart';
import 'package:wonder_souls/src/features/notifications/data/models/user_device_response.dart';
import 'package:wonder_souls/src/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;

  NotificationsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<NotificationInboxItem>>> getMyNotifications() async {
    try {
      final result = await remoteDataSource.getMyNotifications();
      if (result is Failure<List<NotificationInboxItem>>) {
        return Left(Failure(message: result.message, statusCode: result.statusCode));
      }
      return Right((result as Success<List<NotificationInboxItem>>).data);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      final result = await remoteDataSource.markAsRead(notificationId);
      if (result is Failure<void>) {
        return Left(Failure(message: result.message, statusCode: result.statusCode));
      }
      return const Right(null);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserDeviceResponse>> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      final result = await remoteDataSource.registerDevice(
        fcmToken: fcmToken,
        platform: platform,
      );
      if (result is Failure<UserDeviceResponse>) {
        return Left(Failure(message: result.message, statusCode: result.statusCode));
      }
      return Right((result as Success<UserDeviceResponse>).data);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unregisterDevice(String deviceId) async {
    try {
      final result = await remoteDataSource.unregisterDevice(deviceId);
      if (result is Failure<void>) {
        return Left(Failure(message: result.message, statusCode: result.statusCode));
      }
      return const Right(null);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
