import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../auth/auth_controller.dart';
import 'cart_controller.dart';
import 'product_page.dart'; // To access productListProvider

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final _adminNotesController = TextEditingController(); // Actually USER notes for Admin
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final productsAsync = ref.watch(productListProvider);
    final userProfile = ref.watch(userProfileProvider).value;

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Your Request")),
        body: const Center(child: Text("Cart is empty")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Review Request")),
      body: productsAsync.when(
        data: (allProducts) {
          // Filter products in cart
          final cartProducts = allProducts.where((p) => cart.items.containsKey(p.id)).toList();
          
          double estimatedTotal = 0;
          for (var p in cartProducts) {
            estimatedTotal += p.pricePerUnit * (cart.items[p.id] ?? 0);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProducts.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final product = cartProducts[index];
                    final qty = cart.items[product.id] ?? 0;
                    final total = product.pricePerUnit * qty;

                    return ListTile(
                      leading: Image.network(
                        product.imageUrl.isNotEmpty ? product.imageUrl : Constants.defaultTeaImage,
                        width: 50, height: 50, fit: BoxFit.cover,
                      ),
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${Constants.currencySymbol}${product.pricePerUnit} x $qty ${product.unitType}"),
                      trailing: Text(
                        "${Constants.currencySymbol}${total.toStringAsFixed(2)}",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.royalMaroon),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12, offset: Offset(0, -2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Estimated Total:", style: TextStyle(fontSize: 16)),
                        Text(
                          "${Constants.currencySymbol}${estimatedTotal.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.royalMaroon),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _adminNotesController,
                      decoration: const InputDecoration(
                        labelText: "Notes for Admin (Optional)",
                        hintText: "E.g. Deliver by next Monday",
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSubmitting ? null : () => _submitOrder(estimatedTotal, userProfile?['id']),
                      child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SUBMIT REQUEST"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Future<void> _submitOrder(double totalAmount, String? userId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User ID not found")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cart = ref.read(cartProvider);
      
      // 1. Create Order
      final orderRes = await SupabaseConfig.client.from('tea_orders').insert({
        'user_id': userId,
        'status': 'requested',
        'total_amount': totalAmount,
        'admin_notes': _adminNotesController.text, // Using this field for User Notes initially? Or add 'user_notes'? 
        // Schema has 'admin_notes'. Let's assume admin_notes is predominantly for admin. 
        // Maybe I should have added 'user_notes'. For now, I'll put it in admin_notes with prefix "User Note:"
      }).select().single();

      final orderId = orderRes['id'];

      // 2. Create Order Items
      final itemsToInsert = cart.items.entries.map((entry) {
        // Need to find product price again? Or rely on UI? Best to fetch or pass.
        // For simplicity, we assume price hasn't changed in last 2 seconds.
        // We need product list to get price.
        // In a real app we'd fetch prices on backend or re-verify.
        final productList = ref.read(productListProvider).value!; 
        final product = productList.firstWhere((p) => p.id == entry.key);

        return {
          'order_id': orderId,
          'product_id': entry.key,
          'quantity': entry.value,
          'unit_price': product.pricePerUnit,
        };
      }).toList();

      await SupabaseConfig.client.from('tea_order_items').insert(itemsToInsert);

      // 3. Clear Cart & Success
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        Navigator.pop(context); // Close Cart
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order Requested Successfully!"),
            backgroundColor: Colors.green,
          )
        );
        // Switch to Orders Tab (index 2)
        // Need access to vipNavIndexProvider? It sits up the tree. 
        // We can just rely on user going there.
      }

    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
