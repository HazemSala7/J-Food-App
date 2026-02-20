import 'dart:async';
import 'dart:io';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/notifications/notification_service.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:j_food_updated/server/functions/functions.dart';
import 'package:j_food_updated/views/homescreen/custom_upgrader/custom_upgrader.dart';
import 'package:j_food_updated/views/homescreen/homescreen.dart';
import 'package:j_food_updated/views/resturant_page/add_external_order.dart';
import 'package:j_food_updated/views/resturant_page/add_food.dart';
import 'package:j_food_updated/views/resturant_page/add_box.dart';
import 'package:j_food_updated/views/resturant_page/add_story.dart';
import 'package:j_food_updated/views/resturant_page/order_page.dart';
import 'package:j_food_updated/views/resturant_page/order_provider/store_detail_provider.dart';
import 'package:j_food_updated/views/resturant_page/products_page.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_update_dialog/flutter_update_dialog.dart';

class RestaurantPage extends StatefulWidget {
  final String storeId;
  final String userId;
  final String categoryId;
  final String status;
  final String restaurantName;
  final String storeCloseTime;
  final String storeOpenTime;
  final String restaurantImage;
  final String restaurantAddress;
  final String deliveryPrice;
  const RestaurantPage({
    Key? key,
    required this.storeId,
    required this.categoryId,
    required this.status,
    required this.restaurantName,
    required this.restaurantImage,
    required this.restaurantAddress,
    required this.deliveryPrice,
    required this.userId,
    required this.storeCloseTime,
    required this.storeOpenTime,
  }) : super(key: key);

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  bool status = false;
  int selectedTabIndex = 0;
  final ValueNotifier<bool> pendingPage = ValueNotifier<bool>(false);
  final ScrollController _productsScrollController = ScrollController();
  final ScrollController _ordersScrollController = ScrollController();
  bool isLoading = false;
  UpdateDialog? dialog;

  @override
  void initState() {
    super.initState();
    status = widget.status == "true" ? true : false;
    checkForUpdate();
    print(widget.storeId);
    final provider = Provider.of<StoreDetailsProvider>(context, listen: false);
    provider.fetchStoreDetails(widget.storeId);

    // setupLocalNotification();
    // fetchStoreDetails();
  }

  void checkForUpdate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();

    // Set first_open_time once
    if (!prefs.containsKey('first_open_time')) {
      prefs.setString('first_open_time', now.toIso8601String());
    }

    const optionalDuration = Duration(days: 3);

    final firstOpenTimeStr = prefs.getString('first_open_time');
    DateTime firstOpenTime = DateTime.tryParse(firstOpenTimeStr ?? '') ?? now;

    final response = await getUpdateStatus();
    bool updateRequired = response['update_required'] ?? false;

    if (updateRequired) {
      final timeSinceFirstOpen = now.difference(firstOpenTime);

      final isWithinOptionalPeriod = timeSinceFirstOpen < optionalDuration;

      final remaining = optionalDuration - timeSinceFirstOpen;

      showUpdateDialog(
        force: !isWithinOptionalPeriod,
        remainingDuration: isWithinOptionalPeriod ? remaining : Duration.zero,
      );
    }
  }

  void showUpdateDialog(
      {required bool force, Duration? remainingDuration}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (dialog != null && dialog!.isShowing()) return;

    dialog = UpdateDialog.showUpdate(
      context,
      width: 300,
      title: "التحديث مطلوب",
      updateContent:
          'تتوفر نسخة جديدة من التطبيق.\nيرجى التحديث لمواصلة استخدام التطبيق.${!force ? "\nبعد 3 ايام سيصبح التحديث اجباري" : ""}',
      titleTextSize: 16,
      contentTextSize: 14,
      buttonTextSize: 14,
      topImage: Image.asset('assets/images/update.png', fit: BoxFit.cover),
      extraHeight: 10,
      radius: 12,
      themeColor: mainColor,
      progressBackgroundColor: Color(0x55808080),
      isForce: true,
      updateButtonText: "التحديث الان",
      ignoreButtonText: "لاحقا",
      enableIgnore: !force,
      onIgnore: () async {
        prefs.setString(
          'last_skipped_update',
          DateTime.now().toIso8601String(),
        );
        await Future.delayed(Duration(milliseconds: 100));
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      onUpdate: () async {
        final url = Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=j.food.com'
            : 'https://apps.apple.com/app/id6538722890';

        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          print('Could not launch update URL');
        }
      },
    );
  }

  Future<Map<String, dynamic>> getUpdateStatus() async {
    String version = "3";

    final response = await http.post(
      Uri.parse(AppLink.CheckVersion),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'app_version': version,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Update check failed: ${response.statusCode} - ${response.body}");
      return {
        "update_required": false,
        "latest_version": version,
        "your_version": version,
      };
    }
  }

  // Future<void> fetchStoreDetails() async {
  //   try {
  //     await getStoreDetails(widget.storeId);
  //   } catch (e) {
  //     print("Error fetching store details: $e");
  //   }
  // }

  void updateRestaurantStatus(bool status) async {
    final response = await http.post(
      Uri.parse('https://hrsps.com/login/api/update_restaurent_status'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'restaurent_id': widget.storeId,
        'active': status.toString(),
      }),
    );
    print(widget.storeId);
    if (response.statusCode == 200) {
      // Handle successful response
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('status', status.toString());
      print('Status updated successfully');
    } else {
      // Handle error response
      print('Failed to update status');
    }
  }

  void changePendingPage() {
    pendingPage.value = !pendingPage.value;
    print(pendingPage.value);
  }

  @override
  void dispose() {
    _ordersScrollController.dispose();
    _productsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fourthColor,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: fourthColor,
          body: Stack(children: [
            ValueListenableBuilder<bool>(
              valueListenable: pendingPage,
              builder: (context, pendingPage, _) {
                return SingleChildScrollView(
                  controller: selectedTabIndex == 0
                      ? _productsScrollController
                      : _ordersScrollController,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: 35,
                        ),
                        child: Container(
                          // height: 130,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(25),
                              top: Radius.circular(4),
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: -45,
                                left: (MediaQuery.of(context).size.width / 2) -
                                    70,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(
                                      MaterialPageRoute(
                                        builder: (context) => AddStory(
                                          isEditing: false,
                                          categoryId: widget.categoryId,
                                          userId: widget.userId,
                                          restaurantId: widget.storeId,
                                          deliveryPrice: widget.deliveryPrice,
                                          storeCloseTime: widget.storeCloseTime,
                                          storeOpenTime: widget.storeOpenTime,
                                          restaurantAddress:
                                              widget.restaurantAddress,
                                          restaurantName: widget.restaurantName,
                                          restaurantImage:
                                              widget.restaurantImage,
                                          status: widget.status,
                                        ),
                                      ),
                                    )
                                        .then((result) {
                                      if (result == true) {
                                        setState(() {});
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [
                                          Color(0xFFF58529),
                                          Color(0xFFDD2A7B),
                                          Color(0xFF8134AF),
                                          Color(0xFF515BD4),
                                          Color(0xFFF58529),
                                        ],
                                        startAngle: 0.0,
                                        endAngle: 3.14 * 2,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: CircleAvatar(
                                        radius: 45,
                                        backgroundColor: Colors.white,
                                        child: ClipOval(
                                          child: Image.network(
                                            widget.restaurantImage,
                                            fit: BoxFit.cover,
                                            width: 80,
                                            height: 80,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.asset(
                                                "assets/images/logo2.png",
                                                fit: BoxFit.cover,
                                                width: 80,
                                                height: 80,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                // mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Row for icons
                                  buildIconsRow(),
                                  const SizedBox(height: 27),
                                  Text(
                                    widget.restaurantName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff323232),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: secondColor, width: 1),
                                            borderRadius:
                                                BorderRadius.circular(100)),
                                        child: Icon(
                                          Icons.location_on,
                                          color: secondColor,
                                          size: 18,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Text(
                                          widget.restaurantAddress,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Colors.black.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 10.0, right: 10, top: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(25),
                            ),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              // Visibility(
                              //   visible: !pendingPage,
                              //   child: Padding(
                              //     padding: const EdgeInsets.symmetric(
                              //         horizontal: 20),
                              //     child: Card(
                              //         color: Colors.white,
                              //         elevation: 3,
                              //         child: Padding(
                              //           padding: const EdgeInsets.all(8.0),
                              //           child: Row(
                              //             mainAxisAlignment:
                              //                 MainAxisAlignment.spaceBetween,
                              //             children: [
                              //               Text("حالة المطعم",
                              //                   style: TextStyle(
                              //                       fontWeight: FontWeight.bold,
                              //                       color: Colors.black
                              //                           .withOpacity(0.8),
                              //                       fontSize: 18)),
                              //               Stack(
                              //                   alignment: Alignment.center,
                              //                   children: [
                              //                     FlutterSwitch(
                              //                       width: 65.0,
                              //                       height: 25.0,
                              //                       toggleSize: 20.0,
                              //                       borderRadius: 15.0,
                              //                       activeColor: mainColor,
                              //                       inactiveColor:
                              //                           Color(0xffB1B1B1),
                              //                       value: status,
                              //                       onToggle: (val) {
                              //                         setState(() {
                              //                           status = val;
                              //                         });
                              //                         updateRestaurantStatus(
                              //                             val);
                              //                       },
                              //                     ),
                              //                     Positioned(
                              //                       left: status ? 5 : 30,
                              //                       top: 5,
                              //                       child: Text(
                              //                         status ? "مفتوح" : "مغلق",
                              //                         style: TextStyle(
                              //                             color: Colors.white,
                              //                             fontWeight:
                              //                                 FontWeight.bold,
                              //                             fontSize: 12),
                              //                       ),
                              //                     ),
                              //                   ]),
                              //             ],
                              //           ),
                              //         )),
                              //   ),
                              // ),
                              Visibility(
                                visible: !pendingPage,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 34.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedTabIndex = 0;
                                            });
                                          },
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: selectedTabIndex == 0
                                                      ? mainColor
                                                      : Color(0xffB1B1B1),
                                                  width: selectedTabIndex == 0
                                                      ? 2
                                                      : 1,
                                                ),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "منتجاتي",
                                                style: TextStyle(
                                                    color: selectedTabIndex == 0
                                                        ? mainColor
                                                        : Color(0xffB1B1B1),
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedTabIndex = 1;
                                            });
                                          },
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: selectedTabIndex == 1
                                                      ? mainColor
                                                      : Color(0xffB1B1B1),
                                                  width: selectedTabIndex == 1
                                                      ? 2
                                                      : 1.0,
                                                ),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "طلبياتي",
                                                style: TextStyle(
                                                    color: selectedTabIndex == 1
                                                        ? mainColor
                                                        : Color(0xffB1B1B1),
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Stack(
                                children: [
                                  Offstage(
                                    offstage: selectedTabIndex != 0,
                                    child: ProductsPage(
                                      storeId: widget.storeId,
                                      categoryId: widget.categoryId,
                                      userId: widget.userId,
                                      deliveryPrice: widget.deliveryPrice,
                                      restaurantAddress:
                                          widget.restaurantAddress,
                                      restaurantName: widget.restaurantName,
                                      storeCloseTime: widget.storeCloseTime,
                                      storeOpenTime: widget.storeOpenTime,
                                      restaurantImage: widget.restaurantImage,
                                      status: widget.status,
                                      scrollController:
                                          _productsScrollController,
                                    ),
                                  ),
                                  Offstage(
                                    offstage: selectedTabIndex != 1,
                                    child: OrderPage(
                                      changePendingPage: changePendingPage,
                                      storeId: widget.storeId,
                                      categoryId: widget.categoryId,
                                      storeImage: widget.restaurantImage,
                                      storeLocation: widget.restaurantAddress,
                                      storeName: widget.restaurantName,
                                      deliveryPrice: widget.deliveryPrice,
                                      scrollController: _ordersScrollController,
                                      storeOpenTime: widget.storeOpenTime,
                                      storeCloseTime: widget.storeCloseTime,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text(
                          "جاري حذف الحساب...",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget buildIconsRow() {
    final storeProvider = Provider.of<StoreDetailsProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildImageButton('assets/images/resturant-logout.png', () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('sign_in', false);
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                      fromOrderConfirm: false,
                    ),
                  ),
                  (route) => false);
            }),
            SizedBox(
              width: 7,
            ),
            _buildImageButton('assets/images/whatsapp.png', () async {
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
            }),
            SizedBox(
              width: 7,
            ),
            _buildImageButton('assets/images/delete.png', () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    content: Text(
                      "هل تريد بالتأكيد حذف الحساب؟",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    actions: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                            onTap: () async {
                              _deleteUser(context, widget.userId);
                            },
                            child: Container(
                              height: 40,
                              width: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: mainColor,
                              ),
                              child: Center(
                                child: Text(
                                  "نعم",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 40,
                              width: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: mainColor,
                              ),
                              child: Center(
                                child: Text(
                                  "لا",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            }),
          ],
        ),
        Row(
          children: [
            Visibility(
              visible: storeProvider.canMakeOrder ?? false,
              child: _buildImageButton('assets/images/resturant-add.png', () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ExternalOrder(
                          restaurantId: widget.storeId,
                        )));
              }),
            ),
            SizedBox(
              width: 5,
            ),
            _buildImageButton('assets/images/add.png', () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => AddBox(
                    isEditing: false,
                    categoryId: widget.categoryId,
                    userId: widget.userId,
                    restaurantId: widget.storeId,
                    deliveryPrice: widget.deliveryPrice,
                    restaurantAddress: widget.restaurantAddress,
                    restaurantName: widget.restaurantName,
                    storeCloseTime: widget.storeCloseTime,
                    storeOpenTime: widget.storeOpenTime,
                    restaurantImage: widget.restaurantImage,
                    status: widget.status,
                  ),
                ),
              )
                  .then((result) {
                if (result == true) {
                  setState(() {});
                }
              });
            }),
            SizedBox(
              width: 5,
            ),
            _buildImageButton('assets/images/+.png', () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => AddFood(
                    isEditing: false,
                    categoryId: widget.categoryId,
                    userId: widget.userId,
                    storeCloseTime: widget.storeCloseTime,
                    storeOpenTime: widget.storeOpenTime,
                    restaurantId: widget.storeId,
                    deliveryPrice: widget.deliveryPrice,
                    restaurantAddress: widget.restaurantAddress,
                    restaurantName: widget.restaurantName,
                    restaurantImage: widget.restaurantImage,
                    status: widget.status,
                  ),
                ),
              )
                  .then((result) {
                if (result == true) {
                  setState(() {});
                }
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildImageButton(String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: mainColor),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Image.asset(
            imagePath,
            width: 17,
            height: 17,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteUser(BuildContext context, String userId) async {
    if (!context.mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .delete(
            Uri.parse('${AppLink.delete}/$userId'),
          )
          .timeout(const Duration(seconds: 10));

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: "تمت عملية الحذف بنجاح");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => HomeScreen(
                    fromOrderConfirm: false,
                  )),
          (route) => false,
        );
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog(context, "حدث خطأ أثناء حذف الحساب. حاول مرة أخرى.");
      }
    } on TimeoutException {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog(context, "الخادم لا يستجيب. حاول مرة أخرى لاحقًا.");
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog(context, "تعذر الاتصال بالخادم.");
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("خطأ"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إغلاق"),
          ),
        ],
      ),
    );
  }
}
