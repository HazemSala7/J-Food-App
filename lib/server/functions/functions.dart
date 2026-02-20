import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../resources/api-const.dart';

NavigatorFunction(BuildContext context, Widget Widget) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => Widget));
}

Future<dynamic> getStoreDetails(String id,
    {String? searchKey, int page = 1, bool paginate = true}) async {
  final queryParameters = {
    'page': page.toString(),
    'paginate': paginate.toString(),
    if (searchKey != null && searchKey.isNotEmpty) 'search_key': searchKey,
  };

  final uri = Uri.parse('${AppLink.storeDetails}/$id')
      .replace(queryParameters: queryParameters);

  var response = await http.get(uri);
  var responseData = utf8.decode(response.bodyBytes);
  var res = json.decode(responseData);
  return res;
}

getOrderDependOnUserID(userId,
    {int page = 1, int perPage = 10, bool paginate = true}) async {
  final queryParameters = {
    'paginate': paginate.toString(),
    'per_page': perPage.toString(),
    'page': page.toString(),
  };

  final uri = Uri.parse("${AppLink.ordersWithUserID}/$userId")
      .replace(queryParameters: queryParameters);
  print(uri);
  var response = await http.get(uri);
  if (response.statusCode == 200) {
    try {
      var responseData = utf8.decode(response.bodyBytes);
      var res = json.decode(responseData);
      return res;
    } catch (e) {
      print('Error parsing JSON: $e');
      return {};
    }
  } else {
    print('Failed to load data: ${response.statusCode}');
    return {};
  }
}
