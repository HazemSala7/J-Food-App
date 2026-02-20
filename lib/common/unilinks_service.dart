// import 'package:j_food_updated/views/storescreen/store_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:uni_links2/uni_links.dart';
// import 'context_utility.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class UniLinksService {
//   static String _promoId = '';
//   static String get promoId => _promoId;
//   static bool get hasPromoId => _promoId.isNotEmpty;

//   static void reset() => _promoId = '';

//   static Future<void> init({checkActualVersion = false}) async {
//     // Handle the case where the app is not running, and the user clicks on a link
//     try {
//       final Uri? uri = await getInitialUri();
//       _uniLinkHandler(uri: uri);
//     } on PlatformException {
//       if (kDebugMode)
//         print("(PlatformException) Failed to receive initial uri.");
//     } on FormatException catch (error) {
//       if (kDebugMode)
//         print(
//             "(FormatException) Malformed Initial URI received. Error: $error");
//     }

//     // Handle the case where the app is already running, and the user clicks on a link
//     uriLinkStream.listen((Uri? uri) async {
//       _uniLinkHandler(uri: uri);
//     }, onError: (error) {
//       if (kDebugMode) print('UniLinks onUriLink error: $error');
//     });
//   }

//   static Future<void> _uniLinkHandler({required Uri? uri}) async {
//     if (uri == null || uri.queryParameters.isEmpty) return;
//     Map<String, String> params = uri.queryParameters;

//     String receivedPromoId = params['code'] ?? '';
//     if (receivedPromoId.isEmpty) return;
//     _promoId = receivedPromoId;

//     // Call the API to fetch restaurant details
//     try {
//       final response = await http.get(
//         Uri.parse('https://hrsps.com/login/api/restaurants/$_promoId'),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final restaurant = data['restaurant'];
//         ContextUtility.navigator?.push(
//           MaterialPageRoute(
//             builder: (context) => StoreScreen(
//              category_id: restaurant['category_id'],
//                   category_name: "",
//                   open: restaurant['is_open'],
//                   store_address: restaurant['address'],
//                   store_cover_image: restaurant['cover_image'],
//                   store_id: restaurant['id'].toString(),
//                   store_image: restaurant['image'],
//                   store_name: restaurant['name'],
//             ),
//           ),
//         );
//       } else {
//         print('Failed to load restaurant details');
//       }
//     } catch (e) {
//       print('Failed to fetch restaurant details: $e');
//     }
//   }
// }
