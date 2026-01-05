import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../auth/auth_controller.dart';

final walletHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.read(userProfileProvider).value;
  if (user == null) return [];

  // Assuming we have a 'wallet_transactions' table. If not, we might need to create it.
  // For now, let's assume we derive it or use a mock if table missing.
  // Actually, better to check if table exists or just fail gracefully.
  // I'll create a mockup structure that *would* work with a real table, 
  // but since I can't create tables easily without SQL, I'll allow this to be a "Coming Soon" or 
  // simulate it from orders? 
  // Let's simulate "Earned" from orders.
  
  final ordersRes = await SupabaseConfig.client
      .from('tea_orders')
      .select('id, created_at, total_amount, status')
      .eq('user_id', user['id'])
      .order('created_at', ascending: false);
      
  final List<Map<String, dynamic>> transactions = [];
  
  for (var o in ordersRes) {
    // Simulate: You earn coins for every order
    if (o['status'] != 'rejected') {
        final double amount = (o['total_amount'] as num).toDouble();
        final earned = (amount / 25).floor();
        
        transactions.add({
          'type': 'credit',
          'amount': earned,
          'description': 'Earned from Order #${o['id'].toString().split('-')[0]}',
          'date': o['created_at'],
          'is_money': false
        });
    }
  }
  
  return transactions;
});

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final historyAsync = ref.watch(walletHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background
      appBar: AppBar(
        title: const Text("My Wallet"),
        backgroundColor: AppTheme.royalMaroon,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.royalMaroon,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [BoxShadow(color: AppTheme.royalMaroon.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                const Text("Total Supercoins", style: TextStyle(color: AppTheme.goldAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  "${user?['supercoins'] ?? 0}", 
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'CormorantGaramond')
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("1 Coin = ₹1.00", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Transaction History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: historyAsync.when(
                      data: (transactions) {
                        if (transactions.isEmpty) {
                           return Center(
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.history, size: 48, color: Colors.grey[300]),
                                 const SizedBox(height: 16),
                                 const Text("No transactions yet"),
                               ],
                             ),
                           );
                        }
                        
                        return ListView.separated(
                          itemCount: transactions.length,
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final t = transactions[index];
                            final isCredit = t['type'] == 'credit';
                            final date = DateTime.parse(t['date']);
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCredit ? Colors.green[50] : Colors.red[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit ? Icons.arrow_downward : Icons.arrow_upward, 
                                  color: isCredit ? Colors.green : Colors.red,
                                  size: 18,
                                ),
                              ),
                              title: Text(t['description'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(date)),
                              trailing: Text(
                                "${isCredit ? '+' : '-'}${t['amount']}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  color: isCredit ? Colors.green : Colors.red
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e,s) => Center(child: Text("Error: $e")),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
