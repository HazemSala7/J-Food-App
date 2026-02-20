import 'package:j_food_updated/LocalDB/Database/Database.dart';
import 'package:flutter/material.dart';
import '../Models/PackageCartItem.dart';

class PackageCartProvider extends ChangeNotifier {
  List<PackageCartItem> _packageCartItems = [];
  final CartDatabaseHelper _dbHelper = CartDatabaseHelper();

  List<PackageCartItem> get packageCartItems => _packageCartItems;
  int get packageCartItemCount => _packageCartItems.length;

  PackageCartProvider() {
    _init();
  }

  Future<void> _init() async {
    _packageCartItems = await _dbHelper.getPackageCartItems();
    notifyListeners();
  }

  Future<void> addToCart(PackageCartItem item) async {
    await _dbHelper.insertPackageCartItem(item);
    _packageCartItems = await _dbHelper.getPackageCartItems();
    notifyListeners();
  }

  Future<void> removeFromCart(PackageCartItem item) async {
    await _dbHelper.deletePackageCartItem(item.id!);
    _packageCartItems.removeWhere((cartItem) => cartItem.id == item.id);
    notifyListeners();
  }

  Future<void> clearCart() async {
    _packageCartItems.clear();
    await _dbHelper.clearPackageCart();
    notifyListeners();
  }

  Future<void> updateCartItem(PackageCartItem updatedItem) async {
    int index =
        _packageCartItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _packageCartItems[index] = updatedItem;
      await _dbHelper.updatePackageCartItem(updatedItem);
      notifyListeners();
    }
  }

  Future<PackageCartItem?> getCartItemByPackageId(int packageId) async {
    return await _dbHelper.getPackageCartItemByPackageId(packageId);
  }

  double _calculateDrinkTotal(PackageCartItem item) {
    double total = 0.0;
    for (int i = 0; i < item.selected_drinks_prices.length; i++) {
      double price = double.tryParse(item.selected_drinks_prices[i]) ?? 0.0;
      int quantity = int.tryParse(item.selected_drinks_qty[i]) ?? 1;
      total += price * quantity;
    }
    return total;
  }

  List<Map<String, dynamic>> getPackagesArray() {
    return _packageCartItems.map((item) {
      return {
        'package_id': item.packageId,
        'package_name': item.packageName,
        'package_price': item.packagePrice,
        'package_image': item.packageImage,
        'quantity': item.quantity,
        'storeID': item.storeID,
        'storeName': item.storeName,
        'storeImage': item.storeImage,
        'storeLocation': item.storeLocation,
        'storeDeliveryPrice': item.storeDeliveryPrice,
        'productNames': item.productNames,
        'productIds': item.productIds,
        // Serialize productComponents as a Map
        'productComponents': item.productComponents.map((key, value) =>
            MapEntry(key, value.toJson())), // Correcting serialization
        'selected_drinks_names': item.selected_drinks_names.join(','),
        'selected_drinks_prices': item.selected_drinks_prices.join(','),
        'selected_drinks_qty': item.selected_drinks_qty.join(','),
        'selected_drinks_id': item.selected_drinks_id.join(','),
      };
    }).toList();
  }

  double _calculateComponentTotal(PackageCartItem item) {
    double total = 0.0;
    item.productComponents.forEach((_, components) {
      double price = double.tryParse(components.price) ?? 0.0;
      int quantity = int.tryParse(components.qty) ?? 1;
      total += price * quantity;
    });
    return total;
  }
}

  // void increaseQuantity(PackageCartItem item) {
  //   int previousQuantity = item.quantity;
  //   item.quantity += 1;

  //   for (var product in item.products) {
  //     for (int i = 0; i < product['selected_components_qty'].length; i++) {
  //       int currentQty = int.parse(product['selected_components_qty'][i]);
  //       product['selected_components_qty'][i] =
  //           ((currentQty / previousQuantity) * item.quantity)
  //               .round()
  //               .toString();
  //     }
  //   }

  //   for (int i = 0; i < item.selected_drinks_qty.length; i++) {
  //     int currentQty = int.parse(item.selected_drinks_qty[i]);
  //     item.selected_drinks_qty[i] =
  //         ((currentQty / previousQuantity) * item.quantity).round().toString();
  //   }

  //   double packageBaseTotal = item.quantity * double.parse(item.packagePrice);
  //   double componentTotal = _calculateComponentTotal(item);
  //   double drinkTotal = _calculateDrinkTotal(item);
  //   item.total = (packageBaseTotal + componentTotal + drinkTotal).toString();

  //   notifyListeners();
  // }

  // void decreaseQuantity(PackageCartItem item) {
  //   if (item.quantity > 1) {
  //     int previousQuantity = item.quantity;
  //     item.quantity -= 1;

  //     for (var product in item.products) {
  //       for (int i = 0; i < product['selected_components_qty'].length; i++) {
  //         int currentQty = int.parse(product['selected_components_qty'][i]);
  //         product['selected_components_qty'][i] =
  //             ((currentQty / previousQuantity) * item.quantity)
  //                 .round()
  //                 .toString();
  //       }
  //     }

  //     for (int i = 0; i < item.selected_drinks_qty.length; i++) {
  //       int currentQty = int.parse(item.selected_drinks_qty[i]);
  //       item.selected_drinks_qty[i] =
  //           ((currentQty / previousQuantity) * item.quantity)
  //               .round()
  //               .toString();
  //     }

  //     double packageBaseTotal = item.quantity * double.parse(item.packagePrice);
  //     double componentTotal = _calculateComponentTotal(item);
  //     double drinkTotal = _calculateDrinkTotal(item);
  //     item.total = (packageBaseTotal + componentTotal + drinkTotal).toString();

  //     notifyListeners();
  //   }
  // }