import 'dart:async';
import 'package:j_food_updated/server/functions/functions.dart';
import 'package:flutter/material.dart';

class StoreProvider extends ChangeNotifier {
  Map<String, dynamic>? storeData;
  List<dynamic> allProducts = [];
  List<dynamic> allPackages = [];
  List<dynamic> displayedProducts = [];
  List<dynamic> displayedPackages = [];
  List<Map<String, dynamic>>? apiSubCategories;
  List<dynamic> restaurantStories = [];

  // Pagination properties
  int currentPage = 1;
  int lastPage = 1;
  bool isLoadingMore = false;
  bool hasMoreProducts = true;

  bool _disposed = false;

  bool isLoading = true;
  bool hasError = false;
  bool confirmOrder = false;
  bool showSuccessMessage = false;
  bool packagePage = false;

  Timer? _successMessageTimer;

  String selectedCategory = 'الكل';
  int selectedCategoryId = 0;

  // =================== SAFE NOTIFY ===================
  void safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  // =================== FETCH STORE DETAILS ===================
  Future<void> fetchStoreDetails(String storeId) async {
    try {
      final data =
          await getStoreDetails(storeId, page: currentPage, paginate: true);

      apiSubCategories = [
        {"id": 0, "name": "الكل"}
      ];

      apiSubCategories!.addAll(
        (data["restaurant"]["sub_categories"] as List<dynamic>)
            .map((subCategory) => {
                  "id": subCategory["id"],
                  "name": subCategory["name"],
                })
            .toList(),
      );

      storeData = data as Map<String, dynamic>;

      // Extract pagination metadata
      if (data["products"]["meta"] != null) {
        lastPage = data["products"]["meta"]["last_page"] ?? 1;
      }

      allProducts = storeData!["products"]["data"] ?? [];
      allPackages = storeData!["restaurant"]["restaurant_packages"];
      displayedProducts = List.from(allProducts);
      displayedPackages = List.from(allPackages);
      restaurantStories = storeData!["stories"] ?? [];
      isLoading = false;
      currentPage = 1;
      hasMoreProducts = currentPage < lastPage;

      safeNotifyListeners();
    } catch (e) {
      print("Error fetching store details: $e");
      hasError = true;
      isLoading = false;
      safeNotifyListeners();
    }
  }

  // =================== LOAD MORE PRODUCTS ===================
  Future<void> loadMoreProducts(String storeId) async {
    if (isLoadingMore || !hasMoreProducts) return;

    isLoadingMore = true;
    safeNotifyListeners();

    try {
      final nextPage = currentPage + 1;
      final data =
          await getStoreDetails(storeId, page: nextPage, paginate: true);

      if (data["products"]["data"] != null) {
        List<dynamic> newProducts = data["products"]["data"];

        // Create new lists instead of modifying existing ones to avoid render conflicts
        allProducts = List.from(allProducts)..addAll(newProducts);

        // Only update displayed products if not filtered
        if (selectedCategory == "الكل") {
          displayedProducts = List.from(displayedProducts)..addAll(newProducts);
        } else {
          // If filtered, add only filtered items
          List<dynamic> filteredNewProducts = newProducts
              .where(
                  (product) => product["sub_category_id"] == selectedCategoryId)
              .toList();
          displayedProducts = List.from(displayedProducts)
            ..addAll(filteredNewProducts);
        }

        currentPage = nextPage;
        if (data["products"]["meta"] != null) {
          lastPage = data["products"]["meta"]["last_page"] ?? lastPage;
        }
        hasMoreProducts = currentPage < lastPage;
      }

      isLoadingMore = false;
      safeNotifyListeners();
    } catch (e) {
      print("Error loading more products: $e");
      isLoadingMore = false;
      safeNotifyListeners();
    }
  }

  // =================== SEARCH ===================
  void searchItems(String query) {
    if (query.isEmpty) {
      displayedProducts = List.from(allProducts);
      displayedPackages = List.from(allPackages);
    } else {
      displayedProducts = allProducts
          .where((product) => product["name"]
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();

      displayedPackages = allPackages
          .where((package) => package["package_name"]
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
    safeNotifyListeners();
  }

  // =================== TOGGLE PACKAGE PAGE ===================
  void changePackagePage() {
    packagePage = !packagePage;
    safeNotifyListeners();
  }

  // =================== CONFIRM ORDER ===================
  void changeConfirmOrder() {
    confirmOrder = true;
    showOrderSuccessMessage();
    safeNotifyListeners();
  }

  void showOrderSuccessMessage() {
    showSuccessMessage = true;
    _successMessageTimer?.cancel();
    _successMessageTimer = Timer(Duration(seconds: 2), () {
      if (!_disposed) {
        showSuccessMessage = false;
        safeNotifyListeners(); // ✅ check before notifying
      }
    });
  }

  // =================== FILTER BY CATEGORY ===================
  void filterByCategory(int categoryId, String categoryName) {
    selectedCategoryId = categoryId;
    selectedCategory = categoryName;

    if (selectedCategory == "الكل") {
      displayedProducts = List.from(allProducts);
    } else {
      displayedProducts = allProducts
          .where((product) => product["sub_category_id"] == categoryId)
          .toList();
    }
    safeNotifyListeners();
  }

  // =================== DISPOSE ===================
  @override
  void dispose() {
    _disposed = true;
    _successMessageTimer?.cancel();
    super.dispose();
  }
}
