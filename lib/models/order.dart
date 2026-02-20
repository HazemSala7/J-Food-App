class Order {
  final int id;
  final String customerName;
  final int restaurantId;
  final String mobile;
  final String city;
  final String area;
  final String address;
  final String? notes;
  final String status;
  final String checkoutType;
  final String type;
  final String total;
  final double latitude;
  final double longitude;
  final String salesmanId;
  final int userId;
  final bool showNumber;
  final int preparationTime;
  final Restaurant restaurant;
  final List<Item> items;
  final int itemsLength;
  DateTime? createdAt;
  DateTime? updatedAt;

  Order({
    required this.id,
    required this.customerName,
    required this.restaurantId,
    required this.mobile,
    required this.city,
    required this.area,
    required this.address,
    this.notes,
    required this.status,
    required this.checkoutType,
    required this.type,
    required this.total,
    required this.latitude,
    required this.longitude,
    required this.salesmanId,
    required this.userId,
    required this.showNumber,
    required this.preparationTime,
    required this.restaurant,
    required this.items,
    required this.itemsLength,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList =
        (json['items'] as List).map((item) => Item.fromJson(item)).toList();
    return Order(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? 'Unknown',
      restaurantId: json['restaurant_id'] ?? 0,
      mobile: json['mobile'] ?? 'No mobile number',
      city: json['city'] ?? 'Unknown city',
      area: json['area'] ?? 'Unknown area',
      address: json['address'] ?? 'No address provided',
      notes: json['notes'],
      status: json['status'] ?? 'Unknown status',
      checkoutType: json['checkout_type'] ?? 'Unknown checkoutType',
      type: json['type'] ?? 'Unknown type',
      total: json['total'] ?? '0.0',
      latitude: (json['lattitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      salesmanId: json['salesman_id']?.toString() ?? 'No salesman',
      userId: json['user_id'] ?? 0,
      showNumber: json['show_number'].toString().toLowerCase() == 'true',
      preparationTime: json['preparation_time'] ?? 0,
      restaurant: Restaurant.fromJson(json['restaurant'] ?? {}),
      items: itemsList,
      itemsLength: json['items_length'] ?? 0,
      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"])
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.parse(json["updated_at"])
          : null,
    );
  }
}

class Restaurant {
  final int id;
  final String name;
  final String image;
  final String coverImage;
  final double latitude;
  final double longitude;
  final String address;
  final String phoneNumber;
  final String openTime;
  final String closeTime;
  final String deliveryPrice;
  final String deliveryTime;
  final String categoryId;
  final bool active;
  final String special;

  Restaurant({
    required this.id,
    required this.name,
    required this.image,
    required this.coverImage,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phoneNumber,
    required this.openTime,
    required this.closeTime,
    required this.deliveryPrice,
    required this.deliveryTime,
    required this.categoryId,
    required this.active,
    required this.special,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown restaurant',
      image: json['image'] ?? 'No image available',
      coverImage: json['cover_image'] ?? 'No cover image available',
      latitude: (json['lattitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? 'No address provided',
      phoneNumber: json['phone_number'] ?? 'No phone number',
      openTime: json['open_time'] ?? '00:00',
      closeTime: json['close_time'] ?? '00:00',
      deliveryPrice: json['delivery_price'] ?? '0',
      deliveryTime: json['delivery_time'] ?? '0 min',
      categoryId: json['category_id'] ?? 'No category',
      active: json['active'].toString().toLowerCase() == 'true',
      special: json['special'] ?? '',
    );
  }
}

class Item {
  final int id;
  final int orderId;
  final int productId;
  final int restaurantId;
  final String price;
  final String qty;
  final String sum;
  final Product product;
  final Size size;
  final List<Drink> drinks;
  final List<Component> components;
  final List<int> componentIdsQty;
  final List<int> drinkIdsQty;

  Item({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.restaurantId,
    required this.price,
    required this.qty,
    required this.sum,
    required this.product,
    required this.size,
    required this.drinks,
    required this.components,
    required this.componentIdsQty,
    required this.drinkIdsQty,
  });

  String get componentsAsString {
    return components.asMap().entries.map((entry) {
      // int index = entry.key;
      Component component = entry.value;
      // var qty = componentIdsQty.length > index ? componentIdsQty[index] : 0;
      return " ${component.comName} ";
    }).join(',');
  }
  // String get componentsAsString {
  //   return components.asMap().entries.map((entry) {
  //     int index = entry.key;
  //     Component component = entry.value;
  //     var qty = componentIdsQty.length > index ? componentIdsQty[index] : 0;
  //     return "${component.comName} - العدد: $qty - السعر: ${component.comPrice}₪";
  //   }).join('\n');
  // }

  String get drinksAsString {
    return drinks.asMap().entries.map((entry) {
      // int index = entry.key;
      Drink drink = entry.value;
      // var qty = drinkIdsQty.length > index ? drinkIdsQty[index] : 0;
      return " ${drink.drinkName} ";
    }).join(',');
  }
  // String get drinksAsString {
  //   return drinks.asMap().entries.map((entry) {
  //     int index = entry.key;
  //     Drink drink = entry.value;
  //     var qty = drinkIdsQty.length > index ? drinkIdsQty[index] : 0;
  //     return "${drink.drinkName} - العدد: $qty - السعر: ${drink.drinkPrice}₪";
  //   }).join('\n');
  // }

  factory Item.fromJson(Map<String, dynamic> json) {
    var drinksList = json['drinks'] as List? ?? [];
    var componentsList = json['components'] as List? ?? [];

    List<Drink> drinks = drinksList.map((i) => Drink.fromJson(i)).toList();
    List<Component> components =
        componentsList.map((i) => Component.fromJson(i)).toList();

    List<int>? componentIdsQty;
    json['component_ids_qty'] != null
        ? componentIdsQty = (json['component_ids_qty'] as String)
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',')
            .map((e) => int.tryParse(e.trim()) ?? 0)
            .toList()
        : componentIdsQty = [];

    List<int>? drinkIdsQty;
    json['drink_ids_qty'] != null
        ? drinkIdsQty = (json['drink_ids_qty'] as String)
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',')
            .map((e) => int.tryParse(e.trim()) ?? 0)
            .toList()
        : drinkIdsQty = [];

    return Item(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      restaurantId: json['restaurant_id'] ?? 0,
      price: json['price'] ?? '0',
      qty: json['qty'] ?? '0',
      sum: json['sum'] ?? '0',
      product: Product.fromJson(json['product'] ?? {}),
      drinks: drinks,
      size: Size.fromJson(json['size'] ?? {}),
      components: components,
      componentIdsQty: componentIdsQty,
      drinkIdsQty: drinkIdsQty,
    );
  }

  double get totalComponentsPrice {
    double total = 0.0;
    components.asMap().forEach((index, component) {
      var qty = componentIdsQty.length > index ? componentIdsQty[index] : 0;
      var componentPrice = double.tryParse(component.comPrice) ?? 0.0;
      total += componentPrice * qty;
      print("Component Price: $componentPrice, Quantity: $qty");
    });

    return total;
  }

  double get totalDrinksPrice {
    double total = 0.0;
    drinks.asMap().forEach((index, drink) {
      var qty = drinkIdsQty.length > index ? drinkIdsQty[index] : 0;
      var drinkPrice = double.tryParse(drink.drinkPrice) ?? 0.0;
      total += drinkPrice * qty;
    });

    return total;
  }

  double get totalPrice {
    double total = 0.0;
    drinks.asMap().forEach((index, drink) {
      var qty = drinkIdsQty.length > index ? drinkIdsQty[index] : 0;
      var drinkPrice = double.tryParse(drink.drinkPrice) ?? 0.0;
      total += drinkPrice * qty;
    });
    double total2 = 0.0;
    components.asMap().forEach((index, component) {
      var qty = componentIdsQty.length > index ? componentIdsQty[index] : 0;
      var componentPrice = double.tryParse(component.comPrice) ?? 0.0;
      total += componentPrice * qty;
    });

    return total + total2 + (double.parse(price) * double.parse(qty));
  }
}

class Product {
  final int id;
  final int storeId;
  final int categoryId;
  final String name;
  final String description;
  final String price;
  final String image;

  Product({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.price,
    required this.description,
    required this.name,
    required this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      price: json['price'] ?? '0',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
    );
  }
}

class Size {
  final int id;
  final String size;
  final String price;

  Size({
    required this.id,
    required this.size,
    required this.price,
  });

  factory Size.fromJson(Map<String, dynamic> json) {
    return Size(
      id: json['id'] ?? 0,
      size: json['size'] ?? '',
      price: json['size_price_nis'] ?? '0',
    );
  }
}

class Drink {
  final int id;
  final String drinkName;
  final String drinkPrice;

  Drink({
    required this.id,
    required this.drinkName,
    required this.drinkPrice,
  });

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'] ?? 0,
      drinkName: json['name'] ?? '',
      drinkPrice: json['price'] ?? '0',
    );
  }
}

class Component {
  final int id;
  final String comName;
  final String comPrice;

  Component({
    required this.id,
    required this.comName,
    required this.comPrice,
  });

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(
      id: json['id'] ?? 0,
      comName: json['name'] ?? '',
      comPrice: json['price'] ?? '0',
    );
  }
}
