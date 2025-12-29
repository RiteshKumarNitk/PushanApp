import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import 'notifications_page.dart';
import 'address_book_page.dart';
import 'security_page.dart';
import 'help_support_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current user if we want detailed info
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.value;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light bg
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Header
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.royalMaroon,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(Constants.avatarPlaceholder),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Text(
              user?['full_name'] ?? 'VIP Member',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(
              user?['email'] ?? 'user@example.com',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionTitle("Account Settings"),
                   _buildMenuCard([
                     _buildProfileItem(Icons.person_outline, "Edit Profile", () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
                      }),
                      _buildDivider(),
                      _buildProfileItem(Icons.location_on_outlined, "Address Book", () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookPage()));
                      }),
                      _buildDivider(),
                      _buildProfileItem(Icons.notifications_outlined, "Notifications", () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                      }),
                      _buildDivider(),
                      _buildProfileItem(Icons.security_outlined, "Security", () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPage()));
                      }),
                   ]),
                   
                   const SizedBox(height: 24),
                   _buildSectionTitle("Support"),
                   _buildMenuCard([
                      _buildProfileItem(Icons.help_outline, "Help & Center", () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
                      }),
                   ]),

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
                          side: BorderSide(color: Colors.red.shade200),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.red.withOpacity(0.05),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        "Version 1.0.0",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(), 
        style: TextStyle(
          color: Colors.grey[600], 
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 1.2
        )
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, color: Colors.grey[100]);
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.teaLatte.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    );
  }
}
