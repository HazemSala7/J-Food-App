import 'package:j_food_updated/server/functions/functions.dart';
import 'package:flutter/foundation.dart';

class StoreDetailsProvider with ChangeNotifier {
  bool? canMakeOrder;

  Future<void> fetchStoreDetails(String storeId) async {
    try {
      final data = await getStoreDetails(storeId);
      
      // Safely extract restaurant data
      final restaurant = data['restaurant'];
      if (restaurant != null && restaurant is Map) {
        final canOrderValue = restaurant['can_order_outside'];
        canMakeOrder = canOrderValue != "false" && canOrderValue != false;
      } else {
        canMakeOrder = true; // Default to true if data is missing
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching store details: $e");
      canMakeOrder = true; // Default to true on error
      notifyListeners();
    }
  }
}
