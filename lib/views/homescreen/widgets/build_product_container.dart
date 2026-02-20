// import 'package:j_food_updated/component/check_box/check_box.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
// import 'package:j_food_updated/LocalDB/Models/CartItem.dart';
// import 'package:j_food_updated/LocalDB/Provider/CartProvider.dart';
// import 'package:j_food_updated/stubs/fluttertoast_stub.dart';

// class BuildProductContainer extends StatelessWidget {
//   final dynamic product;
//   final int index;

//   final String imgUrl;
//   final String name;
//   final String price;
//   final String originalPrice;
//   final String discount;
//   final String dis;

//   final List<dynamic> drinks;
//   final List<dynamic> components;
//   final List<dynamic> sizes;

//   // ---- STATE FROM PARENT ----
//   final List<bool> isSelected;
//   final List<int> quantities;
//   final List<bool> showComponents;
//   final List<bool> applyToAll;
//   final List<bool> applyToAllDrinks;
//   final List<double> finalPrice;

//   final List<List<List<String>>> selectedComponents;
//   final List<List<List<int>>> componentQuantities;
//   final List<List<List<String>>> selectedDrinks;
//   final List<List<List<int>>> drinkQuantities;
//   final List<List<List<String>>> selectedSizes;
//   final List<List<int>> selectedSizeIndices;

//   // ---- CALLBACKS ----
//   final VoidCallback onTileTap;
//   final VoidCallback onIncrease;
//   final VoidCallback onDecrease;
//   final VoidCallback onAddToCart;
//   final Function(int rowIndex, String sizeId, int sizeIndex) onSizeSelected;
//   final Function() onToggleApplyToAll;
//   final Function() onToggleApplyToAllDrinks;
//   final Function(int index) updateFinalPriceForIndex;

//   // Colors
//   final Color mainColor;
//   final Color fourthColor;

//   const BuildProductContainer({
//     super.key,
//     required this.product,
//     required this.index,
//     required this.imgUrl,
//     required this.name,
//     required this.price,
//     required this.originalPrice,
//     required this.discount,
//     required this.dis,
//     required this.drinks,
//     required this.components,
//     required this.sizes,
//     required this.isSelected,
//     required this.quantities,
//     required this.showComponents,
//     required this.applyToAll,
//     required this.applyToAllDrinks,
//     required this.finalPrice,
//     required this.selectedComponents,
//     required this.componentQuantities,
//     required this.selectedDrinks,
//     required this.drinkQuantities,
//     required this.selectedSizes,
//     required this.selectedSizeIndices,
//     required this.onTileTap,
//     required this.onIncrease,
//     required this.onDecrease,
//     required this.onAddToCart,
//     required this.onSizeSelected,
//     required this.onToggleApplyToAll,
//     required this.onToggleApplyToAllDrinks,
//     required this.updateFinalPriceForIndex,
//     required this.mainColor,
//     required this.fourthColor,
//   });

//   /// Helper: compute item price as string
//   String getItemPrice(Map<String, dynamic> item) {
//     if (item['com_price'] != null) return "₪${item['com_price']}";
//     if (item['drink_price'] != null) return "₪${item['drink_price']}";
//     return "₪0";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<CartProvider>(
//       builder: (context, cartProvider, child) {
//         List<CartItem> cartItems = cartProvider.cartItems;

//         return InkWell(
//           onTap: onTileTap,
//           child: Container(
//             margin: const EdgeInsets.only(bottom: 15),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.3),
//                   spreadRadius: 3,
//                   blurRadius: 5,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeader(),
//                 if (sizes.isNotEmpty)
//                   _buildIndividualSizesSection(
//                       "الحجم", sizes, selectedSizes, selectedSizeIndices),
//                 const SizedBox(height: 10),
//                 if (quantities[index] > 0) ...[
//                   _buildToggleRow(),
//                   const SizedBox(height: 10),
//                   showComponents[index]
//                       ? _buildComponentsSection()
//                       : _buildDrinksSection(),
//                   _buildAddToCartButton(context, cartProvider, cartItems),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ================== WIDGET BUILDERS ==================

//   Widget _buildHeader() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(4.0),
//           child: Stack(
//             alignment: Alignment.topCenter,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: FancyShimmerImage(
//                   imageUrl: imgUrl,
//                   boxFit: BoxFit.cover,
//                   width: 90,
//                   height: 90,
//                   errorWidget: Image.network(
//                     "https://xn--kayaehir-qwb.com/wp-content/uploads/2024/02/Feasibility-study-of-the-Broast-restaurant-project.jpg",
//                     fit: BoxFit.cover,
//                     width: 90,
//                     height: 90,
//                   ),
//                 ),
//               ),
//               if (discount != "0")
//                 Container(
//                   decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16)),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 6.0),
//                     child: Text(
//                       "${discount}%-",
//                       style: TextStyle(
//                           color: mainColor,
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 17,
//                     color: Color(0xff5E5E5E),
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   dis,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.black.withOpacity(0.7),
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     if (discount != "0")
//                       Text(
//                         originalPrice,
//                         style: const TextStyle(
//                           decoration: TextDecoration.lineThrough,
//                           color: Colors.grey,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     const SizedBox(width: 5),
//                     Text(
//                       price,
//                       style: const TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Text(
//                       "${quantities[index]}X",
//                       style: TextStyle(
//                         color: mainColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//         if (isSelected[index]) _buildCounter(),
//       ],
//     );
//   }

//   Widget _buildCounter() {
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: onIncrease,
//           child: Container(
//             height: 35,
//             width: 35,
//             decoration: BoxDecoration(color: mainColor, shape: BoxShape.circle),
//             child: const Center(
//               child: Text(
//                 '+',
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//         ),
//         GestureDetector(
//           onTap: onDecrease,
//           child: Container(
//             height: 30,
//             width: 30,
//             child: const Center(
//               child: Text(
//                 '-',
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildToggleRow() {
//     return Row(
//       children: [
//         const SizedBox(width: 10),
//         if (components.isNotEmpty)
//           GestureDetector(
//             onTap: () => showComponents[index] = true,
//             child: _buildToggleButton("المكونات", showComponents[index]),
//           ),
//         const SizedBox(width: 20),
//         if (drinks.isNotEmpty)
//           GestureDetector(
//             onTap: () => showComponents[index] = false,
//             child: _buildToggleButton("المشروبات", !showComponents[index]),
//           ),
//       ],
//     );
//   }

//   Widget _buildToggleButton(String text, bool selected) {
//     return Container(
//       decoration: BoxDecoration(
//           color: selected ? mainColor : Colors.white,
//           borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
//         child: Text(
//           text,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: selected ? Colors.white : Colors.black.withOpacity(0.7),
//           ),
//         ),
//       ),
//     );
//   }

//   // ================== COMPONENTS / DRINKS ==================

//   Widget _buildComponentsSection() => _buildItemsSection(
//         components,
//         selectedComponents,
//         componentQuantities,
//         applyToAll[index],
//         "مكونات",
//         onToggleApplyToAll,
//       );

//   Widget _buildDrinksSection() => _buildItemsSection(
//         drinks,
//         selectedDrinks,
//         drinkQuantities,
//         applyToAllDrinks[index],
//         "مشروبات",
//         onToggleApplyToAllDrinks,
//       );

//   Widget _buildItemsSection(
//     List<dynamic> items,
//     List<List<List<String>>> selectedItems,
//     List<List<List<int>>> itemQuantities,
//     bool applyAll,
//     String title,
//     VoidCallback onToggleAll,
//   ) {
//     if (items.isEmpty) return const SizedBox.shrink();
//     return Column(
//       children: [
//         Row(
//           children: [
//             const SizedBox(width: 10),
//             RoundedCheckbox(
//               value: applyAll,
//               borderColor: mainColor,
//               borderRadius: 4,
//               activeColor: Colors.white,
//               checkColor: mainColor,
//               onChanged: (_) => onToggleAll(),
//             ),
//             const SizedBox(width: 10),
//             Text("تكرار $title لكافة الطلبات",
//                 style: const TextStyle(color: Color(0xff6D6D6D))),
//           ],
//         ),
//         const SizedBox(height: 5),
//         applyAll
//             ? _buildAllItems(title, items, selectedItems, itemQuantities)
//             : _buildIndividualItems(
//                 title, items, selectedItems, itemQuantities),
//       ],
//     );
//   }

//   Widget _buildAddToCartButton(BuildContext context, CartProvider cartProvider,
//       List<CartItem> cartItems) {
//     return InkWell(
//       onTap: onAddToCart,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         height: 25,
//         decoration: BoxDecoration(
//           color: fourthColor,
//           borderRadius: const BorderRadius.only(
//             bottomLeft: Radius.circular(14),
//             bottomRight: Radius.circular(14),
//           ),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 alignment: Alignment.centerRight,
//                 child: Text(
//                   "الاجمالي: ${finalPrice[index]}",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//             Container(
//               decoration: BoxDecoration(
//                 color: mainColor,
//                 borderRadius: const BorderRadius.only(
//                   topRight: Radius.circular(14),
//                   bottomLeft: Radius.circular(14),
//                 ),
//               ),
//               alignment: Alignment.center,
//               child: const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 10.0),
//                 child: Text(
//                   "اضافة الى السلة",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
