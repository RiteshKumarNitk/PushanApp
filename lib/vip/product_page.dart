import 'cart_controller.dart';
import 'cart_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../shared/models/product.dart';

final productListProvider = FutureProvider<List<Product>>((ref) async {
  final response = await SupabaseConfig.client
      .from('products')
      .select()
      .eq('is_active', true)
      .order('name');
  
  final data = response as List<dynamic>;
  return data.map((e) => Product.fromJson(e)).toList();
});

class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Bulk Catalog")),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text("No products available"));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
            itemCount: products.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: cartState.totalItems > 0 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
        },
        label: Text("Review Request (${cartState.totalItems})"),
        icon: const Icon(Icons.shopping_cart_checkout),
        backgroundColor: AppTheme.royalMaroon,
        foregroundColor: Colors.white,
      ) : null,
    );
  }
}

class ProductCard extends ConsumerWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final quantity = cart.items[product.id] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl.isNotEmpty ? product.imageUrl : Constants.defaultTeaImage,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.local_cafe)),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "Min: ${product.minOrderQuantity} ${product.unitType}s",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${Constants.currencySymbol}${product.pricePerUnit} / ${product.unitType}",
                    style: TextStyle(
                      color: AppTheme.royalMaroon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Stepper
            Column(
              children: [
                const Text("Qty", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: quantity > 0 
                        ? () => ref.read(cartProvider.notifier).setQuantity(product.id, quantity - 1) 
                        : null,
                      color: AppTheme.royalMaroon,
                      iconSize: 20,
                    ),
                    Text(
                      "$quantity",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                         int newQty = quantity + 1;
                         // Enforce Min Order only on verify? Or hint here? 
                         // For now just add.
                         if (quantity == 0 && product.minOrderQuantity > 1) {
                            newQty = product.minOrderQuantity;
                         }
                         ref.read(cartProvider.notifier).setQuantity(product.id, newQty);
                      },
                      color: AppTheme.royalMaroon,
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
