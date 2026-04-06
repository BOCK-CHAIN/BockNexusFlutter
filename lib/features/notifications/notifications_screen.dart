import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/mock_data.dart';
import 'providers/notification_providers.dart';
import '../../core/utils/snackbar_utils.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    // Group by date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayList = notifications.where((n) {
      final d = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      return d == today || d.isAfter(today);
    }).toList();
    final yesterdayList = notifications.where((n) {
      final d = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      return d == yesterday;
    }).toList();
    final earlierList = notifications.where((n) {
      final d = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      return d.isBefore(yesterday);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Mark All Read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmpty(context, theme)
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (todayList.isNotEmpty) ...[
                  _sectionHeader(theme, 'Today'),
                  ...todayList.map((n) => _buildNotificationTile(context, ref, theme, n)),
                ],
                if (yesterdayList.isNotEmpty) ...[
                  _sectionHeader(theme, 'Yesterday'),
                  ...yesterdayList.map((n) => _buildNotificationTile(context, ref, theme, n)),
                ],
                if (earlierList.isNotEmpty) ...[
                  _sectionHeader(theme, 'Earlier'),
                  ...earlierList.map((n) => _buildNotificationTile(context, ref, theme, n)),
                ],
              ],
            ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.8,
          )),
    );
  }

  Widget _buildNotificationTile(BuildContext context, WidgetRef ref, ThemeData theme, AppNotification notif) {
    final (Color accent, IconData icon) = switch (notif.type) {
      NotificationType.orderUpdate => (Colors.blue, Icons.local_shipping_outlined),
      NotificationType.dealAlert => (Colors.green, Icons.local_offer_outlined),
      NotificationType.priceDrop => (Colors.orange, Icons.trending_down),
      NotificationType.system => (Colors.grey, Icons.info_outline),
    };

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(notificationsProvider.notifier).dismiss(notif.id),
      child: InkWell(
        onTap: () {
          ref.read(notificationsProvider.notifier).markRead(notif.id);
          showAppSnackBar(context, notif.deepLink != null
              ? 'Navigating to ${notif.deepLink}'
              : 'Notification tapped');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: notif.isRead ? null : accent.withValues(alpha: 0.04),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                              )),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notif.body,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(_timeAgo(notif.timestamp),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, size: 72,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            Text('No Notifications',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("You're all caught up!",
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
