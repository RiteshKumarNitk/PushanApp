import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_controller.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/supabase_config.dart';
import '../../shared/screens/chat_screen.dart';
import 'vip_bottom_nav.dart';
import 'unread_message_controller.dart';

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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 260, // Increased height for announcement space
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.royalMaroon, AppTheme.royalMaroon.withOpacity(0.8)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$greeting,",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.goldAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?['full_name'] ?? 'Guest',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'CormorantGaramond',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildNotificationIcon(context, ref),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.goldAccent, width: 2),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(Constants.avatarPlaceholder),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Active Announcement (If any)
                        StreamBuilder(
                          stream: SupabaseConfig.client
                              .from('announcements')
                              .stream(primaryKey: ['id'])
                              .eq('is_active', true)
                              .limit(1),
                          builder: (context, snapshot) {
                             if (!snapshot.hasData || (snapshot.data as List).isEmpty) return const SizedBox.shrink();
                             final offer = (snapshot.data as List).first;
                             
                             return Container(
                               margin: const EdgeInsets.only(bottom: 24),
                               width: double.infinity,
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                               decoration: BoxDecoration(
                                 color: AppTheme.goldAccent,
                                 borderRadius: BorderRadius.circular(12),
                                 boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8)],
                               ),
                               child: Row(
                                 children: [
                                   const Icon(Icons.stars, color: AppTheme.royalMaroon),
                                   const SizedBox(width: 12),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(offer['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.royalMaroon)),
                                         Text(offer['message'], style: const TextStyle(fontSize: 12, color: AppTheme.royalMaroon, fontWeight: FontWeight.w500)),
                                       ],
                                     ),
                                   ),
                                 ],
                               ),
                             );
                          },
                        ),
                        
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Business Account",
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?['business_name'] ?? 'VIP Partner',
                                        style: TextStyle(
                                          color: AppTheme.royalMaroon,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.royalMaroon.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.storefront, color: AppTheme.royalMaroon),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem("Last Order", "---"),
                                  _buildStatItem("Status", "Active", color: Colors.green),
                                  _buildStatItem("Credit", "₹0.00"),
                                ],
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
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick Actions",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.add_shopping_cart,
                          title: "New Order",
                          subtitle: "Browse Catalog",
                          color: AppTheme.deepGreen,
                          onTap: () {
                            ref.read(vipNavIndexProvider.notifier).state = 1; 
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.history,
                          title: "Past Orders",
                          subtitle: "Track Status",
                          color: AppTheme.royalMaroon,
                          onTap: () {
                             ref.read(vipNavIndexProvider.notifier).state = 2; 
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSupportBanner(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color ?? Colors.black87)),
      ],
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


  Widget _buildNotificationIcon(BuildContext context, WidgetRef ref) {
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none, color: Colors.white.withOpacity(0.9), size: 28),
          unreadAsync.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_,__) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
