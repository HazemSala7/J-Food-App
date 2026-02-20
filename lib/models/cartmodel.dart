class CartModel {
  final String? id;
  final String? storeId;
  final String? title;
  final String? imageurl;
  String? price;
  String? count;

  CartModel({
    required this.id,
    required this.storeId,
    required this.title,
    required this.imageurl,
    required this.price,
    required this.count,
  });
}
