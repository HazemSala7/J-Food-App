import 'package:j_food_updated/views/storescreen/store_provider/store_provider.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../server/functions/functions.dart';
import '../../storescreen/store_screen.dart';

class ShopsWidgets extends StatelessWidget {
  final bool noDelivery;
  final Function(int) changeTab;
  ShopsWidgets(
      {super.key,
      required this.storesArray,
      required this.categoryName,
      required this.noDelivery,
      required this.changeTab});

  List storesArray = [];
  String categoryName = "";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...List.generate(
              storesArray.length,
              (index) => InkWell(
                    onTap: () {
                      NavigatorFunction(
                          context,
                          ChangeNotifierProvider(
                            create: (_) => StoreProvider()
                              ..fetchStoreDetails(
                                  storesArray[index]['id'].toString()),
                            child: StoreScreen(
                              open: storesArray[index]['is_open'],
                              store_address:
                                  storesArray[index]['address'].toString(),
                              store_id: storesArray[index]['id'].toString(),
                              category_id:
                                  storesArray[index]['category_id'].toString(),
                              category_name: categoryName,
                              store_image:
                                  storesArray[index]['image'].toString(),
                              store_cover_image:
                                  storesArray[index]['cover_image'].toString(),
                              store_name: storesArray[index]['name'].toString(),
                              noDelivery: noDelivery,
                              changeTab: changeTab,
                            ),
                          ));
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3.2,
                      margin:
                          const EdgeInsets.only(top: 4, left: 20, bottom: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FancyShimmerImage(
                              imageUrl: storesArray[index]['image'],
                              boxFit: BoxFit.cover,
                              width: double.infinity,
                              height: 100,
                            ),
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Text(
                                  storesArray[index]['name'].toString().length >
                                          13
                                      ? "${storesArray[index]['name'].toString().substring(0, 13)}.."
                                      : storesArray[index]['name'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 2, left: 2),
                                child: Text(
                                  storesArray[index]['address'].length > 17
                                      ? "${storesArray[index]['address'].substring(0, 17)}.."
                                      : storesArray[index]['address'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 5),
                            child: InkWell(
                              onTap: () {
                                NavigatorFunction(
                                    context,
                                    ChangeNotifierProvider(
                                      create: (_) => StoreProvider()
                                        ..fetchStoreDetails(storesArray[index]
                                                ['id']
                                            .toString()),
                                      child: StoreScreen(
                                        store_cover_image: storesArray[index]
                                                ['cover_image']
                                            .toString(),
                                        store_address: storesArray[index]
                                                ['address']
                                            .toString(),
                                        store_id:
                                            storesArray[index]['id'].toString(),
                                        category_id: storesArray[index]
                                                ['category_id']
                                            .toString(),
                                        category_name: categoryName,
                                        open: storesArray[index]['is_open'],
                                        store_image: storesArray[index]['image']
                                            .toString(),
                                        store_name: storesArray[index]['name']
                                            .toString(),
                                        noDelivery: noDelivery,
                                        changeTab: changeTab,
                                      ),
                                    ));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25, vertical: 3),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: storesArray[index]['is_open']
                                        ? Colors.green
                                        : Colors.red),
                                child: Text(
                                  storesArray[index]['is_open']
                                      ? 'مفتوح'
                                      : "مغلق",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ))
        ],
      ),
    );
  }
}
