import 'package:flutter/material.dart';

import 'section_title.dart';

class ProductsSection extends StatelessWidget {
  final List products;
  final Function buildProductTile;

  const ProductsSection({
    super.key,
    required this.products,
    required this.buildProductTile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'الوجبات:'),
          const SizedBox(height: 10),
          ListView.builder(
            itemCount: products.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final product = products[index];

              final images = product['images'] ?? [];
              final imageUrl = images.isNotEmpty ? images[0]['url'] ?? '' : '';

              final discount =
                  product['discount_percentage']?.toString() ?? "0";

              final originalPrice = product['price']?.toString() ?? "0";

              final price = discount == "0"
                  ? "₪$originalPrice"
                  : "₪${double.parse(originalPrice) - (double.parse(originalPrice) * (double.parse(discount) / 100))}";

              return buildProductTile(
                product,
                index,
                imageUrl,
                product['name'] ?? '',
                price,
                originalPrice,
                discount,
                product['description'] ?? '',
                product['product_drinks'] ?? [],
                product['product_components'] ?? [],
                product['product_sizes'] ?? [],
              );
            },
          ),
        ],
      ),
    );
  }
}
