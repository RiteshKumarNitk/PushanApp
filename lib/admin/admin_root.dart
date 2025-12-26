import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import 'admin_dashboard_tab.dart';
import 'admin_orders_tab.dart'; // We will rename the old dashboard logic to this
import 'admin_products_tab.dart';
import 'admin_chat_tab.dart'; // or Users tab

final adminNavIndexProvider = StateProvider<int>((ref) => 0);

class AdminDashboardRoot extends ConsumerWidget {
  const AdminDashboardRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(adminNavIndexProvider);

    final pages = [
      const AdminDashboardTab(),
      const AdminOrdersTab(),
      const AdminProductsTab(),
      const AdminChatTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => ref.read(adminNavIndexProvider.notifier).state = index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}
