// // ignore_for_file: prefer_const_constructors, unused_import, non_constant_identifier_names, avoid_print, unnecessary_brace_in_string_interps

// import 'dart:convert';

// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;

// import '../models/cartmodel.dart';
// import '../views/homescreen/homescreen.dart';

// class CartController extends GetxController {
//   int? selectedTime;
//   int quantity = 0;

//   Future order({
//     required String city,
//     required String area,
//     required String address,
//     required String total,
//     required String long,
//     required String late,
//     required String mobile,
//     required String note,
//     required List<CartModel> cartList,
//   }) async {
//     Map<String, String> convertedData = {};

//     for (int i = 0; i < cartList.length; i++) {
//       convertedData['product_id[$i]'] = cartList[i].id!;
//       convertedData['price[$i]'] = cartList[i].price!;
//       convertedData['qty[$i]'] = cartList[i].count!;
//       convertedData['restaurant_id[$i]'] = cartList[i].storeId!;
//     }

//     try {
//       var request = http.MultipartRequest(
//           'POST', Uri.parse('https://hrsps.com/login/api/add_order_talabat'));
//       request.fields.addAll({
//         'city': city,
//         'area': area,
//         'address': address,
//         'total': total,
//         'longitude': long,
//         'lattitude': late,
//         'mobile': mobile,
//         ...convertedData,
//         'notes': note,
//       });

//       http.StreamedResponse response = await request.send();

//       if (response.statusCode == 200) {
//         print(await response.stream.bytesToString());
//         CartList.clear();
//         Get.to(HomeScreen());
//       } else {
//         print(response.reasonPhrase);
//       }
//     } catch (ex) {
//       print('error $ex');
//     }
//   }

//   selectTime(int index) {
//     selectedTime = index;
//     update();
//   }

//   void updateCounter(int value) {
//     if (value == -1 && quantity == 0) {
//       // Prevent decrementing if quantity is already 0
//       return;
//     }

//     quantity = quantity + value;
//     update();
//   }

//   List<CartModel> CartList = [];
//   List CartListIDS = [];

//   int calculateTotalPrice(List<CartModel> cartList) {
//     int totalPrice = 0;
//     for (CartModel cartItem in cartList) {
//       int itemPrice = int.parse(cartItem.price!);
//       int itemCount = int.parse(cartItem.count!);
//       totalPrice += itemPrice * itemCount;
//     }
//     return totalPrice;
//   }

//   void updateItemCount(String id, int newCount, String price) {
//     var item = CartList.firstWhere((element) => element.id == id);
//     item.count = newCount.toString();
//     // item.price = (int.parse(price) * int.parse(item.count!)).toString();
//     update();
//   }

//   addProductToCart(dynamic title, dynamic imageurl, dynamic price, dynamic id,
//       dynamic count, String storeID) {
//     CartList.add(CartModel(
//       title: title,
//       imageurl: imageurl,
//       price: price,
//       id: id,
//       count: count.toString(),
//       storeId: storeID,
//     ));
//     CartListIDS.add(id);

//     update();
//   }

//   deleteProductFromCart(
//     int id,
//   ) {
//     CartList.removeAt(id);
//     update();
//   }
// }
