import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../services/invoice_service.dart'; 
import 'package:printing/printing.dart'; 
import 'package:pdf/pdf.dart'; 

final orderDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  // Fetch Order + Items + User + Variants + Products
  final orderRes = await SupabaseConfig.client
      .from('tea_orders')
      // Deep select: items -> product_variants -> products
      .select('*, tea_order_items(*, product_variants(*, products(*))), users:user_id(*)')
      .eq('id', orderId)
      .single();
  
  return orderRes;
});

class AdminOrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;
  const AdminOrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends ConsumerState<AdminOrderDetailPage> {
  bool _isUpdating = false;

  String? _formatAddress(Map<String, dynamic>? addr) {
    if (addr == null) return null;
    return "${addr['address_line']}, ${addr['city']}, ${addr['state']}${addr['zip_code'] != null ? ' - ${addr['zip_code']}' : ''}";
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: orderAsync.when(
        data: (order) {
          final items = List<Map<String, dynamic>>.from(order['tea_order_items']);
          final user = order['users'];
          final status = order['status'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                         ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person, size: 32),
                          title: Text(user['full_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${user['business_name'] ?? ''}\n${user['email']}"),
                          isThreeLine: true,
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on, color: Colors.indigo),
                          title: const Text("Shipping Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          subtitle: SelectableText( 
                            _formatAddress(order['shipping_address']) ?? user['address'] ?? 'No address provided by user.',
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        ),
                        if (user['phone_number'] != null)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.phone, color: Colors.green),
                            title: SelectableText(user['phone_number']),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Status Actions
                _buildStatusSection(status),
                const SizedBox(height: 24),

                // Items List
                const Text("Items Requested", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    // Handle nested data
                    // product_variants might be null if FK failed join, hopefully not.
                    final variant = item['product_variants'];
                    final product = variant?['products'];
                    
                    final productName = product?['name'] ?? 'Unknown Tea';
                    final variantName = variant?['variant_name'] ?? '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("$productName ($variantName)"),
                      subtitle: Text("${item['quantity']} units x ${Constants.currencySymbol}${item['unit_price']}"),
                      trailing: Text(
                        "${Constants.currencySymbol}${(item['quantity'] * item['unit_price'])}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Grand Total: ${Constants.currencySymbol}${order['total_amount']}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.royalMaroon),
                  ),
                ),
                
                const SizedBox(height: 32),
                // Invoice Generation
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: status == 'approved' || status == 'shipped' || status == 'delivered' ? () async {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating Invoice...")));
                        
                        final itemsList = items.map((i) {
                          final variant = i['product_variants'];
                          final product = variant?['products'];
                          final name = "${product?['name'] ?? 'Tea'} ${variant?['variant_name'] ?? ''}";

                          return {
                            'name': name,
                            'quantity': i['quantity'],
                            'unit_price': i['unit_price'],
                            'total': (i['quantity'] * i['unit_price']).toStringAsFixed(2),
                          };
                        }).toList();

                        // Use user details from 'user' map
                        final pdfBytes = await InvoiceService.generateInvoice(
                          orderId: order['id'],
                          date: DateTime.parse(order['created_at']),
                          customerName: user['full_name'] ?? 'Customer',
                          customerBusiness: user['business_name'] ?? 'VIP Business',
                          customerAddress: user['address'] ?? '',
                          items: itemsList,
                          grandTotal: (order['total_amount'] as num).toDouble(),
                        );

                        await Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) async => pdfBytes,
                          name: 'Invoice-${order['id']}.pdf'
                        );
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    } : null,
                    icon: const Icon(Icons.receipt),
                    label: const Text("Generate Invoice PDF"),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildStatusSection(String currentStatus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Current Status: ${currentStatus.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (currentStatus == 'requested')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus('rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _updateStatus('approved'),
                    child: const Text("Approve Order"),
                  ),
                ),
              ],
            ),
          if (currentStatus == 'approved')
            FilledButton(
              onPressed: () => _updateStatus('packed'),
              child: const Text("Mark as Packed"),
            ),
          if (currentStatus == 'packed')
            FilledButton(
              onPressed: () => _updateStatus('shipped'),
              child: const Text("Mark as Shipped"),
            ),
          if (currentStatus == 'shipped')
             FilledButton(
              onPressed: () => _updateStatus('delivered'),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Mark as Delivered"),
            ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      // 1. Update Status
      final res = await SupabaseConfig.client
          .from('tea_orders')
          .update({'status': newStatus})
          .eq('id', widget.orderId)
          .select('user_id')
          .single();
      
      final userId = res['user_id'];

      // 2. Send Notification
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': userId,
        'title': 'Order Update',
        'message': 'Your order #${widget.orderId.substring(0, 8).toUpperCase()} has been $newStatus.',
        'type': 'order_update',
        'related_id': widget.orderId,
      });
      
      ref.refresh(orderDetailProvider(widget.orderId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order marked as $newStatus")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}
