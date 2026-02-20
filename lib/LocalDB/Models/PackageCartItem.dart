import 'dart:convert';

class Product {
  final String name;
  final List<Component> components;

  Product({required this.name, required this.components});

  Map<String, dynamic> toJson() => {
        'name': name,
        'components': components.map((c) => c.toJson()).toList(),
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        name: json['name'] ?? '',
        components: (json['components'] as List?)
                ?.map((c) => Component.fromJson(c))
                .toList() ??
            [],
      );
}

class Component {
  final String name;
  final String price;
  final String qty;
  final String id;

  Component(
      {required this.name,
      required this.price,
      required this.qty,
      required this.id});

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'qty': qty,
        'id': id,
      };

  factory Component.fromJson(Map<String, dynamic> json) => Component(
        name: json['name'] ?? '',
        price: json['price'] ?? '0',
        qty: json['qty'] ?? '0',
        id: json['id'] ?? '0',
      );
}

class PackageCartItem {
  final int? id;
  final int packageId;
  final String packageName;
  final String packageImage;
  String total;
  final String packagePrice;
  final String storeID;
  final String storeName;
  final String storeImage;
  final String storeLocation;
  final String storeDeliveryPrice;
  final int quantity;
  final List<String> productNames;
  final List<String> productIds;
  final Map<String, Component> productComponents;
  final List<String> selected_drinks_names;
  final List<String> selected_drinks_prices;
  final List<String> selected_drinks_qty;
  final List<String> selected_drinks_id;
  final String storeOpenTime;
  final String storeCloseTime;
  final String workingHours; // JSON string of j.food.com.jfood array
  final bool isOpen; // Current is_open status

  PackageCartItem({
    this.id,
    required this.packageId,
    required this.packageName,
    required this.packageImage,
    required this.storeID,
    required this.storeName,
    required this.storeDeliveryPrice,
    required this.storeLocation,
    required this.storeImage,
    required this.total,
    required this.storeCloseTime,
    required this.storeOpenTime,
    this.workingHours = '[]',
    this.isOpen = false,
    required this.packagePrice,
    required this.productNames,
    required this.productIds,
    required this.productComponents,
    required this.selected_drinks_names,
    required this.selected_drinks_prices,
    required this.selected_drinks_qty,
    required this.selected_drinks_id,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageId': packageId,
      'packageName': packageName,
      'packageImage': packageImage,
      'storeID': storeID,
      'storeName': storeName,
      'storeDeliveryPrice': storeDeliveryPrice,
      'storeLocation': storeLocation,
      'storeImage': storeImage,
      'total': total,
      'packagePrice': packagePrice,

      'productNames': jsonEncode(productNames),
      'productIds': jsonEncode(productIds),
      'productComponents': productComponents.map((key, value) =>
          MapEntry(key, value.toJson())), // Use toJson() for each Component

      'selectedDrinksNames': jsonEncode(selected_drinks_names),
      'selectedDrinksPrices': jsonEncode(selected_drinks_prices),
      'selectedDrinksQty': jsonEncode(selected_drinks_qty),
      'selectedDrinksId': jsonEncode(selected_drinks_id),

      'quantity': quantity,
      'storeOpenTime': storeOpenTime,
      'storeCloseTime': storeCloseTime,
      'workingHours': workingHours,
      'isOpen': isOpen ? 1 : 0,
    };
  }

  factory PackageCartItem.fromJson(Map<String, dynamic> json) {
    List<String> _parseStringToList(String? input) {
      if (input == null || input.isEmpty) return [];
      input = input.replaceAll('[', '').replaceAll(']', '');
      return input.contains(',') ? input.split(',') : [input];
    }

    // Deserialize the productComponents field into a Map<String, Component>
    Map<String, Component> _parseProductComponents(dynamic components) {
      if (components is String) {
        try {
          components = jsonDecode(components); // Convert string to Map
        } catch (e) {
          print("Error decoding productComponents: $e");
          return {}; // Return an empty map if decoding fails
        }
      }

      if (components is Map<String, dynamic>) {
        return components.map((key, value) =>
            MapEntry(key, Component.fromJson(value as Map<String, dynamic>)));
      } else {
        print(
            "Unexpected type for productComponents: ${components.runtimeType}");
        return {}; // Return an empty map if the type is unexpected
      }
    }

    return PackageCartItem(
      id: json['id'],
      packageId: json['packageId'] ?? 0,
      packageName: json['packageName'] ?? 'Unknown Package',
      packageImage: json['packageImage'] ?? 'https://example.com/default.jpg',
      storeID: json['storeID'] ?? '',
      storeName: json['storeName'] ?? 'Unknown Store',
      storeLocation: json['storeLocation'] ?? 'Unknown Location',
      storeImage: json['storeImage'] ?? 'Unknown Image',
      storeDeliveryPrice: json['storeDeliveryPrice'] ?? '0',
      total: json['total'] ?? '0',
      storeCloseTime: json['storeCloseTime'] ?? 'Unknown close',
      storeOpenTime: json['storeOpenTime'] ?? 'Unknown open',
      packagePrice: json['packagePrice'] ?? '0',
      productNames: _parseStringToList(json['productNames'] as String?),
      productIds: _parseStringToList(json['productIds'] as String?),
      productComponents:
          _parseProductComponents(json['productComponents'] ?? {}),
      selected_drinks_names:
          _parseStringToList(json['selected_drinks_names'] as String?),
      selected_drinks_prices:
          _parseStringToList(json['selected_drinks_prices'] as String?),
      selected_drinks_qty:
          _parseStringToList(json['selected_drinks_qty'] as String?),
      selected_drinks_id:
          _parseStringToList(json['selected_drinks_id'] as String?),
      quantity: json['quantity'] ?? 1,
      workingHours: json['workingHours'] ?? '[]',
      isOpen: json['isOpen'] == 1,
    );
  }
}
