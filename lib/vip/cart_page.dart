import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../auth/auth_controller.dart';
import 'cart_controller.dart';
import 'product_page.dart'; 
import '../../shared/models/product.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final _adminNotesController = TextEditingController(); 
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
          try {
            // Flatten all variants
            final variantToProductMap = <String, Product>{};
            // Map to store the specific variant object too for easier lookup
            final variantMap = <String, ProductVariant>{};

            for (var p in allProducts) {
              for (var v in p.variants) {
                variantToProductMap[v.id] = p;
                variantMap[v.id] = v;
              }
            }

            // Filter cart items to only show VALID ones
            final validCartItems = cart.items.entries.where((e) {
               return variantMap.containsKey(e.key);
            }).toList();
            
            if (validCartItems.isEmpty) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Text("Items in cart are no longer available."),
                     const SizedBox(height: 16),
                     FilledButton(
                       onPressed: () => ref.read(cartProvider.notifier).clear(),
                       child: const Text("Clear Cart"),
                     )
                   ],
                 )
               );
            }

            double estimatedTotal = 0;
            for (var e in validCartItems) {
              final variant = variantMap[e.key];
              if (variant != null) {
                estimatedTotal += variant.price * e.value;
              }
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: validCartItems.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final entry = validCartItems[index];
                      final variantId = entry.key;
                      final qty = entry.value;
                      
                      final product = variantToProductMap[variantId];
                      final variant = variantMap[variantId];

                      // Defensive Check (should satisfy due to filter above, but safe is better)
                      if (product == null || variant == null) {
                        return const SizedBox.shrink(); 
                      }

                      final total = variant.price * qty;

                      return ListTile(
                        leading: _ProductThumbnail(imageUrl: product.imageUrl),
                        title: Text("${product.name} (${variant.variantName})", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${Constants.currencySymbol}${variant.price.toStringAsFixed(0)} x $qty"),
                        trailing: Text(
                          "${Constants.currencySymbol}${total.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.royalMaroon),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
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
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.royalMaroon),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _adminNotesController,
                        decoration: const InputDecoration(
                          labelText: "Notes (Optional)",
                          hintText: "E.g. Deliver by next Monday",
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isSubmitting ? null : () => _submitOrder(estimatedTotal, userProfile?['id'], variantMap),
                        child: _isSubmitting 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SUBMIT REQUEST"),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } catch (e, stack) {
             debugPrint("Cart Build Error: $e $stack");
             return Center(child: Text("Error displaying cart: $e"));
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) {
          debugPrint("CartPage Error: $e");
          return Center(child: Text("Error loading catalog: $e")); 
        },
      ),
    );
  }

  Future<void> _submitOrder(double totalAmount, String? userId, Map<String, ProductVariant> variantMap) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User ID not found. Please Login.")));
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
        'admin_notes': _adminNotesController.text, 
      }).select().single();

      final orderId = orderRes['id'];

      // 2. Create Order Items (Only valid ones)
      final itemsToInsert = <Map<String, dynamic>>[];
      
      for (var entry in cart.items.entries) {
        if (!variantMap.containsKey(entry.key)) continue; 
        
        final variantId = entry.key;
        final variant = variantMap[variantId]!;
        
        itemsToInsert.add({
          'order_id': orderId,
          'product_id': variantId, 
          'quantity': entry.value,
          'unit_price': variant.price,
        });
      }

      if (itemsToInsert.isNotEmpty) {
        await SupabaseConfig.client.from('tea_order_items').insert(itemsToInsert);
      }

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

class _ProductThumbnail extends StatelessWidget {
  final String imageUrl;
  const _ProductThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _itemsPlaceholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _itemsPlaceholder(),
      ),
    );
  }

  Widget _itemsPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[200],
      child: const Icon(Icons.local_cafe, size: 20, color: Colors.grey),
    );
  }
}
