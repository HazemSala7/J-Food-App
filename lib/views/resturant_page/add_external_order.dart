import 'dart:convert';

import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:http/http.dart' as http;

class ExternalOrder extends StatefulWidget {
  final String restaurantId;
  const ExternalOrder({super.key, required this.restaurantId});

  @override
  State<ExternalOrder> createState() => _ExternalOrderState();
}

class _ExternalOrderState extends State<ExternalOrder> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _nearController;
  late TextEditingController _moneyController;
  late TextEditingController _notesController;
  List<dynamic> areas = [];
  bool emptyArea = false;
  String? selectedArea;
  String? selectedAreaId;

  bool addLoading = false;
  bool nameField = false;
  bool nearField = false;
  bool phoneField = false;
  bool moneyField = false;
  double _sliderValue = 15;
  final List<int> _values = [15, 20, 25, 30, 35, 40];

  String convertArabicToEnglish(String text) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = text;
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _nearController = TextEditingController();
    _moneyController = TextEditingController();
    _notesController = TextEditingController();
    fetchAreas();
  }

  Future<void> sendOrderData() async {
    final url = Uri.parse('${AppLink.addOrderOut}');

    var request = http.MultipartRequest("POST", url);

    // Set headers if needed
    request.headers.addAll({
      'Content-Type': 'application/json',
    });

    // Add fields to the request
    request.fields['customer_name'] = _nameController.text;
    request.fields['city'] = selectedArea ?? "";
    request.fields['mobile'] = convertArabicToEnglish(_phoneController.text)
        .replaceAll(RegExp(r'[-_]'), '');
    request.fields['area_id'] = selectedAreaId.toString();
    request.fields['address'] = _nearController.text;
    request.fields['restaurant_id'] = widget.restaurantId.toString();
    request.fields['notes'] = _notesController.text;
    request.fields['total'] = convertArabicToEnglish(_moneyController.text);
    request.fields['preparation_time'] = _sliderValue.toString();

    print('Request Body: ${request.fields}');

    try {
      setState(() {
        addLoading = true;
      });

      // Send the request
      final response = await request.send();

      // Check the response status
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);

        Fluttertoast.showToast(
            msg: "تم اضافة الطلب الخارجي بنجاح", timeInSecForIosWeb: 3);
        Navigator.of(context).pop();
        print('Order submitted successfully: $data');
      } else {
        Fluttertoast.showToast(
            msg: "حدثت مشكلة اثناء اضافة الطلب", timeInSecForIosWeb: 3);
        print('Failed to submit order. Status code: ${response.statusCode}');
        print('Response: ${response.reasonPhrase}');
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "حدثت مشكلة اثناء اضافة الطلب", timeInSecForIosWeb: 3);
      print('Error occurred while submitting the order: $e');
    }

    setState(() {
      addLoading = false;
    });
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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fourthColor,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: fourthColor,
          body: Padding(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "اضافة طلب خارجي",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: mainColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "أسم الزبون",
                            style: TextStyle(
                                fontSize: 12,
                                color: textColor2,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      StatefulBuilder(builder:
                          (BuildContext context, StateSetter setState) {
                        return Container(
                          height: 30,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12)),
                          child: TextFormField(
                            controller: _nameController,
                            obscureText: false,
                            onTap: () {
                              setState(() {
                                nameField = false;
                              });
                            },
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    width: 1.0,
                                    color: !nameField
                                        ? Colors.black.withOpacity(0.8)
                                        : Colors.red,
                                  )),
                              hintText: "ادخل اسم الزبون",
                            ),
                          ),
                        );
                      }),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "رقم الهاتف",
                            style: TextStyle(
                                fontSize: 12,
                                color: textColor2,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      StatefulBuilder(builder:
                          (BuildContext context, StateSetter setState) {
                        return Container(
                          height: 30,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12)),
                          child: TextFormField(
                            controller: _phoneController,
                            obscureText: false,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9\-_]'))
                            ],
                            onTap: () {
                              setState(() {
                                phoneField = false;
                              });
                            },
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    width: 1.0,
                                    color: !phoneField
                                        ? Colors.black.withOpacity(0.8)
                                        : Colors.red,
                                  )),
                              hintText: "ادخل رقم الهاتف",
                            ),
                          ),
                        );
                      }),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "المنطقة",
                            style: TextStyle(
                                fontSize: 12,
                                color: textColor2,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color:
                                  emptyArea ? Colors.red : Color(0xffD0D0D0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedAreaId,
                          items: areas.map((area) {
                            return DropdownMenuItem<String>(
                              value: area['id'].toString(),
                              child: Text(
                                area['name'],
                                style: TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedAreaId = value;
                              selectedArea = areas.firstWhere(
                                (area) => area['id'].toString() == value,
                              )['name'];
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
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "بالقرب من",
                            style: TextStyle(
                                fontSize: 12,
                                color: textColor2,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      StatefulBuilder(builder:
                          (BuildContext context, StateSetter setState) {
                        return Container(
                          height: 30,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12)),
                          child: TextFormField(
                            controller: _nearController,
                            obscureText: false,
                            onTap: () {
                              setState(() {
                                nearField = false;
                              });
                            },
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    width: 1.0,
                                    color: !nearField
                                        ? Colors.black.withOpacity(0.8)
                                        : Colors.red,
                                  )),
                              hintText: "بالقرب من",
                            ),
                          ),
                        );
                      }),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "مبلغ التحصيل غير شامل التوصيل",
                            style: TextStyle(
                                fontSize: 12,
                                color: textColor2,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      StatefulBuilder(builder:
                          (BuildContext context, StateSetter setState) {
                        return Container(
                          height: 30,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: mainColor,
                              borderRadius: BorderRadius.circular(12)),
                          child: TextFormField(
                            controller: _moneyController,
                            obscureText: false,
                            onTap: () {
                              setState(() {
                                moneyField = false;
                              });
                            },
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9٠-٩]'))
                            ],
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 1.0,
                                  color: !moneyField
                                      ? Colors.transparent
                                      : Colors.red,
                                ),
                              ),
                              hintText: "المبلغ",
                            ),
                          ),
                        );
                      }),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "ملاحظات التوصيل",
                            style: TextStyle(
                                fontSize: 12,
                                color: textColor2,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      StatefulBuilder(builder:
                          (BuildContext context, StateSetter setState) {
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12)),
                          child: TextField(
                            controller: _notesController,
                            obscureText: false,
                            maxLines: 3,
                            minLines: null,
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    width: 1.0,
                                    color: Colors.black.withOpacity(0.8),
                                  )),
                              hintText: "ملاحظات التوصيل",
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 10),
                      Text(
                        "وقت تجهيز الطلب",
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Color(0xffEAEAEA),
                          inactiveTrackColor: Color(0xffEAEAEA),
                          trackHeight: 5,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10),
                          thumbColor: Color(0xffD9D9D9),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 20),
                        ),
                        child: Slider(
                          value: _sliderValue,
                          min: _values.first.toDouble(),
                          max: _values.last.toDouble(),
                          divisions: _values.length - 1,
                          onChanged: (value) {
                            setState(() {
                              _sliderValue = value;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _values.map((value) {
                            return Column(
                              children: [
                                Text(
                                  "|",
                                  style: TextStyle(color: mainColor),
                                ),
                                Text(
                                  value.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 45, vertical: 5),
                          child: MaterialButton(
                            onPressed: () {
                              if (_moneyController.text.isEmpty ||
                                  _nameController.text.isEmpty ||
                                  _phoneController.text.isEmpty ||
                                  selectedArea == null) {
                                if (_moneyController.text.isEmpty) {
                                  setState(() {
                                    moneyField = true;
                                  });
                                }
                                if (selectedArea == null) {
                                  setState(() {
                                    emptyArea = true;
                                  });
                                }

                                if (_nameController.text.isEmpty) {
                                  setState(() {
                                    nameField = true;
                                  });
                                }
                                if (_phoneController.text.isEmpty) {
                                  setState(() {
                                    phoneField = true;
                                  });
                                }

                                Fluttertoast.showToast(
                                    msg: "الرجاء تعبئة الحقول المطلوبة",
                                    timeInSecForIosWeb: 3);
                              } else {
                                sendOrderData();
                              }
                            },
                            child: addLoading
                                ? Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Text(
                                    'اضافه طلب',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            color: mainColor,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
