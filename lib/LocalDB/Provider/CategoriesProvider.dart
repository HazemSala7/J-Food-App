import 'package:flutter/material.dart';
import '../DataBase/DataBase.dart';
import '../Models/CategoryItem.dart';

class CategoriesProvider extends ChangeNotifier {
  List<CategoryItem> _CategoryItems = [];
  CartDatabaseHelper _dbHelper = CartDatabaseHelper();

  List<CategoryItem> get CategoryItems => _CategoryItems;

  CategoriesProvider() {
    _init();
  }

  // Initialize provider by loading categories from database
  Future<void> _init() async {
    _CategoryItems = await _dbHelper.getCategories();
    notifyListeners();
  }

  // Add category to the list and database
  Future<void> addToCategories(CategoryItem category) async {
    await _dbHelper.insertCategory(category);
    _CategoryItems.add(category);

    // Refresh categories with latest data from database
    _CategoryItems = await _dbHelper.getCategories();
    notifyListeners();
  }

  // Check if a category exists in the list by ID
  bool isCategoryExists(int categoryId) {
    return _CategoryItems.any((item) => item.id == categoryId);
  }

  // Remove category from the list and database
  Future<void> removeFromCategories(int categoryId) async {
    await _dbHelper.deleteCategory(categoryId);
    _CategoryItems.removeWhere((item) => item.id == categoryId);
    notifyListeners();
  }

  // Fetch category by ID
  Future<CategoryItem?> getCategoryById(int categoryId) async {
    return await _dbHelper.getCategoryById(categoryId);
  }

  // Convert categories to an array of maps
  List<Map<String, dynamic>> getCategoriesArray() {
    return _CategoryItems.map((item) {
      return {
        'id': item.id,
        'name': item.name,
        'image': item.image,
      };
    }).toList();
  }
}
