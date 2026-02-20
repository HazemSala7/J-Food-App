class UserOrder {
  int? id;
  String? customerName;
  int? restaurantId;
  String? mobile;
  String? city;
  String? area;
  String? address;
  String? notes;
  String? status;
  String? type;
  double? total;
  double? latitude;
  double? longitude;
  String? salesmanId;
  int? userId;
  bool? showNumber;
  int? preparationTime;
  DateTime? createdAt;
  DateTime? updatedAt;
  Restaurant? restaurant;
  String? salesman;
  int? itemsLength;
  List<OrderDetail>? orderDetails;

  UserOrder({
    this.id,
    this.customerName,
    this.restaurantId,
    this.mobile,
    this.city,
    this.area,
    this.address,
    this.notes,
    this.status,
    this.type,
    this.total,
    this.latitude,
    this.longitude,
    this.salesmanId,
    this.userId,
    this.showNumber,
    this.preparationTime,
    this.createdAt,
    this.updatedAt,
    this.restaurant,
    this.salesman,
    this.itemsLength,
    this.orderDetails,
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) => UserOrder(
        id: json["id"],
        customerName: json["customer_name"],
        restaurantId: json["restaurant_id"],
        mobile: json["mobile"],
        city: json["city"],
        area: json["area"],
        address: json["address"],
        notes: json["notes"],
        status: json["status"],
        type: json["type"],
        total: json["total"] != null ? double.tryParse(json["total"]) : null,
        latitude: json["lattitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        salesmanId: json["salesman_id"],
        userId: json["user_id"],
        showNumber: json["show_number"] == "true",
        preparationTime: json["preparation_time"],
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : null,
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : null,
        restaurant: json["restaurant"] != null
            ? Restaurant.fromJson(json["restaurant"])
            : null,
        salesman: json["salesman"],
        itemsLength: json["items_length"],
        orderDetails: json["order_details"] != null
            ? List<OrderDetail>.from(
                json["order_details"].map((x) => OrderDetail.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "customer_name": customerName,
        "restaurant_id": restaurantId,
        "mobile": mobile,
        "city": city,
        "area": area,
        "address": address,
        "notes": notes,
        "status": status,
        "type": type,
        "total": total,
        "lattitude": latitude,
        "longitude": longitude,
        "salesman_id": salesmanId,
        "user_id": userId,
        "show_number": showNumber,
        "preparation_time": preparationTime,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "restaurant": restaurant?.toJson(),
        "salesman": salesman,
        "items_length": itemsLength,
        "order_details": orderDetails != null
            ? List<dynamic>.from(orderDetails!.map((x) => x.toJson()))
            : null,
      };
}

class Restaurant {
  int? id;
  String? name;
  String? image;
  String? coverImage;
  double? latitude;
  double? longitude;
  String? address;
  String? phoneNumber;
  String? openTime;
  String? closeTime;
  String? deliveryPrice;
  String? deliveryTime;
  String? categoryId;
  String? active;
  String? special;

  Restaurant({
    this.id,
    this.name,
    this.image,
    this.coverImage,
    this.latitude,
    this.longitude,
    this.address,
    this.phoneNumber,
    this.openTime,
    this.closeTime,
    this.deliveryPrice,
    this.deliveryTime,
    this.categoryId,
    this.active,
    this.special,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json["id"],
        name: json["name"],
        image: json["image"],
        coverImage: json["cover_image"],
        latitude: json["lattitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        address: json["address"],
        phoneNumber: json["phone_number"],
        openTime: json["open_time"],
        closeTime: json["close_time"],
        deliveryPrice: json["delivery_price"],
        deliveryTime: json["delivery_time"],
        categoryId: json["category_id"],
        active: json["active"],
        special: json["special"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "image": image,
        "cover_image": coverImage,
        "lattitude": latitude,
        "longitude": longitude,
        "address": address,
        "phone_number": phoneNumber,
        "open_time": openTime,
        "close_time": closeTime,
        "delivery_price": deliveryPrice,
        "delivery_time": deliveryTime,
        "category_id": categoryId,
        "active": active,
        "special": special,
      };
}

class OrderDetail {
  int? id;
  int? orderId;
  int? productId;
  int? restaurantId;
  String? price;
  String? qty;
  String? sum;
  Product product;

  OrderDetail({
    this.id,
    this.orderId,
    this.productId,
    this.restaurantId,
    this.price,
    this.qty,
    this.sum,
    Product? product,
  }) : product = product ?? Product(id: 0, name: "Unknown Product");

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
        id: json["id"],
        orderId: json["order_id"],
        productId: json["product_id"],
        restaurantId: json["restaurant_id"],
        price: json["price"],
        qty: json["qty"],
        sum: json["sum"],
        product:
            json["product"] != null ? Product.fromJson(json["product"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "order_id": orderId,
        "product_id": productId,
        "restaurant_id": restaurantId,
        "price": price,
        "qty": qty,
        "sum": sum,
        "product": product.toJson(),
      };
}

class Product {
  int? id;
  String name;
  String price;
  String description;
  int? storeId;
  int? categoryId;
  String active;
  String image;

  Product({
    this.id,
    this.name = '', // Default empty string
    this.price = '0', // Default price as '0'
    this.description = '', // Default empty string
    this.storeId,
    this.categoryId,
    this.active = 'false', // Default to 'false'
    this.image = '', // Default empty string
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["id"],
        name: json["name"] ?? '', // Default to empty string if null
        price: json["price"] ?? '0', // Default to '0' if null
        description:
            json["description"] ?? '', // Default to empty string if null
        storeId: json["store_id"],
        categoryId: json["category_id"],
        active: json["active"] ?? 'false', // Default to 'false' if null
        image: json["image"] ?? '', // Default to empty string if null
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "price": price,
        "description": description,
        "store_id": storeId,
        "category_id": categoryId,
        "active": active,
        "image": image,
      };
}
