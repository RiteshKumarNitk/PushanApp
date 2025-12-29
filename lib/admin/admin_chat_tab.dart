import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../shared/screens/chat_screen.dart';

final usersListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Fetch VIP members (exclude admins for now, or include all)
  final response = await SupabaseConfig.client
      .from('users')
      .select()
      .neq('role', 'admin') // Only chat with customers
      .order('full_name');
  return List<Map<String, dynamic>>.from(response);
});

class AdminChatTab extends ConsumerWidget {
  const AdminChatTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Customer Messages"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.royalMaroon),
            onPressed: () => ref.refresh(usersListProvider),
          )
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   const Text("No customers found", style: TextStyle(color: Colors.grey, fontSize: 16)),
                 ],
               ),
             );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildUserCard(context, users[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
     final name = user['full_name'] ?? 'Unknown';
     final business = user['business_name'] ?? 'VIP Member';
     final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

     return Container(
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(16),
         boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
         ],
       ),
       child: ListTile(
         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
         onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  otherUserId: user['id'], 
                  otherUserName: name
                )
              )
            );
         },
         leading: CircleAvatar(
           backgroundColor: AppTheme.royalMaroon.withOpacity(0.1),
           radius: 24,
           child: Text(
             initial, 
             style: const TextStyle(color: AppTheme.royalMaroon, fontWeight: FontWeight.bold, fontSize: 18)
           ),
         ),
         title: Text(
           name, 
           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
         ),
         subtitle: Row(
           children: [
             Icon(Icons.business, size: 12, color: Colors.grey[500]),
             const SizedBox(width: 4),
             Text(business, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
           ],
         ),
         trailing: Container(
           padding: const EdgeInsets.all(8),
           decoration: BoxDecoration(
             color: AppTheme.royalMaroon,
             shape: BoxShape.circle,
             boxShadow: [
               BoxShadow(color: AppTheme.royalMaroon.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
             ]
           ),
           child: const Icon(Icons.chat, color: Colors.white, size: 16),
         ),
       ),
     );
  }
}
