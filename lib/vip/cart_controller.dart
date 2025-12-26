import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/product.dart';

// Key: Product ID, Value: Quantity
class CartState {
  final Map<String, int> items;

  CartState({this.items = const {}});

  CartState copyWith({Map<String, int>? items}) {
    return CartState(items: items ?? this.items);
  }
  
  int get totalItems => items.values.fold(0, (sum, qty) => sum + qty);
}

class CartController extends StateNotifier<CartState> {
  CartController() : super(CartState());

  void setQuantity(String productId, int quantity) {
    final newItems = Map<String, int>.from(state.items);
    if (quantity > 0) {
      newItems[productId] = quantity;
    } else {
      newItems.remove(productId);
    }
    state = state.copyWith(items: newItems);
  }
  
  void clear() {
    state = CartState();
  }
  
  int getQuantity(String productId) => state.items[productId] ?? 0;
}

final cartProvider = StateNotifierProvider<CartController, CartState>((ref) {
  return CartController();
});
