import 'cart_controller.dart';
import 'cart_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../shared/models/product.dart';
import 'mock_tea_data.dart'; 

final productListProvider = FutureProvider<List<Product>>((ref) async {
  try {
    // Attempt to fetch from Supabase
    final response = await SupabaseConfig.client
      .from('products')
      .select('*, product_variants(*)') 
      .eq('is_active', true)
      .order('name');
      
    final data = response as List<dynamic>;
    // Check if we got data but maybe parsing fails?
    final products = data.map((e) => Product.fromJson(e)).toList();
    
    if (products.isEmpty) {
      debugPrint("DB returned 0 products. Using Mocks.");
      return [...mockTeaProducts];
    }
    
    return products;

  } catch (e) {
    debugPrint("Error fetching/parsing products: $e");
    // Fallback to mocks on ANY error
    return [...mockTeaProducts];
  }
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
            separatorBuilder: (c, i) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
               // Render each Product (which contains its variants)
              return GroupedTeaCard(product: products[index]);
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

class GroupedTeaCard extends ConsumerWidget {
  final Product product;
  
  const GroupedTeaCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no variants, skip or show error (legacy product?)
    if (product.variants.isEmpty) return const SizedBox.shrink();
    
    final cart = ref.watch(cartProvider);
    
    double groupTotal = 0;
    for (var v in product.variants) {
      final qty = cart.items[v.id] ?? 0;
      groupTotal += v.price * qty;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50), 
                  child: Image.network(
                    product.imageUrl.isNotEmpty ? product.imageUrl : Constants.defaultTeaImage,
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.local_cafe)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        product.description,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Variants List
            ...product.variants.map((variant) {
              final quantity = cart.items[variant.id] ?? 0;
              final isSelected = quantity > 0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.royalMaroon.withOpacity(0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: AppTheme.royalMaroon.withOpacity(0.2)) : null,
                ),
                child: Row(
                  children: [
                    // Unit Name and Price
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            variant.variantName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600, 
                              fontSize: 15, 
                              color: Colors.blueGrey[800]
                            ),
                          ),
                          Text(
                            "${Constants.currencySymbol}${variant.price.toStringAsFixed(0)}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    
                    // Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.shade200, blurRadius: 2, offset: const Offset(0, 1))
                        ]
                      ),
                      child: Row(
                        children: [
                          _StepperButton(
                            icon: Icons.remove,
                            onTap: quantity > 0 
                              ? () => ref.read(cartProvider.notifier).setQuantity(variant.id, quantity - 1) 
                              : null,
                            isEnabled: quantity > 0,
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              "$quantity",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          _StepperButton(
                            icon: Icons.add,
                            onTap: () => ref.read(cartProvider.notifier).setQuantity(variant.id, quantity + 1),
                            isEnabled: true,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
            
            // Footer: Total (Only show if calculated total > 0)
            if (groupTotal > 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Subtotal:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  Text(
                    "${Constants.currencySymbol}${groupTotal.toStringAsFixed(0)}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.royalMaroon)
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _StepperButton({required this.icon, this.onTap, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon, 
          size: 18, 
          color: isEnabled ? AppTheme.royalMaroon : Colors.grey[300]
        ),
      ),
    );
  }
}
