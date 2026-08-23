import 'package:flutter/material.dart';

import '../../controller/app_dependencies.dart';
import '../../controller/user_profile/user_profile_facade_interface.dart';
import '../../model/user_profile/app_notification.dart';
import '../collaborative_travel/invitations_view.dart';
import '../../theme/app_colors.dart';
import '../../widgets/malaysia_backdrop.dart';
import '../../widgets/malaysia_loading.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({required this.facade, super.key});

  final INotificationFacade facade;

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final INotificationFacade facade = widget.facade;

  @override
  void initState() {
    super.initState();
    facade.load();
  }

  @override
  void dispose() {
    facade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: facade,
    builder: (context, _) => MalaysiaLoadingBlocker(
      loading: facade.isLoading,
      message: 'Checking your travel messages...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            TextButton(
              onPressed: facade.unreadCount == 0 ? null : facade.markAllRead,
              child: const Text('Mark all read'),
            ),
          ],
        ),
        body: MalaysiaBackdrop(
          child: RefreshIndicator(
            onRefresh: facade.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                if (facade.error != null && facade.notifications.isEmpty)
                  _MessageCard(
                    icon: Icons.cloud_off_rounded,
                    message: facade.error!,
                  )
                else if (facade.notifications.isEmpty)
                  const _MessageCard(
                    icon: Icons.notifications_none_rounded,
                    message: 'No notifications yet.',
                  )
                else ...[
                  if (facade.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        facade.error!,
                        style: const TextStyle(color: AppColors.hibiscus),
                      ),
                    ),
                  ...facade.notifications.map(_notificationCard),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _notificationCard(AppNotification notification) => Card(
    color: notification.isUnread ? AppColors.paleMango : null,
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: _color(notification).withValues(alpha: .14),
        foregroundColor: _color(notification),
        child: Icon(_icon(notification)),
      ),
      title: Row(
        children: [
          Expanded(child: Text(notification.title)),
          if (notification.isUnread)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 4,
                backgroundColor: AppColors.hibiscus,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          '${notification.body}\n${_relativeTime(notification.createdAt)}',
        ),
      ),
      isThreeLine: true,
      onTap: () => _openNotification(notification),
    ),
  );

  Future<void> _openNotification(AppNotification notification) async {
    await facade.markRead(notification);
    if (!mounted || notification.type != 'mission_invitation') return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Mission invitations')),
          body: SafeArea(
            child: InvitationsView(
              facade: AppDependencies.collaborativeTravel(),
            ),
          ),
        ),
      ),
    );
    facade.load();
  }

  IconData _icon(AppNotification notification) => switch (notification.type) {
    'mission_invitation' => Icons.group_add_rounded,
    'mission_member_removed' => Icons.group_off_rounded,
    'group_diary_ready' => Icons.auto_stories_rounded,
    _ => Icons.notifications_rounded,
  };

  Color _color(AppNotification notification) => switch (notification.type) {
    'mission_invitation' => AppColors.purple,
    'mission_member_removed' => AppColors.hibiscus,
    'group_diary_ready' => AppColors.mango,
    _ => AppColors.teal,
  };

  String _relativeTime(DateTime time) {
    final difference = DateTime.now().difference(time.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${time.toLocal().day}/${time.toLocal().month}/${time.toLocal().year}';
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.teal),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
