import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/usecase/usecase.dart';
import 'package:wonder_souls/src/features/notifications/data/models/notification_inbox_item.dart';
import 'package:wonder_souls/src/features/notifications/domain/repositories/notifications_repository.dart';

class GetMyNotificationsUseCase
    implements UseCase<List<NotificationInboxItem>, NoParams> {
  final NotificationsRepository repository;

  GetMyNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationInboxItem>>> call(NoParams params) async {
    return await repository.getMyNotifications();
  }
}
