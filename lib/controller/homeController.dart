// import 'dart:convert';

// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;

// import '../models/favorite_model.dart';
// import '../resources/api-const.dart';

// class HomeController extends GetxController {
//   Future getHomeDataList() async {
//     var response = await http.get(Uri.parse(AppLink.homeData));
//     var responseData = utf8.decode(response.bodyBytes);
//     var res = json.decode(responseData);
//     return res;
//   }

//   Future getStoreDetails(String id) async {
//     var response = await http.get(Uri.parse('${AppLink.storeDetails}/$id'));
//     var responseData = utf8.decode(response.bodyBytes);
//     var res = json.decode(responseData);
//     return res;
//   }

//   List<FavoriteModel> favoriteList = [];
//   List favoriteListIDS = [];
//   bool isAdd = false;

//   void changeColor() {
//     isAdd = !isAdd;
//     update();
//   }

//   bool containsId(List<FavoriteModel> favoriteList, String targetId) {
//     for (var favorite in favoriteList) {
//       if (favorite.id == targetId) {
//         return true;
//       }
//     }
//     return false;
//   }

//   addResturantFavorite(
//     dynamic title,
//     dynamic imageUrl,
//     dynamic id,
//     dynamic des,
//   ) {
//     favoriteList.add(FavoriteModel(
//       title: title,
//       imageurl: imageUrl,
//       id: id,
//       des: des,
//     ));
//     favoriteListIDS.add(id);

//     update();
//   }

//   deleteProductFromCart(
//     int id,
//   ) {
//     favoriteList.removeAt(id);
//     update();
//   }
// }
