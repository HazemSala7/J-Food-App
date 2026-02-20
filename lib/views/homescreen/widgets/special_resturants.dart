import 'package:j_food_updated/server/functions/functions.dart';
import 'package:j_food_updated/views/storescreen/store_provider/store_provider.dart';
import 'package:j_food_updated/views/storescreen/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SpecialRestaurantsWidget extends StatelessWidget {
  final List<dynamic> restaurants;
  final bool noDelivery;
  final Function(int) changeTab;
  const SpecialRestaurantsWidget({
    Key? key,
    required this.restaurants,
    required this.noDelivery,
    required this.changeTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: restaurants.map((restaurant) {
          return _buildRestaurantCard(restaurant, context);
        }).toList(),
      ),
    );
  }

  Widget _buildRestaurantCard(
      Map<String, dynamic> restaurant, BuildContext context) {
    return InkWell(
      onTap: () {
        NavigatorFunction(
            context,
            ChangeNotifierProvider(
              create: (_) => StoreProvider()
                ..fetchStoreDetails(restaurant['id'].toString()),
              child: StoreScreen(
                open: restaurant['is_open'],
                store_cover_image: restaurant['cover_image'].toString(),
                store_address: restaurant['address'].toString(),
                store_id: restaurant['id'].toString(),
                category_id: restaurant['category_id'].toString(),
                category_name: "",
                store_image: restaurant['image'].toString(),
                store_name: restaurant['name'].toString(),
                noDelivery: noDelivery,
                changeTab: changeTab,
              ),
            ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Card(
          elevation: 5,
          child: Container(
            width: 200,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 3,
                ),
                // Image Section
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    restaurant['image'], // Image URL from API
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 3.0),
                        child: Text(
                          restaurant['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff5A5A5A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              restaurant['address'],
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
