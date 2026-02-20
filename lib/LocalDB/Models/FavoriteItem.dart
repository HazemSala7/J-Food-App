class FavoriteItem {
  final int? id;
  final int storeId; // Unique identifier for the product
  final int categoryID;
  final String storeName;
  final String categoryName;
  final String storeImage;
  final String openTime;
  final String closeTime;
  final String storeLocation;
  final String workingHours; // JSON string of j.food.com.jfood array
  final bool isOpen; // Current is_open status

  FavoriteItem({
    this.id,
    required this.storeId,
    required this.categoryID,
    required this.storeName,
    required this.categoryName,
    required this.storeImage,
    required this.openTime,
    required this.closeTime,
    required this.storeLocation,
    this.workingHours = '[]',
    this.isOpen = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'categoryID': categoryID,
      'storeName': storeName,
      'categoryName': categoryName,
      'storeImage': storeImage,
      'openTime': openTime,
      'closeTime': closeTime,
      'storeLocation': storeLocation,
      'workingHours': workingHours,
      'isOpen': isOpen ? 1 : 0,
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'],
      storeId: json['storeId'],
      categoryID: json['categoryID'],
      storeName: json['storeName'],
      categoryName: json['categoryName'],
      storeImage: json['storeImage'],
      openTime: json['openTime'] ?? '',
      closeTime: json['closeTime'] ?? '',
      storeLocation: json['storeLocation'],
      workingHours: json['workingHours'] ?? '[]',
      isOpen: json['isOpen'] == 1,
    );
  }

  FavoriteItem copyWith({
    int? id,
    int? storeId,
    int? categoryID,
    String? storeName,
    String? categoryName,
    String? storeImage,
    String? openTime,
    String? closeTime,
    String? storeLocation,
    String? workingHours,
    bool? isOpen,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      categoryID: categoryID ?? this.categoryID,
      storeName: storeName ?? this.storeName,
      categoryName: categoryName ?? this.categoryName,
      storeImage: storeImage ?? this.storeImage,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      storeLocation: storeLocation ?? this.storeLocation,
      workingHours: workingHours ?? this.workingHours,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
