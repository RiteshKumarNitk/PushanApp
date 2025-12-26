import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import '../core/supabase_config.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../auth/auth_controller.dart';
import 'order_detail_page.dart';

// Fetch All Orders for Admin
final adminOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseConfig.client
      .from('tea_orders')
      .select('*, users:user_id(full_name, business_name)') // Join with users to get name
      .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(response);
});

class AdminOrdersTab extends ConsumerWidget {
  const AdminOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(adminOrdersProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) return const Center(child: Text("No orders found"));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final order = orders[index];
              final user = order['users'] as Map<String, dynamic>?;
              final status = order['status'] as String;
              final total = (order['total_amount'] as num).toDouble();
              final date = DateTime.parse(order['created_at']).toLocal();

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => AdminOrderDetailPage(orderId: order['id']))
                  ).then((_) => ref.refresh(adminOrdersProvider)); // Refresh on return
                },
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  child: Icon(
                    _getStatusIcon(status), 
                    color: _getStatusColor(status),
                    size: 20,
                  ),
                ),
                title: Text(
                  user?['business_name'] ?? user?['full_name'] ?? 'Unknown User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${DateFormat('dd MMM').format(date)} • ${status.toUpperCase()}",
                  style: TextStyle(color: _getStatusColor(status)),
                ),
                trailing: Text(
                  "${Constants.currencySymbol}${total.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'requested': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'packed': return Colors.indigo;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'requested': return Icons.new_releases;
      case 'approved': return Icons.thumb_up;
      case 'packed': return Icons.inventory_2;
      case 'shipped': return Icons.local_shipping;
      case 'delivered': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.help;
    }
  }
}
