// import 'package:flutter/material.dart';
// import 'package:j_food_updated/constants/constants.dart';
// import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
// import '../../views/favorite/favorite_screen.dart';

// class AppBarWidget extends StatefulWidget {
//   final bool noDelivery;

//   const AppBarWidget({super.key, required this.noDelivery});

//   @override
//   State<AppBarWidget> createState() => _AppBarWidgetState();
// }

// class _AppBarWidgetState extends State<AppBarWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       backgroundColor: mainColor,
//       title: Image.asset(
//         "assets/images/logo.png",
//         width: 100,
//         height: 50,
//       ),
//       iconTheme: IconThemeData(
//         color: Colors.white, // Change the color here
//       ),
//       centerTitle: true,
//       actions: [
//         // IconButton(
//         //     onPressed: () {
//         //       showSearch(context: context, delegate: CustomSearch());
//         //     },
//         //     icon: const Icon(
//         //       size: 30,
//         //       Icons.search,
//         //       color: Colors.white,
//         //     )),

//         IconButton(
//             onPressed: () {
//               pushWithoutNavBar(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => FavoriteScreen(
//                       noDelivery: widget.noDelivery,
//                     ),
//                   ));
//             },
//             icon: const Icon(
//               Icons.favorite,
//               color: Colors.white,
//             )),
//       ],
//     );
//   }
// }
