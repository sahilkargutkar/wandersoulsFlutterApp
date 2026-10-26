import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/usecase/usecase.dart';
import 'package:wonder_souls/src/features/notifications/data/models/user_device_response.dart';
import 'package:wonder_souls/src/features/notifications/domain/repositories/notifications_repository.dart';

class RegisterDeviceParams {
  final String fcmToken;
  final String platform;

  const RegisterDeviceParams({
    required this.fcmToken,
    required this.platform,
  });
}

class RegisterDeviceUseCase
    implements UseCase<UserDeviceResponse, RegisterDeviceParams> {
  final NotificationsRepository repository;

  RegisterDeviceUseCase(this.repository);

  @override
  Future<Either<Failure, UserDeviceResponse>> call(
    RegisterDeviceParams params,
  ) async {
    return await repository.registerDevice(
      fcmToken: params.fcmToken,
      platform: params.platform,
    );
  }
}
