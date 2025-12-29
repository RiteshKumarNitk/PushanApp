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
      .select('*, users:user_id(full_name, business_name)') 
      .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(response);
});

class AdminOrdersTab extends ConsumerWidget {
  const AdminOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text("Orders Management"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
             icon: const Icon(Icons.refresh, color: AppTheme.royalMaroon),
            onPressed: () => ref.refresh(adminOrdersProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   const Text("No orders yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildOrderCard(context, ref, orders[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Map<String, dynamic> order) {
    final user = order['users'] as Map<String, dynamic>?;
    final status = order['status'] as String;
    final total = (order['total_amount'] as num).toDouble();
    final date = DateTime.parse(order['created_at']).toLocal();
    final isPending = status == 'requested';

    return InkWell(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => AdminOrderDetailPage(orderId: order['id']))
        ).then((_) => ref.refresh(adminOrdersProvider));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPending ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5) : null,
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "#${order['id'].toString().substring(0, 8).toUpperCase()}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?['business_name'] ?? user?['full_name'] ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(status).withOpacity(0.2)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status), 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  "${Constants.currencySymbol}${total.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.royalMaroon),
                ),
              ],
            ),
          ],
        ),
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
}
