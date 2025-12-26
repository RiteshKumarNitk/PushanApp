import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/supabase_config.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Fetch all orders with relevant fields
  final res = await SupabaseConfig.client
      .from('tea_orders')
      .select('status, total_amount, created_at');

  final orders = List<Map<String, dynamic>>.from(res);

  double totalRevenue = 0; // Delivered
  double totalBooked = 0; // Active (Approved, Packed, Shipped)
  int pendingCount = 0; // Requested
  int completedCount = 0; // Delivered

  for (var o in orders) {
    final status = o['status'];
    final amount = (o['total_amount'] as num).toDouble();

    if (status == 'delivered') {
      totalRevenue += amount;
      completedCount++;
    } else if (['approved', 'packed', 'shipped'].contains(status)) {
      totalBooked += amount;
    } else if (status == 'requested') {
      pendingCount++;
    }
  }

  return {
    'total_sales': totalRevenue,
    'total_booked': totalBooked,
    'total_orders': orders.length,
    'pending_orders': pendingCount,
    'completed_orders': completedCount,
  };
});

class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pushan Tea Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(adminStatsProvider),
          )
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Overview",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Total Sell",
                        "${Constants.currencySymbol}${NumberFormat.compact().format(stats['total_sales'])}",
                        Colors.green,
                        Icons.payments,
                        "Revenue",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        "Total Booked",
                        "${Constants.currencySymbol}${NumberFormat.compact().format(stats['total_booked'])}",
                        Colors.blue,
                        Icons.pending_actions,
                        "In Pipeline",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Total Orders",
                        "${stats['total_orders']}",
                        Colors.orange,
                        Icons.shopping_bag,
                        "Lifetime",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        "Pending Requests",
                        "${stats['pending_orders']}",
                        Colors.redAccent,
                        Icons.new_releases,
                        "Needs Action",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: Colors.grey.shade200),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text(
                         "Analytics Insights",
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: 16),
                       _buildInsightRow("Conversion Rate", "${((stats['completed_orders'] / (stats['total_orders'] == 0 ? 1 : stats['total_orders'])) * 100).toStringAsFixed(1)}%"),
                       const Divider(),
                       _buildInsightRow("Active Pipeline Value", "${Constants.currencySymbol}${stats['total_booked'].toStringAsFixed(2)}"),
                       const Divider(),
                       _buildInsightRow("Avg. Order Value", "${Constants.currencySymbol}${((stats['total_sales'] + stats['total_booked']) / (stats['total_orders'] == 0 ? 1 : stats['total_orders'])).toStringAsFixed(2)}"),
                     ],
                   ),
                )
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                subtitle,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9), // Darker shade for text
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    );
  }
}
