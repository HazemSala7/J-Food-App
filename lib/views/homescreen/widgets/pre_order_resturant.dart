import 'dart:convert';

import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:j_food_updated/server/functions/functions.dart';
import 'package:j_food_updated/views/allresturants/allresturants.dart';
import 'package:j_food_updated/views/storescreen/store_provider/store_provider.dart';
import 'package:j_food_updated/views/storescreen/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class PreOrderResturant extends StatefulWidget {
  final List<dynamic> restaurants;
  final bool noDelivery;
  final Function(int) changeTab;
  const PreOrderResturant({
    Key? key,
    required this.restaurants,
    required this.noDelivery,
    required this.changeTab,
  }) : super(key: key);

  @override
  State<PreOrderResturant> createState() => _PreOrderResturantState();
}

class _PreOrderResturantState extends State<PreOrderResturant> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display up to 3 restaurants
        ...widget.restaurants.take(3).map((restaurant) {
          return _buildRestaurantCard(restaurant, context);
        }).toList(),

        if (widget.restaurants.length > 3)
          InkWell(
            onTap: () {
              NavigatorFunction(
                context,
                AllResturants(
                  storesArray: widget.restaurants,
                  title: "مطاعم الحجز المسبق",
                  image: "assets/images/pre-order.png",
                  noDelivery: widget.noDelivery,
                  changeTab: widget.changeTab,
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  child: Center(
                    child: Text(
                      "المزيد",
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  size: 15,
                  color: mainColor,
                ),
                SizedBox(
                  width: 15,
                )
              ],
            ),
          ),
      ],
    );
  }
Widget _buildRestaurantCard(Map<String, dynamic> restaurant, BuildContext context) {
  final DateTime now = DateTime.now();

  // Get current day name in lowercase
  final List<String> dayNames = [
    'monday','tuesday','wednesday','thursday','friday','saturday','sunday'
  ];
  final String currentDay = dayNames[now.weekday - 1];

  // ✅ API field name is "working_hours"
  final List workingHours = (restaurant['working_hours'] as List?) ?? [];

  // Find today's working hours (nullable)
  Map<String, dynamic>? todaySchedule;
  if (workingHours.isNotEmpty) {
    try {
      final found = workingHours.firstWhere(
        (s) => (s['day']?.toString().toLowerCase() == currentDay),
        orElse: () => null,
      );
      if (found != null) todaySchedule = Map<String, dynamic>.from(found);
    } catch (_) {
      todaySchedule = null;
    }
  }

  bool isOpen = restaurant['is_open'] == true; // API returns bool
  bool closedToday = false;
  int hoursLeft = 0;
  int minutesLeft = 0;

  final bool canBuy = restaurant['is_order_limit_reached'] != null
      ? !(restaurant['is_order_limit_reached'] == true)
      : true;

  // OPTIONAL: if restaurant has "active" as string/boolean, you can disable it:
  final bool isActive = (restaurant['active']?.toString().toLowerCase() == 'true')
      || (restaurant['active'] == true);

  // --- helpers ---
  DateTime parseTimeSmart(String time, DateTime ref) {
    // supports "HH:MM" or "HH:MM:SS"
    final parts = time.split(':');
    if (parts.length < 2) {
      throw FormatException("Invalid time format: $time");
    }
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return DateTime(ref.year, ref.month, ref.day, h, m);
  }

  // ✅ choose times:
  String? openTimeString;
  String? closeTimeString;

  if (todaySchedule != null) {
    openTimeString = todaySchedule!['start_time']?.toString();
    closeTimeString = todaySchedule!['end_time']?.toString();
  } else {
    // ✅ fallback to open_time/close_time if working_hours empty or missing today
    openTimeString = restaurant['open_time']?.toString();
    closeTimeString = restaurant['close_time']?.toString();
  }

  // If still missing, then we can't compute time
  if (openTimeString == null || closeTimeString == null) {
    closedToday = false; // don't lie "closed today"
  } else {
    try {
      DateTime openTime = parseTimeSmart(openTimeString, now);
      DateTime closeTime = parseTimeSmart(closeTimeString, now);

      // handle after-midnight close (e.g., 11:00 -> 04:00)
      if (closeTime.isBefore(openTime)) {
        closeTime = closeTime.add(const Duration(days: 1));
        if (now.isBefore(openTime)) {
          openTime = openTime.subtract(const Duration(days: 1));
        }
      }

      // if now passed today's close, shift to next day schedule window
      if (now.isAfter(closeTime)) {
        openTime = openTime.add(const Duration(days: 1));
        closeTime = closeTime.add(const Duration(days: 1));
      }

      final bool isWithinOperatingHours = now.isAfter(openTime) && now.isBefore(closeTime);

      // Special: within hours but manually closed
      closedToday = isWithinOperatingHours && !isOpen;

      if (!closedToday) {
        if (isOpen) {
          final diff = closeTime.difference(now);
          hoursLeft = diff.inHours;
          minutesLeft = diff.inMinutes.remainder(60);
        } else {
          final diff = openTime.difference(now);
          hoursLeft = diff.inHours;
          minutesLeft = diff.inMinutes.remainder(60);
        }
      }
    } catch (e) {
      // parsing error → don't crash widget
      closedToday = false;
    }
  }

  // If inactive, treat as not buyable
  final bool finalCanTap = canBuy && isActive;

  return InkWell(
    onTap: () async {
      if (!finalCanTap) {
        Fluttertoast.showToast(
          msg: !isActive
              ? "هذا المطعم غير فعال حالياً"
              : "وصلت عدد الطلبات اليوم لهذا المطعم العدد الاقصى",
          timeInSecForIosWeb: 4,
        );
        return;
      }

      NavigatorFunction(
        context,
        ChangeNotifierProvider(
          create: (_) => StoreProvider()
            ..fetchStoreDetails(restaurant['id'].toString()),
          child: StoreScreen(
            open: restaurant['is_open'],
            store_cover_image: restaurant['cover_image'].toString(),
            store_address: restaurant['address'].toString(),
            store_id: restaurant['id'].toString(),
            category_id: (restaurant['category_id'] ?? '').toString(),
            category_name: "",
            store_image: restaurant['image'].toString(),
            store_name: restaurant['name'].toString(),
            noDelivery: widget.noDelivery,
            changeTab: widget.changeTab,
          ),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10),
      child: Card(
        elevation: 5,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: finalCanTap ? Colors.white : Colors.grey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 5),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      restaurant['image'],
                      width: 110,
                      height: 100,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2.0, bottom: 2),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Image.asset(
                          "assets/images/ramadan.png",
                          width: 25,
                          height: 25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      restaurant['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant['address'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff5E5E5E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: closedToday
                          ? [
                              Text(
                                "اليوم المحل مغلق",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: secondColor,
                                ),
                              ),
                            ]
                          : isOpen
                              ? [
                                  Text(
                                    "يغلق بعد ",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                      color: thirdColor,
                                    ),
                                  ),
                                  Text(
                                    "$hoursLeft:${minutesLeft.toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                      color: secondColor,
                                    ),
                                  ),
                                  Text(
                                    hoursLeft > 0 ? " ساعة" : " دقيقة",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                      color: thirdColor,
                                    ),
                                  ),
                                ]
                              : [
                                  Text(
                                    "يفتح بعد ",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                      color: thirdColor,
                                    ),
                                  ),
                                  Text(
                                    "$hoursLeft:${minutesLeft.toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                      color: secondColor,
                                    ),
                                  ),
                                  Text(
                                    hoursLeft > 0 ? " ساعة" : " دقيقة",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                      color: thirdColor,
                                    ),
                                  ),
                                ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: double.infinity,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: finalCanTap
                              ? fourthColor
                              : fourthColor.withOpacity(0.5),
                        ),
                        child: const Center(
                          child: Text(
                            "احجز الان",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
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
  Future<bool> canRestaurantCheckout(String id) async {
    try {
      final Uri url = Uri.parse("${AppLink.canCheck}/${id}/can-checkout");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["can_checkout"] ?? false;
      } else {
        print("Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }
}
