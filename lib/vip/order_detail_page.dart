import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart'; // For invoice
import 'package:pdf/pdf.dart'; // For invoice
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../services/invoice_service.dart';

// Provider to fetch single order details + items
final vipOrderDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  return SupabaseConfig.client
      .from('tea_orders')
      // Deep select: items -> product_variants -> products
      .select('*, tea_order_items(*, product_variants(*, products(*))), users:user_id(*)')
      .eq('id', orderId)
      .single();
});

class VipOrderDetailPage extends ConsumerWidget {
  final String orderId;
  const VipOrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(vipOrderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: orderAsync.when(
        data: (order) {
          final items = List<Map<String, dynamic>>.from(order['tea_order_items']);
          final status = order['status'];
          final total = (order['total_amount'] as num).toDouble();
          final date = DateTime.parse(order['created_at']).toLocal();
          final user = order['users']; // To pass to InvoiceService

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text("Order #${order['id'].split('-')[0]}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                         Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: const TextStyle(color: Colors.grey)),
                         const SizedBox(height: 12),
                         _buildStatusBadge(status),
                         if (order['admin_notes'] != null && order['admin_notes'].isNotEmpty) ...[
                           const SizedBox(height: 12),
                           Text("Admin Note: ${order['admin_notes']}", style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic)),
                         ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Items
                const Text("Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    // Handle nested data
                    final variant = item['product_variants'];
                    final product = variant?['products'];
                    
                    final name = product?['name'] ?? 'Unknown Tea';
                    final variantName = variant?['variant_name'] ?? '';
                    final imageUrl = product?['image_url'];

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                           imageUrl ?? Constants.defaultTeaImage,
                           width: 40, height: 40, fit: BoxFit.cover,
                           errorBuilder: (c,o,s) => Container(width: 40, height: 40, color: Colors.grey[200]),
                        ),
                      ),
                      title: Text("$name ($variantName)"),
                      subtitle: Text("${item['quantity']} pack(s)"),
                      trailing: Text("${Constants.currencySymbol}${item['unit_price']}"),
                    );
                  },
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Total: ${Constants.currencySymbol}${total.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ),

                const SizedBox(height: 32),

                // Download Invoice
                if (status == 'shipped' || status == 'delivered')
                  ElevatedButton.icon(
                    onPressed: () async {
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

                        final pdfBytes = await InvoiceService.generateInvoice(
                          orderId: order['id'],
                          date: date,
                          customerName: user['full_name'] ?? 'You',
                          customerBusiness: user['business_name'] ?? 'Your Business',
                          customerAddress: user['address'] ?? '',
                          items: itemsList,
                          grandTotal: total,
                        );

                        await Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) async => pdfBytes,
                          name: 'Invoice-${order['id']}.pdf'
                        );
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }, 
                    icon: const Icon(Icons.download),
                    label: const Text("Download Invoice"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalMaroon, foregroundColor: Colors.white),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved': color = Colors.blue; break;
      case 'shipped': color = Colors.purple; break;
      case 'delivered': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
