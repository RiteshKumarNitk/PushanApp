import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';
import '../core/app_theme.dart';
import 'admin_dashboard_tab.dart';
import 'admin_orders_tab.dart';
import 'admin_products_tab.dart';
import 'admin_announcements_tab.dart';
import 'admin_chat_tab.dart';
import 'admin_users_page.dart';
import 'admin_coupons_tab.dart';

final adminCurrentPageProvider = StateProvider<int>((ref) => 0);

class AdminScaffold extends ConsumerWidget {
  const AdminScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPageIndex = ref.watch(adminCurrentPageProvider);
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    // Ordered List of Pages matching the Menu
    final pages = [
      const AdminDashboardTab(),      // 0
      const AdminOrdersTab(),         // 1
      const AdminProductsTab(),       // 2
      const AdminUsersPage(),         // 3
      const AdminAnnouncementsTab(),  // 4
      const AdminChatTab(),           // 5
      const AdminCouponsTab(),        // 6
    ];

    // Ensure index is valid
    final safeIndex = currentPageIndex < pages.length ? currentPageIndex : 0;

    return Scaffold(
      body: Row(
        children: [
          // SIDE MENU (Responsive: Drawer on small, Permanent on large)
          if (isLargeScreen) 
            _buildSideMenu(context, ref, safeIndex),
          
          // MAIN CONTENT
          Expanded(
            child: Scaffold(
              appBar: !isLargeScreen 
                  ? AppBar(
                      title: const Text("Admin Panel"),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 1,
                    ) 
                  : null,
              drawer: !isLargeScreen 
                  ? Drawer(child: _buildSideMenu(context, ref, safeIndex)) 
                  : null,
              body: pages[safeIndex],
              bottomNavigationBar: !isLargeScreen
                  ? NavigationBar(
                      selectedIndex: safeIndex > 2 ? 0 : safeIndex, // Only highlight if part of main 3, else 0 or none? Better to map correctly or just allow direct access to top 3.
                      // Logic: If user is on Users(3), bottom bar won't show it selected nicely if we restrict to 3. 
                      // Let's keep it simple: Bottom bar shortcuts to top 3. If on other page, unselect or default to dashboard?
                      // Actually, let's allow it to change the state.
                      onDestinationSelected: (index) => ref.read(adminCurrentPageProvider.notifier).state = index,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: 'Overview',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.shopping_bag_outlined),
                          selectedIcon: Icon(Icons.shopping_bag),
                          label: 'Orders',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.inventory_2_outlined),
                          selectedIcon: Icon(Icons.inventory_2),
                          label: 'Products',
                        ),
                        // Users and others accessed via Drawer
                      ],
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context, WidgetRef ref, int selectedIndex) {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          // Branding Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_cafe_rounded, size: 48, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  "TeaAdmin", 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  )
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildSectionHeader("Overview"),
                _buildMenuItem(context, ref, 0, "Dashboard", Icons.dashboard_rounded, selectedIndex),
                
                _buildSectionHeader("Management"),
                _buildMenuItem(context, ref, 1, "Orders", Icons.shopping_bag_rounded, selectedIndex),
                _buildMenuItem(context, ref, 2, "Products", Icons.inventory_2_rounded, selectedIndex),
                _buildMenuItem(context, ref, 3, "Users & VIPs", Icons.people_alt_rounded, selectedIndex),
                
                _buildSectionHeader("Marketing & Support"),
                _buildMenuItem(context, ref, 4, "Announcements", Icons.campaign_rounded, selectedIndex),
                _buildMenuItem(context, ref, 6, "Coupons", Icons.local_offer, selectedIndex),
                _buildMenuItem(context, ref, 5, "Customer Support", Icons.chat_bubble_rounded, selectedIndex),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    await AuthService().signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, WidgetRef ref, int index, String title, IconData icon, int selectedIndex) {
    final isSelected = index == selectedIndex;
    final themeColor = AppTheme.primaryGreen;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? themeColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: themeColor.withOpacity(0.2)) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? themeColor : Colors.grey.shade600,
          size: 24,
        ),
        title: Text(
          title, 
          style: TextStyle(
            color: isSelected ? themeColor : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          ref.read(adminCurrentPageProvider.notifier).state = index;
          // Close drawer if we are in a drawer context (mobile)
          // Since we are rebuilding, we can check if Scaffold exists in context, but simpler:
          if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
             Navigator.of(context).pop(); 
          }
        },
      ),
    );
  }
}
