class CategoryItem {
  final int? id;
  final String name;
  final String image;

  CategoryItem({
    required this.id,
    required this.name,
    required this.image,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image': image};
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'],
      name: json['name'],
      image: json['image'],
    );
  }

  CategoryItem copyWith({
    int? id,
    String? name,
    String? image,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      image: image ?? this.image,
      name: name ?? this.name,
    );
  }
}
