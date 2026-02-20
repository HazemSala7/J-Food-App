import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/server/functions/functions.dart';
import 'package:j_food_updated/views/storescreen/sub_category_products_screen.dart';
import 'package:flutter/material.dart';

class MarketCategories extends StatefulWidget {
  const MarketCategories(
      {super.key,
      required this.store_id,
      required this.open,
      required this.store_name,
      required this.store_address,
      required this.store_image,
      required this.store_cover_image,
      required this.category_id,
      required this.category_name,
      required this.changeTab,
      required this.noDelivery});

  final String store_id;
  final bool open;
  final String store_name;
  final String store_address;
  final String store_image;
  final String store_cover_image;
  final String category_id;
  final String category_name;
  final Function(int) changeTab;
  final bool noDelivery;

  @override
  State<MarketCategories> createState() => _MarketCategoriesState();
}

class _MarketCategoriesState extends State<MarketCategories> {
  List<dynamic> subCategories = [];
  List<dynamic> allProducts = [];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    print(widget.store_id);
    fetchStoreDetails();
  }

  Future<void> fetchStoreDetails() async {
    setState(() {
      loading = true;
    });
    try {
      final data = await getStoreDetails(widget.store_id);
      setState(() {
        subCategories = data['restaurant']['sub_categories'];
        
        // Handle both paginated and non-paginated products
        final productsData = data['products'];
        if (productsData is Map && productsData.containsKey("data")) {
          // Paginated response: {"data": [...], "meta": {...}}
          allProducts = productsData["data"] ?? [];
        } else if (productsData is List) {
          // Non-paginated response: direct list
          allProducts = productsData;
        } else {
          allProducts = [];
        }
      });
    } catch (e) {
      print("Error fetching store details: $e");
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fourthColor,
      child: SafeArea(
          child: Scaffold(
        backgroundColor: fourthColor,
        body: Padding(
          padding: const EdgeInsets.only(right: 8.0, left: 8, top: 25),
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: loading
                ? Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                        ),
                        CircularProgressIndicator(),
                      ],
                    ))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 25.0, top: 15, left: 25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "أقسام المول",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: mainColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: subCategories.length,
                          itemBuilder: (context, index) {
                            final sub = subCategories[index];
                            return InkWell(
                              onTap: () {
                                final subProducts = allProducts
                                    .where((product) =>
                                        product['sub_category_id'] == sub['id'])
                                    .toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SubCategoryProductsScreen(
                                      categoryName: sub['name'],
                                      products: subProducts,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 50,
                                margin: EdgeInsets.only(
                                    bottom: 10, left: 10, right: 10),
                                decoration: BoxDecoration(
                                    color: fourthColor,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                            "assets/images/logo2.png")),
                                    Text(
                                      sub['name'],
                                      style: TextStyle(
                                          color: textColor2,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                            "assets/images/logo2.png"))
                                  ],
                                ),
                              ),
                            );
                            // ListTile(
                            //   title: Text(sub['name']),
                            //   trailing: Icon(Icons.arrow_forward_ios),
                            //   onTap: () {
                            //     final subProducts = allProducts
                            //         .where((product) =>
                            //             product['sub_category_id'] == sub['id'])
                            //         .toList();

                            //     Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (context) =>
                            //             SubCategoryProductsScreen(
                            //           categoryName: sub['name'],
                            //           products: subProducts,
                            //         ),
                            //       ),
                            //     );
                            //   },
                            // );
                          },
                        )
                      ],
                    ),
                  ),
          ),
        ),
      )),
    );
  }
}
