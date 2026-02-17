import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_controller.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/supabase_config.dart';
import '../../shared/screens/chat_screen.dart';
import 'vip_bottom_nav.dart';
import 'unread_message_controller.dart';
import 'product_page.dart'; // For productListProvider
import '../profile/notifications_page.dart';
import 'wallet_page.dart';

// Define lastOrderProvider locally or find a better home later
final lastOrderProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.read(userProfileProvider).value;
  if (user == null) return null;

  final res = await SupabaseConfig.client
      .from('tea_orders')
      .select()
      .eq('user_id', user['id']) 
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();
      
  return res;
});

// Provider for Active Announcement
final activeAnnouncementProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return SupabaseConfig.client
      .from('announcements')
      .stream(primaryKey: ['id'])
      .eq('is_active', true)
      .limit(1)
      .map((data) => data.isNotEmpty ? data.first : null);
});

class VipHomePage extends ConsumerWidget {
  const VipHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.value;
    final hour = DateTime.now().hour;
    String greeting = "Namaste";
    if (hour < 12) greeting = "Good Morning";
    else if (hour < 17) greeting = "Good Afternoon";
    else greeting = "Good Evening";

    final lastOrderAsync = ref.watch(lastOrderProvider);
    final productsAsync = ref.watch(productListProvider);
    final announcementAsync = ref.watch(activeAnnouncementProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Background Gradient
                Container(
                  height: 280, 
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.royalMaroon, AppTheme.deepGreen],
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                ),
                // Decorative Circle
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(greeting, style: const TextStyle(color: AppTheme.goldAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                                Text(
                                  user?['full_name'] ?? 'Guest',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'CormorantGaramond'),
                                ),
                              ],
                            ),
                          Row(
                            children: [
                              _buildChatIcon(context, ref),
                              const SizedBox(width: 12),
                              _buildRealNotificationIcon(context, ref),
                            ],
                          ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Stats Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Last Order Status
                              Expanded(
                                child: lastOrderAsync.when(
                                  data: (order) {
                                    final status = order != null ? (order['status'] as String).toUpperCase() : 'NO ORDERS';
                                    final date = order != null ? DateTime.parse(order['created_at']).toString().split(' ')[0] : '';
                                    return _buildStatItem("Last Order", status, subtitle: date, color: _getStatusColor(status));
                                  },
                                  loading: () => _buildStatItem("Last Order", "Loading..."),
                                  error: (e,s) => _buildStatItem("Last Order", "Error"),
                                ),
                              ),
                              Container(width: 1, height: 40, color: Colors.grey[200]),
                              // Supercoins Credit
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage()));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: _buildStatItem(
                                      "Your Credit", 
                                      "${user?['supercoins'] ?? 0}", 
                                      subtitle: "Supercoins",
                                      color: AppTheme.primaryGreen,
                                      icon: Icons.monetization_on
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- BODY CONTENT ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Quick Actions
                  const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.add_shopping_cart,
                          title: "New Request",
                          subtitle: "Bulk Order",
                          color: AppTheme.royalMaroon,
                          onTap: () {
                             ref.read(vipNavIndexProvider.notifier).state = 1; 
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.history,
                          title: "Track Order",
                          subtitle: "Check Status",
                          color: AppTheme.deepGreen,
                          onTap: () => ref.read(vipNavIndexProvider.notifier).state = 2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ACTIVE ANNOUNCEMENT / ADVERTISEMENT
                  announcementAsync.when(
                    data: (data) => data != null ? _buildAnnouncementCard(data) : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_,__) => const SizedBox.shrink(),
                  ),

                  if (announcementAsync.value != null) const SizedBox(height: 24),

                  // Pushan Tea Story / Banner
                  _buildBrandBanner(),

                  const SizedBox(height: 24),

                  // Featured Products Horizontal List
                  const Text("Featured Collections", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: productsAsync.when(
                      data: (products) {
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: products.length,
                          separatorBuilder: (c, i) => const SizedBox(width: 16),
                          itemBuilder: (context, index) => _buildFeaturedProductCard(products[index]),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => const Center(child: Text("Unable to load collections")),
                    ),
                  ),
                   
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DELIVERED': return Colors.green;
      case 'IN_PROGRESS': return Colors.blue;
      case 'PLACED': return Colors.orange;
      case 'NO ORDERS': return Colors.grey;
      default: return Colors.black87;
    }
  }

  Widget _buildStatItem(String label, String value, {String? subtitle, Color? color, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
            if(icon != null) ...[const SizedBox(width: 4), Icon(icon, size: 14, color: Colors.orange)],
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color ?? Colors.black87)),
        if (subtitle != null)
        Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
      ],
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Vibrant gradient for ads
        gradient: const LinearGradient(colors: [Colors.orange, Colors.redAccent]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Text("SPECIAL OFFER", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Icon(Icons.local_offer, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['title'] ?? 'Special Announcement',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            data['message'] ?? 'Check out our latest offers!',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.royalMaroon,
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
           image: NetworkImage("https://images.unsplash.com/photo-1594631230802-325a3310110c?auto=format&fit=crop&q=80&w=1000"),
           fit: BoxFit.cover,
           opacity: 0.2, 
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pushan Tea Legacy", style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "Experience the finest\nhand-picked tea leaves.",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'CormorantGaramond'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.royalMaroon,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8)
            ),
            child: const Text("Read Our Story"),
          )
        ],
      ),
    );
  }

  Widget _buildFeaturedProductCard(dynamic product) {
    // Assuming product object structure
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                (product.imageUrl != null && product.imageUrl.isNotEmpty) ? product.imageUrl : Constants.defaultTeaImage,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (c,e,s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(product.category ?? 'Premium Tea', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          )
        ],
      ),
    );
  }



  Widget _buildActionCard({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportBanner(BuildContext context) {
    return InkWell(
      onTap: () async {
         try {
           final res = await SupabaseConfig.client.from('users').select().eq('role', 'admin').limit(1).single();
           final adminId = res['id'];
           final adminName = res['full_name'];
           
           if(context.mounted) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: adminId, otherUserName: adminName ?? 'Admin')));
           }
         } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Support currently offline")));
         }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.goldAccent, Colors.orange.shade300]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
              child: const Icon(Icons.headset_mic, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Need Help?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Chat with our tea experts", style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }


  Widget _buildChatIcon(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadMessageCountProvider);

    return InkWell(
      onTap: () async {
         try {
           final res = await SupabaseConfig.client.from('users').select().eq('role', 'admin').limit(1).single();
           if(context.mounted) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: res['id'], otherUserName: res['full_name'] ?? 'Admin')));
           }
         } catch (e) { /* ignore */ }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1), 
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
            unreadAsync.when(
              data: (count) {
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_,__) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealNotificationIcon(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
      ),
    );
  }
}
