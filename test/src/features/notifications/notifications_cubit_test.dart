import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/features/notifications/data/models/notification_inbox_item.dart';
import 'package:wonder_souls/src/features/notifications/data/models/notification_item.dart';
import 'package:wonder_souls/src/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/get_my_notifications_usecase.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/mark_notification_read_usecase.dart';
import 'package:wonder_souls/src/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wonder_souls/src/features/notifications/presentation/cubit/notifications_state.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  List<NotificationInboxItem> items = [];
  final List<String> readIds = [];

  @override
  Future<Either<Failure, List<NotificationInboxItem>>> getMyNotifications() async {
    return Right(items);
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    readIds.add(notificationId);
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeNotificationsRepository fakeRepo;
  late GetMyNotificationsUseCase getMyNotificationsUseCase;
  late MarkNotificationReadUseCase markNotificationReadUseCase;
  late NotificationsCubit cubit;

  setUp(() {
    fakeRepo = FakeNotificationsRepository();
    getMyNotificationsUseCase = GetMyNotificationsUseCase(fakeRepo);
    markNotificationReadUseCase = MarkNotificationReadUseCase(fakeRepo);
    cubit = NotificationsCubit(
      getMyNotificationsUseCase: getMyNotificationsUseCase,
      markNotificationReadUseCase: markNotificationReadUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is NotificationsInitial', () {
    expect(cubit.state, isA<NotificationsInitial>());
  });

  test('fetchNotifications emits NotificationsLoading then NotificationsLoaded', () async {
    fakeRepo.items = [
      const NotificationInboxItem(
        notification: NotificationItem(id: '1', title: 'Test Notif 1'),
        isRead: false,
      ),
      const NotificationInboxItem(
        notification: NotificationItem(id: '2', title: 'Test Notif 2'),
        isRead: true,
      ),
    ];

    await cubit.fetchNotifications();

    expect(cubit.state, isA<NotificationsLoaded>());
    final loaded = cubit.state as NotificationsLoaded;
    expect(loaded.notifications.length, 2);
    expect(loaded.unreadCount, 1);
  });

  test('markAsRead updates item isRead state optimistically and calls use case', () async {
    fakeRepo.items = [
      const NotificationInboxItem(
        notification: NotificationItem(id: '1', title: 'Test Notif 1'),
        isRead: false,
      ),
    ];

    await cubit.fetchNotifications();
    await cubit.markAsRead('1');

    final loaded = cubit.state as NotificationsLoaded;
    expect(loaded.unreadCount, 0);
    expect(loaded.notifications.first.isRead, true);
    expect(fakeRepo.readIds, contains('1'));
  });

  test('setFilter toggles between all and unread', () async {
    fakeRepo.items = [
      const NotificationInboxItem(
        notification: NotificationItem(id: '1', title: 'Unread 1'),
        isRead: false,
      ),
      const NotificationInboxItem(
        notification: NotificationItem(id: '2', title: 'Read 1'),
        isRead: true,
      ),
    ];

    await cubit.fetchNotifications();
    var loaded = cubit.state as NotificationsLoaded;
    expect(loaded.filteredNotifications.length, 2);

    cubit.setFilter(NotificationFilter.unread);
    loaded = cubit.state as NotificationsLoaded;
    expect(loaded.filteredNotifications.length, 1);
    expect(loaded.filteredNotifications.first.id, '1');
  });
}
