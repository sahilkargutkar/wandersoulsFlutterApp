class NotificationItem {
  final String? id;
  final String? title;
  final String? body;
  final String? audienceType;
  final String? audienceId;
  final String? notificationType;
  final DateTime? scheduledAtUtc;
  final String? status;
  final String? createdBy;
  final DateTime? createdAt;

  const NotificationItem({
    this.id,
    this.title,
    this.body,
    this.audienceType,
    this.audienceId,
    this.notificationType,
    this.scheduledAtUtc,
    this.status,
    this.createdBy,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      audienceType: json['audienceType'] as String?,
      audienceId: json['audienceId'] as String?,
      notificationType: json['notificationType'] as String?,
      scheduledAtUtc: json['scheduledAtUtc'] != null
          ? DateTime.tryParse(json['scheduledAtUtc'].toString())
          : null,
      status: json['status'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'audienceType': audienceType,
      'audienceId': audienceId,
      'notificationType': notificationType,
      'scheduledAtUtc': scheduledAtUtc?.toIso8601String(),
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? audienceType,
    String? audienceId,
    String? notificationType,
    DateTime? scheduledAtUtc,
    String? status,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      audienceType: audienceType ?? this.audienceType,
      audienceId: audienceId ?? this.audienceId,
      notificationType: notificationType ?? this.notificationType,
      scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
