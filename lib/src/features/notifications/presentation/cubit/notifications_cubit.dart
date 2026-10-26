import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonder_souls/src/config/usecase/usecase.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/get_my_notifications_usecase.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/mark_notification_read_usecase.dart';
import 'package:wonder_souls/src/features/notifications/presentation/cubit/notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final GetMyNotificationsUseCase getMyNotificationsUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;

  NotificationsCubit({
    required this.getMyNotificationsUseCase,
    required this.markNotificationReadUseCase,
  }) : super(const NotificationsInitial());

  Future<void> fetchNotifications({bool showLoading = true}) async {
    if (showLoading || state is NotificationsInitial) {
      emit(const NotificationsLoading());
    }

    final result = await getMyNotificationsUseCase(const NoParams());
    result.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (notifications) {
        final currentFilter = state is NotificationsLoaded
            ? (state as NotificationsLoaded).filter
            : NotificationFilter.all;

        emit(NotificationsLoaded(
          notifications: notifications,
          filter: currentFilter,
        ));
      },
    );
  }

  void setFilter(NotificationFilter filter) {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      emit(current.copyWith(filter: filter));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    final target = current.notifications.firstWhere(
      (item) => item.id == notificationId,
      orElse: () => current.notifications.first,
    );

    // If already read, nothing to do
    if (target.isRead) return;

    // Optimistically update
    final updatedList = current.notifications.map((item) {
      if (item.id == notificationId) {
        return item.copyWith(isRead: true, readAtUtc: DateTime.now().toUtc());
      }
      return item;
    }).toList();

    emit(current.copyWith(notifications: updatedList));

    final result = await markNotificationReadUseCase(
      MarkNotificationReadParams(notificationId: notificationId),
    );

    result.fold(
      (failure) {
        debugPrint(
          "Failed to mark notification $notificationId as read: ${failure.message}",
        );
      },
      (_) {},
    );
  }

  Future<void> markAllAsRead() async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    final unreadItems = current.notifications.where((n) => !n.isRead).toList();
    if (unreadItems.isEmpty) return;

    // Optimistically mark all as read
    final updatedList = current.notifications.map((item) {
      return item.copyWith(isRead: true, readAtUtc: DateTime.now().toUtc());
    }).toList();

    emit(current.copyWith(notifications: updatedList));

    // Send mark as read for each unread notification
    for (final item in unreadItems) {
      if (item.id.isNotEmpty) {
        markNotificationReadUseCase(
          MarkNotificationReadParams(notificationId: item.id),
        );
      }
    }
  }
}
