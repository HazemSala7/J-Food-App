class CartItem {
  final int? id;
  final int productId;
  final String name;
  final String image;
  final String? size;
  final String? sizeId;
  String total;
  final String price;
  final String storeID;
  final String storeName;
  final String storeImage;
  final String storeOpenTime;
  final String storeCloseTime;
  final String storeLocation;
  final String storeDeliveryPrice;
  final String workingHours; // JSON string of j.food.com.jfood array
  final bool isOpen; // Current is_open status
  final List<String> components_names;
  final List<String> components_prices;
  List<String> selected_components_names;
  List<String> selected_components_prices;
  List<String> drinks_names;
  List<String> drinks_prices;
  List<String> selected_drinks_names;
  List<String> selected_drinks_prices;
  List<String> selected_drinks_id;
  List<String> selected_components_id;
  List<String> selected_components_images;
  List<String> components_images;
  List<String> drinks_images;
  List<String> selected_drinks_images;
  List<String> selected_drinks_qty;
  List<String> selected_components_qty;
  int quantity;
  String? note;

  CartItem({
    this.id,
    required this.productId,
    required this.name,
    required this.storeID,
    required this.storeName,
    required this.storeDeliveryPrice,
    required this.image,
    required this.storeLocation,
    required this.storeImage,
    required this.storeCloseTime,
    required this.storeOpenTime,
    this.workingHours = '[]',
    this.isOpen = false,
    required this.total,
    required this.price,
    required this.components_names,
    required this.components_prices,
    required this.selected_components_names,
    required this.selected_components_prices,
    required this.selected_drinks_images,
    required this.selected_components_images,
    required this.drinks_images,
    required this.components_images,
    required this.drinks_names,
    required this.drinks_prices,
    required this.selected_drinks_names,
    required this.selected_drinks_prices,
    required this.selected_drinks_id,
    required this.selected_components_id,
    required this.selected_drinks_qty,
    required this.selected_components_qty,
    this.quantity = 1,
    this.size,
    this.sizeId,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'storeID': storeID,
      'storeName': storeName,
      'storeDeliveryPrice': storeDeliveryPrice,
      'image': image,
      'storeLocation': storeLocation,
      'storeImage': storeImage,
      'total': total,
      'price': price,
      'size': size,
      'sizeId': sizeId,
      'components_names': components_names.join(','),
      'components_prices': components_prices.join(','),
      'selected_components_names': selected_components_names.join(','),
      'selected_components_prices': selected_components_prices.join(','),
      'drinks_names': drinks_names.join(','),
      'drinks_prices': drinks_prices.join(','),
      'selected_drinks_names': selected_drinks_names.join(','),
      'selected_drinks_prices': selected_drinks_prices.join(','),
      'selected_drinks_id':
          selected_drinks_id.isNotEmpty ? selected_drinks_id.join(',') : '0',
      'selected_components_id': selected_components_id.isNotEmpty
          ? selected_components_id.join(',')
          : '0',
      'selected_drinks_qty':
          selected_drinks_qty.isNotEmpty ? selected_drinks_qty.join(',') : '0',
      'selected_components_images': selected_components_images.isNotEmpty
          ? selected_components_images.join(',')
          : '0',
      'selected_drinks_images': selected_drinks_images.isNotEmpty
          ? selected_drinks_images.join(',')
          : '0',
      'components_images':
          components_images.isNotEmpty ? components_images.join(',') : '0',
      'drinks_images': drinks_images.isNotEmpty ? drinks_images.join(',') : '0',
      'selected_components_qty': selected_components_qty.isNotEmpty
          ? selected_components_qty.join(',')
          : '0',
      'quantity': quantity,
      'storeCloseTime': storeCloseTime,
      'storeOpenTime': storeOpenTime,
      'workingHours': workingHours,
      'isOpen': isOpen ? 1 : 0,
      'note': note ?? '',
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    List<String> _parseStringToList(String? input) {
      if (input == null || input.isEmpty) return [];
      return input.split(',').map((e) => e.trim()).toList();
    }

    return CartItem(
      id: json['id'],
      productId: json['productId'] ?? 0,
      name: json['name'] ?? 'Unknown',
      storeID: json['storeID'] ?? '',
      storeName: json['storeName'] ?? 'Unknown Store',
      storeCloseTime: json['storeCloseTime'] ?? 'Unknown close',
      storeOpenTime: json['storeOpenTime'] ?? 'Unknown open',
      storeLocation: json['storeLocation'] ?? 'Unknown storeLocation',
      storeImage: json['storeImage'] ?? 'Unknown storeImage',
      storeDeliveryPrice: json['storeDeliveryPrice'] ?? '0',
      total: json['total'] ?? '0',
      price: json['price'] ?? '0',
      size: json['size'] ?? '',
      sizeId: json['sizeId'] ?? '',
      image: json['image'] ?? 'https://example.com/default-image.jpg',
      components_names: _parseStringToList(json['components_names'] as String?),
      components_prices:
          _parseStringToList(json['components_prices'] as String?),
      selected_components_names:
          _parseStringToList(json['selected_components_names'] as String?),
      selected_components_prices:
          _parseStringToList(json['selected_components_prices'] as String?),
      drinks_names: _parseStringToList(json['drinks_names'] as String?),
      drinks_prices: _parseStringToList(json['drinks_prices'] as String?),
      selected_drinks_names:
          _parseStringToList(json['selected_drinks_names'] as String?),
      selected_drinks_images:
          _parseStringToList(json['selected_drinks_images'] as String?),
      selected_components_images:
          _parseStringToList(json['selected_components_images'] as String?),
      drinks_images: _parseStringToList(json['drinks_images'] as String?),
      components_images:
          _parseStringToList(json['components_images'] as String?),
      selected_drinks_prices:
          _parseStringToList(json['selected_drinks_prices'] as String?),
      selected_drinks_id:
          _parseStringToList(json['selected_drinks_id'] as String?),
      selected_components_id:
          _parseStringToList(json['selected_components_id'] as String?),
      selected_drinks_qty:
          _parseStringToList(json['selected_drinks_qty'] as String?),
      selected_components_qty:
          _parseStringToList(json['selected_components_qty'] as String?),
      quantity: json['quantity'] ?? 1,
      workingHours: json['workingHours'] ?? '[]',
      isOpen: json['isOpen'] == 1,
      note: json['note'] ?? '',
    );
  }
}
