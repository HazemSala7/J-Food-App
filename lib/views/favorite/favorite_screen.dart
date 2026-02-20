import 'package:j_food_updated/views/storescreen/store_provider/store_provider.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../LocalDB/Models/FavoriteItem.dart';
import '../../LocalDB/Provider/FavouriteProvider.dart';
import '../../constants/constants.dart';
import '../../server/functions/functions.dart';
import '../storescreen/store_screen.dart';

class FavoriteScreen extends StatefulWidget {
  final bool noDelivery;
  final Function(int) changeTab;
  const FavoriteScreen(
      {super.key, required this.noDelivery, required this.changeTab});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool _isStoreOpen(String openTime, String closeTime) {
    try {
      final currentTime = TimeOfDay.now();
      final open = TimeOfDay(
        hour: int.parse(openTime.split(":")[0]),
        minute: int.parse(openTime.split(":")[1]),
      );
      final close = TimeOfDay(
        hour: int.parse(closeTime.split(":")[0]),
        minute: int.parse(closeTime.split(":")[1]),
      );

      if (currentTime.hour > open.hour && currentTime.hour < close.hour) {
        return true;
      } else if (currentTime.hour == open.hour &&
          currentTime.minute >= open.minute) {
        return true;
      } else if (currentTime.hour == close.hour &&
          currentTime.minute <= close.minute) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error parsing time: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fourthColor,
      child: SafeArea(
        child: Scaffold(
          // appBar: AppBar(
          //   centerTitle: true,
          //   leading: IconButton(
          //       onPressed: () {
          //         Navigator.pop(context);
          //       },
          //       icon: Icon(
          //         Icons.arrow_back,
          //         color: Colors.white,
          //       )),
          //   backgroundColor: mainColor,
          //   title: Text(
          //     "المفضلة",
          //     style:
          //         TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          //   ),
          // ),
          backgroundColor: fourthColor,
          body: Consumer<FavouriteProvider>(
              builder: (context, favoriteProvider, _) {
            List<FavoriteItem> favoritesItems = favoriteProvider.favoriteItems;

            return Padding(
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
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 15.0, top: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "المفضلة",
                              style: TextStyle(
                                  color: mainColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                      favoritesItems.length != 0
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GridView.count(
                                crossAxisCount: 2,
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                childAspectRatio: 1,
                                children: List.generate(
                                  favoritesItems.length,
                                  (index) {
                                    FavoriteItem item = favoritesItems[index];

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
                                    final String currentDay =
                                        dayNames[now.weekday - 1];

                                    // Parse working hours from JSON
                                    List<dynamic> workingHours = [];
                                    try {
                                      workingHours =
                                          jsonDecode(item.workingHours);
                                    } catch (e) {
                                      print('Error parsing working hours: $e');
                                    }

                                    // Find today's schedule
                                    final todaySchedule =
                                        workingHours.firstWhere(
                                      (schedule) =>
                                          schedule['day'] == currentDay,
                                      orElse: () => null,
                                    );

                                    bool notWorkingToday =
                                        todaySchedule == null;
                                    bool isOpen = item.isOpen;
                                    bool closedToday = false;
                                    int hoursLeft = 0;
                                    int minutesLeft = 0;
                                    bool almostClosing = false;

                                    if (notWorkingToday) {
                                      closedToday = true;
                                    } else {
                                      // Use today's working hours
                                      String openTimeString =
                                          todaySchedule['start_time'] ??
                                              item.openTime;
                                      String closeTimeString =
                                          todaySchedule['end_time'] ??
                                              item.closeTime;

                                      DateTime parseTime(
                                          String timeStr, DateTime ref) {
                                        final parts = timeStr.split(':');
                                        return DateTime(
                                          ref.year,
                                          ref.month,
                                          ref.day,
                                          int.parse(parts[0]),
                                          int.parse(parts[1]),
                                        );
                                      }

                                      DateTime openTime =
                                          parseTime(openTimeString, now);
                                      DateTime closeTime =
                                          parseTime(closeTimeString, now);

                                      if (closeTime.isBefore(openTime)) {
                                        closeTime = closeTime
                                            .add(const Duration(days: 1));
                                        if (now.isBefore(openTime)) {
                                          openTime = openTime.subtract(
                                              const Duration(days: 1));
                                        }
                                      }

                                      if (now.isAfter(closeTime)) {
                                        openTime = openTime
                                            .add(const Duration(days: 1));
                                        closeTime = closeTime
                                            .add(const Duration(days: 1));
                                      }

                                      // Check if within operating hours
                                      bool isWithinOperatingHours =
                                          now.isAfter(openTime) &&
                                              now.isBefore(closeTime);

                                      // Check if manually closed
                                      closedToday =
                                          isWithinOperatingHours && !isOpen;

                                      if (!closedToday) {
                                        if (isOpen) {
                                          final remainingTime =
                                              closeTime.difference(now);
                                          hoursLeft = remainingTime.inHours;
                                          minutesLeft = remainingTime.inMinutes
                                              .remainder(60);
                                          almostClosing =
                                              remainingTime.inMinutes <= 90;
                                        } else {
                                          final timeUntilOpen =
                                              openTime.difference(now);
                                          hoursLeft = timeUntilOpen.inHours;
                                          minutesLeft = timeUntilOpen.inMinutes
                                              .remainder(60);
                                        }
                                      }
                                    }
                                    return InkWell(
                                      onTap: () {
                                        pushWithoutNavBar(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeNotifierProvider(
                                                      create: (_) =>
                                                          StoreProvider()
                                                            ..fetchStoreDetails(
                                                                item.storeId
                                                                    .toString()),
                                                      child: StoreScreen(
                                                        open: isOpen,
                                                        store_cover_image: item
                                                            .storeImage
                                                            .toString(),
                                                        store_address: "-",
                                                        store_id: item.storeId
                                                            .toString(),
                                                        category_id: item
                                                            .categoryID
                                                            .toString(),
                                                        changeTab:
                                                            widget.changeTab,
                                                        category_name: item
                                                            .categoryName
                                                            .toString(),
                                                        store_image: item
                                                            .storeImage
                                                            .toString(),
                                                        store_name: item
                                                            .storeName
                                                            .toString(),
                                                        noDelivery:
                                                            widget.noDelivery,
                                                      ),
                                                    )));
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3.3,
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              spreadRadius: 5,
                                              blurRadius: 7,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 50.0,
                                                      vertical: 7),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: FancyShimmerImage(
                                                    imageUrl: item.storeImage,
                                                    boxFit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: 80,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: Text(
                                                item.storeName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: secondColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: Text(
                                                item.storeLocation,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                      color: almostClosing
                                                          ? secondColor
                                                          : const Color(
                                                              0xffFCC516),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              bottomRight:
                                                                  Radius
                                                                      .circular(
                                                                          14),
                                                              topLeft: Radius
                                                                  .circular(
                                                                      14))),
                                                  child: const Icon(
                                                    Icons.access_time,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 3,
                                                ),
                                                Expanded(
                                                  child: Row(
                                                    children: closedToday
                                                        ? [
                                                            Text(
                                                              "اليوم المحل مغلق",
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                color:
                                                                    secondColor,
                                                              ),
                                                            ),
                                                          ]
                                                        : isOpen
                                                            ? [
                                                                Text(
                                                                  "يغلق بعد ",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    color:
                                                                        thirdColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  "$hoursLeft:${minutesLeft.toString().padLeft(2, '0')}",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    color:
                                                                        secondColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  hoursLeft > 0
                                                                      ? " ساعة"
                                                                      : " دقيقة",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    color:
                                                                        thirdColor,
                                                                  ),
                                                                ),
                                                              ]
                                                            : [
                                                                Text(
                                                                  "يفتح بعد ",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    color:
                                                                        thirdColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  "$hoursLeft:${minutesLeft.toString().padLeft(2, '0')}",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    color:
                                                                        secondColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  hoursLeft > 0
                                                                      ? " ساعة"
                                                                      : " دقيقة",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    color:
                                                                        thirdColor,
                                                                  ),
                                                                ),
                                                              ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                          : Container(
                              height: MediaQuery.of(context).size.height,
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 150,
                                  ),
                                  Text(
                                    "لا يوجد أي مطعم بالمفضلة",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Image.asset(
                                    "assets/images/no-favorites.png",
                                    width: 100,
                                    height: 100,
                                  )
                                ],
                              ),
                            ),
                      // SizedBox(
                      //   height: 100,
                      // )
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget favouriteCard(
      {String name = "",
      String image = "",
      String address = "",
      int productID = 0,
      int storeID = 0,
      int categoryID = 0,
      Function? removeStore,
      String categoryName = ""}) {
    return InkWell(
      onTap: () {},
      child: Container(
        width: MediaQuery.of(context).size.width / 3,
        margin: const EdgeInsets.only(top: 4, left: 20, bottom: 4),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.deepOrange)),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: FancyShimmerImage(
                  imageUrl: image,
                  height: 100,
                  width: double.infinity,
                  boxFit: BoxFit.cover,
                  errorWidget: Image.asset(
                    "assets/images/logo2.png",
                    fit: BoxFit.cover,
                    height: 100,
                    width: double.infinity,
                  )),
            ),
            Text(
              name.toString(),
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              name.toString(),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 5),
              child: InkWell(
                onTap: () {
                  pushWithoutNavBar(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider(
                                create: (_) => StoreProvider()
                                  ..fetchStoreDetails(storeID.toString()),
                                child: StoreScreen(
                                  open: true,
                                  store_cover_image: image.toString(),
                                  store_id: storeID.toString(),
                                  store_address: address.toString(),
                                  category_id: categoryID.toString(),
                                  category_name: categoryName,
                                  store_image: image.toString(),
                                  store_name: name.toString(),
                                  noDelivery: widget.noDelivery,
                                  changeTab: widget.changeTab,
                                ),
                              )));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.green),
                  child: const Text(
                    'مفتوح',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
