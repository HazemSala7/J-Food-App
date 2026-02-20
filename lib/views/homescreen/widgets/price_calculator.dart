class PriceCalculator {
  static double applyDiscount(double price, String discount) {
    if (discount == "0") return price;
    return price - (price * (double.parse(discount) / 100));
  }

  static double calculateBasePrice({
    required Map product,
    required int? sizeIndex,
  }) {
    final discount = product['discount_percentage']?.toString() ?? "0";

    if (product['product_sizes'].isEmpty) {
      return applyDiscount(
        double.parse(product['price'].toString()),
        discount,
      );
    }

    if (sizeIndex == null || sizeIndex == -1) return 0;

    final sizePrice = double.parse(
      product['product_sizes'][sizeIndex]['size_price_nis'],
    );

    return applyDiscount(sizePrice, discount);
  }

  static double calculateExtrasTotal(
    List<String> prices,
    List<String> quantities,
  ) {
    double total = 0;
    for (int i = 0; i < prices.length; i++) {
      total += double.parse(prices[i]) * double.parse(quantities[i]);
    }
    return total;
  }
}
