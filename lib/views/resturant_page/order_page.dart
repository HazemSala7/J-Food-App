import 'dart:async';
import 'dart:convert';
import 'package:j_food_updated/notifications/audio_service.dart';
import 'package:j_food_updated/notifications/notification_service.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:j_food_updated/server/functions/functions.dart';
import 'package:j_food_updated/services/timer_calss.dart';
import 'package:j_food_updated/views/storescreen/widgets/items.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/models/order.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class OrderPage extends StatefulWidget {
  const OrderPage(
      {super.key,
      required this.storeId,
      required this.categoryId,
      required this.changePendingPage,
      required this.storeName,
      required this.storeImage,
      required this.storeLocation,
      required this.deliveryPrice,
      required this.scrollController,
      required this.storeOpenTime,
      required this.storeCloseTime});
  final String storeId;
  final String storeName;
  final String storeImage;
  final String storeOpenTime;
  final String storeCloseTime;
  final String storeLocation;
  final String deliveryPrice;
  final ScrollController scrollController;

  final String categoryId;
  final Function changePendingPage;
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  final StreamController<List<Order>> _ordersStreamController =
      StreamController<List<Order>>.broadcast();
  Timer? _debounce;
  Timer? _timer;
  bool loading = false;
  List<Order> previousOrders = [];
  final AudioService _audioService = AudioService();
  List<int> notifiedOrderIds = [];
  final ValueNotifier<int?> _newOrderNotifier = ValueNotifier<int?>(null);
  int selectedTabIndex = 0;
  int lastSelectedTabIndex = 0;
  bool pendingPage = false;
  String? selectedOrderId;
  double _sliderValue = 15;
  final List<int> _values = [15, 20, 25, 30, 35, 40];
  List<double> _dragOffsets = [];
  final double _maxOffset = 80.0;
  bool _isAnimationShowing = false;
  Map<String, dynamic>? storeData;
  List? displayedProducts;
  List? displayedPackages;
  bool isLoadingMore = false;
  int currentPage = 1;
  int lastPage = 1;
  int _retryCount = 0;
  final int _maxRetries = 3;
  bool _retryScheduled = false;
  @override
  void initState() {
    super.initState();
    if (widget.scrollController.hasClients) {
      widget.scrollController.addListener(_scrollListener);
    }
    fetchOrders(getStatusFromIndex(selectedTabIndex), false);
    _timer = Timer.periodic(
        Duration(seconds: 20),
        (Timer t) => fetchOrders(getStatusFromIndex(selectedTabIndex), false,
            page: currentPage));
    Provider.of<TimerService>(context, listen: false).loadRemainingTimes();
    loadNotifiedOrderIds();
    fetchStoreDetails();
  }

  void _scrollListener() {
    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 300) {
      if (!isLoadingMore && currentPage < lastPage) {
        print("-----");
        setState(() {
          isLoadingMore = true;
        });
        fetchOrders(getStatusFromIndex(selectedTabIndex), false,
            page: currentPage + 1);
      }
    }
  }

  Future<void> fetchStoreDetails() async {
    try {
      // Fetch store details from API
      final data = await getStoreDetails(widget.storeId);

      setState(() {
        storeData = data as Map<String, dynamic>;

        // Handle both paginated and non-paginated products
        final productsData = storeData!["products"];
        if (productsData is Map && productsData.containsKey("data")) {
          // Paginated response: {"data": [...], "meta": {...}}
          displayedProducts = productsData["data"] ?? [];
        } else if (productsData is List) {
          // Non-paginated response: direct list
          displayedProducts = productsData;
        } else {
          displayedProducts = [];
        }

        displayedPackages = storeData!["restaurant"]["restaurant_packages"];
      });
    } catch (e) {
      print("Error fetching store details: $e");
    }
  }

  void toggleOrderDetails(String orderId) {
    setState(() {
      if (selectedOrderId == orderId) {
        selectedOrderId = null;
      } else {
        selectedOrderId = orderId;
      }
    });
  }

  @override
  void dispose() {
    _ordersStreamController.close();
    _debounce?.cancel();
    _timer?.cancel();
    widget.scrollController.removeListener(_scrollListener);
    stopSound();
    super.dispose();
  }

  Future<void> loadNotifiedOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notifiedOrderIds =
          prefs.getStringList('notifiedOrderIds')?.map(int.parse).toList() ??
              [];
    });
  }

  Future<void> saveNotifiedOrderId(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    notifiedOrderIds.add(orderId); // Add new order ID to list
    await prefs.setStringList('notifiedOrderIds',
        notifiedOrderIds.map((id) => id.toString()).toList());
  }

  List<String> getStatusFromIndex(int index) {
    if (index == 0) {
      return ['pending'];
    } else if (index == 1) {
      return ['in_progress'];
    } else if (index == 2) {
      return ['in_delivery'];
    } else {
      throw ArgumentError("Invalid tab index: $index");
    }
  }

  Future<void> fetchOrders(List<String> statuses, bool fromTab,
      {int page = 1}) async {
    if (!mounted) return;
    if (fromTab) {
      setState(() {
        loading = true;
        currentPage = 1;
        previousOrders.clear();
        _ordersStreamController.add([]);
      });
    }

    List<Order> allFetchedOrders = [];

    try {
      for (String status in statuses) {
        final response = await http.get(Uri.parse(
            'https://hrsps.com/login/api/filter_shipment_by_status_new/$status/${widget.storeId}?page=$page'));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final Map<String, dynamic> responseBody = json.decode(response.body);

          if (responseBody.containsKey('orders') &&
              responseBody['orders']['data'] is List) {
            List<Order> fetchedOrders = List<Order>.from(responseBody['orders']
                    ['data']
                .map((data) => Order.fromJson(data)));

            if (status == 'pending') {
              checkForNewOrders(fetchedOrders);
            }
            if (status == 'in_delivery') {
              fetchedOrders = fetchedOrders.reversed.toList();
            }

            allFetchedOrders.addAll(fetchedOrders);

            // Update pagination details
            currentPage = responseBody['orders']['current_page'];
            lastPage = responseBody['orders']['last_page'];
          } else {
            throw Exception('Invalid orders data');
          }
        } else {
          throw Exception('Failed to load orders for status $status');
        }
      }

      if (mounted) {
        setState(() {
          if (page == 1) {
            previousOrders = allFetchedOrders;
          } else {
            previousOrders.addAll(allFetchedOrders);
          }
          isLoadingMore = false;
          lastSelectedTabIndex = selectedTabIndex;
        });
        if (lastSelectedTabIndex == selectedTabIndex) {
          _ordersStreamController.add(previousOrders);
        }
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
        _ordersStreamController.addError('Error fetching orders');
      }
    }

    if (fromTab) {
      setState(() {
        loading = false;
      });
    }
  }

  void checkForNewOrders(List<Order> fetchedOrders) {
    final newOrders = fetchedOrders
        .where((newOrder) =>
            !previousOrders.any((oldOrder) => oldOrder.id == newOrder.id) &&
            !notifiedOrderIds.contains(newOrder.id))
        .toList();

    if (newOrders.isNotEmpty) {
      for (var order in newOrders) {
        // showNotification(order);
        // notifiedOrderIds.add(order.id);
        saveNotifiedOrderId(order.id);
        _newOrderNotifier.value = order.id;
      }
    }
  }

  Future<void> showNotification(Order order) async {
    await flutterLocalNotificationsPlugin.show(
      0,
      'هناك طلب جديد',
      'رقم الطلب: ${order.id}.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'channel id 2',
          'Custom Notifications',
          channelDescription:
              'This channel is used for custom sound notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('sound'),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'sound.wav',
        ),
      ),
    );
    await _audioService.playSound();
  }

  Future<void> stopSound() async {
    await _audioService.stopSound();
  }

  void showLottieAnimation() {
    if (_isAnimationShowing)
      return; // Prevent showing the animation multiple times

    setState(() {
      _isAnimationShowing = true; // Set the flag to true
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Lottie.asset('assets/images/order.json'),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: mainColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextButton(
                          onPressed: () {
                            stopSound();
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "حسنا",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 200),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ).whenComplete(() {
        setState(() {
          _isAnimationShowing = false;
        });
      });
    });
  }

  Future<void> confirmAndStartTimer(
      int orderId, int initialTime, int userId) async {
    try {
      await changeOrderPreparationTime(
          orderId.toString(), initialTime.toString());
      await changeOrderStatus(orderId.toString(), 'in_progress', userId,
          'طلبك الان اصبح قيد التجهيز');
      Provider.of<TimerService>(context, listen: false)
          .startTimer(orderId, initialTime);
      fetchOrders(getStatusFromIndex(selectedTabIndex), false);
    } catch (e) {
      print("Error in confirmAndStartTimer: $e");
    }
  }

  Future<void> changeOrderPreparationTime(
      String orderId, String preparationTime) async {
    await http.post(
      Uri.parse('https://hrsps.com/login/api/change_order_preparation_time'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'order_id': orderId,
        'preparation_time': preparationTime
      }),
    );
  }

  Future<void> sendNotification({
    required List<int> userIds,
    required String title,
    required String body,
  }) async {
    const String notificationUrl = AppLink.sendNotification;

    try {
      final response = await http.post(
        Uri.parse(notificationUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_ids': userIds,
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> changeOrderStatus(
      String orderId, String status, int userId, String msg) async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://hrsps.com/login/api/change_order_status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId, 'status': status}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchOrders(getStatusFromIndex(selectedTabIndex), false);

        await sendNotification(
          userIds: [userId],
          title: 'تحديث بخصوص حالة الطلب',
          body: msg,
        );
      } else {
        throw Exception('Failed to change order status');
      }
    } catch (e) {
      _ordersStreamController.addError('Error changing order status');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 5,
        ),
        Visibility(
          visible: !pendingPage,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: loading
                        ? null
                        : () {
                            setState(() {
                              selectedTabIndex = 0;
                            });
                            fetchOrders(
                                getStatusFromIndex(selectedTabIndex), true);
                          },
                    child: Opacity(
                      opacity: loading ? 0.6 : 1.0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                            color: selectedTabIndex == 0
                                ? mainColor
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                            border: Border.all(
                              color: mainColor,
                              width: selectedTabIndex == 0 ? 2 : 1.0,
                            )),
                        child: Center(
                          child: Text(
                            "طلبات معلقة",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: selectedTabIndex == 0
                                    ? Colors.white
                                    : mainColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 3,
                ),
                Expanded(
                  child: InkWell(
                    onTap: loading
                        ? null
                        : () {
                            setState(() {
                              selectedTabIndex = 1;
                            });
                            fetchOrders(
                                getStatusFromIndex(selectedTabIndex), true);
                          },
                    child: Opacity(
                      opacity: loading ? 0.6 : 1.0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                            color: selectedTabIndex == 1
                                ? mainColor
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                            border: Border.all(
                              color: mainColor,
                              width: selectedTabIndex == 1 ? 2 : 1.0,
                            )),
                        child: Center(
                          child: Text(
                            "قيد التجهيز",
                            style: TextStyle(
                                color: selectedTabIndex == 1
                                    ? Colors.white
                                    : mainColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 3,
                ),
                Expanded(
                  child: InkWell(
                    onTap: loading
                        ? null
                        : () {
                            setState(() {
                              selectedTabIndex = 2;
                            });
                            fetchOrders(
                                getStatusFromIndex(selectedTabIndex), true);
                          },
                    child: Opacity(
                      opacity: loading ? 0.6 : 1.0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                            color: selectedTabIndex == 2
                                ? mainColor
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                            border: Border.all(
                              color: mainColor,
                              width: selectedTabIndex == 2 ? 2 : 1.0,
                            )),
                        child: Center(
                          child: Text(
                            "في التوصيل",
                            style: TextStyle(
                                color: selectedTabIndex == 2
                                    ? Colors.white
                                    : mainColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        buildTabViews(),
        SizedBox(height: 30)
      ],
    );
  }

  Widget buildTabViews() {
    return IndexedStack(
      index: selectedTabIndex,
      children: [
        buildOrdersTab(),
        buildOrdersTab(),
        buildOrdersTab(),
      ],
    );
  }

  Widget buildOrdersTab() {
    return StreamBuilder<List<Order>>(
      stream: _ordersStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || loading) {
          return Column(
            children: [
              SizedBox(
                height: 200,
              ),
              Center(child: CircularProgressIndicator()),
            ],
          );
        } else if (snapshot.hasError) {
          if (_retryCount < _maxRetries && !_retryScheduled) {
            _retryScheduled = true;
            Future.delayed(Duration(seconds: 3), () {
              _retryCount++;
              _retryScheduled = false;
              fetchOrders(getStatusFromIndex(selectedTabIndex), false);
            });

            return Column(
              children: [
                SizedBox(height: 200),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          return Column(
            children: [
              SizedBox(height: 20),
              Center(
                  child: Text(
                "حدث خلل في جلب المعلومات",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )),
              SizedBox(height: 10),
              MaterialButton(
                color: mainColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  _retryCount = 0;
                  fetchOrders(getStatusFromIndex(selectedTabIndex), false);
                  (context as Element).markNeedsBuild();
                },
                child: Text(
                  "اعد المحاولة",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              SizedBox(height: 50),
            ],
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            children: [
              SizedBox(
                height: 200,
              ),
              Center(
                child: Text(
                  "لا يوجد طلبيات قائمة",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            ListView.builder(
              itemCount: previousOrders.length + (isLoadingMore ? 1 : 0),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                if (index == previousOrders.length) {
                  return Center(child: CircularProgressIndicator());
                }
                return buildOrderCard(previousOrders[index]);
              },
            ),
            // ValueListenableBuilder<int?>(
            //   valueListenable: _newOrderNotifier,
            //   builder: (context, orderId, _) {
            //     if (orderId != null) {
            //       WidgetsBinding.instance.addPostFrameCallback((_) {
            //         showLottieAnimation();
            //         _newOrderNotifier.value = null;
            //       });
            //     }
            //     return SizedBox.shrink();
            //   },
            // ),
          ],
        );
      },
    );
  }

  Widget buildOrderCard(Order order) {
    return Column(
      children: [
        if (selectedOrderId == order.id.toString())
          InkWell(
            onTap: () {
              if (order.status != "in_delivery") {
                pendingPage = !pendingPage;
                widget.changePendingPage();
                toggleOrderDetails(order.id.toString());
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xffFFC300)),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 7.0),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Visibility(
          visible: selectedOrderId != null
              ? selectedOrderId == order.id.toString()
              : true,
          child: InkWell(
            onTap: () async {
              widget.scrollController.animateTo(
                0,
                duration: Duration(milliseconds: 100),
                curve: Curves.easeInOut,
              );
              await Future.delayed(Duration(milliseconds: 100));

              if (order.status != "in_delivery") {
                pendingPage = !pendingPage;
                widget.changePendingPage();
                toggleOrderDetails(order.id.toString());
              }
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
              child: Stack(children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Color(0xffF8F8F8),
                      borderRadius: BorderRadius.circular(12)),
                  height: pendingPage ? 170 : 130,
                  child: buildOrderDetails(order),
                ),
                Visibility(
                  visible: pendingPage,
                  child: Positioned(
                    top: 0,
                    left: 0,
                    child: InkWell(
                      onTap: () async {
                        final result = await showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return DraggableScrollableSheet(
                              initialChildSize: 0.9,
                              maxChildSize: 1.0,
                              expand: false,
                              builder: (BuildContext context,
                                  ScrollController scrollController) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ItemWidget(
                                          data: displayedProducts!,
                                          packageData: displayedPackages!,
                                          changeConfirmOrder: () {},
                                          changePackagePage: () {},
                                          open: true,
                                          storeCloseTime: widget.storeCloseTime,
                                          storeOpenTime: widget.storeOpenTime,
                                          storeId: widget.storeId,
                                          storeDeliveryPrice:
                                              widget.deliveryPrice,
                                          storeImage: widget.storeImage,
                                          storeLocation: widget.storeLocation,
                                          storeName: widget.storeName,
                                          orderId: order.id.toString(),
                                          isResturant: true,
                                          workingHours: storeData != null &&
                                                  storeData!["restaurant"] !=
                                                      null &&
                                                  storeData!["restaurant"][
                                                          "j.food.com.jfood"] !=
                                                      null
                                              ? jsonEncode(storeData![
                                                      "restaurant"]
                                                  ["j.food.com.jfood"])
                                              : '[]',
                                          isOpen: storeData != null &&
                                                  storeData!["restaurant"] !=
                                                      null &&
                                                  storeData!["restaurant"]
                                                          ["is_open"] !=
                                                      null
                                              ? (storeData!["restaurant"]
                                                      ["is_open"] is bool
                                                  ? storeData!["restaurant"]
                                                      ["is_open"]
                                                  : storeData!["restaurant"]
                                                                  ["is_open"]
                                                              .toString()
                                                              .toLowerCase() ==
                                                          'true' ||
                                                      storeData!["restaurant"]
                                                                  ["is_open"]
                                                              .toString() ==
                                                          '1')
                                              : false,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );

                        // Check the result of the bottom sheet
                        if (result == true) {
                          fetchOrders(
                              getStatusFromIndex(selectedTabIndex), false);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: mainColor),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Image.asset(
                            'assets/images/+.png',
                            width: 17,
                            height: 17,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ]),
            ),
          ),
        ),
        if (selectedOrderId == order.id.toString()) pendingOrderDetails(order)
      ],
    );
  }

  Widget buildOrderDetails(Order order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: buildOrderInfoWidgets(order),
    );
  }

  List<Widget> buildOrderInfoWidgets(Order order) {
    return [
      Visibility(
        visible: !pendingPage,
        child: Expanded(
          child: Stack(
            children: List.generate(
              order.items.length > 3 ? 3 : order.items.length,
              (index) {
                final imageUrl = order.items[index].product.image;

                return Positioned(
                  top: 10.0,
                  right: (index) * 15.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 3,
                          offset: Offset(0, 3),
                        ),
                      ],
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: imageUrl.isNotEmpty
                            ? FancyShimmerImage(
                                imageUrl: imageUrl,
                                width: 70,
                                height: 70,
                                boxFit: BoxFit.cover,
                                errorWidget: Image.asset(
                                  "assets/images/logo2.png",
                                  width: 70,
                                  height: 70,
                                ),
                              )
                            : Image.asset(
                                "assets/images/logo2.png", // fallback image
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Expanded(
                        child: Text(
                          'اسم العميل',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff5D5D5D),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    '${order.customerName}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xff5D5D5D),
                        fontWeight: FontWeight.bold),
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
                        "assets/images/order-num.png",
                        width: 20,
                        height: 20,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          'رقم الطلب',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff5D5D5D),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    "#${order.id}",
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xff5D5D5D),
                        fontWeight: FontWeight.bold),
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
                        "assets/images/price2.png",
                        width: 24,
                        height: 24,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          'المبلغ',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff5D5D5D),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    "₪${order.total}",
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xff5D5D5D),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await _makePhoneCall(order.mobile);
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/images/res-phone.png",
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'رقم العميل',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xff5D5D5D),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    // onTap: () {
                    //   Clipboard.setData(ClipboardData(text: order.mobile));
                    //   Fluttertoast.showToast(
                    //     msg: "تم نسخ رقم العميل",
                    //     toastLength: Toast.LENGTH_SHORT,
                    //     gravity: ToastGravity.BOTTOM,
                    //     backgroundColor: Colors.black54,
                    //     textColor: Colors.white,
                    //   );
                    // },
                    child: Text(
                      "${order.mobile}",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff5D5D5D),
                          fontWeight: FontWeight.bold),
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
                      Expanded(
                        child: Text(
                          'ساعة الطلب',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff5D5D5D),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    "${DateFormat('HH:mm').format(order.createdAt!)}",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xff5D5D5D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: pendingPage,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'تاريخ الطلب',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff5D5D5D),
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "${DateFormat('yyyy-MM-dd').format(order.createdAt!)}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xff5D5D5D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: pendingPage,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/images/take-way.png",
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          'طريقة الاستلام',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff5D5D5D),
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "${order.checkoutType == "pickup" ? "الاستلام من المطعم" : "التوصيل للبيت"}",
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff5D5D5D),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      buildStatusSpecificWidgets(order),
    ];
  }

  Widget pendingOrderDetails(Order order) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 3),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Color(0xffF8F8F8),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ملاحظات",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 12,
                      color: mainColor,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  order.notes == null ? "لا توجد ملاحظات" : "${order.notes}",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    var item = order.items[index];

                    if (_dragOffsets.length <= index) {
                      _dragOffsets.add(0.0);
                    }
                    return Stack(children: [
                      Visibility(
                        visible: order.status == "pending",
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 5,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      showCancellationDialog(
                                          context, order, item);
                                    },
                                    child: Container(
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: Color(0xffA51E22),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                        ),
                                        child: Image.asset(
                                            "assets/images/delete-button.png")),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragOffsets[index] =
                                (_dragOffsets[index]) + details.delta.dx;
                            _dragOffsets[index] =
                                _dragOffsets[index].clamp(-_maxOffset, 0.0);
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          setState(() {
                            if ((_dragOffsets[index].abs()) < _maxOffset / 2) {
                              _dragOffsets[index] = 0.0;
                            } else {
                              _dragOffsets[index] = -_maxOffset;
                            }
                          });
                        },
                        child: Transform.translate(
                          offset: Offset(_dragOffsets[index], 0),
                          child: InkWell(
                            onTap: () {
                              _showDetailsDialog(item);
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 2,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.product.image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff5E5E5E),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "الكمية : ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: mainColor,
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                item.qty,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Visibility(
                                          visible: item.size.size != "",
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    "الحجم : ",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: mainColor,
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      item.size.size,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Visibility(
                                          visible: item.components.isNotEmpty,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    "المكونات : ",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: mainColor,
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      item.componentsAsString,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Visibility(
                                          visible: item.drinks.isNotEmpty,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "المشروبات: ",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: mainColor,
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      item.drinksAsString,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Color(0xffEAEAEA)),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          child: Text(
                                            "₪${item.totalPrice}",
                                            style: TextStyle(
                                              color: mainColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
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
                      ),
                    ]);
                  }),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      color: fourthColor,
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text(
                      "المجموع: ${order.total}₪",
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: order.status == "pending",
                child: Text(
                  "وقت تجهيز الطلب",
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              Visibility(
                visible: order.status == "pending",
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Color(0xffEAEAEA),
                    inactiveTrackColor: Color(0xffEAEAEA),
                    trackHeight: 5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
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
              ),
              Visibility(
                visible: order.status == "pending",
                child: Padding(
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
              ),
              SizedBox(
                height: 10,
              ),
              Visibility(
                visible: order.status == "in_progress",
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: InkWell(
                    onTap: () {
                      generatePdf(order);
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                          color: mainColor,
                          borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: Text(
                          "طباعة الفاتورة",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: order.status == "pending",
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: InkWell(
                    onTap: () {
                      if (_sliderValue > 20) {
                        _showPreparationTimeWarningDialog(order);
                      } else {
                        _proceedWithOrderConfirmation(order);
                      }
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                          color: mainColor,
                          borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: Text(
                          "اضافة الطلب الى قائمة قيد التجهيز",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildStatusSpecificWidgets(Order order) {
    if (selectedTabIndex == 1) {
      if (order.status == 'in_progress') {
        return buildInProgressWidgets(order);
      } else {
        return SizedBox.shrink();
      }
    }
    return SizedBox.shrink();
  }

  Widget buildInProgressWidgets(Order order) {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        final remainingTime = timerService.getRemainingTime(order.id);

        return InkWell(
          // onTap: () async {
          //   await changeOrderStatus(order.id.toString(), 'ready_for_delivery',
          //       order.userId, 'طلبك الان اصبح جاهز للتوصيل');
          // },
          child: Container(
            width: 40,
            height: 30,
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                timerService.formatTime(remainingTime),
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> generatePdf(Order order) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/cairo.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Load logo
    final logoBytes = await rootBundle.load('assets/images/logo3.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    const pageWidth = 226.77;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(pageWidth, PdfPageFormat.a4.height),
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Center(
            child: pw.Image(logoImage, height: 50),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'فاتورة الطلب',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          _buildOrderInfo(ttf, order),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.Text(
            'تفاصيل الطلب:',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          ...List.generate(order.items.length, (index) {
            final item = order.items[index];
            final isEven = index % 2 == 0;
            return pw.Container(
              padding: const pw.EdgeInsets.all(6),
              margin: const pw.EdgeInsets.only(bottom: 6),
              decoration: pw.BoxDecoration(
                color: isEven ? PdfColors.grey100 : PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '- ${item.product.name} (x${item.qty})',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (item.size.size.isNotEmpty)
                    pw.Text('  الحجم: ${item.size.size}',
                        style: pw.TextStyle(font: ttf, fontSize: 11)),
                  if (item.components.isNotEmpty)
                    pw.Text('  الإضافات: ${item.componentsAsString}',
                        style: pw.TextStyle(font: ttf, fontSize: 11)),
                  if (item.drinks.isNotEmpty)
                    pw.Text('  المشروبات: ${item.drinksAsString}',
                        style: pw.TextStyle(font: ttf, fontSize: 11)),
                  pw.Text(
                    '  السعر: ${item.totalPrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: ttf, fontSize: 11),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/order_${order.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    await OpenFile.open(file.path);
  }

  pw.Widget _buildOrderInfo(pw.Font ttf, Order order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('رقم الطلب: ${order.id}',
            style: pw.TextStyle(font: ttf, fontSize: 12)),
        pw.Text('المجموع: ${order.total}',
            style: pw.TextStyle(font: ttf, fontSize: 12)),
        pw.Text('رقم الجوال: ${order.mobile}',
            style: pw.TextStyle(font: ttf, fontSize: 12)),
        pw.Text('الوقت: ${DateFormat('HH:mm').format(order.createdAt!)}',
            style: pw.TextStyle(font: ttf, fontSize: 12)),
        pw.Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(order.createdAt!)}',
            style: pw.TextStyle(font: ttf, fontSize: 12)),
        pw.Text(
            'ملاحظات: ${order.notes == null ? "لا توجد ملاحظات" : order.notes}',
            style: pw.TextStyle(font: ttf, fontSize: 12)),
        pw.Text(
          order.checkoutType == "pickup"
              ? "الاستلام من المطعم"
              : "التوصيل للبيت",
          style: pw.TextStyle(font: ttf, fontSize: 12),
        ),
      ],
    );
  }

  void showCancellationDialog(BuildContext context, Order order, Item item) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: Text(
              "هل تريد حذف هذه الوجبة من الطلب؟",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse(
                          '${AppLink.deleteProductInOrder}/${item.id}');
                      print(url);
                      try {
                        final response = await http.delete(url);

                        if (response.statusCode == 200) {
                          // final data = json.decode(response.body);
                          Navigator.pop(context);
                          fetchOrders(
                              getStatusFromIndex(selectedTabIndex), false);
                          Fluttertoast.showToast(
                              msg: "تم حذف هذه الوجبة بنجاح",
                              timeInSecForIosWeb: 3);
                        } else {
                          print(
                              'Failed to delete order: ${response.statusCode}');
                          Fluttertoast.showToast(
                              msg: "فشلت عملية حذف الوجبة",
                              timeInSecForIosWeb: 3);
                        }
                      } catch (e) {
                        // Handle error (e.g., network issue, invalid URL, etc.)
                        print('Error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('An error occurred. Please try again.')),
                        );
                      }
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
    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       backgroundColor: Colors.white,
    //       title: Text(
    //         'هل تريد الغاء الطلبية ؟',
    //         style: TextStyle(fontSize: 18),
    //       ),
    //       actions: <Widget>[
    //         MaterialButton(
    //             color: Colors.red,
    //             child: Text(
    //               'الغاء',
    //               style: TextStyle(
    //                 color: Colors.white,
    //               ),
    //             ),
    //             onPressed: () => Navigator.of(context).pop()),
    //         MaterialButton(
    //           color: Colors.blue,
    //           child: Text('تأكيد',
    //               style: TextStyle(
    //                 color: Colors.white,
    //               )),
    //           onPressed: () {
    //             changeOrderStatus(order.id.toString(), 'canceled');
    //             Navigator.of(context).pop();
    //           },
    //         ),
    //       ],
    //     );
    //   },
    // );
  }

  void _showDetailsDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) {
        double totalPrice = item.totalPrice;

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: Color(0xffF8F8F8),
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.product.image,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              "${item.product.name}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor),
                            )
                          ],
                        ),
                        Text(
                          "₪${item.price}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: mainColor),
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Container(
                  decoration: BoxDecoration(
                      color: Color(0xffF8F8F8),
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 4),
                    child: Column(
                      children: [
                        Visibility(
                          visible: item.size.size != "",
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "الحجم",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor),
                              ),
                              Text(
                                "${item.size.size}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: mainColor),
                              )
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "الكمية",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor),
                            ),
                            Text(
                              "${item.qty}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: mainColor),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "المجموع",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor),
                            ),
                            Text(
                              "₪${item.price} ${item.qty}x",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7)),
                            ),
                            Text(
                              "₪${double.parse(item.price) * double.parse(item.qty)}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: mainColor),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Visibility(
                  visible: item.components.isNotEmpty || item.drinks.isNotEmpty,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Color(0xffF8F8F8),
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.components.isNotEmpty) ...[
                            Text(
                              "المكونات",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor),
                            ),
                            Column(
                              children: List.generate(
                                item.components.length,
                                (index) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.components[index].comName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: textColor),
                                      ),
                                      Text(
                                        "₪${item.components[index].comPrice} ${item.componentIdsQty[index]}x",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color:
                                                Colors.black.withOpacity(0.7)),
                                      ),
                                      Text(
                                        "₪${double.parse(item.components[index].comPrice) * item.componentIdsQty[index]}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: mainColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          Divider(
                            color: textColor.withOpacity(0.5),
                          ),
                          if (item.drinks.isNotEmpty) ...[
                            Text(
                              "المشروبات",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor),
                            ),
                            Column(
                              children: List.generate(
                                item.drinks.length,
                                (index) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.drinks[index].drinkName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: textColor),
                                      ),
                                      Text(
                                        "₪${item.drinks[index].drinkPrice} ${item.drinkIdsQty[index]}x",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Colors.black.withOpacity(0.7)),
                                      ),
                                      Text(
                                        "₪${double.parse(item.drinks[index].drinkPrice) * item.drinkIdsQty[index]}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: mainColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "المجموع",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor),
                              ),
                              Text(
                                "₪${item.totalDrinksPrice + item.totalComponentsPrice}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: textColor),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: mainColor),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 3),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "الإجمالي",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "₪$totalPrice",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    launch("tel://$phoneNumber");
  }

  void _showPreparationTimeWarningDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: mainColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تنبيه مهم',
                style: TextStyle(
                  color: mainColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يرجى الانتباه والتقيد بالتالي:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'نحن غير مسؤولين عن أي طلب يستغرق وقت تحضير أكثر من 20 دقيقة، إلا في حال تم إبلاغ الزبون مسبقاً بمدة التحضير ووافق عليها.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: mainColor.withOpacity(0.3)),
              ),
              child: const Text(
                '❗ إذا لاحظت أن الطلب بحاجة لأكثر من 20 دقيقة تحضير، يجب عليك التواصل مع الزبون مباشرة وإبلاغه بالمدة المتوقعة قبل متابعة الطلب.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'أي تأخير ناتج عن عدم إبلاغ الزبون سيتم تحميل مسؤوليته للمطعم',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedWithOrderConfirmation(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الموافقة'),
          ),
        ],
      ),
    );
  }

  void _proceedWithOrderConfirmation(Order order) {
    confirmAndStartTimer(order.id, _sliderValue.toInt(), order.userId);
    toggleOrderDetails(order.id.toString());
    widget.changePendingPage();
    setState(() {
      pendingPage = !pendingPage;
    });
    generatePdf(order);
    Fluttertoast.showToast(
      backgroundColor: Colors.green,
      msg: "تم وضع الطلب قيد التجهيز",
      timeInSecForIosWeb: 2,
    );
  }
}
