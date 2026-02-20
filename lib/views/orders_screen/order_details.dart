import 'package:j_food_updated/LocalDB/Models/CartItem.dart';
import 'package:j_food_updated/LocalDB/Provider/CartProvider.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UserOrderDetails extends StatefulWidget {
  final int orderId;
  final String status;
  final String checkoutType;
  const UserOrderDetails(
      {Key? key,
      required this.orderId,
      required this.status,
      required this.checkoutType})
      : super(key: key);

  @override
  _UserOrderDetailsState createState() => _UserOrderDetailsState();
}

class _UserOrderDetailsState extends State<UserOrderDetails> {
  Map<String, dynamic>? order;
  bool isLoading = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    print(widget.orderId);
    final url = Uri.parse(
        'https://hrsps.com/login/api/show-order-data/${widget.orderId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['order'];
        setState(() {
          order = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load order');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching order details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: mainColor,
      child: SafeArea(
        child: Scaffold(
          body: isLoading
              ? Center(child: CircularProgressIndicator())
              : order != null
                  ? buildOrderDetails()
                  : Center(child: Text('Order not found')),
        ),
      ),
    );
  }

  Widget buildOrderDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 15,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: mainColor,
                    border: Border.all(color: mainColor),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12))),
                child: RotatedBox(
                  quarterTurns: 3, // Rotate 90 degrees clockwise
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "تفاصيل المطعم",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
              ),
              Expanded(
                  child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FancyShimmerImage(
                          imageUrl: order!['restaurant']['image'],
                          width: 50,
                          height: 50,
                          errorWidget: Image.asset(
                            "assets/images/logo2.png",
                            width: 50,
                            height: 50,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: Text(
                          "${order!['restaurant']['name']}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  Container(
                    color: Color(0xffF8F8F8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: secondColor, width: 1),
                                    borderRadius: BorderRadius.circular(100)),
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
                                  "${order!['restaurant']['address']}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      TextStyle(color: textColor, fontSize: 12),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 7,
                          ),
                          widget.status == 'in_delivery' &&
                                      widget.checkoutType != "pickup" ||
                                  widget.status == 'ready_for_delivery' ||
                                  widget.status == 'in_progress' ||
                                  widget.status == 'pending'
                              ? phoneNumber()
                              : copyOrder(),
                        ],
                      ),
                    ),
                  )
                ],
              )),
              SizedBox(
                width: 30,
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: mainColor),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12))),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "تفاصيل الزبون",
                      style: TextStyle(
                          color: mainColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
              ),
              Expanded(
                  child: Column(
                children: [
                  Container(
                    color: Color(0xffF8F8F8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/images/user-name.png",
                                      width: 20,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Expanded(
                                      child: Text(
                                        "اسم العميل",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: textColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${order!['customer_name']}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 3,
                          ),
                          InkWell(
                            onTap: () async {
                              await _makePhoneCall(order!['mobile']);
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        "assets/images/res-phone.png",
                                        width: 20,
                                        height: 20,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Text(
                                          "رقم العميل",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: textColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${order!['mobile']}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 3,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
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
                                        "المنطقة",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: textColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${order!['area']}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 3,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/images/near-of.png",
                                      width: 20,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Expanded(
                                      child: Text(
                                        "بالقرب من",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: textColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${order!['address']}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 3,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/images/method.png",
                                      width: 20,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Expanded(
                                      child: Text(
                                        "طريقة الاستلام",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: textColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  order!['checkout_type'] == "pickup "
                                      ? "الاستلام من المطعم"
                                      : "التوصيل للمنزل",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              )),
              SizedBox(
                width: 30,
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: mainColor),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12))),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        "تفاصيل الطلب",
                        style: TextStyle(
                            color: mainColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
              ),
              Expanded(
                  child: Column(
                children: [
                  Container(
                    color: Color(0xffF8F8F8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "رقم الطلب",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "#${order!['id']}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 3,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "وقت وتاريخ الطلب",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  formatDateTime(order!['created_at']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 3,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/images/order-ready.png",
                                      width: 20,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Expanded(
                                      child: Text(
                                        "يتم المعالجة",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: mainColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/images/hour.png",
                                      width: 10,
                                      height: 10,
                                    ),
                                    Text(
                                      "11:00",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Color(0xffE2E2E2),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 20,
                                child: Center(
                                  child: Text(
                                    "|",
                                    style: TextStyle(
                                        color: order!['status'] != "pending"
                                            ? mainColor
                                            : Color(0xffE2E2E2),
                                        fontSize: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Image.asset(
                                      order!['status'] != "pending"
                                          ? "assets/images/in-work.png"
                                          : "assets/images/in-progress.png",
                                      width: 20,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Expanded(
                                      child: Text(
                                        "يتم التجهيز",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: order!['status'] != "pending"
                                                ? mainColor
                                                : Color(0xffE2E2E2),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/images/hour.png",
                                      width: 10,
                                      height: 10,
                                    ),
                                    Text(
                                      "11:00",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Color(0xffE2E2E2),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 20,
                                child: Center(
                                  child: Text(
                                    "|",
                                    style: TextStyle(
                                        color: order!['status'] != "pending" &&
                                                order!['status'] !=
                                                    "in_progress"
                                            ? mainColor
                                            : Color(0xffE2E2E2),
                                        fontSize: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Image.asset(
                                      order!['status'] != "pending" &&
                                              order!['status'] !=
                                                  "in_progress" &&
                                              order!['status'] !=
                                                  "ready_for_delivery"
                                          ? order!['checkout_type'] == "pickup"
                                              ? "assets/images/delivery-done.png"
                                              : "assets/images/in-delivery.png"
                                          : order!['checkout_type'] == "pickup"
                                              ? "assets/images/delivery-done2.png"
                                              : "assets/images/in-delivery2.png",
                                      width: 20,
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Expanded(
                                      child: Text(
                                        order!['checkout_type'] == "pickup"
                                            ? "تم الاستلام"
                                            : "في التوصيل",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color:
                                                order!['status'] != "pending" &&
                                                        order!['status'] !=
                                                            "in_progress" &&
                                                        order!['status'] !=
                                                            "ready_for_delivery"
                                                    ? mainColor
                                                    : Color(0xffE2E2E2),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/images/hour.png",
                                      width: 10,
                                      height: 10,
                                    ),
                                    Text(
                                      "11:00",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Color(0xffE2E2E2),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          Visibility(
                            visible: order!['checkout_type'] != "pickup",
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  child: Center(
                                    child: Text(
                                      "|",
                                      style: TextStyle(
                                          color: mainColor, fontSize: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: order!['checkout_type'] != "pickup",
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        order!['status'] == 'delivered'
                                            ? "assets/images/delivery-done.png"
                                            : "assets/images/delivery-done2.png",
                                        width: 20,
                                        height: 20,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Text(
                                          "تم الاستلام",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: order!['status'] ==
                                                      'delivered'
                                                  ? mainColor
                                                  : Color(0xffE2E2E2),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        "assets/images/hour.png",
                                        width: 10,
                                        height: 10,
                                      ),
                                      Text(
                                        "11:00",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Color(0xffE2E2E2),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              )),
              SizedBox(
                width: 30,
              ),
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: mainColor),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12))),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        "سلة المشتريات",
                        style: TextStyle(
                            color: mainColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
              ),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: order!['order_details'].map<Widget>((detail) {
                    // Extract component and drink information
                    List<String> selectedComponentsNames = [];
                    List<String> selectedDrinksNames = [];

                    // Extract components
                    if (detail['component_id'] != null) {
                      List<String> selectedComponentsId =
                          (jsonDecode(detail['component_id']) as List)
                              .map((e) => e.toString())
                              .toList();
                      for (var component in (detail['components'] ?? [])) {
                        if (selectedComponentsId
                            .contains(component['component_id'].toString())) {
                          selectedComponentsNames
                              .add(component['component']['name'] ?? '');
                        }
                      }
                    }

                    // Extract drinks
                    if (detail['drink_id'] != null) {
                      List<String> selectedDrinksId =
                          (jsonDecode(detail['drink_id']) as List)
                              .map((e) => e.toString())
                              .toList();
                      for (var drink in (detail['drinks'] ?? [])) {
                        if (selectedDrinksId
                            .contains(drink['drink_id'].toString())) {
                          selectedDrinksNames.add(drink['drink']['name'] ?? '');
                        }
                      }
                    }

                    return detail['product'] == null
                        ? Container(
                            child: Center(
                                child: Text(
                              "هناك خلل بالمعلومات القديمة",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            )),
                          )
                        : Container(
                            color: Color(0xffF8F8F8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: FancyShimmerImage(
                                      imageUrl: detail['product']['image'],
                                      width: 50,
                                      height: 50,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          detail['product']['name'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        if (detail['size'] != null)
                                          Row(
                                            children: [
                                              Text(
                                                "الحجم: ",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: mainColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  detail['size']['size'],
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black
                                                          .withOpacity(0.7)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (selectedComponentsNames.isNotEmpty)
                                          Row(
                                            children: [
                                              Text(
                                                "المكونات: ",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: mainColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  selectedComponentsNames
                                                      .join(', '),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black
                                                          .withOpacity(0.7)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        // Display Drinks
                                        if (selectedDrinksNames.isNotEmpty)
                                          Row(
                                            children: [
                                              Text(
                                                "المشروبات: ",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: mainColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  selectedDrinksNames
                                                      .join(', '),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black
                                                          .withOpacity(0.7)),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "₪${detail['sum']}",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: mainColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                  }).toList(),
                ),
              ),
              SizedBox(
                width: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String formatDateTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      final formattedDate = DateFormat('h:mm  dd-MM-yyyy ').format(parsedDate);
      return formattedDate;
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget phoneNumber() {
    Future<void> _makePhoneCall(String phoneNumber) async {
      final Uri phoneUri = Uri.parse("tel:$phoneNumber");
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        debugPrint("Could not launch $phoneUri");
      }
    }

    return InkWell(
      onTap: () {
        _makePhoneCall(order?['restaurant']['phone_number']);
      },
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                "assets/images/res-whatapp.png",
                width: 20,
                height: 20,
              ),
              SizedBox(
                width: 5,
              ),
              Expanded(
                child: Text(
                  "${order!['restaurant']['phone_number']}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              )
            ],
          ),
          SizedBox(
            height: 3,
          ),
          Row(
            children: [
              Image.asset(
                "assets/images/res-phone.png",
                width: 20,
                height: 20,
              ),
              SizedBox(
                width: 5,
              ),
              Expanded(
                child: Text(
                  "${order!['restaurant']['phone_number']}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget copyOrder() {
    return InkWell(
      onTap: () async {
        loading
            ? showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                      backgroundColor: Colors.white,
                      content: Center(
                        child: CircularProgressIndicator(),
                      ));
                })
            : showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    content: Text(
                      "هل تريد بالتأكيد تكرار هذه الوجبة؟",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    actions: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                            onTap: () async {
                              String orderId =
                                  widget.orderId.toString().toString();
                              fetchAndAddOrderToCart(context, orderId);
                            },
                            child: Container(
                              height: 40,
                              width: 55,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: mainColor),
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
                                  color: mainColor),
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
                });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(0xff8AC43E),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Image.asset("assets/images/copy-order.png")),
          SizedBox(
            width: 10,
          ),
          Text(
            "نسخ الطلب",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void fetchAndAddOrderToCart(BuildContext context, String orderId) async {
    final url =
        Uri.parse('https://hrsps.com/login/api/show-order-data/$orderId');
    setState(() {
      loading = true;
    });
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orderDetails = data['order']['order_details'] ?? [];
        final restaurant = data['order']['restaurant'] ?? {};

        final cartProvider = Provider.of<CartProvider>(context, listen: false);

        for (var orderDetail in orderDetails) {
          final product = orderDetail['product'] ?? {};
          final int productId = product['id'] ?? 0;
          final String productName = product['name'] ?? 'Unnamed Product';
          final String size = orderDetail['size']['size'] ?? '';
          final String productPrice = product['price']?.toString() ?? '0';
          final String productImage =
              product['image'] ?? 'https://example.com/default.jpg';
          final int quantity = int.tryParse(orderDetail['qty'].toString()) ?? 1;
          final double sum =
              double.tryParse(orderDetail['sum'].toString()) ?? 0.0;

          // **Parse component details**
          List<String> selectedComponentsId =
              (orderDetail['component_id'] != null)
                  ? (jsonDecode(orderDetail['component_id']) as List)
                      .map((e) => e.toString())
                      .toList()
                  : [];

          List<String> selectedComponentsQty =
              (orderDetail['component_ids_qty'] != null)
                  ? (jsonDecode(orderDetail['component_ids_qty']) as List)
                      .map((e) => e.toString())
                      .toList()
                  : [];

          List<String> selectedComponentsNames = [];
          List<String> componentsNames = [];
          List<String> selectedComponentsPrices = [];
          List<String> componentsPrices = [];
          List<String> selectedComponentsImages = [];
          List<String> componentsImages = [];

          for (var component in (orderDetail['components'] ?? [])) {
            componentsNames.add(component['component']['name'] ?? '');
            componentsPrices
                .add(component['component_price']?.toString() ?? '0');
            componentsImages.add(component['component']['image'] ?? '');
            if (selectedComponentsId
                .contains(component['component_id'].toString())) {
              selectedComponentsNames.add(component['component']['name'] ?? '');
              selectedComponentsPrices
                  .add(component['component_price']?.toString() ?? '0');
              selectedComponentsImages
                  .add(component['component']['image'] ?? '');
            }
          }
          List<String> selectedDrinksId = (orderDetail['drink_id'] != null)
              ? (jsonDecode(orderDetail['drink_id']) as List)
                  .map((e) => e.toString())
                  .toList()
              : [];

          List<String> selectedDrinksQty =
              (orderDetail['drink_ids_qty'] != null)
                  ? (jsonDecode(orderDetail['drink_ids_qty']) as List)
                      .map((e) => e.toString())
                      .toList()
                  : [];

          List<String> selectedDrinksNames = [];
          List<String> selectedDrinksPrices = [];
          List<String> selectedDrinksImages = [];
          List<String> drinksNames = [];
          List<String> drinksPrices = [];
          List<String> drinksImages = [];

          for (var drink in (orderDetail['drinks'] ?? [])) {
            drinksNames.add(drink['drink']['name'] ?? '');
            drinksPrices.add(drink['drink_price']?.toString() ?? '0');
            drinksImages.add(drink['drink']['image'] ?? '');
            if (selectedDrinksId.contains(drink['drink_id'].toString())) {
              selectedDrinksNames.add(drink['drink']['name'] ?? '');
              selectedDrinksPrices.add(drink['drink_price']?.toString() ?? '0');
              selectedDrinksImages.add(drink['drink']['image'] ?? '');
            }
          }

          // **Create new cart item**
          final newItem = CartItem(
            storeDeliveryPrice: restaurant['delivery_price']?.toString() ?? '0',
            storeID: restaurant['id']?.toString() ?? '',
            storeName: restaurant['name'] ?? '',
            storeImage: restaurant['image'] ?? '',
            storeLocation: restaurant['address'] ?? '',
            storeOpenTime: restaurant['open_time'] ?? '',
            storeCloseTime: restaurant['close_time'] ?? '',
            total: sum.toString(),
            price: productPrice,
            size: size,
            name: productName,
            productId: productId,
            image: productImage,
            quantity: quantity,
            selected_components_id: selectedComponentsId,
            selected_components_qty: selectedComponentsQty,
            selected_components_names: selectedComponentsNames,
            selected_components_prices: selectedComponentsPrices,
            selected_components_images: selectedComponentsImages,
            selected_drinks_id: selectedDrinksId,
            selected_drinks_qty: selectedDrinksQty,
            selected_drinks_names: selectedDrinksNames,
            selected_drinks_prices: selectedDrinksPrices,
            selected_drinks_images: selectedDrinksImages,
            components_names: componentsNames,
            components_prices: componentsPrices,
            drinks_names: drinksNames,
            drinks_prices: drinksPrices,
            components_images: componentsImages,
            drinks_images: drinksImages,
          );
          cartProvider.addToCart(newItem);
        }

        Navigator.of(context).pop();
        Fluttertoast.showToast(
            msg: "تمت اضافة الوجبة الى السلة", timeInSecForIosWeb: 3);
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (e) {
      print('Error fetching order details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching order details!")),
      );
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    launch("tel://$phoneNumber");
  }
}
