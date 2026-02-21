import 'package:j_food_updated/server/functions/functions.dart';
import 'package:j_food_updated/views/storescreen/store_provider/store_provider.dart';
import 'package:j_food_updated/views/storescreen/store_screen.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'section_title.dart';

class RestaurantsSection extends StatelessWidget {
  final List restaurants;
  final bool noDelivery;
  final Function(int) changeTab;

  const RestaurantsSection({
    super.key,
    required this.restaurants,
    required this.noDelivery,
    required this.changeTab,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          const SectionTitle(title: 'المطاعم:'),
          const SizedBox(height: 10),
          ListView.builder(
            itemCount: restaurants.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return _RestaurantCard(
                restaurant: restaurants[index],
                noDelivery: noDelivery,
                changeTab: changeTab,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map restaurant;
  final bool noDelivery;
  final Function(int) changeTab;

  const _RestaurantCard({
    required this.restaurant,
    required this.noDelivery,
    required this.changeTab,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

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
    final List workingHours = restaurant['j.food.com.jfood'] ?? [];

    // Find today's working hours
    final todaySchedule = workingHours.firstWhere(
      (schedule) => schedule['day'] == currentDay,
      orElse: () => null,
    );

    // Check if restaurant doesn't work today
    bool notWorkingToday = todaySchedule == null;
    bool isOpen = false;
    bool closedToday = false;
    int hoursLeft = 0;
    int minutesLeft = 0;
    bool almostClosing = false;

    if (notWorkingToday) {
      closedToday = true;
    } else {
      // Parse today's working hours
      String? openTimeStr = todaySchedule['start_time'];
      String? closeTimeStr = todaySchedule['end_time'];

      if (openTimeStr == null || closeTimeStr == null) {
        return const SizedBox.shrink();
      }

      DateTime parseTime(String time, DateTime ref) {
        final parts = time.split(':');
        return DateTime(
          ref.year,
          ref.month,
          ref.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      DateTime openTime = parseTime(openTimeStr, now);
      DateTime closeTime = parseTime(closeTimeStr, now);

      if (closeTime.isBefore(openTime)) {
        closeTime = closeTime.add(const Duration(days: 1));
        if (now.isBefore(openTime)) {
          openTime = openTime.subtract(const Duration(days: 1));
        }
      }

      if (now.isAfter(closeTime)) {
        openTime = openTime.add(const Duration(days: 1));
        closeTime = closeTime.add(const Duration(days: 1));
      }

      // Check if within operating hours
      bool isWithinOperatingHours =
          now.isAfter(openTime) && now.isBefore(closeTime);

      // Check backend is_open status
      bool backendIsOpen = restaurant['is_open'] == true;

      // Special case: within hours but manually closed
      closedToday = isWithinOperatingHours && !backendIsOpen;
      isOpen = backendIsOpen;

      if (!closedToday) {
        if (isOpen) {
          final diff = closeTime.difference(now);
          hoursLeft = diff.inHours;
          minutesLeft = diff.inMinutes.remainder(60);
          almostClosing = diff.inMinutes <= 90;
        } else {
          final diff = openTime.difference(now);
          hoursLeft = diff.inHours;
          minutesLeft = diff.inMinutes.remainder(60);
          almostClosing = false;
        }
      }
    }

    return InkWell(
      onTap: () {
        NavigatorFunction(
          context,
          ChangeNotifierProvider(
            create: (_) =>
                StoreProvider()..fetchStoreDetails(restaurant['id'].toString()),
            child: StoreScreen(
              open: isOpen,
              store_cover_image: restaurant['cover_image'].toString(),
              store_address: restaurant['address'].toString(),
              store_id: restaurant['id'].toString(),
              category_id: restaurant['category_id'].toString(),
              category_name: "",
              store_image: restaurant['image'].toString(),
              store_name: restaurant['name'].toString(),
              noDelivery: noDelivery,
              changeTab: changeTab,
            ),
          ),
        );
      },
      child: Card(
        elevation: 3,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FancyShimmerImage(
                  imageUrl: restaurant['image'],
                  width: 80,
                  height: 80,
                  boxFit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant['address'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: almostClosing
                                ? Colors.red
                                : const Color(0xffFCC516),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                            Icons.access_time,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (closedToday)
                          const Text(
                            "اليوم المحل مغلق",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          )
                        else ...[
                          Text(
                            isOpen ? "يغلق بعد " : "يفتح بعد ",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$hoursLeft:${minutesLeft.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            hoursLeft > 0 ? " ساعة" : " دقيقة",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
