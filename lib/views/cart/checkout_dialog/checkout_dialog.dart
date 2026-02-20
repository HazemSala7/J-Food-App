import 'package:flutter/material.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:j_food_updated/component/button_widget/button_widget.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({super.key});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool editName = false;
  bool editPhone = false;

  @override
  void initState() {
    super.initState();
    setControllers();
  }

  Future<void> setControllers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? buy = prefs.getBool('buy') ?? false;
    if (buy) {
      String name = prefs.getString('name') ?? "";
      String phone = prefs.getString('phone') ?? "";
      setState(() {
        editName = false;
        editPhone = false;
        nameController.text = name;
        phoneController.text = phone;
      });
    } else {
      setState(() {
        editName = true;
        editPhone = true;
        nameController.clear();
        phoneController.clear();
      });
    }
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    if (value.length != 10) {
      return 'يجب أن يكون مجموع خانات الهاتف 10 أرقام';
    }
    if (!value.startsWith('05')) {
      return 'رقم الهاتف يجب ان يبدأ ب 05';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        width: double.maxFinite,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Material(
            child: Column(
              children: [
                Container(
                  height: 600,
                  width: double.infinity,
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                    ),
                  ], color: Colors.white),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "أسم المستخدم",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: mainColor),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  editName
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                              right: 15, left: 15, top: 5),
                                          child: Container(
                                            height: 50,
                                            width: double.infinity,
                                            child: TextField(
                                              controller: nameController,
                                              obscureText: false,
                                              keyboardType: TextInputType.name,
                                              decoration: InputDecoration(
                                                hintStyle:
                                                    TextStyle(fontSize: 12),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: mainColor,
                                                      width: 2.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      width: 2.0,
                                                      color: Color(0xffD6D3D3)),
                                                ),
                                                hintText: "أسم المستخدم",
                                              ),
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                              right: 15, left: 25),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                nameController.text,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                        255, 83, 83, 83),
                                                    fontSize: 20),
                                              ),
                                              IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      editName = true;
                                                    });
                                                  },
                                                  icon: Icon(Icons.edit))
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "رقم الهاتف",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: mainColor),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  editPhone
                                      ? Form(
                                          key: _formKey,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 15, left: 15, top: 5),
                                            child: Container(
                                              height: 50,
                                              width: double.infinity,
                                              child: TextFormField(
                                                controller: phoneController,
                                                keyboardType:
                                                    TextInputType.phone,
                                                decoration: InputDecoration(
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: mainColor,
                                                        width: 2.0),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        width: 2.0,
                                                        color:
                                                            Color(0xffD6D3D3)),
                                                  ),
                                                  hintStyle:
                                                      TextStyle(fontSize: 12),
                                                  hintText: "رقم الهاتف",
                                                ),
                                                validator: validatePhoneNumber,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                              right: 15, left: 25),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                phoneController.text,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                        255, 83, 83, 83),
                                                    fontSize: 20),
                                              ),
                                              IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      editPhone = true;
                                                    });
                                                  },
                                                  icon: Icon(Icons.edit))
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(right: 15, left: 15, top: 30),
                        child: ButtonWidget(
                          name: "تأكيد عملية الشراء",
                          height: 50,
                          width: double.infinity,
                          BorderColor: mainColor,
                          OnClickFunction: () async {
                            if (_formKey.currentState!.validate()) {
                              // Save the updated data to SharedPreferences
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setString('name', nameController.text);
                              await prefs.setString('phone', phoneController.text);
                              Fluttertoast.showToast(msg: "تم تأكيد عملية الشراء بنجاح");
                              Navigator.pop(context);
                            }
                          },
                          BorderRaduis: 4,
                          ButtonColor: mainColor,
                          NameColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
