import 'package:j_food_updated/views/storescreen/store_provider/store_provider.dart';
import 'package:j_food_updated/component/header/header.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:provider/provider.dart';
import '../../server/functions/functions.dart';
import '../storescreen/store_screen.dart';

class AllResturants extends StatefulWidget {
  AllResturants(
      {super.key,
      required this.storesArray,
      required this.image,
      required this.title,
      required this.noDelivery,
      required this.changeTab});
  final bool noDelivery;
  final List storesArray;
  final String title;
  final String image;
  final Function(int) changeTab;
  @override
  State<AllResturants> createState() => _AllResturantsState();
}

class _AllResturantsState extends State<AllResturants> {
  String selectedTab = "مفتوح";

  @override
  Widget build(BuildContext context) {
    bool isOpenByWorkingHours(Map store, DateTime now) {
      final List<String> dayNames = [
        'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
      ];
      final String currentDay = dayNames[now.weekday - 1];
      final String prevDay = dayNames[(now.weekday - 2) < 0 ? 6 : (now.weekday - 2)];
      final List workingHours = (store['working_hours'] as List?) ?? [];

      Map<String, dynamic>? todaySchedule;
      Map<String, dynamic>? prevDaySchedule;
      if (workingHours.isNotEmpty) {
        final foundToday = workingHours.firstWhere(
          (s) => (s['day']?.toString().toLowerCase() == currentDay),
          orElse: () => null,
        );
        if (foundToday != null) todaySchedule = Map<String, dynamic>.from(foundToday);

        final foundPrev = workingHours.firstWhere(
          (s) => (s['day']?.toString().toLowerCase() == prevDay),
          orElse: () => null,
        );
        if (foundPrev != null) prevDaySchedule = Map<String, dynamic>.from(foundPrev);
      }

      DateTime parseTimeSmart(String timeStr, DateTime ref) {
        final parts = timeStr.split(':');
        if (parts.length < 2) throw FormatException("Bad time: $timeStr");
        return DateTime(ref.year, ref.month, ref.day, int.parse(parts[0]), int.parse(parts[1]));
      }

      // Try today schedule first
      String? openTimeString = todaySchedule?['start_time']?.toString();
      String? closeTimeString = todaySchedule?['end_time']?.toString();

      // If not working today, fallback to open_time/close_time
      if (openTimeString == null || closeTimeString == null) {
        openTimeString = store['open_time']?.toString();
        closeTimeString = store['close_time']?.toString();
      }

      if (openTimeString == null || closeTimeString == null) return false;

      try {
        DateTime openTime = parseTimeSmart(openTimeString, now);
        DateTime closeTime = parseTimeSmart(closeTimeString, now);

        // Case 1: Normal working hours (no overnight)
        if (!closeTime.isBefore(openTime)) {
          // Same day: closeTime >= openTime
          if (now.isBefore(openTime)) {
            return false; // Before opening time
          }
          if (now.isAfter(closeTime)) {
            return false; // After closing time
          }
          return true; // Between open and close
        }

        // Case 2: Overnight working hours (closeTime < openTime means it extends past midnight)
        // Example: 11:00 - 04:00 means opens 11:00 today, closes 04:00 tomorrow
        
        closeTime = closeTime.add(const Duration(days: 1));
        
        // Check if now is within today's working hours
        if (now.isAfter(openTime) && now.isBefore(closeTime)) {
          return true;
        }
        
        // Check if now is before opening time (in early morning before next day opens)
        if (now.isBefore(openTime)) {
          // Only within previous day's overnight schedule if previous day ends after midnight
          if (prevDaySchedule != null) {
            String? prevOpen = prevDaySchedule['start_time']?.toString();
            String? prevClose = prevDaySchedule['end_time']?.toString();
            if (prevOpen != null && prevClose != null) {
              DateTime prevOpenTime = parseTimeSmart(prevOpen, now.subtract(const Duration(days: 1)));
              DateTime prevCloseTime = parseTimeSmart(prevClose, now.subtract(const Duration(days: 1)));
              
              // Only if previous day also has overnight schedule
              if (prevCloseTime.isBefore(prevOpenTime)) {
                prevCloseTime = prevCloseTime.add(const Duration(days: 1));
                if (now.isAfter(prevOpenTime) && now.isBefore(prevCloseTime)) {
                  return true;
                }
              }
            }
          }
          return false;
        }

        return false;
      } catch (_) {
        return false;
      }
    }

    // Filter stores based on frontend schedule logic
    final DateTime now = DateTime.now();
    List filteredStores = widget.storesArray.where((store) {
      final bool openByFrontend = isOpenByWorkingHours(store, now);

      if (selectedTab == "مفتوح") {
        return openByFrontend;
      } else if (selectedTab == "مغلق") {
        return !openByFrontend;
      }
      return true;
    }).toList();

    return Container(
      color: mainColor,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: BurgerBoxDelegate(
                  coverImage: widget.image.isNotEmpty
                      ? widget.image
                      : 'assets/images/logo2.png',
                  name: widget.title,
                  noDelivery: widget.noDelivery,
                  onTabSelected: (tab) {
                    setState(() {
                      selectedTab = tab;
                    });
                  },
                  selectedTab: selectedTab,
                  changeTab: widget.changeTab,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(
                    top: 20.0, right: 8, left: 8, bottom: 10),
                sliver: filteredStores.isEmpty
                    ? SliverToBoxAdapter(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 50,
                            ),
                            Center(
                              child: Text(
                                selectedTab == "مغلق"
                                    ? "لا يوجد مطاعم مغلقة"
                                    : selectedTab == "مفتوح"
                                        ? "لا يوجد مطاعم مفتوحة"
                                        : "لا يوجد مطاعم في هذا القسم",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final DateTime now = DateTime.now();
                            final bool isOpenFlag = isOpenByWorkingHours(filteredStores[index], now);
                            final List<String> dayNames = [
                              'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
                            ];
                            final String currentDay = dayNames[now.weekday - 1];
                            final String prevDay = dayNames[(now.weekday - 2) < 0 ? 6 : (now.weekday - 2)];
                            final List workingHours = filteredStores[index]['working_hours'] ?? [];
                            final todaySchedule = workingHours.firstWhere(
                              (schedule) => schedule['day'] == currentDay,
                              orElse: () => null,
                            );
                            final prevDaySchedule = workingHours.firstWhere(
                              (schedule) => schedule['day'] == prevDay,
                              orElse: () => null,
                            );
                            bool notWorkingToday = todaySchedule == null;
                            String statusMessage;
                            int hoursLeft = 0, minutesLeft = 0;
                            bool almostClosing = false;
                            bool isCurrentlyOpen = isOpenFlag;
                            bool closedToday = false;
                            bool isWithinOperatingHours = false;

                            DateTime parseTime(String timeStr, DateTime reference) {
                              final parts = timeStr.split(":");
                              return DateTime(reference.year, reference.month, reference.day, int.parse(parts[0]), int.parse(parts[1]));
                            }

                            DateTime openTime, closeTime;
                            bool isOvernight = false;
                            // Overnight logic: check previous day's schedule if after midnight
                            if (todaySchedule != null) {
                              String openTimeString = todaySchedule['start_time'];
                              String closeTimeString = todaySchedule['end_time'];
                              openTime = parseTime(openTimeString, now);
                              closeTime = parseTime(closeTimeString, now);
                              isOvernight = closeTime.isBefore(openTime);
                              if (isOvernight) {
                                closeTime = closeTime.add(const Duration(days: 1));
                                if (now.isBefore(openTime) && prevDaySchedule != null) {
                                  // Use previous day's schedule
                                  String prevOpen = prevDaySchedule['start_time'];
                                  String prevClose = prevDaySchedule['end_time'];
                                  openTime = parseTime(prevOpen, now.subtract(const Duration(days: 1)));
                                  closeTime = parseTime(prevClose, now.subtract(const Duration(days: 1)));
                                  if (closeTime.isBefore(openTime)) {
                                    closeTime = closeTime.add(const Duration(days: 1));
                                  }
                                } else if (now.isBefore(openTime)) {
                                  openTime = openTime.subtract(const Duration(days: 1));
                                }
                              }
                            } else if (prevDaySchedule != null) {
                              // If not working today, check previous day's overnight
                              String prevOpen = prevDaySchedule['start_time'];
                              String prevClose = prevDaySchedule['end_time'];
                              openTime = parseTime(prevOpen, now.subtract(const Duration(days: 1)));
                              closeTime = parseTime(prevClose, now.subtract(const Duration(days: 1)));
                              if (closeTime.isBefore(openTime)) {
                                closeTime = closeTime.add(const Duration(days: 1));
                              }
                            } else {
                              // fallback
                              openTime = now;
                              closeTime = now;
                              notWorkingToday = true;
                            }

                            if (now.isAfter(closeTime)) {
                              openTime = openTime.add(const Duration(days: 1));
                              closeTime = closeTime.add(const Duration(days: 1));
                            }

                            isWithinOperatingHours = now.isAfter(openTime) && now.isBefore(closeTime);
                            closedToday = isWithinOperatingHours && !isCurrentlyOpen;

                            if (notWorkingToday) {
                              closedToday = true;
                              statusMessage = "اليوم المحل مغلق";
                            } else if (closedToday) {
                              statusMessage = "اليوم المحل مغلق";
                              almostClosing = false;
                            } else if (isCurrentlyOpen) {
                              final Duration remainingTime = closeTime.difference(now);
                              hoursLeft = remainingTime.inHours;
                              minutesLeft = remainingTime.inMinutes.remainder(60);
                              statusMessage = "يغلق بعد $hoursLeft:${minutesLeft.toString().padLeft(2, '0')} ساعة";
                              almostClosing = remainingTime.inMinutes <= 90;
                            } else {
                              final Duration timeUntilOpen = openTime.difference(now);
                              hoursLeft = timeUntilOpen.inHours;
                              minutesLeft = timeUntilOpen.inMinutes.remainder(60);
                              statusMessage = "يفتح بعد $hoursLeft:${minutesLeft.toString().padLeft(2, '0')} ساعة";
                              almostClosing = false;
                            }

                            final bool canBuy = isCurrentlyOpen &&
                                (filteredStores[index]
                                        ['is_order_limit_reached'] !=
                                    true);
                            // print(statusMessage);
                            // print("🛒 Can Buy: $canBuy");

                            return InkWell(
                              onTap: () async {
                                // bool canBuy = await canRestaurantCheckout(
                                //     filteredStores[index]['id'].toString());
                                // if (canBuy) {
                                NavigatorFunction(
                                    context,
                                    ChangeNotifierProvider(
                                      create: (_) => StoreProvider()
                                        ..fetchStoreDetails(
                                            filteredStores[index]['id']
                                                .toString()),
                                      child: StoreScreen(
                                        open: isCurrentlyOpen,
                                        store_cover_image: filteredStores[index]
                                                ['cover_image']
                                            .toString(),
                                        store_address: filteredStores[index]
                                                ['address']
                                            .toString(),
                                        store_id: filteredStores[index]['id']
                                            .toString(),
                                        category_id: filteredStores[index]
                                                ['category_id']
                                            .toString(),
                                        category_name: widget.title.toString(),
                                        store_image: filteredStores[index]
                                                ['image']
                                            .toString(),
                                        store_name: filteredStores[index]
                                                ['name']
                                            .toString(),
                                        noDelivery: widget.noDelivery,
                                        changeTab: widget.changeTab,
                                      ),
                                    ));
                                // } else {
                                //   Fluttertoast.showToast(
                                //       msg:
                                //           "وصلت عدد الطلبات اليوم لهذا المطعم العدد الاقصى",
                                //       timeInSecForIosWeb: 3);
                                // }
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width / 3.3,
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color:
                                      // canBuy
                                      //     ?
                                      Colors.white,
                                  // :
                                  //  Colors.grey.withOpacity(0.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 5,
                                      blurRadius: 7,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Store Image
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 50.0, vertical: 7),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: FancyShimmerImage(
                                            imageUrl: filteredStores[index]
                                                ['image'],
                                            boxFit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 80,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Store Name
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        filteredStores[index]['name']
                                            .toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: secondColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    // Store Address
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        filteredStores[index]['address']
                                            .toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12),
                                      ),
                                    ),
                                    // Closing Information
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                              color: almostClosing
                                                  ? secondColor
                                                  : const Color(0xffFCC516),
                                              borderRadius: BorderRadius.only(
                                                  bottomRight:
                                                      Radius.circular(14),
                                                  topLeft:
                                                      Radius.circular(14))),
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
                                                            FontWeight.bold,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        color: secondColor,
                                                      ),
                                                    ),
                                                  ]
                                                : isCurrentlyOpen
                                                    ? [
                                                        Text(
                                                          "يغلق بعد ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color: thirdColor,
                                                          ),
                                                        ),
                                                        Text(
                                                          "$hoursLeft:${minutesLeft.toString().padLeft(2, '0')}",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color: secondColor,
                                                          ),
                                                        ),
                                                        Text(
                                                          hoursLeft > 0
                                                              ? " ساعة"
                                                              : " دقيقة",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color: thirdColor,
                                                          ),
                                                        ),
                                                      ]
                                                    : [
                                                        Text(
                                                          "يفتح بعد ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color: thirdColor,
                                                          ),
                                                        ),
                                                        Text(
                                                          "$hoursLeft:${minutesLeft.toString().padLeft(2, '0')}",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color: secondColor,
                                                          ),
                                                        ),
                                                        Text(
                                                          hoursLeft > 0
                                                              ? " ساعة"
                                                              : " دقيقة",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color: thirdColor,
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
                          childCount: filteredStores.length,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BurgerBoxDelegate extends SliverPersistentHeaderDelegate {
  final String coverImage;
  final String name;
  final Function(String) onTabSelected;
  final String selectedTab;
  final bool noDelivery;
  final Function(int) changeTab;
  BurgerBoxDelegate(
      {required this.coverImage,
      required this.name,
      required this.changeTab,
      required this.noDelivery,
      required this.onTabSelected,
      required this.selectedTab});

  final double maxExtentHeight = 350;
  final double minExtentHeight = 100;

  @override
  double get maxExtent => maxExtentHeight;

  @override
  double get minExtent => minExtentHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double progress = shrinkOffset / (maxExtentHeight - minExtentHeight);
    final double imageHeight = (230 * (1 - progress)).clamp(0, 230);
    final double topPosition = (40 - shrinkOffset * 0.5).clamp(0, 40);
    final double scaleFactor =
        (1 - (shrinkOffset / (maxExtentHeight - minExtentHeight)))
            .clamp(0.2, 1.0);
    bool showName = progress > 0.8 ? true : false;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        color: secondColor,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: -25,
            child: Container(
                height: 25,
                decoration: BoxDecoration(color: Colors.white),
                width: MediaQuery.of(context).size.width,
                child: Text("")),
          ),
          Positioned(
            top: 20,
            child: SizedBox(
              // height: 40,
              width: MediaQuery.of(context).size.width,
              child: Header(
                fromAllResturant: true,
                noDelivery: noDelivery,
                changeTab: changeTab,
              ),
            ),
          ),
          if (imageHeight > 0 && !showName)
            Positioned(
              top: (topPosition + 20).clamp(0, 60),
              child: Transform.scale(
                scale: scaleFactor,
                child: Image.asset(
                  coverImage,
                  fit: BoxFit.cover,
                  height: 230,
                ),
              ),
            ),
          if (showName)
            Positioned(
              top: minExtentHeight / 2 - 10,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          Positioned(
            bottom: -20,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xffFFC509),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildTab("الكل"),
                    buildTab("مفتوح"),
                    buildTab("مغلق"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTab(String title) {
    return MaterialButton(
      onPressed: () => onTabSelected(title),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: selectedTab == title ? mainColor : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
