import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/supabase_config.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import 'admin_users_page.dart';

// Provider to fetch minimal stats (Mock or Real)
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await SupabaseConfig.client
      .from('tea_orders')
      .select('status, total_amount');

  final orders = List<Map<String, dynamic>>.from(res);
  double totalRevenue = 0.0; 
  double pendingAmount = 0.0;
  int pendingCount = 0;

  for (var o in orders) {
    final status = o['status'];
    // Safely handle total_amount being null or not a number
    final rawAmount = o['total_amount'];
    final double amount = (rawAmount is num) ? rawAmount.toDouble() : 0.0;

    if (status == 'delivered') {
      totalRevenue += amount;
    } else if (['placed', 'in_progress'].contains(status)) {
      pendingAmount += amount;
    }
    if (status == 'placed') {
      pendingCount++;
    }
  }

  return {
    'total_sales': totalRevenue,
    'pending_value': pendingAmount,
    'total_orders': orders.length,
    'action_needed': pendingCount,
  };
});

class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    // Using app theme colors for consistency
    final primaryColor = AppTheme.primaryGreen;

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adminStatsProvider),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Header Area
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 40),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    "Welcome back, Admin",
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Dashboard",
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.date_range, color: Colors.white, size: 20),
                      )
                    ],
                  ),
                ],
              ),
            ),
            
            // Stats Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: statsAsync.when(
                data: (stats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Business Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard("Revenue", "${Constants.currencySymbol}${NumberFormat.compact().format(stats['total_sales'])}", Colors.green, Icons.attach_money)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard("Pending", "${Constants.currencySymbol}${NumberFormat.compact().format(stats['pending_value'])}", Colors.orange, Icons.pending_actions)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard("Total Orders", "${stats['total_orders']}", Colors.purple, Icons.shopping_bag)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard("New Requests", "${stats['action_needed']}", Colors.red, Icons.notification_important)),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    const SizedBox(height: 16),
                    
                    // Quick Action List
                    _buildQuickAction(context, "Manage Users", "View and edit user roles", Icons.people_outline, Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text("Users")), body: const AdminUsersPage())));
                    }),
                    const SizedBox(height: 12),
                    // Add more actions as needed...
                  ],
                ),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                error: (e,s) => Text("Error: $e"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 24, child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
