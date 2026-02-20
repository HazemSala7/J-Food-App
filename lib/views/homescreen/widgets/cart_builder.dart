import 'package:j_food_updated/LocalDB/Models/CartItem.dart';

class CartBuilder {
  static CartItem build({
    required Map product,
    required double basePrice,
    required double totalPrice,
    required List<String> componentsNames,
    required List<String> componentsPrices,
    required List<String> drinksNames,
    required List<String> drinksPrices,
    required String? size,
    required String? sizeId,
  }) {
    return CartItem(
      storeDeliveryPrice: product['store']['delivery_price'],
      storeID: product['store']['id'].toString(),
      storeName: product['store']['name'],
      storeImage: product['store']['image'],
      storeLocation: product['store']['address'],
      storeOpenTime: product['store']['open_time'],
      storeCloseTime: product['store']['close_time'],
      total: totalPrice.toString(),
      price: basePrice.toString(),
      size: size ?? "",
      sizeId: sizeId ?? "",
      name: product['name'],
      productId: product['id'],
      image: product['images'].isNotEmpty
          ? product['images'][0]['url']
          : '',
      quantity: 1,
      components_names: componentsNames,
      components_prices: componentsPrices,
      drinks_names: drinksNames,
      drinks_prices: drinksPrices,
      selected_components_names: componentsNames,
      selected_components_prices: componentsPrices,
      selected_drinks_names: drinksNames,
      selected_drinks_prices: drinksPrices,
      selected_components_id: [],
      selected_drinks_id: [],
      selected_components_qty: [],
      selected_drinks_qty: [],
      components_images: [],
      drinks_images: [],
      selected_components_images: [],
      selected_drinks_images: [],
    );
  }
}
