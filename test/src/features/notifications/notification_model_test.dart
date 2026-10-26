import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_souls/src/features/notifications/data/models/notification_inbox_item.dart';
import 'package:wonder_souls/src/features/notifications/data/models/notification_item.dart';

void main() {
  group('NotificationItem', () {
    test('fromJson and toJson should correctly serialize/deserialize', () {
      final json = {
        'id': 'notif-123',
        'title': 'Trip Confirmed',
        'body': 'Your trip to Bali has been confirmed!',
        'audienceType': 'User',
        'audienceId': 'user-1',
        'notificationType': 'trip',
        'scheduledAtUtc': '2026-10-26T10:00:00.000Z',
        'status': 'Sent',
        'createdBy': 'system',
        'createdAt': '2026-10-26T10:00:00.000Z',
      };

      final item = NotificationItem.fromJson(json);

      expect(item.id, 'notif-123');
      expect(item.title, 'Trip Confirmed');
      expect(item.body, 'Your trip to Bali has been confirmed!');
      expect(item.audienceType, 'User');
      expect(item.notificationType, 'trip');
      expect(item.status, 'Sent');
      expect(item.createdAt, isNotNull);

      final backToJson = item.toJson();
      expect(backToJson['id'], 'notif-123');
      expect(backToJson['title'], 'Trip Confirmed');
    });

    test('copyWith creates a new instance with updated fields', () {
      const original = NotificationItem(
        id: '1',
        title: 'Original Title',
        body: 'Body',
      );

      final updated = original.copyWith(title: 'New Title');

      expect(updated.id, '1');
      expect(updated.title, 'New Title');
      expect(updated.body, 'Body');
    });
  });

  group('NotificationInboxItem', () {
    test('fromJson correctly parses inbox item and nested notification', () {
      final json = {
        'notification': {
          'id': 'notif-456',
          'title': 'Welcome to WanderSouls!',
          'body': 'Explore the world with us.',
          'notificationType': 'welcome',
          'createdAt': '2026-10-26T12:00:00.000Z',
        },
        'isRead': false,
        'readAtUtc': null,
      };

      final inboxItem = NotificationInboxItem.fromJson(json);

      expect(inboxItem.id, 'notif-456');
      expect(inboxItem.title, 'Welcome to WanderSouls!');
      expect(inboxItem.body, 'Explore the world with us.');
      expect(inboxItem.type, 'welcome');
      expect(inboxItem.isRead, false);
      expect(inboxItem.readAtUtc, isNull);
    });

    test('copyWith updates isRead status', () {
      final now = DateTime.now().toUtc();
      const inboxItem = NotificationInboxItem(
        notification: NotificationItem(id: '1', title: 'Hello'),
        isRead: false,
      );

      final readItem = inboxItem.copyWith(isRead: true, readAtUtc: now);

      expect(readItem.isRead, true);
      expect(readItem.readAtUtc, now);
      expect(readItem.id, '1');
    });
  });
}
