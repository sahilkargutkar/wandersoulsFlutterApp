import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/usecase/usecase.dart';
import 'package:wonder_souls/src/features/notifications/domain/repositories/notifications_repository.dart';

class UnregisterDeviceUseCase implements UseCase<void, String> {
  final NotificationsRepository repository;

  UnregisterDeviceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String deviceId) async {
    return await repository.unregisterDevice(deviceId);
  }
}
