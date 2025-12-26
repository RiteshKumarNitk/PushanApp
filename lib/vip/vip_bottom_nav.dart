import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import 'home_page.dart';
import 'product_page.dart';
import '../orders/orders_page.dart'; 
import '../profile/profile_page.dart';

final vipNavIndexProvider = StateProvider<int>((ref) => 0);

class VipBottomNav extends ConsumerWidget {
  const VipBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(vipNavIndexProvider);

    final pages = [
      const VipHomePage(),
      const ProductPage(),
      const OrdersPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(vipNavIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.royalMaroon,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
