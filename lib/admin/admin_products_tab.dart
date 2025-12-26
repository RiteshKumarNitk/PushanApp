import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../shared/models/product.dart';
import 'add_product_page.dart';

final adminProductsProvider = FutureProvider<List<Product>>((ref) async {
  final response = await SupabaseConfig.client
      .from('products')
      .select()
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
      appBar: AppBar(title: const Text("Manage Products")),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) return const Center(child: Text("No products yet"));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: Image.network(
                  product.imageUrl.isNotEmpty ? product.imageUrl : Constants.defaultTeaImage,
                  width: 50, height: 50, fit: BoxFit.cover,
                ),
                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Price: ${Constants.currencySymbol}${product.pricePerUnit} | Min: ${product.minOrderQuantity}"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.royalMaroon),
                  onPressed: () {
                    // Navigate to Edit
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddProductPage()));
        },
        backgroundColor: AppTheme.royalMaroon,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
