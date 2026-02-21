import 'package:j_food_updated/LocalDB/Models/PackageCartItem.dart';
import 'package:j_food_updated/LocalDB/Provider/PackageCartProvider.dart';
import 'package:j_food_updated/views/cart/cart_widget/package_widget.dart';
import 'package:j_food_updated/views/cart/edit_cart.dart';
import 'package:j_food_updated/views/cart/verification_code/verification_code.dart';
import 'package:j_food_updated/views/storescreen/store_provider/store_provider.dart';
import 'package:j_food_updated/views/storescreen/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/views/checkout_screen/checkout_screen.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../LocalDB/Models/CartItem.dart';
import '../../LocalDB/Provider/CartProvider.dart';
import 'cart_widget/cart_widget.dart';

class CartScreen extends StatefulWidget {
  final bool fromHome;
  final bool noDelivery;
  final bool ramadanTime;
  final Function(int) changeTab;
  CartScreen(
      {super.key,
      required this.fromHome,
      required this.noDelivery,
      required this.ramadanTime,
      required this.changeTab});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int? currentEditingIndex;

  bool isStoreOpenByWorkingHours(String workingHoursJson, bool isOpen) {
    try {
      final now = DateTime.now();
      final List<String> dayNames = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ];
      final String currentDay = dayNames[now.weekday - 1];

      final workingHoursList = jsonDecode(workingHoursJson) as List<dynamic>;
      final todaySchedule = workingHoursList.firstWhere(
        (schedule) => schedule['day'] == currentDay,
        orElse: () => null,
      );
      print(
          "⏰ Checking Store Hours - Now: $now, Today: $currentDay, Schedule: $todaySchedule, IsOpen Flag: $isOpen");

      // If no schedule for today, store is closed
      if (todaySchedule == null) return false;

      String? openTimeString = todaySchedule['start_time'];
      String? closeTimeString = todaySchedule['end_time'];

      if (openTimeString == null ||
          closeTimeString == null ||
          !openTimeString.contains(":") ||
          !closeTimeString.contains(":")) {
        return false;
      }

      DateTime parseTime(String timeStr, DateTime reference) {
        final parts = timeStr.split(":");
        return DateTime(reference.year, reference.month, reference.day,
            int.parse(parts[0]), int.parse(parts[1]));
      }

      DateTime openTime = parseTime(openTimeString, now);
      DateTime closeTime = parseTime(closeTimeString, now);

      final bool isOvernight = closeTime.isBefore(openTime);
      if (isOvernight) {
        closeTime = closeTime.add(const Duration(days: 1));
        if (now.isBefore(openTime)) {
          openTime = openTime.subtract(const Duration(days: 1));
        }
      }

      if (now.isAfter(closeTime)) {
        openTime = openTime.add(const Duration(days: 1));
        closeTime = closeTime.add(const Duration(days: 1));
      }

      // Check if within working hours AND backend says it's open
      final bool withinWorkingHours =
          now.isAfter(openTime) && now.isBefore(closeTime);
      return withinWorkingHours && isOpen;
    } catch (e) {
      debugPrint("Error checking working hours: $e");
      return isOpen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fourthColor,
      child: SafeArea(
        child: Consumer2<CartProvider, PackageCartProvider>(
          builder: (context, cartProvider, packageCartProvider, _) {
            List<CartItem> cartItems = cartProvider.cartItems;
            List<PackageCartItem> packageCartItems =
                packageCartProvider.packageCartItems;
            double total = 0;

            for (CartItem item in cartItems) {
              total += double.parse(item.total);
            }

            for (PackageCartItem package in packageCartItems) {
              total += double.parse(package.total);
            }
            return Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: fourthColor,
              body: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8, top: 25),
                child: Stack(children: [
                  Column(
                    children: [
                      SizedBox(height: 15),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(25),
                            top: Radius.circular(4),
                          ),
                        ),
                        child: (cartItems.isNotEmpty ||
                                packageCartItems.isNotEmpty)
                            ? Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    top: -35,
                                    left: (MediaQuery.of(context).size.width /
                                            2) -
                                        50,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeNotifierProvider(
                                                      create: (_) =>
                                                          StoreProvider()
                                                            ..fetchStoreDetails(
                                                                cartItems.first
                                                                    .storeID),
                                                      child: StoreScreen(
                                                        noDelivery:
                                                            widget.noDelivery,
                                                        changeTab:
                                                            widget.changeTab,
                                                        category_id: cartItems
                                                            .first.storeID,
                                                        store_id: cartItems
                                                            .first.storeID,
                                                        category_name: cartItems
                                                            .first.storeName,
                                                        store_address: cartItems
                                                            .first
                                                            .storeLocation,
                                                        open: true,
                                                        store_cover_image:
                                                            cartItems
                                                                .first.name,
                                                        store_image: cartItems
                                                            .first.storeImage,
                                                        store_name: cartItems
                                                            .first.storeName,
                                                      ),
                                                    )));
                                      },
                                      child: CircleAvatar(
                                        radius: 45,
                                        backgroundColor: fourthColor,
                                        child: ClipOval(
                                          child: Image.network(
                                            cartItems.isNotEmpty
                                                ? cartItems.first.storeImage
                                                : packageCartItems
                                                    .first.storeImage,
                                            fit: BoxFit.cover,
                                            width: 80,
                                            height: 80,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 60),
                                      Text(
                                        cartItems.isNotEmpty
                                            ? cartItems.first.storeName
                                            : packageCartItems.first.storeName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff323232),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          SizedBox(width: 5),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: secondColor, width: 1),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            child: Icon(
                                              Icons.location_on,
                                              color: secondColor,
                                              size: 18,
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              cartItems.isNotEmpty
                                                  ? cartItems
                                                      .first.storeLocation
                                                  : packageCartItems
                                                      .first.storeLocation,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                    ],
                                  ),
                                ],
                              )
                            : SizedBox(
                                height: 150,
                                child: Center(
                                  child: Text(
                                    "سلتك فارغة",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ),
                              ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Visibility(
                                  visible: cartItems.isNotEmpty,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0, vertical: 5),
                                    child: MaterialButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeNotifierProvider(
                                                      create: (_) =>
                                                          StoreProvider()
                                                            ..fetchStoreDetails(
                                                                cartItems.first
                                                                    .storeID),
                                                      child: StoreScreen(
                                                        noDelivery:
                                                            widget.noDelivery,
                                                        changeTab:
                                                            widget.changeTab,
                                                        category_id: cartItems
                                                            .first.storeID,
                                                        store_id: cartItems
                                                            .first.storeID,
                                                        category_name: cartItems
                                                            .first.storeName,
                                                        store_address: cartItems
                                                            .first
                                                            .storeLocation,
                                                        open: true,
                                                        store_cover_image:
                                                            cartItems
                                                                .first.name,
                                                        store_image: cartItems
                                                            .first.storeImage,
                                                        store_name: cartItems
                                                            .first.storeName,
                                                      ),
                                                    )));
                                      },
                                      color: mainColor,
                                      height: 40,
                                      minWidth: double.infinity,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Text(
                                        "اضف المزيد",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                (cartItems.isNotEmpty ||
                                        packageCartItems.isNotEmpty)
                                    ? ListView.builder(
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: cartItems.length +
                                            packageCartItems.length,
                                        itemBuilder: (context, index) {
                                          if (index < cartItems.length) {
                                            CartItem item = cartItems[index];
                                            return Column(
                                              children: [
                                                CartProductMethod(
                                                  item: item,
                                                  removeProduct: () {
                                                    cartProvider
                                                        .removeFromCart(item);
                                                  },
                                                  editProduct: () {
                                                    setState(() {
                                                      currentEditingIndex =
                                                          (currentEditingIndex ==
                                                                  index)
                                                              ? null
                                                              : index;
                                                    });
                                                  },
                                                ),
                                                if (currentEditingIndex ==
                                                    index)
                                                  SizedBox(
                                                    height: 250,
                                                    child: EditOrderWidget(
                                                      item: item,
                                                      onUpdate: (updatedItem) {
                                                        cartProvider
                                                            .updateCartItem(
                                                                updatedItem);
                                                        setState(() {
                                                          currentEditingIndex =
                                                              null;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            );
                                          } else {
                                            int packageIndex =
                                                index - cartItems.length;
                                            PackageCartItem package =
                                                packageCartItems[packageIndex];

                                            return Column(
                                              children: [
                                                PackageProductMethod(
                                                  item: package,
                                                  removeProduct: () {
                                                    packageCartProvider
                                                        .removeFromCart(
                                                            package);
                                                  },
                                                  editProduct: () {
                                                    setState(() {
                                                      currentEditingIndex =
                                                          (currentEditingIndex ==
                                                                  index)
                                                              ? null
                                                              : index;
                                                    });
                                                  },
                                                ),
                                              ],
                                            );
                                          }
                                        },
                                      )
                                    : Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                            ),
                                            Text(
                                              "لا يوجد منتجات بالسله",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17),
                                            ),
                                            SizedBox(height: 10),
                                            ImageIcon(
                                              AssetImage(
                                                  'assets/images/out-of-stock.png'),
                                              size: 40,
                                            ),
                                            SizedBox(height: 20),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.8,
                                              child: Text(
                                                "يمكنك الطلب من خلال المطاعم في الصفحة الرئيسية",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: mainColor,
                                                    fontSize: 19),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                SizedBox(
                                  height: 30,
                                ),
                                Visibility(
                                    visible: cartItems.isNotEmpty ||
                                        packageCartItems.isNotEmpty,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                        ),
                                        Text(
                                          "المجموع: ${total}",
                                          style: TextStyle(
                                              color: Color(0xff5D5D5D),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                      ],
                                    )),
                                SizedBox(
                                  height: 150,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible:
                        cartItems.isNotEmpty || packageCartItems.isNotEmpty,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            bool hasEnteredPhoneNumber =
                                prefs.getBool('has_entered_phone_number') ??
                                    false;

                            if (!hasEnteredPhoneNumber) {
                              bool? isVerified =
                                  await showPhoneVerificationBottomSheet(
                                      context, false);
                              if (isVerified == true) {
                                // Refresh SharedPreferences to ensure hasEnteredPhoneNumber is persisted
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                bool phoneNumberEntered =
                                    prefs.getBool('has_entered_phone_number') ??
                                        false;

                                if (phoneNumberEntered) {
                                  if (cartItems.isNotEmpty) {
                                    // final cartItem = cartItems[0];
                                    // final isOpen = isStoreOpenByWorkingHours(
                                    //     cartItem.workingHours, cartItem.isOpen);
                                    // print(
                                    //     "🏪 Cart Check - Store: ${cartItem.storeName}, Working Hours: ${cartItem.workingHours}, IsOpen: $isOpen");
                                    // if (!isOpen) {
                                    //   Fluttertoast.showToast(
                                    //       msg:
                                    //           "المطعم مغلق حاليا، لا يمكنك الشراء الآن",
                                    //       timeInSecForIosWeb: 3);
                                    //   return;
                                    // }
                                  } else {
                                    // final packageCartItem = packageCartItems[0];
                                    // final isOpen = isStoreOpenByWorkingHours(
                                    //     packageCartItem.workingHours,
                                    //     packageCartItem.isOpen);
                                    // print(
                                    //     "📦 Package Check - Store: ${packageCartItem.storeName}, Working Hours: ${packageCartItem.workingHours}, IsOpen: $isOpen");
                                    // if (!isOpen) {
                                    //   // Show a message if the store is closed
                                    //   Fluttertoast.showToast(
                                    //       msg:
                                    //           "المطعم مغلق حاليا، لا يمكنك الشراء الآن",
                                    //       timeInSecForIosWeb: 3);
                                    //   return;
                                    // }
                                  }

                                  pushWithoutNavBar(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BuyNow(
                                          total: total,
                                          noDelivery: widget.noDelivery,
                                          ramadanTime: widget.ramadanTime,
                                          deliveryPrice: double.parse(
                                              cartItems.isNotEmpty
                                                  ? cartItems[0]
                                                      .storeDeliveryPrice
                                                      .trim()
                                                  : packageCartItems[0]
                                                      .storeDeliveryPrice
                                                      .trim()),
                                        ),
                                      ));
                                } else {
                                  // If verification returned true but flag not set, show error
                                  Fluttertoast.showToast(
                                      msg:
                                          "حدث خطأ في حفظ بيانات التحقق، يرجى المحاولة مرة أخرى",
                                      timeInSecForIosWeb: 3);
                                }
                              }
                            } else {
                              // User already verified before, proceed with store check
                              if (cartItems.isNotEmpty) {
                                // final cartItem = cartItems[0];
                                // final isOpen = isStoreOpenByWorkingHours(
                                //     cartItem.workingHours, cartItem.isOpen);
                                // print(
                                //     "🏪 Verified User - Store: ${cartItem.storeName}, Working Hours: ${cartItem.workingHours}, IsOpen: $isOpen");
                                // if (!isOpen) {
                                //   Fluttertoast.showToast(
                                //       msg:
                                //           "المطعم مغلق حاليا، لا يمكنك الشراء الآن",
                                //       timeInSecForIosWeb: 3);
                                //   return;
                                // }
                              } else {
                                // final packageCartItem = packageCartItems[0];
                                // final isOpen = isStoreOpenByWorkingHours(
                                //     packageCartItem.workingHours,
                                //     packageCartItem.isOpen);
                                // print(
                                //     "📦 Verified User - Store: ${packageCartItem.storeName}, Working Hours: ${packageCartItem.workingHours}, IsOpen: $isOpen");
                                // if (!isOpen) {
                                //   Fluttertoast.showToast(
                                //       msg:
                                //           "المطعم مغلق حاليا، لا يمكنك الشراء الآن",
                                //       timeInSecForIosWeb: 3);
                                //   return;
                                // }
                              }

                              pushWithoutNavBar(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BuyNow(
                                      total: total,
                                      noDelivery: widget.noDelivery,
                                      ramadanTime: widget.ramadanTime,
                                      deliveryPrice: double.parse(
                                          cartItems.isNotEmpty
                                              ? cartItems[0]
                                                  .storeDeliveryPrice
                                                  .trim()
                                              : packageCartItems[0]
                                                  .storeDeliveryPrice
                                                  .trim()),
                                    ),
                                  ));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 70),
                            child: Container(
                              width: double.infinity,
                              height: 40,
                              child: Center(
                                child: Text(
                                  "تابع عملية الشراء",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16),
                                ),
                              ),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: mainColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  bool isStoreOpen(String workingHoursJson, bool isOpen) {
    try {
      final now = DateTime.now();

      // Get current day name
      final List<String> dayNames = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ];
      final String currentDay = dayNames[now.weekday - 1];

      // Parse working hours from JSON
      List<dynamic> workingHours = [];
      try {
        workingHours = jsonDecode(workingHoursJson);
      } catch (e) {
        print('Error parsing working hours: $e');
        print('⚠️ WARNING: Invalid working hours JSON, assuming open');
        return true; // Assume open if can't parse
      }

      // Find today's schedule
      final todaySchedule = workingHours.firstWhere(
        (schedule) => schedule['day'] == currentDay,
        orElse: () => null,
      );

      // If restaurant doesn't work today
      if (todaySchedule == null) {
        print('🚫 Restaurant doesn\'t work on $currentDay');
        return false;
      }

      // Use today's working hours
      String? openTimeStr = todaySchedule['start_time'];
      String? closeTimeStr = todaySchedule['end_time'];

      if (openTimeStr == null || closeTimeStr == null) {
        print('⚠️ WARNING: Invalid times in schedule');
        return false;
      }

      DateTime parseTime(String time, DateTime ref) {
        final parts = time.split(':');
        return DateTime(
          ref.year,
          ref.month,
          ref.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      DateTime openTime = parseTime(openTimeStr, now);
      DateTime closeTime = parseTime(closeTimeStr, now);

      if (closeTime.isBefore(openTime)) {
        closeTime = closeTime.add(const Duration(days: 1));
        if (now.isBefore(openTime)) {
          openTime = openTime.subtract(const Duration(days: 1));
        }
      }

      if (now.isAfter(closeTime)) {
        openTime = openTime.add(const Duration(days: 1));
        closeTime = closeTime.add(const Duration(days: 1));
      }

      // Check if within operating hours
      bool isWithinOperatingHours =
          now.isAfter(openTime) && now.isBefore(closeTime);

      // If within hours but backend says closed
      if (isWithinOperatingHours && !isOpen) {
        print('🚫 Restaurant is manually closed today');
        return false;
      }

      // Return backend's is_open status
      print('✅ Restaurant status: ${isOpen ? "OPEN" : "CLOSED"}');
      return isOpen;
    } catch (e, stackTrace) {
      print("❌ Error checking store status: $e");
      print("   StackTrace: $stackTrace");
      return false; // Assume closed on error for safety
    }
  }
}
