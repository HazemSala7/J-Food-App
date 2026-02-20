// import 'dart:async';
// import 'package:j_food_updated/constants/constants.dart';
// import 'package:j_food_updated/views/homescreen/homescreen.dart';
// import 'package:j_food_updated/views/resturant_page/restaurant_page.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   bool signIn = false;
//   String restuarantID = "";
//   String categoryId = "";
//   String status = "";
//   String restaurantName = "";
//   String restaurantUserId = "";
//   String restaurantImage = "";
//   String restaurantAddress = "";
//   String delivery_price = "";
//   String latestVersion = "";
//   bool enteredPhone = false;
//   @override
//   void initState() {
//     super.initState();
//     loadData();
//   }

//   Future<void> loadData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     setState(() {
//       signIn = prefs.getBool('sign_in') ?? false;
//       restuarantID = prefs.getString('restaurant_id') ?? "";
//       categoryId = prefs.getString('category_id') ?? "";
//       status = prefs.getString('status') ?? "";
//       restaurantName = prefs.getString('restaurant_name') ?? "";
//       restaurantImage = prefs.getString('restaurant_image') ?? "";
//       restaurantAddress = prefs.getString('restaurant_address') ?? "";
//       delivery_price = prefs.getString('delivery_price') ?? "";
//       latestVersion = prefs.getString('version') ?? "";
//       restaurantUserId = prefs.getString('restaurant_user_id') ?? "";
//       enteredPhone = prefs.getBool('has_entered_phone_number') ?? false;
//     });
//     signIn
//         ? Timer(
//             Duration(seconds: 2),
//             () => Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) => RestaurantPage(
//                         storeId: restuarantID,
//                         categoryId: categoryId,
//                         status: status,
//                         userId: restaurantUserId,
//                         restaurantAddress: restaurantAddress,
//                         restaurantImage: restaurantImage,
//                         deliveryPrice: delivery_price,
//                         restaurantName: restaurantName))))
//         : Timer(
//             Duration(seconds: 2),
//             () => Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) => HomeScreen(
//                           fromOrderConfirm: false,
//                         ))));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: splashColor,
//       child: SafeArea(
//         child: Scaffold(
//           backgroundColor: splashColor,
//           body: Stack(
//             fit: StackFit.expand,
//             children: [
//               Image.asset(
//                 "assets/images/splash-screen.png",
//                 fit: BoxFit.fill,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
