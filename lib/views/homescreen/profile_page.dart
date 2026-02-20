import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:j_food_updated/views/cart/verification_code/verification_code.dart';
import 'package:j_food_updated/views/favorite/favorite_screen.dart';
import 'package:j_food_updated/views/homescreen/homescreen.dart';
import 'package:j_food_updated/views/orders_screen/orders_screen.dart';
import 'package:j_food_updated/views/resturant_page/restaurant_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:lottie/lottie.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final bool noDelivery;
  final bool appHasError;
  final Function(int) changeTab;
  ProfilePage(
      {super.key,
      required this.noDelivery,
      required this.changeTab,
      required this.appHasError});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "";
  String phoneNumber = "";
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool loading = false;
  String? userId;
  String myToken = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadData();
    getToken();
  }

  Future<void> getToken() async {
    try {
      myToken = (await FirebaseMessaging.instance.getToken())!;

      print("FCM Token: $myToken");
    } catch (e) {
      print("Error getting token: $e");
    }
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? '';
      userId = prefs.getString('user_id') ?? '';
      phoneNumber = prefs.getString('phone_number') ?? '';
      phoneController.text = prefs.getString('restaurant_phone') ?? "";
      passwordController.text = prefs.getString('restaurant_password') ?? "";
    });
  }

  Widget build(BuildContext context) {
    return Container(
      color: fourthColor,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: fourthColor,
          body: Stack(children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0, left: 8, top: 25),
              child: Container(
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Visibility(
                        visible: userName != "",
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 25.0, top: 15, left: 25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${userName}",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: mainColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${phoneNumber}",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: mainColor,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: userName != "",
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 15.0, top: 15, left: 15),
                          child: Card(
                            elevation: 3,
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IgnorePointer(
                                  ignoring: widget.appHasError,
                                  child: InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.white,
                                        isScrollControlled: true,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                        ),
                                        builder: (context) {
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              left: 16.0,
                                              right: 16.0,
                                              top: 16.0,
                                              bottom: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom,
                                            ),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "ادخل اسم المستخدم",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 16),
                                                  Container(
                                                    height: 40,
                                                    width: double.infinity,
                                                    child: TextField(
                                                      controller:
                                                          nameController,
                                                      obscureText: false,
                                                      decoration:
                                                          InputDecoration(
                                                        hintStyle: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xffD0D0D0),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              BorderSide(
                                                                  color:
                                                                      mainColor,
                                                                  width: 2.0),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              BorderSide(
                                                            width: 2.0,
                                                            color: Color(
                                                                0xffD0D0D0),
                                                          ),
                                                        ),
                                                        hintText:
                                                            "ادخل اسم المستخدم الجديد",
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  MaterialButton(
                                                    minWidth: 100,
                                                    height: 30,
                                                    color: mainColor,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                    onPressed: () async {
                                                      SharedPreferences prefs =
                                                          await SharedPreferences
                                                              .getInstance();
                                                      prefs.setString('name',
                                                          nameController.text);
                                                      loadData();
                                                      nameController.text = "";
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text(
                                                      "حفظ",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                  SizedBox(height: 12),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "تغيير اسم المستخدم",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: textColor,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: mainColor,
                                            size: 15,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  ignoring: widget
                                      .appHasError, // Prevents interaction when error exists
                                  child: InkWell(
                                    onTap: () async {
                                      if (widget.appHasError)
                                        return; // Additional safeguard
                                      await showPhoneVerificationBottomSheet(
                                          context, true);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "تغيير رقم الهاتف المدخل",
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: textColor,
                                                fontWeight: FontWeight.w400),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: mainColor,
                                            size: 15,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 15.0, top: 8, left: 15),
                        child: Card(
                          elevation: 3,
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IgnorePointer(
                                ignoring: widget.appHasError,
                                child: InkWell(
                                  onTap: () {
                                    pushWithoutNavBar(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OrdersScreen(),
                                        ));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: mainColor),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Image.asset(
                                                  'assets/images/history.png',
                                                  width: 15,
                                                  height: 15,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              "طلباتي السابقة",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: mainColor,
                                          size: 15,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                ignoring: widget.appHasError,
                                child: InkWell(
                                  onTap: () {
                                    pushWithoutNavBar(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FavoriteScreen(
                                            noDelivery: widget.noDelivery,
                                            changeTab: widget.changeTab,
                                          ),
                                        ));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: mainColor),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Image.asset(
                                                  'assets/images/fav.png',
                                                  width: 15,
                                                  height: 15,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              "المطاعم المفضلة",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: mainColor,
                                          size: 15,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 15.0, top: 5, left: 15),
                        child: Card(
                          elevation: 3,
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.white,
                                    isScrollControlled: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    builder: (context) {
                                      return StatefulBuilder(
                                          builder: (context, setModalState) {
                                        return Stack(children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: 16.0,
                                              right: 16.0,
                                              top: 16.0,
                                              bottom: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom,
                                            ),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "تسجيل الدخول كمطعم",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      Text(
                                                        "رقم الهاتف",
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Color(
                                                                0xff666666),
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      )
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Container(
                                                    height: 40,
                                                    width: double.infinity,
                                                    child: TextField(
                                                      controller:
                                                          phoneController,
                                                      obscureText: false,
                                                      keyboardType:
                                                          TextInputType.phone,
                                                      decoration:
                                                          InputDecoration(
                                                        hintStyle: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xffD0D0D0),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              BorderSide(
                                                                  color:
                                                                      mainColor,
                                                                  width: 2.0),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              BorderSide(
                                                            width: 2.0,
                                                            color: Color(
                                                                0xffD0D0D0),
                                                          ),
                                                        ),
                                                        hintText:
                                                            "ادخل رقم الهاتف",
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      Text(
                                                        "كلمة المرور",
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Color(
                                                                0xff666666),
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      )
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Container(
                                                    height: 40,
                                                    width: double.infinity,
                                                    child: TextField(
                                                      controller:
                                                          passwordController,
                                                      obscureText: false,
                                                      decoration:
                                                          InputDecoration(
                                                        hintStyle: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xffD0D0D0),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              BorderSide(
                                                                  color:
                                                                      mainColor,
                                                                  width: 2.0),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              BorderSide(
                                                            width: 2.0,
                                                            color: Color(
                                                                0xffD0D0D0),
                                                          ),
                                                        ),
                                                        hintText:
                                                            "ادخل كلمة المرور",
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  MaterialButton(
                                                    minWidth: 100,
                                                    height: 30,
                                                    color: mainColor,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                    onPressed: () {
                                                      login(setModalState);
                                                    },
                                                    child: Text(
                                                      "تسجيل الدخول كمطعم",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                  SizedBox(height: 12),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (loading)
                                            Positioned.fill(
                                              child: Container(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          color: mainColor),
                                                ),
                                              ),
                                            ),
                                        ]);
                                      });
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: mainColor),
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: Icon(
                                                    Icons.login_rounded,
                                                    color: Colors.white,
                                                    size: 15,
                                                  )),
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            Expanded(
                                              child: Text(
                                                "تسجيل الدخول كمطعم",
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: textColor,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: mainColor,
                                        size: 15,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                ignoring: widget.appHasError,
                                child: InkWell(
                                  onTap: () {
                                    Fluttertoast.showToast(
                                        msg: "هذه الصفحة غير متوفرة الان");
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: mainColor),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: Image.asset(
                                                    'assets/images/add-user.png',
                                                    width: 15,
                                                    height: 15,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  "طلب انشاء حساب مطعم",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w400),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: mainColor,
                                          size: 15,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 15.0, top: 5, left: 15),
                        child: Card(
                          elevation: 3,
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IgnorePointer(
                                ignoring: widget.appHasError,
                                child: InkWell(
                                  onTap: () {
                                    Fluttertoast.showToast(
                                        msg: "هذه الصفحة غير متوفرة الان");
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "نقاطي",
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: textColor,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: mainColor,
                                          size: 15,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: widget.appHasError,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 15.0, top: 5, left: 15),
                          child: Card(
                            elevation: 3,
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IgnorePointer(
                                  ignoring: widget.appHasError,
                                  child: InkWell(
                                    onTap: () {
                                      Fluttertoast.showToast(
                                          msg: "هذه الصفحة غير متوفرة الان");
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "فيديوهات مساعدة",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: mainColor,
                                            size: 15,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  ignoring: widget.appHasError,
                                  child: InkWell(
                                    onTap: () {
                                      Fluttertoast.showToast(
                                          msg: "هذه الصفحة غير متوفرة الان");
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "الأسئلة المتكررة",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: mainColor,
                                            size: 15,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 15.0, top: 5, left: 15),
                        child: Card(
                          elevation: 3,
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IgnorePointer(
                                ignoring: widget.appHasError,
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
                                    } catch (e) {
                                      Fluttertoast.showToast(
                                          msg: "لم يتم تنزيل الواتساب");
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "اتصل بنا",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: textColor,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: mainColor,
                                          size: 15,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                ignoring: widget.appHasError,
                                child: InkWell(
                                  onTap: () {
                                    Fluttertoast.showToast(
                                        msg: "هذه الصفحة غير متوفرة الان");
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "سياسة الخصوصية والأمان",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: textColor,
                                                fontWeight: FontWeight.w400),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: mainColor,
                                          size: 15,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: userId != "",
                                child: IgnorePointer(
                                  ignoring: widget.appHasError,
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: Colors.white,
                                            content: Text(
                                              "هل تريد بالتأكيد حذف الحساب؟",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                            actions: <Widget>[
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  InkWell(
                                                    onTap: () async {
                                                      Navigator.pop(context);
                                                      _deleteUser(
                                                          context, userId!);
                                                    },
                                                    child: Container(
                                                      height: 40,
                                                      width: 55,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color: mainColor,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "نعم",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 13,
                                                              color:
                                                                  Colors.white),
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
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color: mainColor,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "لا",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 13,
                                                              color:
                                                                  Colors.white),
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
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "حذف الحساب",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: textColor,
                                                fontWeight: FontWeight.w400),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: mainColor,
                                            size: 15,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

  Future<void> login(Function setModalState) async {
    setModalState(() {
      loading = true;
    });
    final response = await http.post(
      Uri.parse(AppLink.login),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'phone': phoneController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final roleId = responseData['user']['role_id'];
        print(roleId);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (roleId == 2) {
          await prefs.setString(
              'user_id', responseData['user']['id'].toString());
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  fromOrderConfirm: false,
                ),
              ),
              (route) => false);
        } else {
          final restaurantId = responseData['restaurent']['id'];
          final userId = responseData['user']['id'];
          final categoryId = responseData['restaurent']['category_id'];
          final status = responseData['restaurent']['active'];
          final restaurantName = responseData['restaurent']['name'];
          final restaurantImage = responseData['restaurent']['image'];
          final restaurantAddress = responseData['restaurent']['address'];
          final delivery_price = responseData['restaurent']['delivery_price'];
          final storeCloseTime = responseData['restaurent']['close_time'];
          final storeOpenTime = responseData['restaurent']['open_time'];
          final List subCategories = responseData['sub_categories'] ?? [];
          final String subCategoriesJson = jsonEncode(subCategories);
          if (responseData['user']['fcm_token'] == null ||
              responseData['user']['fcm_token'] != myToken) {
            print(responseData['user']['fcm_token']);
            // Only send token to server if it's not empty
            if (myToken.isNotEmpty) {
              await sendTokenToServer(myToken, responseData['access_token']);
            }
          }
          print("---");
          await prefs.setString('sub_categories', subCategoriesJson);
          await prefs.setBool('sign_in', true);
          await prefs.setString('restaurant_id', restaurantId.toString());
          await prefs.setString('restaurant_user_id', userId.toString());
          await prefs.setString('restaurant_name', restaurantName);
          await prefs.setString('restaurant_image', restaurantImage);
          await prefs.setString('restaurant_phone', phoneController.text);
          await prefs.setString('restaurant_password', passwordController.text);
          await prefs.setString('delivery_price', delivery_price);
          await prefs.setString('storeOpenTime', storeOpenTime);
          await prefs.setString('storeCloseTime', storeCloseTime);
          await prefs.setString('restaurant_address', restaurantAddress);
          await prefs.setString('category_id', categoryId.toString());
          await prefs.setString('password', passwordController.text);
          await prefs.setString('phone', phoneController.text);
          await prefs.setString('status', status);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => RestaurantPage(
                  storeId: restaurantId.toString(),
                  userId: userId.toString(),
                  categoryId: categoryId.toString(),
                  status: status,
                  restaurantAddress: restaurantAddress,
                  deliveryPrice: delivery_price,
                  storeCloseTime: storeCloseTime,
                  storeOpenTime: storeOpenTime,
                  restaurantImage: restaurantImage,
                  restaurantName: restaurantName),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        setModalState(() {
          loading = false;
        });
        _showAccountErrorDialog(context);
      }
    } else {
      setModalState(() {
        loading = false;
      });
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'خطأ',
              style: TextStyle(fontSize: 18),
            ),
            content: Text('رقم الهاتف خاطئ او كلمة المرور غير صحيحة'),
            actions: [
              MaterialButton(
                color: Colors.green,
                onPressed: () {
                  Navigator.of(context).pop();
                  passwordController.text = "";
                  phoneController.text = "";
                },
                child: Text(
                  'حسنا',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _showAccountErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'مشكلة في الحساب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'عذرًا، يوجد مشكلة مع بيانات حسابك. يرجى التواصل مع الدعم الفني للمساعدة.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                color: mainColor,
                height: 45,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  phoneController.text = "";
                  passwordController.text = "";
                },
                child: Text(
                  'حسنًا',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendTokenToServer(String token, String barrierToken) async {
    // Don't send if token is null or empty
    if (token.isEmpty) {
      print("FCM token is empty, skipping token send.");
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

        Fluttertoast.showToast(msg: "تمت عملية الحذف بنجاح");

        setState(() {
          isLoading = false;
        });

        widget.changeTab?.call(0);
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
