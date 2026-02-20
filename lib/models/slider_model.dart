class SliderClass {
  final int id;
  final String url;
  final String type;
  final String? link;
  final int dataId;
  final RestaurantData? data;

  SliderClass({
    required this.id,
    required this.url,
    required this.type,
    required this.link,
    required this.dataId,
    this.data,
  });

  factory SliderClass.fromJson(Map<String, dynamic> json) {
    return SliderClass(
      id: json['id'],
      url: json['url'],
      type: json['type'],
      link: json['link'] ?? "",
      dataId: json['data_id'],
      data:
          (json['data'] != null) ? RestaurantData.fromJson(json['data']) : null,
    );
  }
}

class RestaurantData {
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
  final bool special;

  RestaurantData({
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

  factory RestaurantData.fromJson(Map<String, dynamic> json) {
    return RestaurantData(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      coverImage: json['cover_image'],
      latitude: (json['lattitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      phoneNumber: json['phone_number'],
      openTime: json['open_time'],
      closeTime: json['close_time'],
      deliveryPrice: json['delivery_price'],
      deliveryTime: json['delivery_time'],
      categoryId: json['category_id'] ?? "",
      active: json['active'] == "true",
      special: json['special'] == "true",
    );
  }
}
