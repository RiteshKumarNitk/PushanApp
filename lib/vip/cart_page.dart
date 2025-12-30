import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../auth/auth_controller.dart';
import 'cart_controller.dart';
import 'product_page.dart'; 
import '../../shared/models/product.dart';
import '../profile/address_book_page.dart'; // Import for provider
import '../../shared/models/user_address.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final _adminNotesController = TextEditingController(); 
  bool _isSubmitting = false;
  UserAddress? _selectedAddress;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final productsAsync = ref.watch(productListProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final addressesAsync = ref.watch(userAddressesProvider);

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
            final variantMap = <String, ProductVariant>{};

            for (var p in allProducts) {
              for (var v in p.variants) {
                variantToProductMap[v.id] = p;
                variantMap[v.id] = v;
              }
            }

            final validCartItems = cart.items.entries.where((e) {
               return variantMap.containsKey(e.key);
            }).toList();
            
            if (validCartItems.isEmpty) {
               return Center(child: Text("Cart items invalid"));
            }

            double estimatedTotal = 0;
            for (var e in validCartItems) {
              final variant = variantMap[e.key];
              if (variant != null) {
                estimatedTotal += variant.price * e.value;
              }
            }

            return SingleChildScrollView( 
              child: Column(
                children: [
                  ListView.separated(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: validCartItems.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = validCartItems[index]; 
                      final v = variantMap[item.key]!; 
                      final p = variantToProductMap[item.key]!;
                      return ListTile(
                        leading: _ProductThumbnail(imageUrl: p.imageUrl),
                        title: Text("${p.name} (${v.variantName})"),
                        subtitle: Text("${Constants.currencySymbol}${v.price.toStringAsFixed(0)} x ${item.value}"),
                        trailing: Text("${Constants.currencySymbol}${(v.price * item.value).toStringAsFixed(0)}"),
                      );
                    },
                  ),
                  
                  // Address Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: addressesAsync.when(
                      data: (addresses) {
                        // Auto-select default if none selected
                        if (_selectedAddress == null && addresses.isNotEmpty) {
                          try {
                            _selectedAddress = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
                          } catch (_) {}
                        }

                        if (addresses.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(8), color: Colors.red.shade50),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                const SizedBox(width: 8),
                                const Expanded(child: Text("No address found. Please add one.")),
                                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookPage())), child: const Text("Manage"))
                              ],
                            ),
                          );
                        }

                        return DropdownButtonFormField<UserAddress>(
                          decoration: const InputDecoration(labelText: "Delivery Address"),
                          value: _selectedAddress,
                          isExpanded: true,
                          items: addresses.map((addr) {
                             return DropdownMenuItem(
                               value: addr,
                               child: Text(addr.toString(), overflow: TextOverflow.ellipsis),
                             );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedAddress = val),
                        );
                      },
                      loading: () => const LinearProgressIndicator(), 
                      error: (e, s) => Text("Error loading addresses: $e"),
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
              ),
            );
          } catch (e, stack) {
             return Center(child: Text("Error: $e"));
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Future<void> _submitOrder(double totalAmount, String? userId, Map<String, ProductVariant> variantMap) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User ID not found. Please Login.")));
      return;
    }
    if (_selectedAddress == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a delivery address")));
       return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cart = ref.read(cartProvider);
      
      final orderRes = await SupabaseConfig.client.from('tea_orders').insert({
        'user_id': userId,
        'status': 'requested',
        'total_amount': totalAmount,
        'admin_notes': _adminNotesController.text, 
        'shipping_address': _selectedAddress!.toJson(), // Snapshot the address
      }).select().single();

      final orderId = orderRes['id'];
      final itemsToInsert = <Map<String, dynamic>>[];
      
      for (var entry in cart.items.entries) {
        if (!variantMap.containsKey(entry.key)) continue; 
        final variant = variantMap[entry.key]!;
        
        itemsToInsert.add({
          'order_id': orderId,
          'product_id': entry.key, 
          'quantity': entry.value,
          'unit_price': variant.price,
        });
      }

      if (itemsToInsert.isNotEmpty) {
        await SupabaseConfig.client.from('tea_order_items').insert(itemsToInsert);
      }

      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order Requested Successfully!"), backgroundColor: Colors.green)
        );
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
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
