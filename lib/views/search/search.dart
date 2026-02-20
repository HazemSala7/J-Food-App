// import 'dart:async';
// import 'dart:convert';
// import 'package:j_food_updated/constants/constants.dart';
// import 'package:j_food_updated/views/homescreen/widgets/shops.dart';
// import 'package:j_food_updated/views/storescreen/widgets/bottomsheet.dart';
// import 'package:j_food_updated/views/storescreen/widgets/items.dart';
// import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
// import 'package:flutter/material.dart';
// import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
// import 'package:http/http.dart' as http;

// class CustomSearch extends SearchDelegate {
//   List<dynamic> allProducts = [];
//   List<dynamic> allRestaurants = [];

//   @override
//   List<Widget>? buildActions(BuildContext context) {
//     return [
//       IconButton(
//         onPressed: () {
//           query = "";
//           showSuggestions(context);
//         },
//         icon: const Icon(Icons.close),
//       )
//     ];
//   }

//   @override
//   Widget? buildLeading(BuildContext context) {
//     return IconButton(
//       onPressed: () {
//         close(context, null);
//       },
//       icon: const Icon(Icons.arrow_back_ios),
//     );
//   }

//   @override
//   Widget buildResults(BuildContext context) {
//     if (query.isEmpty) {
//       return Center(
//         child: Text(
//           "البحث عن مطعم معين او وجبة معينة",
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//       );
//     }

//     return FutureBuilder(
//       future: fetchProducts(query),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                     width: MediaQuery.of(context).size.width * 0.8,
//                     child: Center(child: Text("Error"))),
//                 SizedBox(height: 10),
//                 IconButton(
//                     onPressed: () {
//                       fetchProducts(query);
//                     },
//                     icon: Icon(Icons.refresh))
//               ],
//             ),
//           );
//         } else {
//           return buildProductAndRestaurantGrid();
//         }
//       },
//     );
//   }

//   @override
//   Widget buildSuggestions(BuildContext context) {
//     if (query.isEmpty) {
//       return Center(
//         child: Text(
//           "البحث عن مطعم معين او وجبة معينة",
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//       );
//     }

//     return FutureBuilder(
//       future: fetchProducts(query),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                     width: MediaQuery.of(context).size.width * 0.8,
//                     child: Center(child: Text("Error"))),
//                 SizedBox(height: 10),
//                 IconButton(
//                     onPressed: () {
//                       fetchProducts(query);
//                     },
//                     icon: Icon(Icons.refresh))
//               ],
//             ),
//           );
//         } else {
//           return buildProductAndRestaurantGrid();
//         }
//       },
//     );
//   }

//   Widget buildProductAndRestaurantGrid() {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           if (allRestaurants.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'مطاعم:',
//                     style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 10),
//                   SizedBox(
//                     height: 200,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: allRestaurants.length,
//                       itemBuilder: (context, index) {
//                         final restaurant = allRestaurants[index];
//                         return ShopsWidgets(
//                           categoryName: restaurant['category_name'],
//                           storesArray: [restaurant],
//                           ,
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 15),
//             child: Divider(
//               thickness: 3,
//             ),
//           ),
//           if (allProducts.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'وجبات:',
//                     style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 10),
//                   SizedBox(
//                     height: 200,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: allProducts.length,
//                       itemBuilder: (context, index) {
//                         final product = allProducts[index];
//                         return Padding(
//                           padding: const EdgeInsets.only(left: 10),
//                           child: InkWell(
//                             onTap: () {
//                               if (product['store']['is_open']) {
//                                 showDialog(
//                                   context: context,
//                                   builder: (BuildContext context) {
//                                     return AlertDialog(
//                                       insetPadding: EdgeInsets.zero,
//                                       contentPadding: EdgeInsets.all(2),
//                                       clipBehavior: Clip.antiAliasWithSaveLayer,
//                                       backgroundColor: Colors.transparent,
//                                       content: BottomSheetWidget(
//                                         data: [product],
//                                         storeDeliveryPrice: product['store']
//                                             ['delivery_price'],
//                                         storeName: product['store']['name'],
//                                         storeId:
//                                             product['store']['id'].toString(),
//                                         index: index,
//                                         fromSearch: true,
//                                         addToCartClick: (p0) {},
//                                         widgetKey: GlobalKey(),
//                                       ),
//                                     );
//                                   },
//                                 );
//                               } else {
//                                 Fluttertoast.showToast(
//                                     msg: "لا يمكنك الطلب الان ،المحل مغلق");
//                               }
//                             },
//                             child: Container(
//                               width: MediaQuery.of(context).size.width / 3.3,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10),
//                                 color: Colors.white,
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.grey.withOpacity(0.2),
//                                     spreadRadius: 5,
//                                     blurRadius: 7,
//                                     offset: Offset(0, 1),
//                                   ),
//                                 ],
//                               ),
//                               child: Column(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   ClipRRect(
//                                     borderRadius: const BorderRadius.only(
//                                       topLeft: Radius.circular(10),
//                                       topRight: Radius.circular(10),
//                                     ),
//                                     child: product['images'].isNotEmpty
//                                         ? FancyShimmerImage(
//                                             imageUrl: product['images'][0]
//                                                 ['url'],
//                                             boxFit: BoxFit.cover,
//                                             width: double.infinity,
//                                             height: 120,
//                                           )
//                                         : Container(
//                                             width: 120,
//                                             height: 120,
//                                             color: Colors.grey,
//                                             child: Center(
//                                               child: Text(
//                                                 'No Image Available',
//                                                 style: TextStyle(
//                                                     color: Colors.white),
//                                               ),
//                                             ),
//                                           ),
//                                   ),
//                                   SizedBox(
//                                     height: 35,
//                                     child: Padding(
//                                       padding: const EdgeInsets.only(
//                                           left: 8.0, right: 8),
//                                       child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Flexible(
//                                             child: Text(
//                                               product['name'],
//                                               maxLines: 3,
//                                               textAlign: TextAlign.center,
//                                               overflow: TextOverflow.ellipsis,
//                                               style: const TextStyle(
//                                                   fontSize: 13,
//                                                   fontWeight: FontWeight.w800),
//                                             ),
//                                           ),
//                                           Text(
//                                             "₪${product['price']}",
//                                             style: const TextStyle(
//                                                 fontSize: 15,
//                                                 fontWeight: FontWeight.w800),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                   InkWell(
//                                     onTap: () {
//                                       if (product['store']['is_open']) {
//                                         showDialog(
//                                           context: context,
//                                           builder: (BuildContext context) {
//                                             return AlertDialog(
//                                               insetPadding: EdgeInsets.zero,
//                                               contentPadding: EdgeInsets.all(2),
//                                               clipBehavior:
//                                                   Clip.antiAliasWithSaveLayer,
//                                               backgroundColor:
//                                                   Colors.transparent,
//                                               content: BottomSheetWidget(
//                                                 data: [product],
//                                                 storeDeliveryPrice:
//                                                     product['store']
//                                                         ['delivery_price'],
//                                                 storeName: product['store']
//                                                     ['name'],
//                                                 storeId: product['store']['id']
//                                                     .toString(),
//                                                 index: index,
//                                                 fromSearch: true,
//                                                 addToCartClick: (p0) {},
//                                                 widgetKey: GlobalKey(),
//                                               ),
//                                             );
//                                           },
//                                         );
//                                       } else {
//                                         Fluttertoast.showToast(
//                                             msg:
//                                                 "لا يمكنك الطلب الان ،المحل مغلق");
//                                       }
//                                     },
//                                     child: Container(
//                                       width: double.infinity,
//                                       height: 30,
//                                       alignment: Alignment.center,
//                                       decoration: BoxDecoration(
//                                           borderRadius: BorderRadius.only(
//                                             bottomLeft: Radius.circular(10),
//                                             bottomRight: Radius.circular(10),
//                                           ),
//                                           color: mainColor),
//                                       child: const Text(
//                                         'اضف الى السلة',
//                                         style: TextStyle(
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.bold),
//                                       ),
//                                     ),
//                                   )
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Future<void> fetchProducts(String query) async {
//     var response = await http
//         .get(Uri.parse('https://hrsps.com/login/api/search_general/$query'));
//     if (response.statusCode == 200) {
//       var data = jsonDecode(response.body);

//       // Ensure products and restaurants are lists
//       if (data['products'] is Map) {
//         allProducts = (data['products'] as Map).values.toList();
//       } else if (data['products'] is List) {
//         allProducts = data['products'];
//       } else {
//         allProducts = [];
//       }

//       if (data['restaurants'] is Map) {
//         allRestaurants = (data['restaurants'] as Map).values.toList();
//       } else if (data['restaurants'] is List) {
//         allRestaurants = data['restaurants'];
//       } else {
//         allRestaurants = [];
//       }
//     } else {
//       print('Failed to load products and restaurants');
//       allProducts = [];
//       allRestaurants = [];
//     }
//   }
// }
