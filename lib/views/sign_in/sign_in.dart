import 'dart:convert';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:j_food_updated/views/homescreen/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class signIn extends StatefulWidget {
  const signIn({super.key});

  @override
  State<signIn> createState() => _signInState();
}

class _signInState extends State<signIn> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool loading = false;
  String password = "";
  String phone = "";
  Future<void> login() async {
    setState(() {
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

    setState(() {
      loading = false;
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      final roleId = responseData['user']['role_id'];
      print(roleId);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (roleId == 2) {
        await prefs.setString('user_id', responseData['user']['id'].toString());
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(fromOrderConfirm: false,),
            ),
            (route) => false);
      } else {
        final restaurantId = responseData['restaurent']['id'];
        final categoryId = responseData['restaurent']['category_id'];
        final status = responseData['restaurent']['active'];
        final restaurantName = responseData['restaurent']['name'];
        final List subCategories = responseData['sub_categories'] ?? [];
        final String subCategoriesJson = jsonEncode(subCategories);
        await prefs.setString('sub_categories', subCategoriesJson);
        await prefs.setBool('sign_in', true);
        await prefs.setString('restaurant_id', restaurantId.toString());
        await prefs.setString('restaurant_name', restaurantName);
        await prefs.setString('category_id', categoryId.toString());
        await prefs.setString('password', passwordController.text);
        await prefs.setString('phone', phoneController.text);
        await prefs.setString('status', status);
        // Navigator.of(context).push(MaterialPageRoute(
        //   builder: (context) => RestaurantPage(
        //       storeId: restaurantId.toString(),
        //       categoryId: categoryId.toString(),
        //       status: status,
        //       restaurantName: restaurantName),
        // ));
      }
    } else {
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

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      password = prefs.getString('password') ?? "";
      phone = prefs.getString('phone') ?? "";
      phoneController.text = phone;
      passwordController.text = password;
    });

    return;
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: mainColor,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: mainColor,
          body: Center(
            child: loading
                ? CircularProgressIndicator(backgroundColor: Colors.white)
                : SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04),
                        Text(
                          'أهلا و سهلا بكم في تطبيق J-Food',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.60,
                          height: MediaQuery.of(context).size.width * 0.60,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("assets/images/logo.png"),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  right: 25, left: 25, top: 5),
                              child: Container(
                                height: 50,
                                width: double.infinity,
                                child: TextField(
                                  style: TextStyle(color: Colors.white),
                                  controller: phoneController,
                                  obscureText: false,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.phone,
                                      color: Color(0xff428fc6),
                                    ),
                                    fillColor: Colors.white,
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(40),
                                      borderSide: BorderSide(
                                          color: Colors.white, width: 2.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(40),
                                      borderSide: BorderSide(
                                          width: 2.0, color: Colors.white),
                                    ),
                                    hintText: "رقم الهاتف",
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  right: 25, left: 25, top: 5),
                              child: Container(
                                height: 50,
                                width: double.infinity,
                                child: TextField(
                                  controller: passwordController,
                                  obscureText: false,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.password,
                                      color: Colors.white,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(40),
                                      borderSide: BorderSide(
                                          color: Colors.white, width: 2.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(40),
                                      borderSide: BorderSide(
                                          width: 2.0, color: Colors.white),
                                    ),
                                    hintText: "كلمة المرور",
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04),
                        MaterialButton(
                          onPressed: login,
                          color: Colors.black,
                          textColor: Colors.white,
                          minWidth: MediaQuery.of(context).size.width * 0.5,
                          height: MediaQuery.of(context).size.width * 0.12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "تسجيل الدخول",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01),
                        MaterialButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "الرجوع الى الشاشة الرئيسية",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w200,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
