import 'notification_item.dart';

class NotificationInboxItem {
  final NotificationItem? notification;
  final bool isRead;
  final DateTime? readAtUtc;

  const NotificationInboxItem({
    this.notification,
    this.isRead = false,
    this.readAtUtc,
  });

  factory NotificationInboxItem.fromJson(Map<String, dynamic> json) {
    return NotificationInboxItem(
      notification: json['notification'] != null &&
              json['notification'] is Map<String, dynamic>
          ? NotificationItem.fromJson(
              json['notification'] as Map<String, dynamic>,
            )
          : null,
      isRead: json['isRead'] as bool? ?? false,
      readAtUtc: json['readAtUtc'] != null
          ? DateTime.tryParse(json['readAtUtc'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification': notification?.toJson(),
      'isRead': isRead,
      'readAtUtc': readAtUtc?.toIso8601String(),
    };
  }

  NotificationInboxItem copyWith({
    NotificationItem? notification,
    bool? isRead,
    DateTime? readAtUtc,
  }) {
    return NotificationInboxItem(
      notification: notification ?? this.notification,
      isRead: isRead ?? this.isRead,
      readAtUtc: readAtUtc ?? this.readAtUtc,
    );
  }

  String get id => notification?.id ?? "";
  String get title => notification?.title ?? "Notification";
  String get body => notification?.body ?? "";
  String get type => notification?.notificationType ?? "general";
  DateTime? get createdAt => notification?.createdAt;

  /// Returns a human-friendly relative time (e.g. "Just now", "5m ago", "2h ago", "Yesterday")
  String get timeAgo {
    final date = createdAt;
    if (date == null) return "";
    final now = DateTime.now();
    final difference = now.difference(date.toLocal());

    if (difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
