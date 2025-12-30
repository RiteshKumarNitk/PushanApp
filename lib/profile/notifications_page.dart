import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../auth/auth_controller.dart';
import '../../shared/models/app_notification.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.read(userProfileProvider).value;
  if (user == null) return const Stream.empty();

  return SupabaseConfig.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user['id'])
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => AppNotification.fromJson(json)).toList());
});

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: notificationsAsync.when(
        data: (notifications) {
           if (notifications.isEmpty) {
             return const Center(child: Text("No notifications yet"));
           }
           return ListView.separated(
             padding: const EdgeInsets.all(16),
             itemCount: notifications.length,
             separatorBuilder: (c, i) => const Divider(),
             itemBuilder: (context, index) {
               final notification = notifications[index];
               return ListTile(
                 leading: CircleAvatar(
                   backgroundColor: _getColorForType(notification.type).withOpacity(0.1),
                   child: Icon(_getIconForType(notification.type), color: _getColorForType(notification.type)),
                 ),
                 title: Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold)),
                 subtitle: Text(notification.message),
                 trailing: Text(notification.timeAgo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
               );
             },
           );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'order_update': return Colors.blue;
      case 'promo': return Colors.purple;
      case 'alert': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _getIconForType(String type) {
     switch (type) {
      case 'order_update': return Icons.local_shipping;
      case 'promo': return Icons.local_offer;
      case 'alert': return Icons.warning;
      default: return Icons.notifications;
    }
  }
}
