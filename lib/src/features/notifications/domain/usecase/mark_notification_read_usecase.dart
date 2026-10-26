import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/usecase/usecase.dart';
import 'package:wonder_souls/src/features/notifications/domain/repositories/notifications_repository.dart';

class MarkNotificationReadParams {
  final String notificationId;

  const MarkNotificationReadParams({required this.notificationId});
}

class MarkNotificationReadUseCase
    implements UseCase<void, MarkNotificationReadParams> {
  final NotificationsRepository repository;

  MarkNotificationReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkNotificationReadParams params) async {
    return await repository.markAsRead(params.notificationId);
  }
}
