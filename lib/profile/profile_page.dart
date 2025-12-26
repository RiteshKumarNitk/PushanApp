import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import 'notifications_page.dart';
import 'address_book_page.dart';
import 'security_page.dart';
import 'help_support_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current user if we want detailed info
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(Constants.avatarPlaceholder),
            ),
            const SizedBox(height: 16),
            Text(
              user?['full_name'] ?? 'VIP Member',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user?['email'] ?? 'user@example.com',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildProfileItem(Icons.person_outline, "Edit Profile", () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit Profile Not Implemented")));
            }),
            _buildProfileItem(Icons.location_on_outlined, "Address Book", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookPage()));
            }),
            _buildProfileItem(Icons.notifications_outlined, "Notifications", () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
            }),
            _buildProfileItem(Icons.security_outlined, "Security", () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPage()));
            }),
            _buildProfileItem(Icons.help_outline, "Help & Support", () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text("Log Out"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.teaLatte,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryGreen),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
