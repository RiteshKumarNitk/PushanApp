import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../services/invoice_service.dart';
import 'package:pdf/pdf.dart';
import '../../shared/models/tea_order.dart';
import '../vip/order_detail_page.dart';



final ordersProvider = StreamProvider<List<TeaOrder>>((ref) {
  return SupabaseConfig.client
      .from('tea_orders')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => data.map((e) => TeaOrder.fromJson(e)).toList());
});

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Although StreamProvider updates automatically, 
              // sometimes a manual refresh is reassuring to user.
              // We can force a refresh by using ref.refresh logic if we change the provider 
              // but since it's a stream, we can just let Supabase handle it or 
              // provide a visual feedback that "it is live".
              // Or force re-build the provider:
              // ref.refresh(ordersProvider); // But this returns AsyncValue which is void
              ref.invalidate(ordersProvider);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Refreshing orders...")));
            },
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_food_beverage_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("No orders yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _OrderCard(order: orders[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final TeaOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    if (order.status == 'approved') statusColor = Colors.blue;
    if (order.status == 'packed') statusColor = Colors.orange;
    if (order.status == 'shipped') statusColor = Colors.indigo;
    if (order.status == 'delivered') statusColor = Colors.green;
    if (order.status == 'rejected') statusColor = Colors.red;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => VipOrderDetailPage(orderId: order.id)));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(order.createdAt), 
                    style: const TextStyle(color: Colors.grey, fontSize: 12)
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Order #${order.id.split('-')[0]}", // Short ID
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  order.items.map((i) => "${i['products']['name']} (${i['quantity']})").take(3).join(", ") + (order.items.length > 3 ? "..." : ""),
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (order.adminNotes != null && order.adminNotes!.isNotEmpty)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Text(
                     "Note: ${order.adminNotes}",
                     style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13),
                   ),
                 ),
              const SizedBox(height: 12),
              // Dynamic Status Message
              _buildStatusMessage(order.status),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total", style: TextStyle(color: Colors.grey)),
                  Text(
                    "${Constants.currencySymbol}${order.totalAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              
              // Invoice Button (Only if delivered or shipped)
              if (order.status == 'delivered' || order.status == 'shipped')
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating Invoice...")));
                          
                          // Fetch items for this order
                          final itemsRes = await SupabaseConfig.client.from('tea_order_items').select('*, products(name)').eq('order_id', order.id);
                          final itemsList = List<Map<String, dynamic>>.from(itemsRes).map((i) {
                            return {
                              'name': i['products']['name'],
                              'quantity': i['quantity'],
                              'unit_price': i['unit_price'],
                              'total': (i['quantity'] * i['unit_price']).toStringAsFixed(2),
                            };
                          }).toList();
  
                          final pdfBytes = await InvoiceService.generateInvoice(
                            orderId: order.id,
                            date: order.createdAt,
                            customerName: "Valued Customer", 
                            customerBusiness: "Your Business",
                            customerAddress: "",
                            items: itemsList,
                            grandTotal: order.totalAmount,
                          );
  
                          await Printing.layoutPdf(
                            onLayout: (PdfPageFormat format) async => pdfBytes,
                            name: 'Invoice-${order.id}.pdf'
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text("Download Invoice"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.royalMaroon,
                        side: BorderSide(color: AppTheme.royalMaroon),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(String status) {
    String message = "";
    Color bgColor = Colors.grey.shade100;
    Color textColor = Colors.black87;
    IconData icon = Icons.info_outline;

    switch (status) {
      case 'requested':
        message = "Your order request has been sent to the Admin. Waiting for approval.";
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        break;
      case 'approved':
        message = "Great news! Your order is approved and is being prepared.";
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        icon = Icons.thumb_up_alt_outlined;
        break;
      case 'packed':
        message = "Your tea is packed with care and ready for shipping.";
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade800;
        icon = Icons.inventory_2_outlined;
        break;
      case 'shipped':
        message = "On its way! Your order has been shipped.";
        bgColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade800;
        icon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        message = "Delivered! Thanks for shopping with Pushan Tea. Enjoy your tea!";
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        message = "Order rejected. Please check Admin notes or contact support.";
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: textColor, fontSize: 13))),
        ],
      ),
    );
  }
}
