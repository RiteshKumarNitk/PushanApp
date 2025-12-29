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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
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
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(color: Colors.blueGrey[50], shape: BoxShape.circle),
                     child: Icon(Icons.receipt_long_outlined, size: 64, color: Colors.blueGrey[300]),
                   ),
                   const SizedBox(height: 24),
                   const Text("No orders yet", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   const Text("Start by exploring our catalog!", style: TextStyle(color: Colors.grey, fontSize: 14)),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => VipOrderDetailPage(orderId: order.id)));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order #${order.id.split('-')[0]}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt), 
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)
                        ),
                      ],
                    ),
                    Text(
                      "${Constants.currencySymbol}${order.totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        color: AppTheme.royalMaroon,
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),

                // Status Timeline
                _buildStatusTimeline(),

                const SizedBox(height: 16),
                
                if (order.adminNotes != null && order.adminNotes!.isNotEmpty)
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.amber.shade50,
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: Colors.amber.shade200),
                     ),
                     child: Row(
                       children: [
                         const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                         const SizedBox(width: 8),
                         Expanded(
                           child: Text(
                             order.adminNotes!,
                             style: const TextStyle(color: Colors.brown, fontSize: 13),
                           ),
                         ),
                       ],
                     ),
                   ),

                // Actions
                if (order.status == 'delivered' || order.status == 'shipped')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                           _generateInvoice(context);
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text("Download Invoice"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.royalMaroon,
                          side: const BorderSide(color: AppTheme.royalMaroon),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusTimeline() {
    // Determine active step index
    // const steps = ['requested', 'approved', 'packed', 'shipped', 'delivered'];
    if (order.status == 'rejected') return _buildRejectedStatus();
    
    // activeStep = steps.indexOf(order.status);
    // if (activeStep == -1) activeStep = 0; // Default or custom status

    // We will show 4 visual steps: Request -> Confirm -> Ship -> Deliver
    // Mapping:
    // requested -> Step 0 (Active)
    // approved -> Step 1 (Active)
    // packed -> Step 1 (Active)
    // shipped -> Step 2 (Active)
    // delivered -> Step 3 (Active)
    
    int visualStep = 0;
    if (order.status == 'approved' || order.status == 'packed') visualStep = 1;
    if (order.status == 'shipped') visualStep = 2;
    if (order.status == 'delivered') visualStep = 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimelineStep("Placed", visualStep >= 0, isFirst: true),
        _buildTimelineLine(visualStep >= 1),
        _buildTimelineStep("Confirmed", visualStep >= 1),
        _buildTimelineLine(visualStep >= 2),
        _buildTimelineStep("Shipped", visualStep >= 2),
        _buildTimelineLine(visualStep >= 3),
        _buildTimelineStep("Delivered", visualStep >= 3, isLast: true),
      ],
    );
  }

  Widget _buildRejectedStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red[700]),
          const SizedBox(width: 8),
          Text("Order Rejected", style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, bool isActive, {bool isFirst = false, bool isLast = false}) {
    Color color = isActive ? AppTheme.primaryGreen : Colors.grey.shade300;
    
    return Column(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)] : [],
          ),
          child: isActive ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(
          label, 
          style: TextStyle(
            fontSize: 10, 
            color: isActive ? Colors.black87 : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          )
        ),
      ],
    );
  }

  Widget _buildTimelineLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppTheme.primaryGreen : Colors.grey.shade300,
      ),
    );
  }

  Future<void> _generateInvoice(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating Invoice...")));
      
      final itemsRes = await SupabaseConfig.client
          .from('tea_order_items')
          .select('*, product_variants(*, products(name))')
          .eq('order_id', order.id);
          
      final itemsList = List<Map<String, dynamic>>.from(itemsRes).map((i) {
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
  }
}
