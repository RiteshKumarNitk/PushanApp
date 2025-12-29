import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../shared/models/product.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';

final adminProductsProvider = FutureProvider<List<Product>>((ref) async {
  final response = await SupabaseConfig.client
      .from('products')
      .select('*, product_variants(*)') 
      .order('created_at', ascending: false);
  
  final data = response as List<dynamic>;
  return data.map((e) => Product.fromJson(e)).toList();
});

class AdminProductsTab extends ConsumerWidget {
  const AdminProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Product Catalog"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh, color: AppTheme.royalMaroon),
            onPressed: () => ref.refresh(adminProductsProvider),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   const Text("No products found", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(context, ref, product);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddProductPage())).then((_) {
             ref.refresh(adminProductsProvider);
          });
        },
        backgroundColor: AppTheme.royalMaroon,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ADD PRODUCT", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Image Section
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                child: Container(
                  width: 100, 
                  height: 100,
                  color: Colors.grey[100],
                  child: product.imageUrl.isNotEmpty 
                    ? Image.network(
                        product.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                      )
                    : const Icon(Icons.shopping_bag_outlined, size: 30, color: Colors.grey),
                ),
              ),
              
              // Details Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Expanded(
                             child: Text(
                              product.name, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                             ),
                           ),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: AppTheme.goldAccent.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(4),
                             ),
                             child: Text(
                               product.category,
                               style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown),
                             ),
                           )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description.isEmpty ? "No description" : product.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                           Icon(Icons.layers_outlined, size: 14, color: Colors.grey[700]),
                           const SizedBox(width: 4),
                           Text(
                             "${product.variants.length} Variants",
                             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                           ),
                           const Spacer(),
                           Text(
                             "${Constants.currencySymbol}${product.pricePerUnit}", 
                             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.royalMaroon),
                           ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          InkWell(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductPage(product: product))).then((_) {
                 ref.refresh(adminProductsProvider);
               });
            },
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note, size: 18, color: AppTheme.royalMaroon),
                  SizedBox(width: 8),
                  Text("EDIT DETAILS & VARIANTS", style: TextStyle(color: AppTheme.royalMaroon, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
