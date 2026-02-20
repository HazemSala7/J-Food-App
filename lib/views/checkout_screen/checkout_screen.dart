import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:j_food_updated/LocalDB/Provider/PackageCartProvider.dart';
import 'package:j_food_updated/views/orders_screen/orders_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:gif/gif.dart';
import 'package:http/http.dart' as http;
import 'package:j_food_updated/views/homescreen/homescreen.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../LocalDB/Provider/CartProvider.dart';
import '../../constants/constants.dart';
import '../../resources/api-const.dart';

class BuyNow extends StatefulWidget {
  final double total;
  final double deliveryPrice;
  final bool noDelivery;
  final bool ramadanTime;
  BuyNow({
    Key? key,
    required this.total,
    required this.deliveryPrice,
    required this.noDelivery,
    required this.ramadanTime,
  }) : super(key: key);

  @override
  State<BuyNow> createState() => _BuyNowState();
}

class _BuyNowState extends State<BuyNow> with TickerProviderStateMixin {
  TextEditingController noteController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController phone2Controller = TextEditingController();
  TextEditingController nearofController = TextEditingController();
  bool validPhone = false;
  late final GifController controller;
  bool emptyName = false;
  bool emptyArea = false;
  double lati = 31;
  double longi = 31;
  String? payment;
  String servicePrice = "1";
  bool validPayment = true;
  List<Map<String, dynamic>>? paymentOptions;
  String? selectedArea;
  List<dynamic> areas = [];
  String ramadanDeliveryTime = "";
  String myToken = "";
  bool isSubmitting = false;
  Future<Map<String, dynamic>> registerFunction() async {
    var headers = {'Accept': 'application/json'};
    final response = await http.post(
      Uri.parse(AppLink.signUp),
      headers: headers,
      body: {
        'email': "${nameController.text}${phoneController.text}@gmail.com",
        'password': "123",
        'phone': phoneController.text,
        'name': nameController.text,
        'serial_number': "0",
        'id_number': "0",
        'role_id': "2",
        'restaurant_id': "0",
      },
    );

    print('Register response body: ${response.body}');

    try {
      var data = jsonDecode(response.body.toString());
      return data;
    } catch (e) {
      print('Error decoding JSON: $e');
      throw Exception('Failed to parse register response');
    }
  }

  Future<Map<String, dynamic>> checkPhoneNumber(String phoneNumber) async {
    final response = await http.get(
      Uri.parse('${AppLink.checkPhoneNumber}/$phoneNumber'),
    );

    if (response.headers['content-type']?.contains('application/json') ??
        false) {
      try {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          return responseData;
        } else {
          Navigator.of(context).pop();
          Fluttertoast.showToast(
            msg: 'Error checking phone number or during registration',
            timeInSecForIosWeb: 4,
          );
          print(
              'Error checking phone number or during registration: ${responseData['message']}');
          throw Exception('Failed to check phone number');
        }
      } catch (e) {
        print('Error decoding JSON: $e');
        throw Exception('Failed to parse phone check response');
      }
    } else {
      throw Exception(
          'Unexpected content type: ${response.headers['content-type']}');
    }
  }

  Future<void> loginAndGetToken(String phone, String password) async {
    const String loginUrl = AppLink.login;

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "phone": phone,
          "password": password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final token = responseData['access_token'];
        if (token != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('barrierToken', token);
          // Only send token to server if it's not empty
          if (myToken.isNotEmpty) {
            await sendTokenToServer(myToken);
          }
        }
      } else {
        print(
            "Login failed. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Login error: $e");
    }
  }

  Future<void> getToken() async {
    try {
      myToken = (await FirebaseMessaging.instance.getToken())!;

      print("FCM Token: $myToken");
    } catch (e) {
      print("Error getting token: $e");
    }
  }

  Widget _buildSupportWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: InkWell(
        onTap: () async {
          var contact = "+972503050099";
          var androidUrl =
              "whatsapp://send?phone=$contact&text=Hi, I need some help";
          var iosUrl =
              "https://wa.me/$contact?text=${Uri.parse('Hi, I need some help')}";

          try {
            if (Platform.isIOS) {
              await launchUrl(Uri.parse(iosUrl));
            } else {
              await launchUrl(Uri.parse(androidUrl));
            }
          } on Exception {
            Fluttertoast.showToast(msg: "WhatsApp is not installed.");
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                  color: mainColor, borderRadius: BorderRadius.circular(50)),
              width: 30,
              height: 30,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Material(
                  color: Colors.transparent,
                  child: Image.asset(
                    "assets/images/whatsapp.png",
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 5,
            ),
            Expanded(
              child: Container(
                width: 200,
                child: Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "في حال وجود اي خلل ",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: "اضغط هنا",
                          style: TextStyle(
                            color: mainColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: " للتواصل مع الدعم الفني على الواتساب",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendTokenToServer(String token) async {
    // Don't send if token is null or empty
    if (token.isEmpty) {
      print("FCM token is empty, skipping token send.");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? barrierToken = prefs.getString('barrierToken');
    print("barrierToken");
    print(barrierToken);
    if (barrierToken == null) {
      print("No barrier token found. Please login first.");
      return;
    }

    String apiUrl = AppLink.sendFcmToken;
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $barrierToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "fcm_token": token,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Token sent successfully!");
      } else {
        print("Failed to send token. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error sending token: $e");
    }
  }

  Future<void> addOrder() async {
    var phoneCheckResponse = await checkPhoneNumber(phoneController.text);

    if (phoneCheckResponse['status'] == 'true') {
      var user = phoneCheckResponse['user'];

      if (user['status'] == 'blocked') {
        Navigator.of(context).pop();
        print('User is blocked: ${user['id']}');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "حسابك محظور",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "حسابك محظور ولا يمكنك إكمال الطلب",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSupportWidget(),
                      const SizedBox(height: 20),
                      Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: fourthColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "حسناً",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
        throw Exception('User is blocked');
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (user['fcm_token'] == null || user['fcm_token'] != myToken) {
        await loginAndGetToken(phoneController.text, "123");
      }

      print("3");
      await prefs.setString('user_id', user['id'].toString());
      await prefs.setString('name', user['name']);
      await prefs.setString('phone_number', user['phone']);

      String userID = user['id'].toString();
      await addOrderAfterRegistration(userID);
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var registerResponse = await registerFunction();

      if (registerResponse['status'] == 'true') {
        var user = registerResponse['user'];
        var token = registerResponse['access_token'];
        await prefs.setString('barrierToken', token);
        // Only send token to server if it's not empty
        if (myToken.isNotEmpty) {
          await sendTokenToServer(myToken);
        }
        await prefs.setString('user_id', user['id'].toString());
        await prefs.setString('name', user['name']);
        await prefs.setString('phone_number', user['phone']);
        await addOrderAfterRegistration(user['id'].toString());
      } else {
        Navigator.of(context).pop();
        Fluttertoast.showToast(
            msg: 'حدث مشكلة اثناء تسجيل البيانات يرجى المحاولة مرة اخرى',
            timeInSecForIosWeb: 4);
        print('Registration failed: ${registerResponse['message']}');
        throw Exception('Registration failed: ${registerResponse['message']}');
      }
    }
  }

  Future<void> addOrderAfterRegistration(String user_id) async {
    try {
      CartProvider cartProvider =
          Provider.of<CartProvider>(context, listen: false);
      PackageCartProvider packageCartProvider =
          Provider.of<PackageCartProvider>(context, listen: false);
      List<Map<String, dynamic>> productsArray =
          cartProvider.getProductsArray();
      List<Map<String, dynamic>> packagesArray =
          packageCartProvider.getPackagesArray();

      String jsonProducts = jsonEncode(productsArray);
      String jsonPackages = jsonEncode(packagesArray);

      List<dynamic> parsedProducts = jsonDecode(jsonProducts);
      List<dynamic> parsedPackages = jsonDecode(jsonPackages);

      final String resturantId = parsedPackages.isNotEmpty
          ? parsedPackages[0]["storeID"].toString()
          : parsedProducts[0]["storeID"].toString();

      List<Map<String, dynamic>> allProducts = [];

      final bool canBuy =
          widget.ramadanTime ? await canRestaurantCheckout(resturantId) : true;
      if (canBuy) {
        for (var i = 0; i < productsArray.length; i++) {
          var item = productsArray[i];
          double itemBaseTotal = double.parse(item["price"].toString()) *
              int.parse(item["quantity"].toString());

          double componentTotal = 0.0;
          if (item["selected_components_id"] != null &&
              item["selected_components_id"].isNotEmpty &&
              item["selected_components_id"][0] != "0") {
            for (int j = 0; j < item["selected_components_id"].length; j++) {
              double componentPrice = double.parse(
                  item["selected_components_prices"][j].toString());
              int componentQty =
                  int.parse(item["selected_components_qty"][j].toString());
              componentTotal += componentPrice * componentQty;
            }
          }

          double drinkTotal = 0.0;
          if (item["selected_drinks_id"] != null &&
              item["selected_drinks_id"].isNotEmpty &&
              item["selected_drinks_id"][0] != "0") {
            for (int j = 0; j < item["selected_drinks_id"].length; j++) {
              double drinkPrice =
                  double.parse(item["selected_drinks_prices"][j].toString());
              int drinkQty =
                  int.parse(item["selected_drinks_qty"][j].toString());
              drinkTotal += drinkPrice * drinkQty;
            }
          }

          double finalTotal = itemBaseTotal + componentTotal + drinkTotal;

          Map<String, dynamic> product = {
            "product_type": "product",
            "product_id": item["product_id"],
            "price": double.parse(item["price"].toString()),
            "size_id": item["sizeId"] != "" ? item["sizeId"] : "0",
            // "note": item["note"] != "" ? item["note"] : "0",
            "qty": int.parse(item["quantity"].toString()),
            "sum": finalTotal,
            "component_id": item["selected_components_id"] != null
                ? List<int>.from(item["selected_components_id"]
                    .map((x) => int.tryParse(x.toString()) ?? 0))
                : [],
            "component_ids_qty": item["selected_components_qty"] != null
                ? List<int>.from(item["selected_components_qty"]
                    .map((x) => int.tryParse(x.toString()) ?? 0))
                : [],
            "drink_id": item["selected_drinks_id"] != null
                ? List<int>.from(item["selected_drinks_id"]
                    .map((x) => int.tryParse(x.toString()) ?? 0))
                : [],
            "drink_ids_qty": item["selected_drinks_qty"] != null
                ? List<int>.from(item["selected_drinks_qty"]
                    .map((x) => int.tryParse(x.toString()) ?? 0))
                : [],
          };

          allProducts.add(product);
        }

        for (var package in packagesArray) {
          Map<String, dynamic> packageData = {
            "product_type": "package",
            "package_drinks_ids": package["selected_drinks_id"] != null
                ? [package["selected_drinks_id"]]
                : [],
            "package_drinks_ids_qty": package["selected_drinks_qty"] != null
                ? [package["selected_drinks_qty"]]
                : [],
            "products_details": []
          };

          if (package["productNames"] != null) {
            for (var i = 0; i < package["productNames"].length; i++) {
              String productName = package["productNames"][i];
              Map<String, dynamic> productDetailData = {
                "product_id": package["productIds"][i],
                "component_id": [],
                "component_ids_qty": [],
                "drink_id": [],
                "drink_ids_qty": [],
                "size_id": "0",
                "price": "0",
                "qty": "1",
                "sum": "0",
              };

              if (package["productComponents"] != null &&
                  package["productComponents"].containsKey(productName)) {
                var components = package["productComponents"][productName];

                if (components["id"].isNotEmpty) {
                  String id =
                      components["id"].replaceAll("[", "").replaceAll("]", "");
                  String qty =
                      components["qty"].replaceAll("[", "").replaceAll("]", "");

                  List<String> ids =
                      id.split(",").map((e) => e.trim()).toList();
                  List<String> qtys =
                      qty.split(",").map((e) => e.trim()).toList();
                  productDetailData["component_id"] = ids;
                  productDetailData["component_ids_qty"] = qtys;
                } else {
                  print(
                      "Component id and qty are not valid lists for $productName");
                }
              } else {
                print("No components found for $productName");
              }

              packageData["products_details"].add(productDetailData);
            }
          }

          allProducts.add(packageData);
        }

        String selectedAreaName = areas.firstWhere(
            (area) => area['id'].toString() == selectedArea)['name'];
        String selectedAreaId = areas
            .firstWhere((area) => area['id'].toString() == selectedArea)['id']
            .toString();
        final now = DateTime.now();
        final orderDate = DateFormat('yyyy-MM-dd').format(now);
        final orderTime = DateFormat('HH:mm:ss').format(now);
        final data = {
          'customer_name': nameController.text,
          'city': "القدس",
          'mobile': phoneController.text,
          'mobile_2':
              convertArabicToEnglish(phone2Controller.text).replaceAll('-', ''),
          'area': selectedAreaName,
          'area_id': selectedAreaId,
          'user_id': user_id.toString(),
          'address':
              nearofController.text.isEmpty ? "-" : nearofController.text,
          'restaurant_id': parsedPackages.isNotEmpty
              ? parsedPackages[0]["storeID"].toString()
              : parsedProducts[0]["storeID"].toString(),
          'notes': noteController.text,
          'total': widget.total.toString(),
          'type': "load",
          'lattitude': lati.toString(),
          'longitude': longi.toString(),
          'preparation_time': "0",
          'checkout_type':
              payment == "الاستلام من المطعم" ? "pickup" : "delivery",
          'order_date': orderDate,
          'order_time': orderTime,
          'service_price': servicePrice,
          'products': allProducts,
        };
        final headers = {'Content-Type': 'application/json'};

        print(jsonEncode(data));
        final response = await http.post(
          Uri.parse(AppLink.addOrderAutomat),
          headers: headers,
          body: jsonEncode(data),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.of(context, rootNavigator: true).pop();
          Fluttertoast.showToast(msg: "تم اضافه الطلبيه بنجاح");

          cartProvider.clearCart();
          packageCartProvider.clearCart();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return WillPopScope(
                onWillPop: () async => false, // Prevent back button
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child:
                                    Lottie.asset('assets/images/dialog.json'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "تمت عملية الشراء",
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 35,
                                width: MediaQuery.of(context).size.width * 0.7,
                                decoration: BoxDecoration(
                                  color: fourthColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HomeScreen(fromOrderConfirm: false),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text(
                                    "الانتقال الى الصفحة الرئيسية",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 35,
                                width: MediaQuery.of(context).size.width * 0.7,
                                decoration: BoxDecoration(
                                  color: fourthColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HomeScreen(fromOrderConfirm: false),
                                      ),
                                      (route) => false,
                                    );
                                    pushWithoutNavBar(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrdersScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "الانتقال الى متابعة الطلب",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', nameController.text);
          await prefs.setString('phone_number', phoneController.text);
        } else {
          Navigator.of(context, rootNavigator: true).pop();
          Fluttertoast.showToast(msg: "حدث خطأ أثناء إضافة الطلبية");
          throw Exception('Failed to add order: ${response.statusCode}');
        }
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        Fluttertoast.showToast(
            msg: "عذرا وصلت عدد الطلبات اليوم لهذا المطعم العدد الاقصى",
            timeInSecForIosWeb: 5);
        throw Exception('Restaurant cannot checkout');
      }
    } catch (e) {
      print('Error in addOrderAfterRegistration: $e');
      rethrow;
    }
  }

  Future<bool> canRestaurantCheckout(String id) async {
    try {
      final Uri url = Uri.parse("${AppLink.canCheck}/${id}/can-checkout");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["can_checkout"] ?? false;
      } else {
        print("Error: ${response.body}");
        return true;
      }
    } catch (e) {
      print("Exception: $e");
      return true;
    }
  }

  Future<void> getServicePrice() async {
    try {
      final Uri url = Uri.parse("${AppLink.settings}");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['settings'] != null &&
            data['settings']['service_price'] != null) {
          setState(() {
            servicePrice = data['settings']['service_price'].toString();
          });
          print("✅ Service Price fetched successfully: $servicePrice");
        } else {
          print("⚠️ Service price not found in response");
        }
      } else {
        print(
            "❌ Error fetching service price: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Exception getting service price: $e");
    }
  }

  String convertArabicToEnglish(String text) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = text;
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return result;
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء ادخال رقم الهاتف';
    }
    // Remove hyphens for validation
    String cleanValue = value.replaceAll('-', '');
    if (!cleanValue.startsWith('05')) {
      return 'رقم الهاتف يجب أن يبدأ ب 05';
    }
    if (cleanValue.length > 10) {
      return 'رقم الهاتف لا يجب أن يزيد عن 10 رقم';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fourthColor,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: fourthColor,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0, left: 8, top: 20),
              child: Container(
                // height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        topLeft: Radius.circular(12)),
                    color: Colors.white),
                child: Column(
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 30, left: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "*",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                          SizedBox(
                            width: 2,
                          ),
                          Text(
                            "اسم الزبون",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                        ],
                      ),
                    ),
                    StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(right: 25, left: 25, top: 5),
                        child: Container(
                          height: 40,
                          width: double.infinity,
                          child: TextField(
                            controller: nameController,
                            obscureText: false,
                            onTap: () {
                              setState(() {
                                emptyName = false;
                              });
                            },
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Color(0xffD0D0D0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainColor, width: 2.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: emptyName
                                      ? Colors.red
                                      : Color(0xffD0D0D0),
                                ),
                              ),
                              hintText: "ادخل اسم الزبون",
                            ),
                          ),
                        ),
                      );
                    }),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 10, right: 25, left: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "*",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                          SizedBox(
                            width: 2,
                          ),
                          Text(
                            "رقم الهاتف",
                            style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 30, left: 25, top: 5),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                            color: Color(0xffD0D0D0),
                            borderRadius: BorderRadius.circular(12)),
                        width: double.infinity,
                        child: TextFormField(
                          enabled: false,
                          validator: validatePhoneNumber,
                          controller: phoneController,
                          obscureText: false,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintStyle: TextStyle(
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: validPhone ? Colors.green : mainColor,
                                  width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                width: 2.0,
                                color: validPhone
                                    ? Colors.green
                                    : Color(0xffD0D0D0),
                              ),
                            ),
                            hintText: "رقم الهاتف",
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 10, right: 30, left: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "رقم هاتف اخر",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 25, left: 25, top: 5),
                      child: Container(
                        height: 40,
                        width: double.infinity,
                        child: TextFormField(
                          validator: validatePhoneNumber,
                          controller: phone2Controller,
                          obscureText: false,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Color(0xffD0D0D0),
                            ),
                            // prefixIcon: Icon(
                            //   Icons.phone,
                            //   color: Color(0xff428fc6),
                            // ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: mainColor, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                width: 2.0,
                                color: Color(0xffD0D0D0),
                              ),
                            ),
                            hintText: "ادخل رقم هاتف اخر",
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 10, right: 25, left: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "*",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                          SizedBox(
                            width: 2,
                          ),
                          Text(
                            "المنطقه",
                            style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color:
                                  emptyArea ? Colors.red : Color(0xffD0D0D0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedArea,
                          items: areas
                              .map((area) => DropdownMenuItem<String>(
                                    value: area['id'].toString(),
                                    child: Text(
                                      area['name'],
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedArea = value;
                            });
                          },
                          onTap: () {
                            setState(() {
                              emptyArea = false;
                            });
                          },
                          decoration: InputDecoration(
                            labelText:
                                selectedArea == null ? 'اختر المنطقة' : null,
                            labelStyle: TextStyle(
                              color: Color(0xffD0D0D0),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                width: 0.0,
                                color:
                                    emptyArea ? Colors.red : Color(0xffD0D0D0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                width: 0.0,
                                color:
                                    emptyArea ? Colors.red : Color(0xffD0D0D0),
                              ),
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.black.withOpacity(0.8),
                          ),
                          dropdownColor: Colors.white,
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 10, right: 25, left: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "بالقرب من",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                        ],
                      ),
                    ),
                    StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(right: 25, left: 25, top: 5),
                        child: Container(
                          height: 40,
                          width: double.infinity,
                          child: TextField(
                            controller: nearofController,
                            obscureText: false,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.only(
                              //     bottom: 10, top: 12, left: 2, right: 2),
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Color(0xffD0D0D0),
                              ),
                              // prefixIcon: Icon(
                              //   Icons.near_me,
                              //   color: Color(0xff428fc6),
                              // ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainColor, width: 2.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Color(0xffD0D0D0),
                                ),
                              ),
                              hintText: "بالقرب من",
                            ),
                          ),
                        ),
                      );
                    }),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 10, right: 25, left: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "ملاحظات",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                        ],
                      ),
                    ),
                    StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(right: 25, left: 25, top: 5),
                        child: Container(
                          height: 80,
                          width: double.infinity,
                          child: TextField(
                            controller: noteController,
                            obscureText: false,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Color(0xffD0D0D0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: mainColor, width: 2.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Color(0xffD0D0D0),
                                ),
                              ),
                              hintText: "ملاحظات",
                            ),
                          ),
                        ),
                      );
                    }),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: paymentOptions!.take(2).map((options) {
                          bool isSelected = payment == options['title'];
                          return Expanded(
                            child: Visibility(
                              visible: !(options['title'] == 'التوصيل للبيت' &&
                                  widget.noDelivery),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    validPayment = true;
                                    payment = options['title'];
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  margin: EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? secondColor
                                        : Color(0xffCBCBCB),
                                    border: Border.all(
                                      color: validPayment
                                          ? Colors.transparent
                                          : Colors.red,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      options['title'],
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w100,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 30, left: 30, top: 10),
                      child: Container(
                        // color: Color(0xffFFFAF3),
                        child: Column(
                          children: [
                            Visibility(
                              visible: widget.ramadanTime &&
                                  ramadanDeliveryTime != "",
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ramadanDeliveryTime,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                        style: TextStyle(
                                            color: secondColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "الاجمالي",
                                    style: TextStyle(
                                        color: secondColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                      "₪${double.parse(widget.total.toString())}",
                                      style: TextStyle(
                                          color: secondColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold))
                                ],
                              ),
                            ),
                            Visibility(
                              visible: payment != "الاستلام من المطعم",
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("سعر التوصيل",
                                        style: TextStyle(
                                            color: secondColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      "₪${widget.deliveryPrice}",
                                      style: TextStyle(
                                          color: secondColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("رسوم الخدمة",
                                      style: TextStyle(
                                          color: secondColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    "₪${servicePrice}",
                                    style: TextStyle(
                                        color: secondColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("المجموع النهائي",
                                      style: TextStyle(
                                          color: secondColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      payment != "الاستلام من المطعم"
                                          ? "₪${widget.total + widget.deliveryPrice + 1}"
                                          : "₪${widget.total + 1}",
                                      style: TextStyle(
                                          color: secondColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold))
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 60, left: 60, top: 40),
                      child: MaterialButton(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(25))),
                        height: 50,
                        minWidth: double.infinity,
                        color: isSubmitting ? Colors.grey : mainColor,
                        textColor: Colors.white,
                        child: Text(
                          "تأكيد الطلب",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (nameController.text.isEmpty ||
                                    selectedArea == null ||
                                    payment == null ||
                                    phoneController.text.isEmpty) {
                                  if (nameController.text.isEmpty) {
                                    setState(() {
                                      emptyName = true;
                                    });
                                  }
                                  if (payment == null) {
                                    setState(() {
                                      validPayment = false;
                                    });
                                  }
                                  if (selectedArea == null) {
                                    setState(() {
                                      emptyArea = true;
                                    });
                                  }
                                  await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return StatefulBuilder(
                                        builder: (BuildContext context,
                                            StateSetter setState) {
                                          return AlertDialog(
                                            content: Text(
                                                'الرجاء تعبئة الحقول المطلوبة'),
                                            actions: <Widget>[
                                              InkWell(
                                                onTap: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Container(
                                                  width: 80,
                                                  height: 40,
                                                  color: mainColor,
                                                  child: Center(
                                                    child: Text(
                                                      'حسنا',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                } else {
                                  setState(() {
                                    isSubmitting = true;
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return StatefulBuilder(
                                        builder: (BuildContext context,
                                            StateSetter setState) {
                                          return AlertDialog(
                                            content: SizedBox(
                                              height: 100,
                                              width: 100,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );

                                  try {
                                    await addOrder();
                                  } catch (e) {
                                    print('Error submitting order: $e');
                                  } finally {
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                }
                              },
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = GifController(vsync: this);
    getServicePrice();
    setControllers();
    getToken();
    paymentOptions = widget.noDelivery
        ? [
            {
              'title': "الاستلام من المطعم",
            },
          ]
        : [
            {
              'title': "الاستلام من المطعم",
            },
            {
              'title': "التوصيل للبيت",
            },
          ];
    if (widget.ramadanTime) fetchDeliveryTime();
    fetchAreas();
  }

  Future<void> fetchDeliveryTime() async {
    final String apiUrl = '${AppLink.orderTime}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data.containsKey('delivery_time')) {
          String deliveryTime = data['delivery_time'];

          extractDeliveryTime(deliveryTime);
        } else {
          print('Invalid API response format');
        }
      } else {
        print('Failed to fetch data. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void extractDeliveryTime(String deliveryTime) {
    List<String> parts =
        deliveryTime.split('-'); // Splitting "5:30-5:45" -> ["5:30", "5:45"]

    if (parts.length == 2) {
      List<String> startParts = parts[0].split(':'); // "5:30" -> ["5", "30"]
      List<String> endParts = parts[1].split(':'); // "5:45" -> ["5", "45"]

      if (startParts.length == 2 && endParts.length == 2) {
        int startHour = int.parse(startParts[0]);
        int startMinute = int.parse(startParts[1]);
        int endHour = int.parse(endParts[0]);
        int endMinute = int.parse(endParts[1]);

        setState(() {
          ramadanDeliveryTime =
              "ملاحظة: سيتم توصيل الطلب من الساعة ${startHour}:${startMinute} إلى الساعة ${endHour}:${endMinute}";
        });
      } else {
        print('Invalid time format');
      }
    } else {
      print('Invalid format');
    }
  }

  Future<void> fetchAreas() async {
    try {
      final response = await http.get(Uri.parse('${AppLink.getAreas}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          areas = data['area'];
        });
      } else {
        print('Failed to load areas: ${response.statusCode}');
        setState(() {});
      }
    } catch (e) {
      print('Error fetching areas: $e');
      setState(() {
        // isLoading = false;
      });
    }
  }

  Future<void> setControllers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('name') ?? "";
    String? phone_number = prefs.getString('phone_number') ?? "";
    if (phone_number != "") {
      validPhone = true;
    }
    nameController.text = name.toString();
    phoneController.text = phone_number.toString();
    setState(() {});
  }
}
