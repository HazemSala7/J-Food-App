import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:j_food_updated/models/order.dart';

class OrderProvider with ChangeNotifier {
  final String storeId;
  final String categoryId;

  OrderProvider({required this.storeId, required this.categoryId}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchOrders('pending'); // Fetch orders after the first frame
    });
  }

  Map<String, List<Order>> _cachedOrders = {};
  Map<String, bool> _isLoading = {};
  final StreamController<List<Order>> _ordersStreamController =
      StreamController<List<Order>>.broadcast();

  Stream<List<Order>> getOrdersStreamForStatus(String status) {
    return _ordersStreamController.stream.map(
        (orders) => orders.where((order) => order.status == status).toList());
  }

  bool isLoading(String status) => _isLoading[status] ?? false;

  void _addOrders(String status, List<Order> orders) {
    _cachedOrders[status] = orders;
    _isLoading[status] = false;
    _ordersStreamController
        .add(_cachedOrders.values.expand((orders) => orders).toList());
    print("Added orders to stream: ${orders.length}");
    notifyListeners();
  }

  Future<void> fetchOrders(String status) async {
    print('Fetching orders with status: $status');
    if (_cachedOrders.containsKey(status)) {
      print('Using cached orders for status: $status');
      _ordersStreamController
          .add(_cachedOrders.values.expand((orders) => orders).toList());
      return;
    }

    _addOrders(status, []); // Add empty list to indicate no initial data
    _isLoading[status] = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(
          'https://hrsps.com/login/api/filter_shipment_by_status/$status/$storeId'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Orders fetched successfully');
        List<Order> fetchedOrders = List<Order>.from(json
            .decode(response.body)['orders']
            .map((data) => Order.fromJson(data)));
        _addOrders(status, fetchedOrders);
      } else {
        print('Failed to load orders: ${response.statusCode}');
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      _ordersStreamController.addError('Error fetching orders');
      _isLoading[status] = false;
      notifyListeners();
    }
  }

  Future<void> changeOrderPreparationTime(
      String orderId, String preparationTime) async {
    await http.post(
      Uri.parse('https://hrsps.com/login/api/change_order_preparation_time'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'order_id': orderId,
        'preparation_time': preparationTime
      }),
    );
  }

  Future<void> changeOrderStatus(String orderId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('https://hrsps.com/login/api/change_order_status'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body:
            jsonEncode(<String, String>{'order_id': orderId, 'status': status}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _cachedOrders.remove(status); // Invalidate the cache for the status
        fetchOrders(status); // Fetch the updated orders
      } else {
        throw Exception('Failed to change order status');
      }
    } catch (e) {
      _ordersStreamController.addError('Error changing order status');
    }
  }

  @override
  void dispose() {
    _ordersStreamController.close();
    super.dispose();
  }
}
