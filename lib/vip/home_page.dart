import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

// --- PROVIDERS (Kept same logic, just cleaner) ---

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

final activeAnnouncementProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return SupabaseConfig.client
      .from('announcements')
      .stream(primaryKey: ['id'])
      .eq('is_active', true)
      .limit(1)
      .map((data) => data.isNotEmpty ? data.first : null);
});


// --- MAIN WIDGET ---

class VipHomePage extends ConsumerWidget {
  const VipHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.value;
    final productsAsync = ref.watch(productListProvider);
    final announcementAsync = ref.watch(activeAnnouncementProvider);
    
    // Greeting Logic
    final hour = DateTime.now().hour;
    String greeting = "Welcome back,";
    if (hour < 12) greeting = "Good Morning,";
    else if (hour < 17) greeting = "Good Afternoon,";
    else greeting = "Good Evening,";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Very light grey, modern web app feel
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting, 
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600], 
                          fontSize: 14,
                          fontWeight: FontWeight.w500
                        )
                      ),
                      Text(
                        user?['full_name'] ?? 'Guest',
                        style: GoogleFonts.poppins(
                          fontSize: 24, 
                          fontWeight: FontWeight.w700, 
                          color: const Color(0xFF1A1A1A)
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _SupportChatButton(ref: ref),
                      const SizedBox(width: 12),
                      _NotificationButton(ref: ref),
                    ],
                  )
                ],
              ),
              
              const SizedBox(height: 32),

              // 2. DASHBOARD CARDS (Wallet & Orders)
              const _DashboardStatsRow(),
              
              const SizedBox(height: 32),

              // 3. ANNOUNCEMENT (Condition Render)
              announcementAsync.when(
                data: (data) => data != null ? _ModernAnnouncementCard(data: data) : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_,__) => const SizedBox.shrink(),
              ),
              if (announcementAsync.value != null) const SizedBox(height: 32),

              // 4. QUICK ACTIONS GRID
              Text(
                "Quick Actions", 
                style: GoogleFonts.poppins(
                  fontSize: 18, 
                  fontWeight: FontWeight.w600, 
                  color: const Color(0xFF1A1A1A)
                )
              ),
              const SizedBox(height: 16),
              const _QuickActionsGrid(),

              const SizedBox(height: 32),

              // 5. FEATURED COLLECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Featured Collection", 
                    style: GoogleFonts.poppins(
                      fontSize: 18, 
                      fontWeight: FontWeight.w600, 
                      color: const Color(0xFF1A1A1A)
                    )
                  ),
                  TextButton(
                    onPressed: () => ref.read(vipNavIndexProvider.notifier).state = 1, // Go to Catalog
                    child: Text("View All", style: GoogleFonts.poppins(color: AppTheme.royalMaroon, fontWeight: FontWeight.w600))
                  )
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: productsAsync.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return const Center(child: Text("No products featured yet."));
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 20),
                      itemBuilder: (context, index) => _ModernProductCard(product: products[index]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => const Center(child: Text("Unable to load collection")),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // 6. BRAND BANNER (Subtle footer)
              const _ModernBrandBanner(),
              const SizedBox(height: 80), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }
}

// --- SUB-WIDGETS & COMPONENTS ---

class _DashboardStatsRow extends ConsumerWidget {
  const _DashboardStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final lastOrderAsync = ref.watch(lastOrderProvider);

    return Row(
      children: [
        // Credit Card
        Expanded(
          child: GestureDetector(
             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())),
             child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A), // Dark elegant card
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                     child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 20),
                   ),
                   const SizedBox(height: 16),
                   Text("Available Credit", style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
                   const SizedBox(height: 4),
                   Text(
                     "${user?['supercoins'] ?? 0}", 
                     style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)
                   ),
                   const SizedBox(height: 4),
                   Text("Supercoins", style: GoogleFonts.poppins(color: AppTheme.goldAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
             ),
          ),
        ),
        const SizedBox(width: 16),
        // Last Order Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: lastOrderAsync.when(
              data: (order) {
                final status = order != null ? (order['status'] as String).toUpperCase() : 'NO ORDERS';
                final date = order != null ? DateTime.parse(order['created_at']).toString().split(' ')[0] : '-';
                Color statusColor = Colors.grey;
                if (status == 'DELIVERED') statusColor = Colors.green;
                else if (status == 'PLACED') statusColor = Colors.orange;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                       child: Icon(Icons.local_shipping_outlined, color: statusColor, size: 20),
                     ),
                     const SizedBox(height: 16),
                     Text("Last Order", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
                     const SizedBox(height: 4),
                     Text(
                       status, 
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                       style: GoogleFonts.poppins(color: const Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.w600)
                     ),
                     const SizedBox(height: 4),
                     Text(date, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_,__) => const Center(child: Icon(Icons.error_outline, color: Colors.grey)),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _buildActionBtn(
          context, 
          icon: Icons.add_shopping_cart, 
          label: "New Order", 
          color: AppTheme.royalMaroon,
          onTap: () => ref.read(vipNavIndexProvider.notifier).state = 1
        ),
        const SizedBox(width: 16),
        _buildActionBtn(
          context, 
          icon: Icons.inventory_2_outlined, 
          label: "Track", 
          color: AppTheme.deepGreen,
          onTap: () => ref.read(vipNavIndexProvider.notifier).state = 2
        ),
        const SizedBox(width: 16),
        _buildActionBtn(
          context, 
          icon: Icons.support_agent, 
          label: "Support", 
          color: Colors.orange,
          onTap: () async {
            // Re-using the robust chat logic
            try {
               final res = await SupabaseConfig.client.from('users').select().eq('role', 'admin').limit(1).maybeSingle();
               if (res != null && context.mounted) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                   otherUserId: res['id'], 
                   otherUserName: res['full_name'] ?? 'Support Admin'
                 )));
               } else {
                 if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Support offline")));
               }
             } catch (e) { /* ignore */ }
          }
        ),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ]
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernProductCard extends StatelessWidget {
  final dynamic product;
  const _ModernProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: DecorationImage(
                  image: NetworkImage((product.imageUrl != null && product.imageUrl.isNotEmpty) ? product.imageUrl : Constants.defaultTeaImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.category?.toUpperCase() ?? 'TEA', 
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis, 
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))
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

class _ModernAnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ModernAnnouncementCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF9966), Color(0xFFFF5E62)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFFF5E62).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text("NEW OFFER", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(data['title'] ?? 'Announcement', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(data['message'] ?? '', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 14)),
        ],
      ),
    );
  }
}

class _ModernBrandBanner extends StatelessWidget {
  const _ModernBrandBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pushan Tea Legacy", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                Text("Experience the finest hand-picked tea leaves from our gardens.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.verified, color: Colors.grey, size: 32),
        ],
      ),
    );
  }
}

// --- BUTTONS ---

class _SupportChatButton extends ConsumerWidget {
  final WidgetRef ref;
  const _SupportChatButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadMessageCountProvider);
    return InkWell(
      onTap: () async {
         try {
           final res = await SupabaseConfig.client
               .from('users')
               .select()
               .eq('role', 'admin')
               .limit(1)
               .maybeSingle(); // ROBUST FETCH
           
           if (res != null && context.mounted) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
               otherUserId: res['id'], 
               otherUserName: res['full_name'] ?? 'Support Admin'
             )));
           } else {
             if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Support unavailable")));
           }
         } catch (e) { /* ignore */ }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!)
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.support_agent, color: Color(0xFF1A1A1A), size: 24),
            unreadAsync.when(
              data: (count) {
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  top: -2, right: -2,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_,__) => const SizedBox.shrink(),
            )
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends ConsumerWidget {
  final WidgetRef ref;
  const _NotificationButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!)
        ),
        child: const Icon(Icons.notifications_outlined, color: Color(0xFF1A1A1A), size: 24),
      ),
    );
  }
}
