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
      backgroundColor: Colors.grey[50],
      body: statsAsync.when(
        data: (stats) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, ref),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Business Overview",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "Total Revenue",
                              "${Constants.currencySymbol}${NumberFormat.compact().format(stats['total_sales'])}",
                              Colors.green.shade700,
                              Icons.payments_outlined,
                              "Actual Sales",
                              isPrimary: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              "In Pipeline",
                              "${Constants.currencySymbol}${NumberFormat.compact().format(stats['total_booked'])}",
                              AppTheme.royalMaroon,
                              Icons.hourglass_top_outlined,
                              "Pending Delivery",
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
                              Colors.orange.shade800,
                              Icons.shopping_bag_outlined,
                              "Lifetime Volume",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              "Action Needed",
                              "${stats['pending_orders']}",
                              Colors.redAccent,
                              Icons.notification_important_outlined,
                              "New Requests",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildInsightsSection(stats),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20, 
        left: 24, 
        right: 24, 
        bottom: 30
      ),
      decoration: const BoxDecoration(
        color: AppTheme.royalMaroon,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Admin Portal", style: TextStyle(color: AppTheme.goldAccent, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  SizedBox(height: 4),
                  Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'CormorantGaramond')),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => ref.refresh(adminStatsProvider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, String subtitle, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isPrimary ? Border.all(color: color.withOpacity(0.3), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(Map<String, dynamic> stats) {
    return Container(
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
         gradient: LinearGradient(
           colors: [Colors.white, Colors.grey.shade50],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
         ),
         borderRadius: BorderRadius.circular(24),
         boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
         ],
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           const Row(
             children: [
               Icon(Icons.analytics_outlined, color: AppTheme.royalMaroon),
               SizedBox(width: 8),
               Text(
                 "Performance Insights",
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
               ),
             ],
           ),
           const SizedBox(height: 24),
           _buildInsightRow("Conversion Rate", "${((stats['completed_orders'] / (stats['total_orders'] == 0 ? 1 : stats['total_orders'])) * 100).toStringAsFixed(1)}%"),
           const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
           _buildInsightRow("Avg. Order Value", "${Constants.currencySymbol}${((stats['total_sales'] + stats['total_booked']) / (stats['total_orders'] == 0 ? 1 : stats['total_orders'])).toStringAsFixed(2)}"),
           const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
            _buildInsightRow("Pending Value", "${Constants.currencySymbol}${stats['total_booked'].toStringAsFixed(2)}"),
         ],
       ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
      ],
    );
  }
}
