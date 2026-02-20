// import 'package:j_food_updated/constants/constants.dart';
// import 'package:flutter/material.dart';
// import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
// import 'package:provider/provider.dart';
// import '../../../LocalDB/Models/CartItem.dart';
// import '../../../LocalDB/Provider/CartProvider.dart';

// class BottomSheetWidget extends StatefulWidget {
//   final String storeId;
//   final dynamic data;
//   final int index;
//   final String storeName;
//   final String storeDeliveryPrice;
//   final bool fromSearch;
//   final void Function(GlobalKey) addToCartClick;
//   final GlobalKey widgetKey;
//   BottomSheetWidget({
//     Key? key,
//     required this.storeId,
//     required this.index,
//     required this.data,
//     required this.storeName,
//     required this.storeDeliveryPrice,
//     required this.fromSearch,
//     required this.addToCartClick,
//     required this.widgetKey,
//   }) : super(key: key);

//   @override
//   State<BottomSheetWidget> createState() => _BottomSheetWidgetState();
// }

// class _BottomSheetWidgetState extends State<BottomSheetWidget> {
//   int qty = 1;
//   final GlobalKey itemKey = GlobalKey();
//   Map<int, List<bool>> componentCheckboxValues = {};
//   Map<int, List<bool>> drinkCheckboxValues = {};
//   Map<int, Map<int, int>> componentQty = {};
//   Map<int, Map<int, int>> drinkQty = {};
//   double total = 0.0;
//   bool pressedNext = false;
//   late bool noDrinks;
//   bool chooseQty = true;
//   List<Map<String, dynamic>> selections = [];
//   int currentStep = 0;
//   bool addToCart = false;
//   bool finishCom = false;
//   bool showComponents = true;

//   @override
//   void initState() {
//     super.initState();
//     final productData = widget.data[widget.fromSearch ? 0 : widget.index];
//     total = double.tryParse(productData['price'].toString()) ?? 0.0;
//     noDrinks = productData['product_drinks']?.isEmpty ?? true;
//   }

//   void _updateTotalPrice() {
//     // Get the base price from the data
//     double basePrice = double.parse(
//         widget.data[widget.fromSearch ? 0 : widget.index]['price']);
//     double extraPrice = 0.0;

//     // Iterate over each order in componentCheckboxValues
//     componentCheckboxValues.forEach((orderId, checkboxList) {
//       var quantityMap = componentQty[orderId] ?? {};

//       for (var index = 0; index < checkboxList.length; index++) {
//         if (checkboxList[index]) {
//           if (index <
//               widget
//                   .data[widget.fromSearch ? 0 : widget.index]
//                       ['product_components']
//                   .length) {
//             double componentPrice = double.parse(
//                 widget.data[widget.fromSearch ? 0 : widget.index]
//                     ['product_components'][index]['com_price']);
//             int quantity = quantityMap[index] ?? 1; // Get quantity from the map
//             extraPrice += componentPrice * quantity;
//           } else {
//             print('Invalid index for product_components: $index');
//           }
//         }
//       }
//     });

//     // Iterate over each order in drinkCheckboxValues
//     drinkCheckboxValues.forEach((orderId, checkboxList) {
//       var quantityMap = drinkQty[orderId] ?? {};

//       for (var index = 0; index < checkboxList.length; index++) {
//         if (checkboxList[index]) {
//           if (index <
//               widget
//                   .data[widget.fromSearch ? 0 : widget.index]['product_drinks']
//                   .length) {
//             double drinkPrice = double.parse(
//                 widget.data[widget.fromSearch ? 0 : widget.index]
//                     ['product_drinks'][index]['drink_price']);
//             int quantity = quantityMap[index] ?? 1; // Get quantity from the map
//             extraPrice += drinkPrice * quantity;
//           } else {
//             print('Invalid index for product_drinks: $index');
//           }
//         }
//       }
//     });

//     // Update the total price for the current order
//     setState(() {
//       total = (basePrice * qty) + extraPrice;
//     });
//   }

//   void _addToCart(CartProvider cartProvider) async {
//     final productData = widget.data[widget.fromSearch ? 0 : widget.index];

//     bool hasSelectedComponentsOrDrinks =
//         componentCheckboxValues.values.any((list) => list.contains(true)) ||
//             drinkCheckboxValues.values.any((list) => list.contains(true));

//     if (!hasSelectedComponentsOrDrinks) {
//       List<String> allComponentsNames = [];
//       List<String> allComponentsPrices = [];
//       List<String> allDrinksNames = [];
//       List<String> allDrinksPrices = [];
//       componentCheckboxValues.forEach((orderId, checkboxList) {
//         for (var index = 0; index < checkboxList.length; index++) {
//           allComponentsNames
//               .add(productData["product_components"][index]["com_name"] ?? '');
//           allComponentsPrices.add(productData["product_components"][index]
//                       ["com_price"]
//                   ?.toString() ??
//               '0');
//         }
//         if (drinkCheckboxValues.containsKey(orderId)) {
//           for (var index = 0;
//               index < drinkCheckboxValues[orderId]!.length;
//               index++) {
//             allDrinksNames
//                 .add(productData["product_drinks"][index]["drink_name"] ?? '');
//             allDrinksPrices.add(productData["product_drinks"][index]
//                         ["drink_price"]
//                     ?.toString() ??
//                 '0');
//           }
//         }
//       });
//       // If there are no selected components or drinks, add the base product only
//       final basePrice =
//           double.parse(productData['price']?.toString() ?? '0') * qty;
//       final newItem = CartItem(
//         storeDeliveryPrice: widget.storeDeliveryPrice.toString(),
//         storeID: widget.storeId.toString(),
//         storeName: widget.storeName.toString(),
//         total: basePrice.toString(),
//         price: basePrice.toString(),
//          storeOpenTime: widget. ,
//             storeCloseTime: restaurant['close_time'] ?? '',
//         storeImage: "",
//         storeLocation: "",
//         components_names: allComponentsNames,
//         components_prices: allComponentsPrices,
//         selected_components_names: [],
//         selected_components_prices: [],
//         drinks_names: allDrinksNames,
//         drinks_prices: allDrinksPrices,
//         components_images: [],
//         drinks_images: [],
//         selected_components_images: [],
//         selected_drinks_images: [],
//         selected_drinks_names: [],
//         selected_drinks_prices: [],
//         name: productData["name"] ?? 'Unnamed Product',
//         productId: productData["id"] ?? 0,
//         image: productData['images'].isNotEmpty
//             ? productData['images'][0]['url'] ??
//                 'https://example.com/default-image.jpg'
//             : 'https://example.com/default-image.jpg',
//         quantity: qty,
//         selected_drinks_id: [],
//         selected_components_id: [],
//         selected_drinks_qty: [],
//         selected_components_qty: [],
//       );
//       cartProvider.addToCart(newItem);
//     } else {
//       // Iterate over each unique orderId in componentCheckboxValues as usual
//       componentCheckboxValues.forEach((orderId, checkboxList) {
//         List<String> allComponentsNames = [];
//         List<String> allComponentsPrices = [];
//         List<String> selectedComponentsNames = [];
//         List<String> selectedComponentsId = [];
//         List<String> selectedComponentsQty = [];
//         List<String> allDrinksNames = [];
//         List<String> allDrinksPrices = [];
//         List<String> selectedDrinksNames = [];
//         List<String> selectedDrinksId = [];
//         List<String> selectedDrinksQty = [];

//         // Define selected components and drinks prices here
//         List<String> selectedComponentsPrices = [];
//         List<String> selectedDrinksPrices = [];

//         var componentQuantityMap = componentQty[orderId] ?? {};
//         var drinkQuantityMap = drinkQty[orderId] ?? {};

//         double orderTotal =
//             double.parse(productData['price']?.toString() ?? '0');

//         // Process components
//         for (var index = 0; index < checkboxList.length; index++) {
//           allComponentsNames
//               .add(productData["product_components"][index]["com_name"] ?? '');
//           allComponentsPrices.add(productData["product_components"][index]
//                       ["com_price"]
//                   ?.toString() ??
//               '0');
//           if (checkboxList[index]) {
//             selectedComponentsNames.add(
//                 productData["product_components"][index]["com_name"] ?? '');
//             selectedComponentsPrices.add(productData["product_components"]
//                         [index]["com_price"]
//                     ?.toString() ??
//                 '0');
//             selectedComponentsId.add(
//                 productData["product_components"][index]["id"]?.toString() ??
//                     '0');

//             int quantity = componentQuantityMap[index] ?? 1;
//             selectedComponentsQty.add(quantity.toString());

//             double componentPrice = double.parse(selectedComponentsPrices.last);
//             orderTotal += componentPrice * quantity;
//           }
//         }

//         // Process drinks if available
//         if (drinkCheckboxValues.containsKey(orderId)) {
//           for (var index = 0;
//               index < drinkCheckboxValues[orderId]!.length;
//               index++) {
//             allDrinksNames
//                 .add(productData["product_drinks"][index]["drink_name"] ?? '');
//             allDrinksPrices.add(productData["product_drinks"][index]
//                         ["drink_price"]
//                     ?.toString() ??
//                 '0');

//             if (drinkCheckboxValues[orderId]![index]) {
//               selectedDrinksNames.add(
//                   productData["product_drinks"][index]["drink_name"] ?? '');
//               selectedDrinksPrices.add(productData["product_drinks"][index]
//                           ["drink_price"]
//                       ?.toString() ??
//                   '0');
//               selectedDrinksId.add(
//                   productData["product_drinks"][index]["id"]?.toString() ??
//                       '0');

//               int quantity = drinkQuantityMap[index] ?? 1;
//               selectedDrinksQty.add(quantity.toString());

//               double drinkPrice = double.parse(selectedDrinksPrices.last);
//               orderTotal += drinkPrice * quantity;
//             }
//           }
//         }
//         print(allComponentsNames);
//         print(allComponentsPrices);

//         // Finalize the cart item
//         final newItem = CartItem(
//           storeDeliveryPrice: widget.storeDeliveryPrice.toString(),
//           storeID: widget.storeId.toString(),
//           storeName: widget.storeName.toString(),
//           total: orderTotal.toString(),
//           storeImage: "",
//           storeLocation: "",
//           price: productData['price']?.toString() ?? '0',
//           components_names: allComponentsNames,
//           components_prices: allComponentsPrices,
//           selected_components_names: selectedComponentsNames,
//           selected_components_prices: selectedComponentsPrices,
//           drinks_names: allDrinksNames,
//           drinks_prices: allDrinksPrices,
//           components_images: [],
//           drinks_images: [],
//           selected_components_images: [],
//           selected_drinks_images: [],
//           selected_drinks_names: selectedDrinksNames,
//           selected_drinks_prices: selectedDrinksPrices,
//           name: productData["name"] ?? 'Unnamed Product',
//           productId: productData["id"] ?? 0,
//           image: productData['images'].isNotEmpty
//               ? productData['images'][0]['url'] ??
//                   'https://example.com/default-image.jpg'
//               : 'https://example.com/default-image.jpg',
//           quantity: 1,
//           selected_drinks_id: selectedDrinksId,
//           selected_components_id: selectedComponentsId,
//           selected_drinks_qty: selectedDrinksQty,
//           selected_components_qty: selectedComponentsQty,
//         );

//         cartProvider.addToCart(newItem);
//       });
//     }

//     Navigator.pop(context);
//     Fluttertoast.showToast(
//         msg: "تم الاضافة بنجاح", backgroundColor: Colors.green);
//     await Future.delayed(const Duration(milliseconds: 500));
//     widget.addToCartClick(widget.widgetKey);
//   }

//   void initializeOrderState(int orderId, int componentCount, int drinkCount) {
//     componentCheckboxValues[orderId] =
//         List.generate(componentCount, (_) => false);
//     drinkCheckboxValues[orderId] = List.generate(drinkCount, (_) => false);
//     componentQty[orderId] = {};
//     drinkQty[orderId] = {};
//   }

//   // Widget _buildComponentsOrDrinks(int index, Map<String, dynamic> productData) {
//   //   if (!pressedNext) {
//   //     return _buildComponentsList(productData, index);
//   //   }

//   //   return _buildDrinksList(productData, index);
//   // }

//   // void _onNextStep() {
//   //   setState(() {
//   //     if (!pressedNext && currentStep < qty - 1) {
//   //       currentStep++;
//   //       noDrinks && currentStep == qty - 1 ? addToCart = true : null;
//   //     } else if (!pressedNext && currentStep == qty - 1) {
//   //       pressedNext = true;
//   //       noDrinks ? addToCart = true : null;
//   //       currentStep = 0;
//   //     } else if (pressedNext && currentStep < qty - 1) {
//   //       currentStep++;
//   //       addToCart = true;
//   //     }
//   //   });
//   // }

//   Widget _buildComponentsOrDrinks(int index, Map<String, dynamic> productData) {
//     // Handle case where there are no drinks
//     if (noDrinks) {
//       return _buildComponentsList(productData, index);
//     }

//     // Alternate between showing components and drinks based on the step
//     bool isComponentsStep = index % 2 == 0;

//     if (isComponentsStep) {
//       return _buildComponentsList(
//           productData, index ~/ 2); // Divide index by 2 for components
//     } else {
//       return _buildDrinksList(
//           productData, index ~/ 2); // Divide index by 2 for drinks
//     }
//   }

//   void _onNextStep() {
//     setState(() {
//       // If qty is 1, directly set addToCart to true
//       if (qty == 1 && noDrinks) {
//         addToCart = true;
//         return;
//       }

//       // Increment step normally if qty > 1
//       if (currentStep < (qty * (noDrinks ? 1 : 2)) - 1) {
//         currentStep++;

//         // If we've reached the last step for components (or pair if drinks exist), set addToCart to true
//         if (currentStep == (qty * (noDrinks ? 1 : 2)) - 1) {
//           addToCart = true;
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cartProvider = Provider.of<CartProvider>(context);
//     final productData = widget.fromSearch
//         ? widget.data[0]
//         : widget.index >= 0 && widget.index < widget.data.length
//             ? widget.data[widget.index]
//             : null;

//     if (productData == null) {
//       return Center(child: Text("Invalid product data"));
//     }

//     return Container(
//       width: MediaQuery.of(context).size.width,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 25),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Stack(
//                 alignment: Alignment.topLeft,
//                 children: [
//                   Container(
//                     height: 200,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       image: DecorationImage(
//                         image: NetworkImage(productData['images'].isNotEmpty
//                             ? productData['images'][0]['url']
//                             : 'https://xn--kayaehir-qwb.com/wp-content/uploads/2024/02/Feasibility-study-of-the-Broast-restaurant-project.jpg'),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                   CircleAvatar(
//                     backgroundColor: mainColor,
//                     child: IconButton(
//                       onPressed: () {
//                         setState(() {
//                           pressedNext = false;
//                         });
//                         Navigator.pop(context);
//                       },
//                       icon: const Icon(
//                         Icons.close,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 50),
//               Container(
//                 decoration: BoxDecoration(
//                   color: mainColor,
//                   border: Border.all(color: mainColor),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 padding: const EdgeInsets.all(8),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildProductInfoRow(productData),
//                       SizedBox(
//                         height: 10,
//                       ),
//                       _buildProductDescription(productData),
//                       SizedBox(
//                         height: 10,
//                       ),
//                       if (chooseQty)
//                         Row(
//                           children: [
//                             Text(
//                               "اختر الكمية",
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                             SizedBox(
//                               width: 10,
//                             ),
//                             Card(
//                               color: Colors.white,
//                               child: SizedBox(
//                                 height: 35,
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.remove,
//                                           color: Colors.black, size: 20),
//                                       onPressed: () {
//                                         if (qty > 1) {
//                                           setState(() {
//                                             qty--;
//                                             _updateTotalPrice();
//                                             selections.removeLast();
//                                           });
//                                         }
//                                       },
//                                     ),
//                                     Text(
//                                       qty.toString(),
//                                       style:
//                                           const TextStyle(color: Colors.black),
//                                     ),
//                                     IconButton(
//                                       icon: const Icon(
//                                         Icons.add,
//                                         color: Colors.black,
//                                         size: 20,
//                                       ),
//                                       onPressed: () {
//                                         setState(() {
//                                           qty++;
//                                           _updateTotalPrice();
//                                           selections.add({});
//                                         });
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       _buildPriceInfo(productData),
//                       if (!chooseQty)
//                         Visibility(
//                           visible: productData["product_components"].isNotEmpty,
//                           child: Column(
//                             children: [
//                               SizedBox(
//                                 height: 5,
//                               ),
//                               Container(
//                                 decoration: BoxDecoration(
//                                     border: Border.all(color: Colors.white)),
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(8.0),
//                                   child: Text(
//                                     noDrinks
//                                         ? "مكونات الطلب: ${currentStep + 1}"
//                                         : (currentStep % 2 == 0
//                                             ? "مكونات الطلب: ${(currentStep ~/ 2) + 1}"
//                                             : "مشروبات الطلب: ${(currentStep ~/ 2) + 1}"),
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 17,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(
//                                 height: 10,
//                               ),
//                               Container(
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: _buildComponentsOrDrinks(
//                                     currentStep, productData),
//                               ),
//                             ],
//                           ),
//                         ),
//                       SizedBox(
//                         height: 10,
//                       ),
//                       Center(
//                         child: ElevatedButton(
//                           style: ButtonStyle(
//                             backgroundColor:
//                                 MaterialStateProperty.all(Colors.white),
//                             textStyle: MaterialStateProperty.all(
//                                 const TextStyle(fontSize: 20)),
//                           ),
//                           onPressed: () {
//                             if (chooseQty) {
//                               setState(() {
//                                 chooseQty = !chooseQty;
//                               });
//                             }
//                             // else {
//                             //   if ((pressedNext && noDrinks) ||
//                             //       addToCart ||
//                             //       (pressedNext && currentStep == qty - 1) ||
//                             //       (qty == 1 && !chooseQty && noDrinks) ||
//                             //       productData["product_components"].isEmpty) {
//                             //     _addToCart(cartProvider);
//                             //   } else {
//                             //     print((pressedNext));
//                             //     print((noDrinks));
//                             //     print((currentStep == qty - 1));
//                             //     _onNextStep();
//                             //   }
//                             // }
//                             else {
//                               if (addToCart ||
//                                   (pressedNext && noDrinks) ||
//                                   (pressedNext && currentStep == qty - 1) ||
//                                   (qty == 1 && !chooseQty && noDrinks)) {
//                                 _addToCart(cartProvider);
//                               } else {
//                                 _onNextStep();
//                               }
//                             }
//                           },
//                           child: Text(
//                             // productData["product_components"].isEmpty &&
//                             //         !chooseQty
//                             //     ? 'اضف الى السلة'
//                             //     : addToCart
//                             //         ? 'اضف الى السلة'
//                             //         : qty == 1 && !chooseQty && noDrinks
//                             //             ? 'اضف الى السلة'
//                             //             : (pressedNext &&
//                             //                     currentStep == qty - 1)
//                             //                 ? 'اضف الى السلة'
//                             //                 : "التالي",
//                             addToCart
//                                 ? 'اضف الى السلة'
//                                 : qty == 1 && noDrinks && !chooseQty
//                                     ? 'اضف الى السلة'
//                                     : 'التالي',
//                             style: const TextStyle(color: Colors.black),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Row _buildProductInfoRow(dynamic productData) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Expanded(
//           child: Text(
//             productData['name'].toString().length > 25
//                 ? productData['name'].toString().substring(0, 25)
//                 : productData['name'].toString(),
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildProductDescription(dynamic productData) {
//     return Text(
//       productData['description'] ?? '',
//       style: const TextStyle(
//         color: Colors.white,
//         fontSize: 12,
//         fontWeight: FontWeight.bold,
//       ),
//       textAlign: TextAlign.center,
//     );
//   }

//   Widget _buildPriceInfo(dynamic productData) {
//     return Column(
//       children: [
//         const SizedBox(height: 4),
//         Text(
//           'سعر الوجبة :  ${productData['price']}₪',
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'الاجمالي : $total₪',
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 4),
//       ],
//     );
//   }

//   Widget _buildComponentsList(dynamic productData, int orderId) {
//     return ListView.builder(
//       itemCount: productData["product_components"]?.length ?? 0,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemBuilder: (BuildContext context, int index) {
//         var component = productData["product_components"][index];
//         if (component == null) return SizedBox.shrink();

//         // Initialize state for the first time for each order
//         if (!componentCheckboxValues.containsKey(orderId)) {
//           initializeOrderState(
//               orderId,
//               productData["product_components"].length,
//               productData["product_drinks"].length);
//         }

//         return Visibility(
//           visible: component != null,
//           child: Padding(
//             padding: const EdgeInsets.all(3.0),
//             child: GestureDetector(
//               onTap: () {
//                 setState(() {
//                   componentCheckboxValues[orderId]![index] =
//                       !componentCheckboxValues[orderId]![index];
//                   _updateTotalPrice();
//                 });
//               },
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(component["com_name"]?.toString() ??
//                           "Unknown Component"),
//                       Row(
//                         children: [
//                           Text("₪${component["com_price"]?.toString() ?? "0"}"),
//                           Checkbox(
//                             value: componentCheckboxValues[orderId]![index],
//                             onChanged: (value) {
//                               setState(() {
//                                 componentCheckboxValues[orderId]![index] =
//                                     value!;
//                                 _updateTotalPrice();
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   if (componentCheckboxValues[orderId]![index])
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text("الكمية", style: TextStyle(color: mainColor)),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             IconButton(
//                               icon: Icon(Icons.remove, color: mainColor),
//                               onPressed: () {
//                                 setState(() {
//                                   componentQty[orderId]![index] =
//                                       (componentQty[orderId]![index] ?? 1) - 1;
//                                   if (componentQty[orderId]![index]! < 1) {
//                                     componentQty[orderId]![index] = 1;
//                                   }
//                                   _updateTotalPrice();
//                                 });
//                               },
//                             ),
//                             Text(
//                               componentQty[orderId]![index]?.toString() ?? "1",
//                               style: TextStyle(color: mainColor),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.add, color: mainColor),
//                               onPressed: () {
//                                 setState(() {
//                                   componentQty[orderId]![index] =
//                                       (componentQty[orderId]![index] ?? 1) + 1;
//                                   _updateTotalPrice();
//                                 });
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDrinksList(dynamic productData, int orderId) {
//     return ListView.builder(
//       itemCount: productData["product_drinks"]?.length ?? 0,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemBuilder: (BuildContext context, int index) {
//         var drink = productData["product_drinks"][index];
//         if (drink == null) return SizedBox.shrink();

//         // Initialize state for the first time for each order
//         if (!drinkCheckboxValues.containsKey(orderId)) {
//           initializeOrderState(
//               orderId,
//               productData["product_components"].length,
//               productData["product_drinks"].length);
//         }

//         return Visibility(
//           visible: drink != null,
//           child: Padding(
//             padding: const EdgeInsets.all(3.0),
//             child: GestureDetector(
//               onTap: () {
//                 setState(() {
//                   drinkCheckboxValues[orderId]![index] =
//                       !drinkCheckboxValues[orderId]![index];
//                   _updateTotalPrice();
//                 });
//               },
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(drink["drink_name"]?.toString() ?? "Unknown Drink"),
//                       Row(
//                         children: [
//                           Text("₪${drink["drink_price"]?.toString() ?? "0"}"),
//                           Checkbox(
//                             value: drinkCheckboxValues[orderId]![index],
//                             onChanged: (value) {
//                               setState(() {
//                                 drinkCheckboxValues[orderId]![index] = value!;
//                                 _updateTotalPrice();
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   if (drinkCheckboxValues[orderId]![index])
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text("الكمية", style: TextStyle(color: mainColor)),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             IconButton(
//                               icon: Icon(Icons.remove, color: mainColor),
//                               onPressed: () {
//                                 setState(() {
//                                   drinkQty[orderId]![index] =
//                                       (drinkQty[orderId]![index] ?? 1) - 1;
//                                   if (drinkQty[orderId]![index]! < 1) {
//                                     drinkQty[orderId]![index] = 1;
//                                   }
//                                   _updateTotalPrice();
//                                 });
//                               },
//                             ),
//                             Text(
//                               drinkQty[orderId]![index]?.toString() ?? "1",
//                               style: TextStyle(color: mainColor),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.add, color: mainColor),
//                               onPressed: () {
//                                 setState(() {
//                                   drinkQty[orderId]![index] =
//                                       (drinkQty[orderId]![index] ?? 1) + 1;
//                                   _updateTotalPrice();
//                                 });
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
