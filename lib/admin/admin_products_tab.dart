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
    final themeColor = AppTheme.primaryGreen;

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adminProductsProvider),
      child: Column(
        children: [
          // Custom Header
          Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Inventory", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    const Text("Product Catalog", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddProductPage())).then((_) {
                       ref.refresh(adminProductsProvider);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.royalMaroon,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                         BoxShadow(color: AppTheme.royalMaroon.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text("Add Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: productsAsync.when(
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
                  padding: const EdgeInsets.all(20),
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
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4)),
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
                  width: 110, 
                  height: 110,
                  color: Colors.grey[50],
                  child: product.imageUrl.isNotEmpty 
                    ? Image.network(
                        product.imageUrl,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                      )
                    : const Icon(Icons.shopping_bag_outlined, size: 30, color: Colors.grey),
                ),
              ),
              
              // Details Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                             decoration: BoxDecoration(
                               color: AppTheme.goldAccent.withOpacity(0.15),
                               borderRadius: BorderRadius.circular(20),
                             ),
                             child: Text(
                               product.category,
                               style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown, letterSpacing: 0.5),
                             ),
                           )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description.isEmpty ? "No description" : product.description,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                           Icon(Icons.layers_outlined, size: 14, color: Colors.grey[500]),
                           const SizedBox(width: 4),
                           Text(
                             "${product.variants.length} Variants",
                             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                           ),
                           const Spacer(),
                           Text(
                             "${Constants.currencySymbol}${product.pricePerUnit}", 
                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                           ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          InkWell(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductPage(product: product))).then((_) {
                 ref.refresh(adminProductsProvider);
               });
            },
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              width: double.infinity,
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note, size: 18, color: AppTheme.royalMaroon),
                  SizedBox(width: 8),
                  Text("EDIT DETAILS & VARIANTS", style: TextStyle(color: AppTheme.royalMaroon, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
