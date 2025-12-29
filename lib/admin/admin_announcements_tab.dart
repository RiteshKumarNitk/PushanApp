import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';

class AdminAnnouncementsTab extends StatefulWidget {
  const AdminAnnouncementsTab({super.key});

  @override
  State<AdminAnnouncementsTab> createState() => _AdminAnnouncementsTabState();
}

class _AdminAnnouncementsTabState extends State<AdminAnnouncementsTab> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _postAnnouncement() async {
    if (_titleCtrl.text.isEmpty || _msgCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // Deactivate all previous active announcements
      await SupabaseConfig.client
          .from('announcements')
          .update({'is_active': false})
          .eq('is_active', true);

      // Insert new one
      await SupabaseConfig.client.from('announcements').insert({
        'title': _titleCtrl.text.trim(),
        'message': _msgCtrl.text.trim(),
        'is_active': true,
      });

      _titleCtrl.clear();
      _msgCtrl.clear();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Announcement Broadcasted Successfully!")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text("Marketing & Offers"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Composer Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.royalMaroon.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.royalMaroon.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.campaign_outlined, color: AppTheme.royalMaroon),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Broadcast New Offer", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: "Campaign Title",
                      hintText: "e.g., Monsoon Sale",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.title),
                      filled: true,
                      fillColor: Colors.grey[50]
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      labelText: "Message Body",
                      hintText: "Describe the offer details...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.message_outlined),
                      filled: true,
                      fillColor: Colors.grey[50]
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _postAnnouncement,
                    icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                    label: Text(_isLoading ? "BROADCASTING..." : "BROADCAST TO ALL USERS"),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.royalMaroon, 
                      padding: const EdgeInsets.all(18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // History Section
            const Row(
              children: [
                Icon(Icons.history, color: Colors.grey),
                SizedBox(width: 8),
                Text("Recent Broadcasts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            
            StreamBuilder(
              stream: SupabaseConfig.client.from('announcements').stream(primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final items = snapshot.data as List<dynamic>;
                if (items.isEmpty) return const Text("No broadcast history");

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isActive = item['is_active'] as bool;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isActive ? Border.all(color: Colors.green.withOpacity(0.5)) : null,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
                      ),
                      child: ListTile(
                        leading: Icon(
                          isActive ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          item['title'],
                          style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                        ),
                        subtitle: Text(item['message'], maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: isActive 
                           ? Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                               child: const Text("Active", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                             )
                           : const Text("Expired", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
