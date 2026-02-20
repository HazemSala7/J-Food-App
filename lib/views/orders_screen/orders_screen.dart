import 'dart:convert';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:j_food_updated/views/orders_screen/orders_provider.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:http/http.dart' as http;
import 'package:j_food_updated/LocalDB/Models/CartItem.dart';
import 'package:j_food_updated/LocalDB/Provider/CartProvider.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/models/user_order.dart';
import 'package:j_food_updated/views/orders_screen/order_details.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String user_id = "";
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    setControllers();
  }

  void _onScroll() {
    if (!mounted) return;

    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    if (!ordersProvider.isLoadingMore &&
        ordersProvider.hasMoreOrders &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      ordersProvider.loadMoreOrders(user_id);
    }
  }

  setControllers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('user_id') ?? "";
    setState(() {
      user_id = userID;
    });
    print("UserID: $userID");

    // Fetch initial orders
    if (mounted && userID.isNotEmpty) {
      Future.microtask(() {
        Provider.of<OrdersProvider>(context, listen: false).fetchOrders(userID);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
              child: Column(
                children: [
                  SizedBox(height: 15),
                  Consumer<OrdersProvider>(
                    builder: (context, ordersProvider, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 34.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  ordersProvider.changeTab(0);
                                },
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color:
                                            ordersProvider.activeTabIndex == 0
                                                ? mainColor
                                                : Color(0xffB1B1B1),
                                        width:
                                            ordersProvider.activeTabIndex == 0
                                                ? 2
                                                : 1,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "طلباتي الحالية",
                                      style: TextStyle(
                                          color:
                                              ordersProvider.activeTabIndex == 0
                                                  ? mainColor
                                                  : Color(0xffB1B1B1),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  ordersProvider.changeTab(1);
                                },
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color:
                                            ordersProvider.activeTabIndex == 1
                                                ? mainColor
                                                : Color(0xffB1B1B1),
                                        width:
                                            ordersProvider.activeTabIndex == 1
                                                ? 2
                                                : 1.0,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "طلباتي السابقة",
                                      style: TextStyle(
                                          color:
                                              ordersProvider.activeTabIndex == 1
                                                  ? mainColor
                                                  : Color(0xffB1B1B1),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Consumer<OrdersProvider>(
                      builder: (context, ordersProvider, _) {
                        if (ordersProvider.isLoading) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (ordersProvider.hasError) {
                          return Center(
                            child: Text(
                              'حدث خطأ ما. حاول مرة أخرى.',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          );
                        } else if (ordersProvider.displayedOrders.isEmpty) {
                          return Center(
                            child: Text(
                              'لا يوجد أية طلبية هنا',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          );
                        } else {
                          return ListView.builder(
                            controller: _scrollController,
                            itemCount: ordersProvider.displayedOrders.length +
                                (ordersProvider.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Show loading indicator at the end
                              if (index ==
                                  ordersProvider.displayedOrders.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              Map<String, dynamic> order =
                                  ordersProvider.displayedOrders[index];

                              List<String> images = [];
                              if (order['order_details'] != null) {
                                for (var detail in order['order_details']) {
                                  if (detail['product'] != null &&
                                      detail['product']['image'] != null) {
                                    images.add(detail['product']['image']);
                                  }
                                }
                              }
                              if (images.isEmpty) {
                                images.add('assets/images/logo.png');
                              }
                              return OrderCard(
                                order: UserOrder.fromJson(order),
                                storeImage: order['restaurant']?['image'] ?? "",
                                storeName: order['restaurant']?['name'] ?? "",
                                orderStatus: order['status'] ?? 'unknown',
                                checkoutType:
                                    order['checkout_type'] ?? 'unknown',
                                orderGeo: order['city'] ?? 'unknown',
                                orderLength: order['items_length'] ?? 0,
                                orderID: order['id'] ?? 0,
                                images: images,
                                orderProducts: order['order_details'] ?? [],
                                createdAt: DateTime.parse(order['updated_at']),
                                preparationTime: order['preparation_time'] ?? 0,
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrderCard extends StatefulWidget {
  final UserOrder order;
  final String orderStatus;
  final String storeImage;
  final String storeName;
  final String checkoutType;
  final String orderGeo;
  final int orderLength;
  final int orderID;
  final List<String> images;
  final List<dynamic> orderProducts;
  final DateTime createdAt;
  final int preparationTime;

  const OrderCard({
    required this.order,
    required this.orderStatus,
    required this.storeImage,
    required this.storeName,
    required this.checkoutType,
    required this.orderGeo,
    required this.orderLength,
    required this.orderID,
    required this.images,
    required this.orderProducts,
    required this.createdAt,
    required this.preparationTime,
    Key? key,
  }) : super(key: key);

  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final ValueNotifier<double> _dragOffset = ValueNotifier(0.0);
  final double _maxOffset = 110.0;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(builder: (context, cartProvider, child) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Stack(children: [
          buildButtons(),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              _dragOffset.value = (_dragOffset.value + details.delta.dx)
                  .clamp(-_maxOffset, 0.0);
            },
            onHorizontalDragEnd: (details) {
              if (_dragOffset.value.abs() < _maxOffset / 2) {
                _dragOffset.value = 0.0;
              } else {
                _dragOffset.value = -_maxOffset;
              }
            },
            child: ValueListenableBuilder<double>(
              valueListenable: _dragOffset,
              builder: (context, dragOffset, child) {
                return Transform.translate(
                  offset: Offset(dragOffset, 0),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          height: MediaQuery.of(context).size.height * 0.85,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: UserOrderDetails(
                            orderId: widget.orderID,
                            status: widget.orderStatus,
                            checkoutType: widget.checkoutType,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FancyShimmerImage(
                                  imageUrl: widget.storeImage,
                                  width: 50,
                                  height: 50,
                                  errorWidget: Image.asset(
                                    "assets/images/logo2.png",
                                    width: 50,
                                    height: 50,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.storeName,
                                    style: const TextStyle(
                                      color: Color(0xff323232),
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Image.asset(
                                        widget.orderStatus == "pending"
                                            ? "assets/images/order-ready.png"
                                            : widget.orderStatus ==
                                                    "in_progress"
                                                ? "assets/images/in-work.png"
                                                : widget.orderStatus ==
                                                        "ready_for_delivery"
                                                    ? "assets/images/in-work.png"
                                                    : widget.orderStatus ==
                                                            "in_delivery"
                                                        ? widget.checkoutType ==
                                                                "pickup"
                                                            ? "assets/images/delivery-done.png"
                                                            : "assets/images/in-delivery.png"
                                                        : "assets/images/delivery-done.png",
                                        width: 20,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _getOrderStatusText(),
                                        style: const TextStyle(
                                          color: Color(0xff323232),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 15,
                              color: Color(0xffB1B1B1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      );
    });
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

  Widget buildButtons() {
    return Visibility(
      visible: widget.orderStatus == "canceled" ||
          widget.orderStatus == "delivered" ||
          widget.orderStatus == "in_delivery" &&
              widget.checkoutType == "pickup",
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 5,
                ),
                InkWell(
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
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                actions: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          String orderId =
                                              widget.orderID.toString();
                                          fetchAndAddOrderToCart(
                                              context, orderId);
                                        },
                                        child: Container(
                                          height: 40,
                                          width: 55,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                  child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xff8AC43E),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Image.asset("assets/images/copy-order.png")),
                ),
                SizedBox(
                  width: 5,
                ),
                InkWell(
                  onTap: () async {
                    String orderId = widget.orderID.toString();
                    final String apiUrl = '${AppLink.deleteOrder}/$orderId';
                    try {
                      final response = await http.delete(Uri.parse(apiUrl));

                      if (response.statusCode == 200) {
                        final data = json.decode(response.body);
                        _dragOffset.value = 0;
                        print('Order deleted: $data');
                        Fluttertoast.showToast(
                            msg: "تم حذف الطلب بنجاح", timeInSecForIosWeb: 3);
                      } else {
                        print('Failed to delete order: ${response.statusCode}');
                        Fluttertoast.showToast(
                            msg: "فشلت عملية الحذف", timeInSecForIosWeb: 3);
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xffA51E22),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Image.asset("assets/images/delete-button.png"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getOrderStatusText() {
    final checkoutType = widget.checkoutType;
    switch (widget.orderStatus) {
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

  // void _addToCart(CartProvider cartProvider) async {
  //   List<String> allComponentsNames = [];
  //   List<String> allComponentsImages = [];
  //   List<String> allComponentsPrices = [];
  //   List<String> allDrinksNames = [];
  //   List<String> allDrinksImages = [];
  //   List<String> allDrinksPrices = [];

  //   // Process each order independently

  //   // Selected components and drinks for the current order
  //   List<String> orderComponentsNames = [];
  //   List<String> orderComponentsImages = [];
  //   List<String> orderComponentsPrices = [];
  //   List<String> orderComponentsId = [];
  //   List<String> orderComponentsQty = [];
  //   List<String> orderDrinksNames = [];
  //   List<String> orderDrinksImages = [];
  //   List<String> orderDrinksPrices = [];
  //   List<String> orderDrinksId = [];
  //   List<String> orderDrinksQty = [];

  //   // Create a new cart item for the current order
  //   final newItem = CartItem(
  //       storeDeliveryPrice: "",
  //       storeID: "",
  //       storeName: widget.storeName.toString(),
  //       storeImage: widget.storeImage,

  //       storeLocation: "",
  //       total: "",
  //       price: "",
  //       components_names: allComponentsNames,
  //       components_prices: allComponentsPrices,
  //       selected_components_names: orderComponentsNames,
  //       selected_components_prices:
  //           List.generate(orderComponentsQty.length, (i) {
  //         return (double.parse(orderComponentsPrices[i]) *
  //                 double.parse(orderComponentsQty[i]))
  //             .toString();
  //       }),
  //       drinks_names: allDrinksNames,
  //       drinks_prices: allDrinksPrices,
  //       selected_drinks_names: orderDrinksNames,
  //       selected_drinks_prices: List.generate(orderDrinksQty.length, (i) {
  //         return (double.parse(orderDrinksPrices[i]) *
  //                 double.parse(orderDrinksQty[i]))
  //             .toString();
  //       }),
  //       name: "",
  //       productId: 0,
  //       image: "",
  //       quantity: 1, // Each entry is for a single order
  //       selected_drinks_id: orderDrinksId,
  //       selected_components_id: orderComponentsId,
  //       selected_drinks_qty: orderDrinksQty,
  //       selected_components_qty: orderComponentsQty,
  //       components_images: allComponentsImages,
  //       drinks_images: allDrinksImages,
  //       selected_components_images: orderComponentsImages,
  //       selected_drinks_images: orderDrinksImages);

  //   cartProvider.addToCart(newItem);
  // }
}
