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
import '../../core/cart_utils.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final _adminNotesController = TextEditingController(); 
  final _couponController = TextEditingController();
  double _appliedCouponDiscount = 0.0;
  bool _useSupercoins = false;
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
      appBar: AppBar(title: const Text("Book Your Order")),
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
            double totalWeightKg = 0;

            for (var e in validCartItems) {
              final variant = variantMap[e.key];
              if (variant != null) {
                final bags = e.value;
                final pieces = bags * CartUtils.piecesPerBag;
                final weightPerPiece = CartUtils.parseWeightFromVariant(variant.variantName);
                
                estimatedTotal += variant.price * pieces;
                totalWeightKg += weightPerPiece * pieces;
              }
            }
            
            final earnedPoints = CartUtils.calculatePoints(totalWeightKg);
            final remainingKg = CartUtils.minOrderWeightKg - totalWeightKg;
            final isMinOrderMet = remainingKg <= 0;

            // Supercoin Calculation
            final int availableCoins = (userProfile != null && userProfile['supercoins'] != null) 
                ? userProfile['supercoins'] as int 
                : 0;
            
            // 4 coins = 1 unit discount
            // Max discount cannot exceed total
            double possibleDiscount = availableCoins / 4.0;
            if (possibleDiscount > estimatedTotal) {
              possibleDiscount = estimatedTotal;
            }
            int coinsToBurn = (possibleDiscount * 4).ceil();

            // Final Calculation
            double finalTotal = estimatedTotal;
            if (_useSupercoins) {
              finalTotal -= possibleDiscount;
            }
            finalTotal -= _appliedCouponDiscount;
            if (finalTotal < 0) finalTotal = 0;

            return SingleChildScrollView( 
              child: Column(
                children: [
                   // Min Order Progress
                   Container(
                     padding: const EdgeInsets.all(16),
                     color: isMinOrderMet ? Colors.green.shade50 : Colors.orange.shade50,
                     child: Column(
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               isMinOrderMet ? "Minimum Order Met!" : "Add ${remainingKg.toStringAsFixed(1)} KG more",
                               style: TextStyle(
                                 fontWeight: FontWeight.bold, 
                                 color: isMinOrderMet ? Colors.green : Colors.deepOrange
                               )
                             ),
                             Text(
                               "${totalWeightKg.toStringAsFixed(1)} / ${CartUtils.minOrderWeightKg} KG",
                               style: const TextStyle(fontWeight: FontWeight.bold)
                             ),
                           ],
                         ),
                         const SizedBox(height: 8),
                         LinearProgressIndicator(
                           value: (totalWeightKg / CartUtils.minOrderWeightKg).clamp(0.0, 1.0),
                           backgroundColor: Colors.grey[200],
                           color: isMinOrderMet ? Colors.green : Colors.orange,
                           minHeight: 8,
                           borderRadius: BorderRadius.circular(4),
                         ),
                       ],
                     ),
                   ),

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
                      final bags = item.value;
                      final pieces = bags * CartUtils.piecesPerBag;
                      final itemTotal = v.price * pieces;

                      return ListTile(
                        leading: _ProductThumbnail(imageUrl: p.imageUrl),
                        title: Text("${p.name} (${v.variantName})"),
                        subtitle: Text("$bags Bag(s) x 30 pcs\n₹${v.price.toStringAsFixed(0)}/pc"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${Constants.currencySymbol}${itemTotal.toStringAsFixed(0)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              "${(CartUtils.parseWeightFromVariant(v.variantName) * pieces).toStringAsFixed(1)} KG",
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            )
                          ],
                        ),
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

                  // Supercoin Section
                  if (availableCoins > 0)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                             Row(
                               children: [
                                 const Icon(Icons.monetization_on, color: Colors.orange),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: Text(
                                     "Use Supercoins (Balance: $availableCoins)",
                                     style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                   ),
                                 ),
                                 Switch(
                                   value: _useSupercoins, 
                                   onChanged: (val) => setState(() => _useSupercoins = val),
                                   activeColor: Colors.orange,
                                 ),
                               ],
                             ),
                             if (_useSupercoins)
                               Text(
                                 "You will save ${Constants.currencySymbol}${possibleDiscount.toStringAsFixed(2)} using $coinsToBurn coins",
                                 style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                               ),
                        ],
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
                            const Text("Subtotal:", style: TextStyle(fontSize: 16, color: Colors.grey)),
                            Text("${Constants.currencySymbol}${estimatedTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        if (_useSupercoins)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Discount:", style: TextStyle(fontSize: 16, color: Colors.green)),
                            Text("-${Constants.currencySymbol}${possibleDiscount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, color: Colors.green)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              "${Constants.currencySymbol}${finalTotal.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.royalMaroon),
                            ),
                          ],
                        ),
                        // COUPON SECTION
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50], 
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer_outlined, color: Colors.grey, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  decoration: const InputDecoration(
                                    hintText: "Enter Coupon Code",
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  enabled: _appliedCouponDiscount == 0,
                                ),
                              ),
                              if (_appliedCouponDiscount > 0)
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _appliedCouponDiscount = 0;
                                      _couponController.clear();
                                    });
                                  },
                                )
                              else
                                TextButton(
                                  onPressed: () => _verifyCoupon(estimatedTotal),
                                  child: const Text("APPLY"),
                                )
                            ],
                          ),
                        ),
                        if (_appliedCouponDiscount > 0)
                           Padding(
                             padding: const EdgeInsets.only(top: 8.0),
                             child: Text("Coupon Applied: -${Constants.currencySymbol}${_appliedCouponDiscount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
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
                          onPressed: (_isSubmitting || !isMinOrderMet) ? null : () => _submitOrder(
                            finalTotal, 
                            userProfile?['id'], 
                            variantMap, 
                            validCartItems, 
                            _useSupercoins ? coinsToBurn : 0
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: isMinOrderMet ? AppTheme.royalMaroon : Colors.grey,
                          ),
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

  Future<void> _submitOrder(
    double totalAmount, 
    String? userId, 
    Map<String, ProductVariant> variantMap,
    List<MapEntry<String, int>> cartItems,
    int coinsToRedeem,
  ) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User ID not found. Please Login.")));
      return;
    }

    // Check if user is active
    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile != null && userProfile['is_active'] == false) {
       await showDialog(
         context: context,
         builder: (context) => AlertDialog(
           title: const Text("Account Restricted"),
           content: const Text("Your account is currently inactive. You cannot place new orders. Please contact support."),
           actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
         ),
       );
       return;
    }

    if (_selectedAddress == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a delivery address")));
       return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Construct items array
      final itemsList = <Map<String, dynamic>>[];
      for (var entry in cartItems) {
        if (!variantMap.containsKey(entry.key)) continue; 
        final variant = variantMap[entry.key]!;
        final bags = entry.value;
        final pieces = bags * CartUtils.piecesPerBag;
        itemsList.add({
          'product_id': entry.key,
          'quantity': pieces, // Converting Bags to Units (Pieces)
          'unit_price': variant.price,
        });
      }

      // Call the secure RPC function
      await SupabaseConfig.client.rpc('place_order', params: {
        'p_total_amount': totalAmount,
        'p_admin_notes': _adminNotesController.text,
        'p_shipping_address': _selectedAddress!.toJson(),
        'p_items': itemsList,
        'p_coins_to_redeem': coinsToRedeem,
        'p_coupon_code': _appliedCouponDiscount > 0 ? _couponController.text.toUpperCase() : null,
        'p_discount_amount': _appliedCouponDiscount,
      });

      // Clear cart on success
      ref.read(cartProvider.notifier).clear();
      
      // Refresh profile to show updated coin balance
      ref.invalidate(userProfileProvider);

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

  Future<void> _verifyCoupon(double orderTotal) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    try {
      // Query DB directly
      final res = await SupabaseConfig.client
          .from('coupons')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (res != null) {
        final percent = res['discount_percent'] as int;
        final discountAmount = orderTotal * (percent / 100.0);
        
        setState(() {
          _appliedCouponDiscount = discountAmount;
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text("Applied $percent% off! You save ${Constants.currencySymbol}${discountAmount.toStringAsFixed(2)}"), 
               backgroundColor: Colors.green
             )
           );
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Invalid or expired coupon code"), backgroundColor: Colors.red)
           );
        }
        setState(() => _appliedCouponDiscount = 0);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to verify coupon: $e")));
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
