import 'package:flutter/foundation.dart';

import '../services/config/app_config.dart';
import '../services/errors/api_error.dart';
import '../../model/user_profile/app_notification.dart';
import '../services/supabase/supabase_data_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({SupabaseDataService? dataService})
    : _dataService = dataService ?? SupabaseDataService();

  final SupabaseDataService _dataService;

  List<AppNotification> notifications = const [];
  bool isLoading = false;
  String? error;

  int get unreadCount =>
      notifications.where((notification) => notification.isUnread).length;

  Future<void> load() async {
    if (!AppConfig.demoMode && !AppConfig.isConfigured) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      notifications = await _dataService.loadNotifications();
    } on ApiError catch (apiError) {
      error = apiError.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotification notification) async {
    if (!notification.isUnread) return;
    try {
      final readAt = DateTime.now().toUtc();
      await _dataService.markNotificationRead(notification.id, readAt);
      notifications = notifications
          .map(
            (item) => item.id == notification.id ? item.markRead(readAt) : item,
          )
          .toList(growable: false);
      notifyListeners();
    } on ApiError catch (apiError) {
      error = apiError.message;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    try {
      final readAt = DateTime.now().toUtc();
      await _dataService.markAllNotificationsRead(readAt);
      notifications = notifications
          .map((notification) => notification.markRead(readAt))
          .toList(growable: false);
      notifyListeners();
    } on ApiError catch (apiError) {
      error = apiError.message;
      notifyListeners();
    }
  }
}
