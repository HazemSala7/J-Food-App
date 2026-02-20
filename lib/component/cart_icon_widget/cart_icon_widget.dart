// import 'package:add_to_cart_animation/add_to_cart_icon.dart';
// import 'package:flutter/material.dart';
// import 'package:j_food_updated/constants/constants.dart';
// import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
// import 'package:provider/provider.dart';
// import '../../LocalDB/Provider/CartProvider.dart';
// import '../../views/cart/cartscreen.dart';

// class CartIcon extends StatefulWidget {
//   final bool fromResturant;
//   final bool noDelivery;
//   final GlobalKey<CartIconKey> cartKey;
//   const CartIcon(
//       {super.key,
//       required this.fromResturant,
//       required this.cartKey,
//       required this.noDelivery});

//   @override
//   State<CartIcon> createState() => _CartIconState();
// }

// class _CartIconState extends State<CartIcon> {
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.topRight,
//       children: [
//         InkWell(
//           onTap: () {
//             pushWithoutNavBar(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => CartScreen(
//                     noDelivery: widget.noDelivery,
//                     fromHome: false,
//                   ),
//                 ));
//           },
//           child: Padding(
//               padding: const EdgeInsets.all(6.0),
//               child: AddToCartIcon(
//                 key: widget.cartKey,
//                 icon: Icon(
//                   Icons.shopping_cart_outlined,
//                   color: widget.fromResturant ? mainColor : Colors.white,
//                 ),
//                 badgeOptions: BadgeOptions(
//                     backgroundColor: Colors.transparent,
//                     foregroundColor: Colors.transparent),
//               )
//               // Image.asset(
//               //   "assets/images/cart.png",
//               //   height: 20,
//               //   width: 20,
//               //   color: widget.fromResturant ? mainColor : null,
//               // ),
//               ),
//         ),
//         Consumer<CartProvider>(
//           builder: (context, cartProvider, _) {
//             int itemCount = cartProvider.cartItemsCount;
//             return CartIcon(itemCount);
//           },
//         )
//       ],
//     );
//   }

//   Widget CartIcon(int itemCount) {
//     return Container(
//       height: 19,
//       width: 19,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.red,
//       ),
//       child: Center(
//         child: Padding(
//           padding: const EdgeInsets.only(top: 2),
//           child: Text(
//             itemCount.toString(),
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
