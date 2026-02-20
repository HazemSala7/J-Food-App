import 'package:flutter/material.dart';
import '../DataBase/DataBase.dart';
import '../Models/CartItem.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _cartItems = [];
  CartDatabaseHelper _dbHelper = CartDatabaseHelper();

  List<CartItem> get cartItems => _cartItems;
  int get cartItemsCount => _cartItems.length;

  CartProvider() {
    _init();
  }

  Future<void> _init() async {
    _cartItems = await _dbHelper.getCartItems();
    notifyListeners();
  }

  Future<void> addToCart(CartItem item) async {
    await _dbHelper.insertCartItem(item);
    _cartItems.add(item);
    _cartItems = await _dbHelper.getCartItems();
    notifyListeners();
  }

  Future<void> removeFromCart(CartItem item) async {
    await _dbHelper.deleteCartItem(item.id!);
    _cartItems.remove(item);
    notifyListeners();
  }

  void increaseQuantity(CartItem item) {
    // Store the previous quantity
    int previousQuantity = item.quantity;

    // Increase the item quantity
    item.quantity += 1;

    // Scale selected component quantities proportionally
    for (int i = 0; i < item.selected_components_qty.length; i++) {
      int currentQty = int.parse(item.selected_components_qty[i]);
      // Scale the component quantity based on the new order quantity
      item.selected_components_qty[i] =
          ((currentQty / previousQuantity) * item.quantity).round().toString();
    }

    // Scale selected drink quantities proportionally
    for (int i = 0; i < item.selected_drinks_qty.length; i++) {
      int currentQty = int.parse(item.selected_drinks_qty[i]);
      // Scale the drink quantity based on the new order quantity
      item.selected_drinks_qty[i] =
          ((currentQty / previousQuantity) * item.quantity).round().toString();
    }

    // Recalculate the total for components
    double componentTotal = 0.0;
    for (int i = 0; i < item.selected_components_prices.length; i++) {
      double price = double.parse(item.selected_components_prices[i]);
      int quantity = int.parse(item.selected_components_qty[i]);
      componentTotal += price * quantity;
    }

    // Recalculate the total for drinks
    double drinkTotal = 0.0;
    for (int i = 0; i < item.selected_drinks_prices.length; i++) {
      double price = double.parse(item.selected_drinks_prices[i]);
      int quantity = int.parse(item.selected_drinks_qty[i]);
      drinkTotal += price * quantity;
    }

    // Calculate new item total
    double itemBaseTotal = item.quantity * double.parse(item.price);
    item.total = (itemBaseTotal + componentTotal + drinkTotal).toString();

    // Notify listeners about the change
    notifyListeners();
  }

  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      // Store the previous quantity
      int previousQuantity = item.quantity;

      // Decrease the item quantity
      item.quantity -= 1;

      // Scale selected component quantities proportionally
      for (int i = 0; i < item.selected_components_qty.length; i++) {
        int currentQty = int.parse(item.selected_components_qty[i]);
        // Scale the component quantity based on the new order quantity
        item.selected_components_qty[i] =
            ((currentQty / previousQuantity) * item.quantity)
                .round()
                .toString();
      }

      // Scale selected drink quantities proportionally
      for (int i = 0; i < item.selected_drinks_qty.length; i++) {
        int currentQty = int.parse(item.selected_drinks_qty[i]);
        // Scale the drink quantity based on the new order quantity
        item.selected_drinks_qty[i] =
            ((currentQty / previousQuantity) * item.quantity)
                .round()
                .toString();
      }

      // Recalculate the total for components
      double componentTotal = 0.0;
      for (int i = 0; i < item.selected_components_prices.length; i++) {
        double price = double.parse(item.selected_components_prices[i]);
        int quantity = int.parse(item.selected_components_qty[i]);
        componentTotal += price * quantity;
      }

      // Recalculate the total for drinks
      double drinkTotal = 0.0;
      for (int i = 0; i < item.selected_drinks_prices.length; i++) {
        double price = double.parse(item.selected_drinks_prices[i]);
        int quantity = int.parse(item.selected_drinks_qty[i]);
        drinkTotal += price * quantity;
      }

      // Calculate new item total
      double itemBaseTotal = item.quantity * double.parse(item.price);
      item.total = (itemBaseTotal + componentTotal + drinkTotal).toString();

      // Notify listeners about the change
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    await _dbHelper.clearCart();
    notifyListeners();
  }

  void updateCartItem(CartItem updatedItem) async {
    int index = _cartItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _cartItems[index] = updatedItem;
      await _dbHelper.updateCartItem(updatedItem);

      notifyListeners();
    }
  }

  Future<CartItem?> getCartItemByProductId(int productId) async {
    return await CartDatabaseHelper().getCartItemByProductId(productId);
  }

  List<Map<String, dynamic>> getProductsArray() {
    List<Map<String, dynamic>> productsArray = [];

    for (CartItem item in _cartItems) {
      Map<String, dynamic> productData = {
        'product_id': item.productId,
        'name': item.name,
        'price': item.price,
        'size': item.size,
        'sizeId': item.sizeId,
        'image': item.image,
        'components_names': item.components_names,
        'components_prices': item.components_prices,
        'quantity': item.quantity,
        'storeID': item.storeID,
        'storeName': item.storeName,
        'storeImage': item.storeImage,
        'storeLocation': item.storeLocation,
        'storeDeliveryPrice': item.storeDeliveryPrice,
        'selected_components_names': item.selected_components_names,
        'selected_components_prices': item.selected_components_prices,
        'drinks_names': item.drinks_names,
        'drinks_prices': item.drinks_prices,
        'selected_drinks_names': item.selected_drinks_names,
        'selected_drinks_prices': item.selected_drinks_prices,
        'selected_drinks_id': item.selected_drinks_id.isNotEmpty
            ? item.selected_drinks_id
            : ['0'],
        'selected_components_id': item.selected_components_id.isNotEmpty
            ? item.selected_components_id
            : ['0'],
        'selected_drinks_images': item.selected_drinks_images.isNotEmpty
            ? item.selected_drinks_images
            : ['0'],
        'selected_components_images': item.selected_components_images.isNotEmpty
            ? item.selected_components_images
            : ['0'],
        'drinks_images':
            item.drinks_images.isNotEmpty ? item.drinks_images : ['0'],
        'components_images':
            item.components_images.isNotEmpty ? item.components_images : ['0'],
        'selected_drinks_qty': item.selected_drinks_qty.isNotEmpty
            ? item.selected_drinks_qty
            : ['0'],
        'selected_components_qty': item.selected_components_qty.isNotEmpty
            ? item.selected_components_qty
            : ['0'],
      };
      productsArray.add(productData);
    }

    return productsArray;
  }
}
