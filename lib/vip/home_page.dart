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
    final userName = user?['full_name'] ?? 'Guest';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Namaste,",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.goldAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$userName Ji",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNotificationIcon(context, ref),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        backgroundImage: NetworkImage(Constants.avatarPlaceholder),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Business Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.royalMaroon,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.royalMaroon.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Business Account",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?['business_name'] ?? 'Pushan Tea Partner',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'CormorantGaramond',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryStat("Last Order", "---"),
                        _buildSummaryStat("Pending", "0 Orders"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.add_shopping_cart,
                      title: "Place New\nBulk Order",
                      color: AppTheme.deepGreen,
                      onTap: () {
                        ref.read(vipNavIndexProvider.notifier).state = 1; // Switch to Catalog
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.support_agent,
                      title: "Contact\nSupport",
                      color: AppTheme.goldAccent,
                      onTap: () async {
                         // Find First Admin to chat with
                         try {
                           final res = await SupabaseConfig.client.from('users').select().eq('role', 'admin').limit(1).single();
                           final adminId = res['id'];
                           final adminName = res['full_name'];
                           
                           if(context.mounted) {
                             Navigator.push(
                               context, 
                               MaterialPageRoute(
                                 builder: (_) => ChatScreen(otherUserId: adminId, otherUserName: adminName ?? 'Admin')
                               )
                             );
                           }
                         } catch (e) {
                           if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Support currently offline")));
                         }
                      },
                      isDark: false,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isDark = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                color: isDark ? Colors.white : AppTheme.royalMaroon, 
                size: 24,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.royalMaroon,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadMessageCountProvider);

    return InkWell(
      onTap: () async {
         // Find First Admin to chat with
         try {
           final res = await SupabaseConfig.client.from('users').select().eq('role', 'admin').limit(1).single();
           final adminId = res['id'];
           final adminName = res['full_name'];
           
           if(context.mounted) {
             Navigator.push(
               context, 
               MaterialPageRoute(
                 builder: (_) => ChatScreen(otherUserId: adminId, otherUserName: adminName ?? 'Admin')
               )
             );
           }
         } catch (e) {
           if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Support currently offline")));
         }
      },
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(blurRadius: 5, color: Colors.black12, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.notifications_none, color: AppTheme.royalMaroon),
          ),
          unreadAsync.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
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
