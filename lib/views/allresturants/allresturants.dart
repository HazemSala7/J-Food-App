import 'package:j_food_updated/views/storescreen/market_catergories.dart';
import 'package:j_food_updated/views/storescreen/store_provider/store_provider.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
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
    'monday','tuesday','wednesday','thursday','friday','saturday','sunday'
  ];
  final String currentDay = dayNames[now.weekday - 1];

  // ✅ correct key from API
  final List workingHours = (store['working_hours'] as List?) ?? [];

  Map<String, dynamic>? todaySchedule;
  if (workingHours.isNotEmpty) {
    final found = workingHours.firstWhere(
      (s) => (s['day']?.toString().toLowerCase() == currentDay),
      orElse: () => null,
    );
    if (found != null) todaySchedule = Map<String, dynamic>.from(found);
  }

  DateTime parseTimeSmart(String timeStr, DateTime ref) {
    final parts = timeStr.split(':'); // supports HH:MM or HH:MM:SS
    if (parts.length < 2) throw FormatException("Bad time: $timeStr");
    return DateTime(ref.year, ref.month, ref.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  // ✅ choose times: working_hours today OR fallback open_time/close_time
  String? openTimeString;
  String? closeTimeString;

  if (todaySchedule != null) {
    openTimeString = todaySchedule!['start_time']?.toString();
    closeTimeString = todaySchedule!['end_time']?.toString();
  } else {
    openTimeString = store['open_time']?.toString();
    closeTimeString = store['close_time']?.toString();
  }

  if (openTimeString == null || closeTimeString == null) return false;

  try {
    DateTime openTime = parseTimeSmart(openTimeString, now);
    DateTime closeTime = parseTimeSmart(closeTimeString, now);

    // overnight
    if (closeTime.isBefore(openTime)) {
      closeTime = closeTime.add(const Duration(days: 1));
      if (now.isBefore(openTime)) {
        openTime = openTime.subtract(const Duration(days: 1));
      }
    }

    // passed close -> shift window to next day
    if (now.isAfter(closeTime)) {
      openTime = openTime.add(const Duration(days: 1));
      closeTime = closeTime.add(const Duration(days: 1));
    }

    return now.isAfter(openTime) && now.isBefore(closeTime);
  } catch (_) {
    return false;
  }
}

    // Filter stores based on the selected tab (working hours + backend flag)
    final DateTime now = DateTime.now();
    List filteredStores = widget.storesArray.where((store) {
      final bool openByHours = isOpenByWorkingHours(store, now);
      final bool openByBackend = store['is_open'] == true;

      if (selectedTab == "مفتوح") {
        return openByHours && openByBackend;
      } else if (selectedTab == "مغلق") {
        return !openByHours || !openByBackend;
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
                            final bool isOpenFlag =
                                filteredStores[index]['is_open'];
                            final DateTime now = DateTime.now();

                            // Get current day name in lowercase
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

                            // Get restaurant working hours
                            final List workingHours = filteredStores[index]
                                    ['working_hours'] ??
                                [];

                            // Find today's working hours
                            final todaySchedule = workingHours.firstWhere(
                              (schedule) => schedule['day'] == currentDay,
                              orElse: () => null,
                            );

                            // Check if restaurant doesn't work today
                            bool notWorkingToday = todaySchedule == null;

                            String statusMessage;
                            int hoursLeft = 0, minutesLeft = 0;
                            bool almostClosing = false;
                            bool isCurrentlyOpen = false;
                            bool closedToday = false;
                            bool isWithinOperatingHours = false;

                            if (notWorkingToday) {
                              // Restaurant doesn't work on this day
                              closedToday = true;
                              statusMessage = "🚫 Closed today - day off";
                            } else {
                              // Parse today's working hours
                              String openTimeString =
                                  todaySchedule['start_time'];
                              String closeTimeString =
                                  todaySchedule['end_time'];

                              if (openTimeString == null ||
                                  closeTimeString == null ||
                                  !openTimeString.contains(":") ||
                                  !closeTimeString.contains(":")) {
                                print(
                                    "Error: Invalid time format in restaurant data.");
                                return Container();
                              }

                              DateTime parseTime(
                                  String timeStr, DateTime reference) {
                                final parts = timeStr.split(":");
                                return DateTime(
                                    reference.year,
                                    reference.month,
                                    reference.day,
                                    int.parse(parts[0]),
                                    int.parse(parts[1]));
                              }

                              DateTime openTime =
                                  parseTime(openTimeString, now);
                              DateTime closeTime =
                                  parseTime(closeTimeString, now);

                              bool isOvernight = closeTime.isBefore(openTime);
                              if (isOvernight) {
                                closeTime =
                                    closeTime.add(const Duration(days: 1));
                                if (now.isBefore(openTime)) {
                                  openTime = openTime
                                      .subtract(const Duration(days: 1));
                                }
                              }

                              if (now.isAfter(closeTime)) {
                                openTime =
                                    openTime.add(const Duration(days: 1));
                                closeTime =
                                    closeTime.add(const Duration(days: 1));
                              }

                              // Check if current time is within operating hours
                              isWithinOperatingHours = now.isAfter(openTime) &&
                                  now.isBefore(closeTime);

                              // Check if backend says it's open
                              isCurrentlyOpen = isOpenFlag == true;

                              // Special case: within operating hours but backend says closed
                              closedToday =
                                  isWithinOperatingHours && !isCurrentlyOpen;

                              if (closedToday) {
                                // Special case: should be open by time, but manually closed
                                statusMessage = "🚫 Closed today";
                                almostClosing = false;
                              } else if (isCurrentlyOpen) {
                                final Duration remainingTime =
                                    closeTime.difference(now);
                                hoursLeft = remainingTime.inHours;
                                minutesLeft =
                                    remainingTime.inMinutes.remainder(60);
                                statusMessage =
                                    "🕒 Store is currently OPEN\n⏰ Closes in ${hoursLeft}h ${minutesLeft}m";
                                almostClosing = remainingTime.inMinutes <= 90;
                              } else {
                                final Duration timeUntilOpen =
                                    openTime.difference(now);
                                hoursLeft = timeUntilOpen.inHours;
                                minutesLeft =
                                    timeUntilOpen.inMinutes.remainder(60);
                                statusMessage =
                                    "🕒 Store is currently CLOSED\n⏰ Opens in ${hoursLeft}h ${minutesLeft}m";
                                almostClosing = false;
                              }
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
