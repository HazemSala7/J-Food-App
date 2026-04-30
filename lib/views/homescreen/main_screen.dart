import 'dart:async';
import 'dart:convert';
import 'package:j_food_updated/LocalDB/Database/Database.dart';
import 'package:j_food_updated/LocalDB/Models/CategoryItem.dart';
import 'package:j_food_updated/component/header/header.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/models/slider_model.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:j_food_updated/server/functions/functions.dart';
import 'package:j_food_updated/views/homescreen/widgets/category.dart';
import 'package:j_food_updated/views/homescreen/widgets/pre_order_resturant.dart';
import 'package:j_food_updated/views/homescreen/widgets/slider.dart';
import 'package:j_food_updated/views/homescreen/widgets/special_resturants.dart';
import 'package:j_food_updated/views/orders_screen/home_order_details_screen.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    this.changeDelivery,
    required this.noDelivery,
    this.changeRamadanTime,
    this.changeAppError,
    required this.changeTab,
  });
  final Function? changeDelivery;
  final Function? changeRamadanTime;
  final Function? changeAppError;
  final bool noDelivery;
  final Function(int) changeTab;
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool noDelivery = false;
  bool validPhone = false;
  TextEditingController phoneController = TextEditingController();
  bool _hasShownModal = false;
  @override
  bool get wantKeepAlive => true;
  final CartDatabaseHelper dbHelper = CartDatabaseHelper();
  late Stream<ConnectivityResult> connectivityStream;
  final Connectivity _connectivity = Connectivity();
  late StreamController<ConnectivityResult> _connectivityController;
  late Future<List<Map<String, dynamic>>> _currentOrdersFuture;
  List<Map<String, dynamic>> _currentOrdersFromHome = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Create a StreamController to manage connectivity state
    _connectivityController = StreamController<ConnectivityResult>();

    // Listen to connectivity changes and emit them
    _connectivity.onConnectivityChanged.listen((list) {
      final result = list.isNotEmpty ? list.first : ConnectivityResult.none;
      _connectivityController.add(result);
    });

    // Check initial connectivity status
    _checkConnectivity();

    connectivityStream = _connectivityController.stream;
    _currentOrdersFuture = _fetchCurrentOrders();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final connectivityResult = result.isNotEmpty
          ? result.first
          : ConnectivityResult.none;
      _connectivityController.add(connectivityResult);
    } catch (e) {
      print('Error checking connectivity: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityController.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When the app resumes, check connectivity status
      _checkConnectivity();
    }
  }

  Future<void> syncCategoriesFromApi(List<dynamic> categories) async {
    final CartDatabaseHelper dbHelper = CartDatabaseHelper();

    try {
      await dbHelper.deleteAllCategories();

      List<CategoryItem> categoryItems = categories.map((category) {
        return CategoryItem(
          id: category['id'],
          name: category['name'],
          image: category['image'],
        );
      }).toList();

      for (var category in categoryItems) {
        await dbHelper.insertCategory(category);
      }
    } catch (e) {
      print('Error syncing categories: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCurrentOrders() async {
    try {
      final data = await getHomeDataList();

      if (data == null || data is! Map) {
        return [];
      }

      final dynamic hasOrder = data['has_order'];
      if (hasOrder == true || hasOrder == 1 || hasOrder == "1") {
        if (data['current_orders'] is List) {
          final List orders = data['current_orders'] as List;
          return orders
              .whereType<Map<String, dynamic>>()
              .map((o) => Map<String, dynamic>.from(o))
              .where((o) => _isActiveOrder(o))
              .toList();
        }
        // Fallback: support old single current_order key
        if (data['current_order'] is Map<String, dynamic>) {
          final currentOrder = Map<String, dynamic>.from(
            data['current_order'] as Map,
          );
          if (_isActiveOrder(currentOrder)) {
            return [currentOrder];
          }
        }
      }

      return [];
    } catch (e) {
      print('Error fetching current orders: $e');
      return [];
    }
  }

  bool _isActiveOrder(Map<String, dynamic> order) {
    final String status = (order['status'] ?? '').toString();
    return status == 'pending' ||
        status == 'in_progress' ||
        status == 'ready_for_delivery' ||
        status == 'in_delivery';
  }

  String _getOrderStatusText(String status, String checkoutType) {
    switch (status) {
      case "pending":
        return "قيد المعالجة";
      case "in_progress":
        return "قيد التجهيز";
      case "ready_for_delivery":
        return checkoutType == "pickup" ? "جاهز للاستلام" : "جاهز للتوصيل";
      case "delivered":
        return "تم التوصيل";
      case "in_delivery":
        return checkoutType == "pickup" ? "تم الاستلام" : "في التوصيل";
      case "canceled":
        return "تم الغائه";
      default:
        return "تم رفضه";
    }
  }

  String _getOrderStatusIcon(String status, String checkoutType) {
    if (status == "pending") return "assets/images/order-ready.png";
    if (status == "in_progress") return "assets/images/in-work.png";
    if (status == "ready_for_delivery") return "assets/images/in-work.png";
    if (status == "in_delivery") {
      return checkoutType == "pickup"
          ? "assets/images/delivery-done.png"
          : "assets/images/in-delivery.png";
    }
    return "assets/images/delivery-done.png";
  }

  Widget _buildCurrentOrderSection() {
    if (_currentOrdersFromHome.isNotEmpty) {
      return Column(
        children: _currentOrdersFromHome
            .map((order) => _buildCurrentOrderCard(order))
            .toList(),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _currentOrdersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final orders = snapshot.data;
        if (orders == null || orders.isEmpty) return const SizedBox.shrink();

        return Column(
          children: orders
              .map((order) => _buildCurrentOrderCard(order))
              .toList(),
        );
      },
    );
  }

  int _getStatusStep(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'in_progress':
        return 1;
      case 'ready_for_delivery':
        return 2;
      case 'in_delivery':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildStatusDots(int currentStep) {
    const int totalSteps = 4;
    return Row(
      children: List.generate(totalSteps, (index) {
        final bool isActive = index <= currentStep;
        final bool isCurrent = index == currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: index < totalSteps - 1 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.25),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentOrderCard(Map<String, dynamic> order) {
    final int orderId = order['id'] ?? 0;
    final String status = order['status'] ?? 'unknown';
    final String checkoutType = order['checkout_type'] ?? 'unknown';
    final String statusText = _getOrderStatusText(status, checkoutType);
    final String storeName = order['restaurant']?['name'] ?? "";
    final String orderNumber = (order['id'] ?? '').toString();
    final int statusStep = _getStatusStep(status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeOrderDetailsScreen(
                orderId: orderId,
                status: status,
                checkoutType: checkoutType,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                mainColor,
                mainColor.withOpacity(0.85),
                const Color(0xffB83634),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: mainColor.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circle
              Positioned(
                left: -20,
                top: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                left: 30,
                bottom: -15,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Image.asset(
                            _getOrderStatusIcon(status, checkoutType),
                            width: 26,
                            height: 26,
                            color: Colors.white,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      "لديك طلبية حالية",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "تتبع",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5,
                                            color: Colors.white.withOpacity(0.95),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 10,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "#$orderNumber${storeName.isNotEmpty ? "  •  $storeName" : ""}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Progress bar
                    _buildStatusDots(statusStep),
                    const SizedBox(height: 8),
                    // Status label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xffFFC509),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffFFC509).withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
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

  Stream<Map<String, dynamic>> homeDataStream() async* {
    while (true) {
      yield await getHomeDataList();
      await Future.delayed(Duration(minutes: 5));
    }
  }

  // ---- Cache keys ----
  static const String _kCacheSliders = 'home_cache_sliders';
  static const String _kCacheCategories = 'home_cache_categories';
  static const String _kCacheStatic = 'home_cache_static';
  static const String _kCacheTimestamp = 'home_cache_timestamp';
  static const int _kCacheTtlMs = 24 * 60 * 60 * 1000; // 24 hours

  bool _isCacheFresh(int timestamp) =>
      (DateTime.now().millisecondsSinceEpoch - timestamp) < _kCacheTtlMs;

  Future<void> _saveStaticCache(
      SharedPreferences prefs, Map<String, dynamic> res) async {
    final sliders = res['sliders'];
    final categories = res['categories'];
    final staticData = {
      'close_app': res['close_app'],
      'app_type': res['app_type'],
      'error': res['error'],
      'error_description': res['error_description'],
      'error_image': res['error_image'],
    };
    if (sliders != null)
      await prefs.setString(_kCacheSliders, json.encode(sliders));
    if (categories != null)
      await prefs.setString(_kCacheCategories, json.encode(categories));
    await prefs.setString(_kCacheStatic, json.encode(staticData));
    await prefs.setInt(
        _kCacheTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>> getHomeDataList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String userId = prefs.getString('user_id') ?? "";

      final String? cachedSlidersJson = prefs.getString(_kCacheSliders);
      final String? cachedCategoriesJson = prefs.getString(_kCacheCategories);
      final String? cachedStaticJson = prefs.getString(_kCacheStatic);
      final int cachedTimestamp = prefs.getInt(_kCacheTimestamp) ?? 0;

      final bool cacheIsFresh = cachedSlidersJson != null &&
          cachedCategoriesJson != null &&
          cachedStaticJson != null &&
          _isCacheFresh(cachedTimestamp);

      // No user logged in + cache is fresh → skip API call entirely
      if (cacheIsFresh && userId.isEmpty) {
        final Map<String, dynamic> result =
            Map<String, dynamic>.from(json.decode(cachedStaticJson!));
        result['sliders'] = json.decode(cachedSlidersJson!);
        result['categories'] = json.decode(cachedCategoriesJson!);
        result['special_restaurensts'] =
            result['special_restaurensts'] ?? [];
        result['has_order'] = false;
        return result;
      }

      Uri homeUri = Uri.parse(AppLink.homeDataSimple);
      if (userId.isNotEmpty) {
        homeUri = homeUri.replace(queryParameters: {'user_id': userId});
      }

      var response = await http.get(homeUri);
      if (response.statusCode == 200 || response.statusCode == 201) {
        var res = json.decode(response.body);

        if (res is Map<String, dynamic>) {
          if (cacheIsFresh) {
            // Use cached sliders/categories, only take current_orders from API
            res['sliders'] = json.decode(cachedSlidersJson!);
            res['categories'] = json.decode(cachedCategoriesJson!);
          } else {
            // Stale/missing cache → save fresh data
            await _saveStaticCache(prefs, res);
          }

          res['sliders'] = res['sliders'] ??
              [
                {
                  "id": 59,
                  "url":
                      "https://hrsps.com/login/storage/Sliders-Talabat/Ojr4wmEZKMxwSVnJabBBkigTkQilA4hfDEJQw9IO.jpg",
                  "type": "restaurent",
                  "data_id": 127,
                },
              ];
          res['special_restaurensts'] = res['special_restaurensts'] ?? [];
          res['categories'] = res['categories'] ?? [];

          return res;
        } else {
          print('Unexpected response structure');
        }
      } else if (response.statusCode == 500) {
        return {
          'error': 'server',
          'message': 'There is an error in the server, it will be solved soon.',
        };
      } else {
        print('Unexpected response: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching home data: $e');
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<ConnectivityResult>(
      stream: connectivityStream,
      initialData: ConnectivityResult.none,
      builder: (context, connectivitySnapshot) {
        // Check if connected to any network
        final bool hasNetworkConnection =
            connectivitySnapshot.data != ConnectivityResult.none;

        return Container(
          color: Colors.white,
          child: SafeArea(
            child: WillPopScope(
              onWillPop: () async => false,
              child: Scaffold(
                body: hasNetworkConnection
                    ? _buildOnlineView(context)
                    : _buildOfflineView(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnlineView(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: homeDataStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData) return noData();

        final Map data = snapshot.data as Map;
        return _handleData(context, data);
      },
    );
  }

  Widget _buildOfflineView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 50, color: mainColor),
          const SizedBox(height: 10),
          const Text(
            "لا يوجد اتصال بالانترنت",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          MaterialButton(
            color: mainColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onPressed: () {
              // Check connectivity when retry is pressed
              _checkConnectivity();
            },
            child: const Text(
              "اعد المحاولة",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------- DATA HANDLING --------------------
  Widget _handleData(BuildContext context, Map data) {
    if (_shouldShowErrorModal(data)) {
      _showErrorModal(context, data['error_description']);
    } else if (_shouldCloseApp(data)) {
      _showCloseAppModal(context, data['error_description']);
    } else if (data['error'] == 'server') {
      return _buildServerError();
    }

    if (data["sliders"] == null || data["categories"] == null) {
      return noData();
    }

    final List<SliderClass> sliders = (data["sliders"] ?? [])
        .map<SliderClass>((s) => SliderClass.fromJson(s))
        .toList();

    syncCategoriesFromApi(data["categories"]);

    final bool ramadanTime = data["app_type"] == "ramadan";
    if (ramadanTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.changeRamadanTime!(true);
      });
    }

    final dynamic hasOrder = data['has_order'];
    if (hasOrder == true || hasOrder == 1 || hasOrder == "1") {
      if (data['current_orders'] is List) {
        final List orders = data['current_orders'] as List;
        _currentOrdersFromHome = orders
            .whereType<Map<String, dynamic>>()
            .map((o) => Map<String, dynamic>.from(o))
            .where((o) => _isActiveOrder(o))
            .toList();
      } else if (data['current_order'] is Map<String, dynamic>) {
        // Fallback: support old single current_order key
        final currentOrder = Map<String, dynamic>.from(
          data['current_order'] as Map,
        );
        if (_isActiveOrder(currentOrder)) {
          _currentOrdersFromHome = [currentOrder];
        } else {
          _currentOrdersFromHome = [];
        }
      } else {
        _currentOrdersFromHome = [];
      }
    } else {
      _currentOrdersFromHome = [];
    }

    return _buildHomeContent(context, data, sliders, ramadanTime);
  }

  Widget _buildHomeContent(
    BuildContext context,
    Map data,
    List<SliderClass> sliders,
    bool ramadanTime,
  ) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        RefreshIndicator(
          color: mainColor,
          backgroundColor: Colors.white,
          displacement: 40,
          strokeWidth: 3.0,
          onRefresh: () async {
            setState(() {
              _currentOrdersFromHome = [];
              _currentOrdersFuture = _fetchCurrentOrders();
            });
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 65,
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                backgroundColor: Colors.transparent,
                toolbarHeight: 65,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.none,
                  background: Header(
                    fromAllResturant: false,
                    noDelivery: widget.noDelivery,
                    changeTab: widget.changeTab,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildCurrentOrderSection(),
                    _buildSliderSection(context, sliders),
                    _buildSpecialRestaurantsSection(data, ramadanTime),
                    _buildRamadanRestaurantsSection(data, ramadanTime),
                    _buildCategoriesSection(data, ramadanTime),
                  ],
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: data['error'] == "true",
          child: FancyShimmerImage(
            boxFit: BoxFit.fill,
            imageUrl: data['error_image'] ?? "",
            errorWidget: Image.asset("assets/images/bbb.png", fit: BoxFit.fill),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSection(BuildContext context, List<SliderClass> sliders) {
    if (sliders.isNotEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.28,
        child: StackedSlider(
          sliders: sliders,
          noDelivery: widget.noDelivery,
          changeTab: widget.changeTab,
        ),
      );
    }

    return Image.asset(
      "assets/images/logo2.png",
      fit: BoxFit.cover,
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.28,
    );
  }

  Widget _buildSpecialRestaurantsSection(Map data, bool ramadanTime) {
    if (data['special_restaurensts'] == null ||
        data['special_restaurensts'].isEmpty) {
      return const SizedBox.shrink();
    }

    return Visibility(
      visible: !ramadanTime,
      child: Padding(
        padding: const EdgeInsets.only(right: 4.0, top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Text(
                "المطاعم المميزة",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xff982C2A),
                ),
              ),
            ),
            SpecialRestaurantsWidget(
              restaurants: data['special_restaurensts'],
              noDelivery: widget.noDelivery,
              changeTab: widget.changeTab,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRamadanRestaurantsSection(Map data, bool ramadanTime) {
    if (data['ramadan_restaurents'] == null ||
        data['ramadan_restaurents'].isEmpty) {
      return const SizedBox.shrink();
    }

    return Visibility(
      visible: ramadanTime,
      child: Padding(
        padding: const EdgeInsets.only(right: 4.0, top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Text(
                "مطاعم الحجز المسبق",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xff982C2A),
                ),
              ),
            ),
            PreOrderResturant(
              restaurants: data['ramadan_restaurents'],
              noDelivery: widget.noDelivery,
              changeTab: widget.changeTab,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(Map data, bool ramadanTime) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 15),
              Text(
                ramadanTime ? "الماركت" : "الأقسام الرئيسية",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xff982C2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CategoryWidget(
              cat: data['categories'],
              noDelivery: noDelivery,
              fromMarket: false,
              ramadanTime: ramadanTime,
              changeTab: widget.changeTab,
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------- HELPERS --------------------
  bool _shouldShowErrorModal(Map data) =>
      data['error'] == "true" && !_hasShownModal;

  bool _shouldCloseApp(Map data) =>
      data['close_app'] == "true" && !_hasShownModal;

  Widget _buildServerError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.error),
          Text(
            "هناك مشكلة بالسيرفر يتم العمل على حلها",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }

  void _showErrorModal(BuildContext context, String description) {
    _hasShownModal = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.changeAppError!(true);
    });
  }

  void _showCloseAppModal(BuildContext context, String description) {
    _hasShownModal = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return _CloseAppSheet(
            description: description,
            onConfirm: widget.changeDelivery!,
          );
        },
      );
    });
  }

  Widget noData() {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "حدث خطأ اثناء تحميل البيانات",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
            ),
            MaterialButton(
              onPressed: () {
                setState(() {});
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: mainColor,
              child: Text(
                "حاول مرة اخرى",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- SEPARATE WIDGET --------------------
class _CloseAppSheet extends StatelessWidget {
  final String description;
  final Function onConfirm;

  const _CloseAppSheet({
    Key? key,
    required this.description,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/no-truck.png', width: 200, height: 200),
          const SizedBox(height: 30),
          Container(
            color: mainColor,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: Text(
              "خدمة التوصيل غير متاحة الان بسبب $description يمكنك الطلب والاستلام من المطعم",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
              child: const Text("حسنا", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 200),
        ],
      ),
    );
  }
}
// ...List.generate(
                                              //   data['categories'].length,
                                              //   (index) => Container(
                                              //     margin: const EdgeInsets.only(right: 8),
                                              //     child: Column(
                                              //       crossAxisAlignment: CrossAxisAlignment.start,
                                              //       children: [
                                              //         Visibility(
                                              //           visible: data['categories'][index]
                                              //                   ['restaurants']
                                              //               .isNotEmpty,
                                              //           child: Row(
                                              //             mainAxisAlignment:
                                              //                 MainAxisAlignment.spaceBetween,
                                              //             children: [
                                              //               Text(
                                              //                 data['categories'][index]['name'],
                                              //                 style: const TextStyle(
                                              //                     fontWeight: FontWeight.bold,
                                              //                     fontSize: 17),
                                              //               ),
                                              //               Padding(
                                              //                 padding:
                                              //                     const EdgeInsets.only(left: 8),
                                              //                 child: InkWell(
                                              //                   onTap: () {
                                              //                     NavigatorFunction(
                                              //                         context,
                                              //                         AllResturants(
                                              //                           storesArray:
                                              //                               data['categories']
                                              //                                       [index]
                                              //                                   ['restaurants'],
                                              //                           title: data['categories']
                                              //                               [index]['name'],
                                              //                           noDelivery: noDelivery,
                                              //                         ));
                                              //                   },
                                              //                   child: Text(
                                              //                     "عرض المزيد",
                                              //                     style: TextStyle(
                                              //                         color: mainColor,
                                              //                         fontWeight: FontWeight.bold,
                                              //                         fontSize: 16),
                                              //                   ),
                                              //                 ),
                                              //               )
                                              //             ],
                                              //           ),
                                              //         ),
                                              //         Padding(
                                              //           padding:
                                              //               const EdgeInsets.only(right: 5, top: 5),
                                              //           child: ShopsWidgets(
                                              //               categoryName: data['categories'][index]
                                              //                   ["name"],
                                              //               storesArray: data['categories'][index]
                                              //                   ['restaurants'],
                                              //               noDelivery: noDelivery),
                                              //         ),
                                              //         Visibility(
                                              //           visible: data['categories'][index]
                                              //                   ['restaurants']
                                              //               .isNotEmpty,
                                              //           child: Divider(
                                              //             color: mainColor,
                                              //           ),
                                              //         ),
                                              //       ],
                                              //     ),
                                              //   ),
                                              // )