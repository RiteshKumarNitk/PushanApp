import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../auth/auth_controller.dart'; 
import '../../core/app_theme.dart';

final supercoinHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return [];
  final response = await SupabaseConfig.client
      .from('supercoin_history')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final historyAsync = ref.watch(supercoinHistoryProvider);

    final supercoins = (userProfile != null && userProfile['supercoins'] != null)
        ? userProfile['supercoins'] as int
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Supercoin Wallet")),
      body: RefreshIndicator(
        onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(supercoinHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Supercoin Balance",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.yellowAccent, size: 36),
                        const SizedBox(width: 12),
                        Text(
                          "$supercoins",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildWalletAction(Icons.shopping_bag, "Redeem", () {
                          // Navigate to Product page? Or show info
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Use coins at checkout!")));
                        }),
                        _buildWalletAction(Icons.info_outline, "Info", () {
                           showDialog(context: context, builder: (c) => AlertDialog(
                             title: Text("Supercoin Info"),
                             content: Text("Earn coins on deliveries. Redeem 4 coins for 1 Rupee/Unit discount."),
                             actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: Text("OK"))],
                           ));
                        }),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recent Transactions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              historyAsync.when(
                data: (history) {
                   if (history.isEmpty) return const Text("No transactions yet.");
                   return ListView.builder(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: history.length,
                     itemBuilder: (context, index) {
                       final item = history[index];
                       final amount = item['amount'] as int;
                       final desc = item['description'] ?? 'Transaction';
                       final date = DateTime.parse(item['created_at']);
                       return _buildTransactionTile(desc, amount, date);
                     },
                   );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text("Error: $e"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(String title, int amount, DateTime date) {
    final isCredit = amount > 0;
    final displayAmount = isCredit ? "+ $amount" : "$amount"; 
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "${date.day}/${date.month} ${date.hour}:${date.minute}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
               Icon(Icons.monetization_on, size: 16, color: isCredit ? Colors.green : Colors.red),
               const SizedBox(width: 4),
               Text(
                displayAmount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
