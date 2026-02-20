import 'dart:async';
import 'dart:convert';
import 'package:j_food_updated/LocalDB/Database/Database.dart';
import 'package:j_food_updated/LocalDB/Models/CategoryItem.dart';
import 'package:j_food_updated/component/header/header.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/models/slider_model.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:j_food_updated/views/homescreen/widgets/category.dart';
import 'package:j_food_updated/views/homescreen/widgets/pre_order_resturant.dart';
import 'package:j_food_updated/views/homescreen/widgets/slider.dart';
import 'package:j_food_updated/views/homescreen/widgets/special_resturants.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class MainScreen extends StatefulWidget {
  const MainScreen(
      {super.key,
      this.changeDelivery,
      required this.noDelivery,
      this.changeRamadanTime,
      this.changeAppError,
      required this.changeTab});
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
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final connectivityResult =
          result.isNotEmpty ? result.first : ConnectivityResult.none;
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

  Stream<Map<String, dynamic>> homeDataStream() async* {
    while (true) {
      yield await getHomeDataList();
      await Future.delayed(Duration(minutes: 5));
    }
  }

  Future<Map<String, dynamic>> getHomeDataList() async {
    try {
      var response = await http.get(Uri.parse(AppLink.homeData));
      if (response.statusCode == 200 || response.statusCode == 201) {
        var res = json.decode(response.body);

        if (res is Map<String, dynamic>) {
          res['sliders'] = res['sliders'] ??
              [
                {
                  "id": 59,
                  "url":
                      "https://hrsps.com/login/storage/Sliders-Talabat/Ojr4wmEZKMxwSVnJabBBkigTkQilA4hfDEJQw9IO.jpg",
                  "type": "restaurent",
                  "data_id": 127
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
          'message': 'There is an error in the server, it will be solved soon.'
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            setState(() {});
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
              SizedBox(
                width: 15,
              ),
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
              description: description, onConfirm: widget.changeDelivery!);
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
                  fontSize: 16, fontWeight: FontWeight.bold, color: mainColor),
            ),
            MaterialButton(
              onPressed: () {
                setState(() {});
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              color: mainColor,
              child: Text(
                "حاول مرة اخرى",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            )
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