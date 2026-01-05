import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import '../core/supabase_config.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
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
    final themeColor = AppTheme.primaryGreen;

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adminOrdersProvider),
      child: Column(
        children: [
          // Custom Header
          Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Management", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    const Text("Client Orders", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: themeColor),
                    onPressed: () => ref.refresh(adminOrdersProvider),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                         const SizedBox(height: 16),
                         const Text("No orders found", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: orders.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildOrderCard(context, ref, orders[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Map<String, dynamic> order) {
    final user = order['users'] as Map<String, dynamic>?;
    final status = order['status'] as String;
    final rawTotal = order['total_amount'];
    final total = (rawTotal is num) ? rawTotal.toDouble() : 0.0;
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPending ? Colors.orange.withOpacity(0.3) : Colors.transparent, width: 1),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "#${order['id'].toString().substring(0, 8).toUpperCase()}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?['business_name'] ?? user?['full_name'] ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd • HH:mm').format(date),
                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  "${Constants.currencySymbol}${NumberFormat('#,##0.00').format(total)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'requested': color = Colors.orange; break;
      case 'approved': color = Colors.blue; break;
      case 'packed': color = Colors.indigo; break;
      case 'shipped': color = Colors.purple; break;
      case 'delivered': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Color _getStatusColor(String status) {
      // Helper kept if needed, but mostly served by _buildStatusBadge now
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
