import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/model/user_profile/app_notification.dart';

void main() {
  test('parses unread notification and can mark it read', () {
    final notification = AppNotification.fromJson({
      'id': 'notification-1',
      'notification_type': 'mission_invitation',
      'title': 'Invitation',
      'body': 'Join a mission.',
      'data': {'session_id': 'session-1'},
      'created_at': '2026-07-28T10:00:00Z',
      'read_at': null,
    });

    expect(notification.isUnread, isTrue);
    expect(notification.data['session_id'], 'session-1');
    expect(notification.markRead(DateTime.utc(2026, 7, 28)).isUnread, isFalse);
  });
}
