import 'package:wonder_souls/src/features/notifications/data/models/notification_inbox_item.dart';

enum NotificationFilter { all, unread }

sealed class NotificationsState {
  const NotificationsState();
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationInboxItem> notifications;
  final NotificationFilter filter;

  const NotificationsLoaded({
    required this.notifications,
    this.filter = NotificationFilter.all,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationInboxItem> get filteredNotifications {
    if (filter == NotificationFilter.unread) {
      return notifications.where((n) => !n.isRead).toList();
    }
    return notifications;
  }

  NotificationsLoaded copyWith({
    List<NotificationInboxItem>? notifications,
    NotificationFilter? filter,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      filter: filter ?? this.filter,
    );
  }
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
}
