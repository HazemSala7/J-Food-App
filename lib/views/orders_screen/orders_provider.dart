import 'package:flutter/material.dart';
import 'package:j_food_updated/server/functions/functions.dart';

class OrdersProvider extends ChangeNotifier {
  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> displayedOrders = [];

  // Pagination properties
  int currentPage = 1;
  int lastPage = 1;
  int perPage = 10;
  bool isLoadingMore = false;
  bool hasMoreOrders = true;
  bool isLoading = true;
  bool hasError = false;

  bool _disposed = false;

  int activeTabIndex = 0;

  void safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  // =================== FETCH ORDERS ===================
  Future<void> fetchOrders(String userId) async {
    try {
      isLoading = true;
      final data = await getOrderDependOnUserID(
        userId,
        page: currentPage,
        perPage: perPage,
        paginate: true,
      );

      if (data.isNotEmpty && data['orders'] != null) {
        // Extract orders data
        var ordersResponse = data['orders'];

        // Handle both paginated and non-paginated responses
        List<Map<String, dynamic>> orders;
        if (ordersResponse is Map && ordersResponse.containsKey('data')) {
          // Paginated response
          orders =
              List<Map<String, dynamic>>.from(ordersResponse['data'] ?? []);
          lastPage = ordersResponse['last_page'] ?? 1;
        } else if (ordersResponse is List) {
          // Non-paginated response (backward compatibility)
          orders = List<Map<String, dynamic>>.from(ordersResponse);
          lastPage = 1;
        } else {
          orders = [];
          lastPage = 1;
        }

        allOrders = orders;
        _filterAndDisplayOrders();
        currentPage = 1;
        hasMoreOrders = currentPage < lastPage;
      } else {
        allOrders = [];
        displayedOrders = [];
      }

      isLoading = false;
      hasError = false;
      safeNotifyListeners();
    } catch (e) {
      print("Error fetching orders: $e");
      hasError = true;
      isLoading = false;
      safeNotifyListeners();
    }
  }

  // =================== LOAD MORE ORDERS ===================
  Future<void> loadMoreOrders(String userId) async {
    if (isLoadingMore || !hasMoreOrders) return;

    isLoadingMore = true;
    safeNotifyListeners();

    try {
      final nextPage = currentPage + 1;
      final data = await getOrderDependOnUserID(
        userId,
        page: nextPage,
        perPage: perPage,
        paginate: true,
      );

      if (data.isNotEmpty && data['orders'] != null) {
        var ordersResponse = data['orders'];
        List<Map<String, dynamic>> newOrders;

        if (ordersResponse is Map && ordersResponse.containsKey('data')) {
          newOrders =
              List<Map<String, dynamic>>.from(ordersResponse['data'] ?? []);
          lastPage = ordersResponse['last_page'] ?? lastPage;
        } else if (ordersResponse is List) {
          newOrders = List<Map<String, dynamic>>.from(ordersResponse);
        } else {
          newOrders = [];
        }

        // Create new lists to avoid concurrent modification
        allOrders = List.from(allOrders)..addAll(newOrders);

        // Add filtered new orders to displayed list
        List<Map<String, dynamic>> filteredNewOrders =
            _filterOrdersByTab(newOrders, activeTabIndex);
        displayedOrders = List.from(displayedOrders)..addAll(filteredNewOrders);

        currentPage = nextPage;
        hasMoreOrders = currentPage < lastPage;
      }

      isLoadingMore = false;
      safeNotifyListeners();
    } catch (e) {
      print("Error loading more orders: $e");
      isLoadingMore = false;
      safeNotifyListeners();
    }
  }

  // =================== FILTER ORDERS BY TAB ===================
  List<Map<String, dynamic>> _filterOrdersByTab(
      List<Map<String, dynamic>> orders, int tabIndex) {
    if (tabIndex == 0) {
      // Active orders
      return orders.where((order) {
        return order['status'] == 'in_delivery' &&
                order['checkout_type'] != "pickup" ||
            order['status'] == 'ready_for_delivery' ||
            order['status'] == 'in_progress' ||
            order['status'] == 'pending';
      }).toList();
    } else if (tabIndex == 1) {
      // Completed/Canceled orders
      return orders.where((order) {
        return order['status'] == 'canceled' ||
            order['status'] == 'delivered' ||
            (order['status'] == 'in_delivery' &&
                order['checkout_type'] == "pickup");
      }).toList();
    }
    return orders;
  }

  void _filterAndDisplayOrders() {
    displayedOrders = _filterOrdersByTab(allOrders, activeTabIndex);
  }

  // =================== CHANGE TAB ===================
  void changeTab(int tabIndex) {
    activeTabIndex = tabIndex;
    _filterAndDisplayOrders();
    safeNotifyListeners();
  }

  // =================== RESET PAGINATION ===================
  void resetPagination() {
    currentPage = 1;
    lastPage = 1;
    allOrders.clear();
    displayedOrders.clear();
    hasMoreOrders = true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
