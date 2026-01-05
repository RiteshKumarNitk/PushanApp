import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';

class AdminCouponsTab extends StatefulWidget {
  const AdminCouponsTab({super.key});

  @override
  State<AdminCouponsTab> createState() => _AdminCouponsTabState();
}

class _AdminCouponsTabState extends State<AdminCouponsTab> {
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _percentCtrl = TextEditingController(text: "20");
  bool _isLoading = false;

  Future<void> _createCoupon() async {
    if (_codeCtrl.text.isEmpty || _percentCtrl.text.isEmpty) return;

    final code = _codeCtrl.text.trim().toUpperCase();
    final percent = int.tryParse(_percentCtrl.text) ?? 0;
    
    if (percent <= 0 || percent > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid percentage")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SupabaseConfig.client.from('coupons').insert({
        'code': code,
        'discount_percent': percent,
        'description': _descCtrl.text.trim(),
        'is_active': true,
      });

      _codeCtrl.clear();
      _descCtrl.clear();
      _percentCtrl.text = "20";
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coupon Created!")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(String id, bool current) async {
    try {
      await SupabaseConfig.client.from('coupons').update({'is_active': !current}).eq('id', id);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deleteCoupon(String id) async {
    try {
      await SupabaseConfig.client.from('coupons').delete().eq('id', id);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 24),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Manage Coupons", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.discount, color: Colors.purple),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Creator Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0,5))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text("Create New Coupon", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _codeCtrl,
                              decoration: const InputDecoration(labelText: "Code (e.g. TEA20)", border: OutlineInputBorder()),
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _percentCtrl,
                              decoration: const InputDecoration(labelText: "Discount %", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(labelText: "Description (Optional)", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _createCoupon,
                        icon: const Icon(Icons.add),
                        label: Text(_isLoading ? "Saving..." : "Create Coupon"),
                        style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const Align(alignment: Alignment.centerLeft, child: Text("Active Coupons", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                const SizedBox(height: 16),

                // List
                StreamBuilder(
                  stream: SupabaseConfig.client.from('coupons').stream(primaryKey: ['id']).order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final items = snapshot.data as List<dynamic>;
                    if (items.isEmpty) return const Text("No coupons found");

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
                            border: isActive ? Border.all(color: Colors.purple.withOpacity(0.3)) : null,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isActive ? Colors.purple[50] : Colors.grey[200],
                              child: Icon(Icons.local_offer, color: isActive ? Colors.purple : Colors.grey),
                            ),
                            title: Text(item['code'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${item['discount_percent']}% Off - ${item['description'] ?? ''}"),
                            trailing: PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'toggle') _toggleStatus(item['id'], isActive);
                                if (val == 'delete') _deleteCoupon(item['id']);
                              },
                              itemBuilder: (c) => [
                                PopupMenuItem(value: 'toggle', child: Text(isActive ? "Deactivate" : "Activate")),
                                const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
