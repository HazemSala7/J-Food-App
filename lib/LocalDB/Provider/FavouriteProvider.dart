import 'dart:convert';
import 'package:flutter/material.dart';
import '../DataBase/DataBase.dart';
import '../Models/FavoriteItem.dart';

class FavouriteProvider extends ChangeNotifier {
  List<FavoriteItem> _favouritesItems = [];
  CartDatabaseHelper _dbHelper = CartDatabaseHelper();

  List<FavoriteItem> get favoriteItems => _favouritesItems;

  FavouriteProvider() {
    _init();
  }

  Future<void> _init() async {
    _favouritesItems = await _dbHelper.getFavoriteItems();
    notifyListeners();
  }

  Future<void> addToFavorite(FavoriteItem item) async {
    final existingIndex = _favouritesItems
        .indexWhere((cartItem) => cartItem.storeId == item.storeId);
    // Item does not exist in the cart, add it as a new item
    await _dbHelper.insertFavoriteItem(item);
    _favouritesItems.add(item);
    // Refresh _cartItems with the latest data from the database
    _favouritesItems = await _dbHelper.getFavoriteItems();

    notifyListeners();
  }

  bool isProductFavorite(int productId) {
    // Assuming you have a list of favorite items in _favoriteItems
    return _favouritesItems.any((item) => item.storeId == productId);
  }

  Future<void> removeFromFavorite(int storeId) async {
    await _dbHelper.deleteFavoriteItem(storeId);
    _favouritesItems.removeWhere((item) => item.storeId == storeId);
    notifyListeners();
  }

  Future<FavoriteItem?> getFavoriteItemByProductId(int productId) async {
    return await CartDatabaseHelper().getFavoriteItemByProductId(productId);
  }

  List<Map<String, dynamic>> getProductsArray() {
    List<Map<String, dynamic>> productsArray = [];

    for (FavoriteItem item in _favouritesItems) {
      Map<String, dynamic> productData = {
        'storeId': item.storeId,
        'storeName': item.storeName,
        'storeImage': item.storeImage,
        'categoryName': item.storeImage,
        'categoryID': item.categoryID,
        'openTime': item.openTime,
        'closeTime': item.closeTime,
        'storeLocation': item.storeLocation,
      };
      productsArray.add(productData);
    }

    return productsArray;
  }
}
