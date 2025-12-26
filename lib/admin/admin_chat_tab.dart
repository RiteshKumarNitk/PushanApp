import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
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
      appBar: AppBar(title: const Text("Customer Support")),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) return const Center(child: Text("No customers found"));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user['full_name'][0].toUpperCase())),
                title: Text(user['full_name']),
                subtitle: Text(user['business_name'] ?? 'VIP Member'),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: user['id'], 
                        otherUserName: user['full_name']
                      )
                    )
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
