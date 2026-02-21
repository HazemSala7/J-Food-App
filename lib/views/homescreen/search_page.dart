import 'dart:async';
import 'dart:convert';
import 'package:j_food_updated/LocalDB/Models/CartItem.dart';
import 'package:j_food_updated/LocalDB/Provider/CartProvider.dart';
import 'package:j_food_updated/component/check_box/check_box.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/views/homescreen/widgets/filter.dart';
import 'package:j_food_updated/views/homescreen/widgets/search_input.dart';
import 'package:j_food_updated/views/homescreen/widgets/products_section.dart';
import 'package:j_food_updated/views/homescreen/widgets/restaurants_section.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:material_dialogs/dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  final bool noDelivery;
  final Function(int) changeTab;
  SearchPage({super.key, required this.noDelivery, required this.changeTab});
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> allProducts = [];
  List<dynamic> allRestaurants = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool noData = false;
  Map<String, dynamic> appliedFilters = {};
  late List<bool> isSelected;
  late List<List<List<String>>> selectedComponents;
  late List<int> quantities;
  late List<bool> applyToAll;
  late List<bool> showComponents;
  late List<List<List<int>>> componentQuantities;
  late List<List<List<String>>> selectedDrinks;
  late List<List<List<int>>> drinkQuantities;
  late List<bool> applyToAllDrinks;
  late List<double> finalPrice;
  List<List<int>> selectedSizeIndices = [];
  late List<List<List<String>>> selectedSizes;

  // Debounce timer to avoid calling API on every keystroke
  Timer? _searchDebounce;
  // Track the last query we sent to the server to avoid duplicate fetches
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    // Cancel previous debounce timer if still active
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      if (query.isEmpty) {
        // Clear displayed results when the query is empty
        if (mounted) {
          setState(() {
            allProducts = [];
            allRestaurants = [];
            noData = false;
            _lastQuery = '';
          });
        } else {
          _lastQuery = '';
        }
        return;
      }

      // Only fetch if the query actually changed since the last fetch
      if (query != _lastQuery) {
        _lastQuery = query;
        fetchProducts(query, filters: appliedFilters);
        if (mounted) {
          setState(() {
            noData = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  bool isStoreOpenByWorkingHours(Map<String, dynamic> storeData, bool isOpen) {
    try {
      final now = DateTime.now();
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

      // Try to get working hours from the store data
      final workingHours = storeData['working_hours'];
      if (workingHours == null) {
        return isOpen;
      }

      List<dynamic> workingHoursList;
      if (workingHours is String) {
        workingHoursList = jsonDecode(workingHours) as List<dynamic>;
      } else {
        workingHoursList = workingHours as List<dynamic>;
      }

      final todaySchedule = workingHoursList.firstWhere(
        (schedule) => schedule['day'] == currentDay,
        orElse: () => null,
      );

      // If no schedule for today, store is closed
      if (todaySchedule == null) return false;

      String? openTimeString = todaySchedule['start_time'];
      String? closeTimeString = todaySchedule['end_time'];

      if (openTimeString == null ||
          closeTimeString == null ||
          !openTimeString.contains(":") ||
          !closeTimeString.contains(":")) {
        return false;
      }

      DateTime parseTime(String timeStr, DateTime reference) {
        final parts = timeStr.split(":");
        return DateTime(reference.year, reference.month, reference.day,
            int.parse(parts[0]), int.parse(parts[1]));
      }

      DateTime openTime = parseTime(openTimeString, now);
      DateTime closeTime = parseTime(closeTimeString, now);

      final bool isOvernight = closeTime.isBefore(openTime);
      if (isOvernight) {
        closeTime = closeTime.add(const Duration(days: 1));
        if (now.isBefore(openTime)) {
          openTime = openTime.subtract(const Duration(days: 1));
        }
      }

      if (now.isAfter(closeTime)) {
        openTime = openTime.add(const Duration(days: 1));
        closeTime = closeTime.add(const Duration(days: 1));
      }

      // Check if within working hours AND backend says it's open
      final bool withinWorkingHours =
          now.isAfter(openTime) && now.isBefore(closeTime);
      return withinWorkingHours && isOpen;
    } catch (e) {
      debugPrint("Error checking working hours: $e");
      return isOpen;
    }
  }

  void updateFinalPriceForIndex(int index) {
    String discount = allProducts[index]['discount_percentage'] != null
        ? allProducts[index]['discount_percentage'].toString()
        : "0";
    double orderPrice = 0;
    if (selectedSizes[index].isEmpty) {
      orderPrice = discount == "0"
          ? double.parse(allProducts[index]['price']) *
              quantities[index].toDouble()
          : (double.parse(allProducts[index]['price']) -
                  (double.parse(allProducts[index]['price']) *
                      (double.parse(discount) / 100))) *
              quantities[index].toDouble();
    } else {
      for (int dropdownIndex = 0;
          dropdownIndex < quantities[index];
          dropdownIndex++) {
        if (selectedSizeIndices[index].length > dropdownIndex) {
          int sizeIndex = selectedSizeIndices[index][dropdownIndex];

          if (sizeIndex != -1) {
            // Ensure a valid selection
            double sizePrice = double.parse(allProducts[index]['product_sizes']
                [sizeIndex]['size_price_nis']);

            // Apply discount if available
            double finalPrice = (discount == "0")
                ? sizePrice
                : (sizePrice - (sizePrice * (double.parse(discount) / 100)));

            // Multiply by quantity
            orderPrice += finalPrice;
          }
        }
      }
    }

    double componentsPrice = 0;
    double drinksPrice = 0;

    // Calculate components price
    for (int row = 0; row < selectedComponents[index].length; row++) {
      if (componentQuantities[index].length <= row) {
        componentQuantities[index].add([]);
      }

      for (int j = 0; j < selectedComponents[index][row].length; j++) {
        if (componentQuantities[index][row].length <= j) {
          componentQuantities[index][row].add(0);
        }
        String componentName = selectedComponents[index][row][j];
        final component = allProducts[index]['product_components'].firstWhere(
          (c) => c['component_details']['name'] == componentName,
          orElse: () => null,
        );

        if (component != null) {
          double componentPrice = (double.parse(component['com_price'])) *
              (componentQuantities[index][row][j]).toDouble();
          componentsPrice += componentPrice;
        }
      }
    }

    // Calculate drinks price
    for (int row = 0; row < selectedDrinks[index].length; row++) {
      if (drinkQuantities[index].length <= row) {
        drinkQuantities[index].add([]);
      }

      for (int j = 0; j < selectedDrinks[index][row].length; j++) {
        if (drinkQuantities[index][row].length <= j) {
          drinkQuantities[index][row].add(0);
        }
        String drinkName = selectedDrinks[index][row][j];
        final drink = allProducts[index]['product_drinks'].firstWhere(
          (d) => d["drink_details"]['name'] == drinkName,
          orElse: () => null,
        );

        if (drink != null) {
          double drinkPrice = (double.parse(drink["drink_price"])) *
              (drinkQuantities[index][row][j]).toDouble();
          drinksPrice += drinkPrice;
        }
      }
    }

    finalPrice[index] = orderPrice + componentsPrice + drinksPrice;
  }

  void _addToCart(CartProvider cartProvider, int index) async {
    if (selectedSizeIndices[index].contains(-1) &&
        allProducts[index]['product_sizes'].isNotEmpty) {
      Fluttertoast.showToast(
          msg: "يجب اختيار الحجم لجميع الوجبات", timeInSecForIosWeb: 4);
      return;
    }
    final productData = allProducts[index];

    List<String> allComponentsNames = [];
    List<String> allComponentsImages = [];
    List<String> allComponentsPrices = [];
    List<String> allDrinksNames = [];
    List<String> allDrinksImages = [];
    List<String> allDrinksPrices = [];

    if (productData['product_components'] != null) {
      for (var component in productData['product_components']) {
        allComponentsNames
            .add(component['component_details']['name'] ?? 'Unknown');
        allComponentsPrices.add(component['com_price']?.toString() ?? '0');
        allComponentsImages.add(component['component_details']['image'] ?? '0');
      }
    }

    if (productData['product_drinks'] != null) {
      for (var drink in productData['product_drinks']) {
        allDrinksNames.add(drink['drink_details']['name'] ?? 'Unknown');
        allDrinksPrices.add(drink['drink_price']?.toString() ?? '0');
        allDrinksImages.add(drink['drink_details']['image'] ?? '0');
      }
    }

    // Process each order independently
    for (int orderIndex = 0; orderIndex < quantities[index]; orderIndex++) {
      List<String> orderComponentsNames = [];
      List<String> orderComponentsImages = [];
      List<String> orderComponentsPrices = [];
      List<String> orderComponentsId = [];
      List<String> orderComponentsQty = [];
      List<String> orderDrinksNames = [];
      List<String> orderDrinksImages = [];
      List<String> orderDrinksPrices = [];
      List<String> orderDrinksId = [];
      List<String> orderDrinksQty = [];

      // Process selected components for the current order
      if (orderIndex < selectedComponents[index].length) {
        for (int componentIndex = 0;
            componentIndex < selectedComponents[index][orderIndex].length;
            componentIndex++) {
          String componentName =
              selectedComponents[index][orderIndex][componentIndex];
          final component = productData['product_components'].firstWhere(
            (c) => c['component_details']['name'] == componentName,
            orElse: () => null,
          );

          if (component != null) {
            orderComponentsNames.add(componentName);
            orderComponentsPrices
                .add(component['com_price']?.toString() ?? '0');
            orderComponentsImages
                .add(component['component_details']['image'] ?? '0');
            orderComponentsId
                .add(component['component_details']['id']?.toString() ?? '0');
            orderComponentsQty.add(componentQuantities[index][orderIndex]
                    [componentIndex]
                .toString());
          }
        }
      }

      if (orderIndex < selectedDrinks[index].length) {
        for (int drinkIndex = 0;
            drinkIndex < selectedDrinks[index][orderIndex].length;
            drinkIndex++) {
          String drinkName = selectedDrinks[index][orderIndex][drinkIndex];
          final drink = productData['product_drinks'].firstWhere(
            (d) {
              final isMatch = d['drink_details']['name'] == drinkName;
              return isMatch;
            },
            orElse: () => null,
          );

          if (drink != null) {
            orderDrinksNames.add(drinkName);
            orderDrinksImages.add(drink['drink_details']['image'] ?? '0');
            orderDrinksPrices.add(drink['drink_price']?.toString() ?? '0');
            orderDrinksId.add(drink['drink_details']['id']?.toString() ?? '0');
            orderDrinksQty
                .add(drinkQuantities[index][orderIndex][drinkIndex].toString());
          }
        }
      }

      // Calculate the total price for the current order
      String discount = productData['discount_percentage'] == null
          ? "0"
          : productData['discount_percentage'].toString();
      String? size;
      String? sizeId;
      double orderBasePrice = 0;
      if (productData['product_sizes'].isEmpty) {
        orderBasePrice = discount == "0"
            ? double.parse(productData['price']?.toString() ?? '0')
            : double.parse(productData['price']) -
                (double.parse(productData['price']) *
                    (double.parse(discount) / 100));
      } else {
        int selectedSizeIndex = selectedSizeIndices[index][orderIndex];
        if (selectedSizeIndex != -1 &&
            selectedSizeIndex < productData['product_sizes'].length) {
          size = productData['product_sizes'][selectedSizeIndex]['size']
              .toString();
          sizeId =
              productData['product_sizes'][selectedSizeIndex]['id'].toString();
          double sizePrice = double.parse(productData['product_sizes']
              [selectedSizeIndex]['size_price_nis']);
          orderBasePrice = discount == "0"
              ? sizePrice
              : (sizePrice - (sizePrice * (double.parse(discount) / 100)));
        }
      }
      double componentsTotalPrice = 0;
      for (int i = 0; i < orderComponentsQty.length; i++) {
        componentsTotalPrice += double.parse(orderComponentsQty[i]) *
            double.parse(orderComponentsPrices[i]);
      }

      double drinksTotalPrice = 0;
      for (int i = 0; i < orderDrinksQty.length; i++) {
        drinksTotalPrice += double.parse(orderDrinksQty[i]) *
            double.parse(orderDrinksPrices[i]);
      }

      double orderTotalPrice =
          orderBasePrice + componentsTotalPrice + drinksTotalPrice;

      final newItem = CartItem(
          storeDeliveryPrice: allProducts[index]['store']['delivery_price'],
          storeID: allProducts[index]['store']['id'].toString(),
          storeName: allProducts[index]['store']['name'],
          storeImage: allProducts[index]['store']['image'],
          storeLocation: allProducts[index]['store']['address'],
          storeOpenTime: allProducts[index]['store']['open_time'],
          storeCloseTime: allProducts[index]['store']['close_time'],
          total: orderTotalPrice.toString(),
          price: orderBasePrice.toString(),
          size: size ?? "",
          sizeId: sizeId ?? "",
          components_names: allComponentsNames,
          components_prices: allComponentsPrices,
          selected_components_names: orderComponentsNames,
          selected_components_prices:
              List.generate(orderComponentsQty.length, (i) {
            return (double.parse(orderComponentsPrices[i]) *
                    double.parse(orderComponentsQty[i]))
                .toString();
          }),
          drinks_names: allDrinksNames,
          drinks_prices: allDrinksPrices,
          selected_drinks_names: orderDrinksNames,
          selected_drinks_prices: List.generate(orderDrinksQty.length, (i) {
            return (double.parse(orderDrinksPrices[i]) *
                    double.parse(orderDrinksQty[i]))
                .toString();
          }),
          name: productData["name"] ?? 'Unnamed Product',
          productId: productData["id"] ?? 0,
          image: productData['images'].isNotEmpty
              ? productData['images'][0]['url'] ??
                  'https://example.com/default.jpg'
              : 'https://example.com/default.jpg',
          quantity: 1, // Each entry is for a single order
          selected_drinks_id: orderDrinksId,
          selected_components_id: orderComponentsId,
          selected_drinks_qty: orderDrinksQty,
          selected_components_qty: orderComponentsQty,
          components_images: allComponentsImages,
          drinks_images: allDrinksImages,
          selected_components_images: orderComponentsImages,
          selected_drinks_images: orderDrinksImages);

      // Add the current order to the cart
      cartProvider.addToCart(newItem);
    }

    quantities[index] = 0;
    selectedComponents[index].clear();
    selectedDrinks[index].clear();
    componentQuantities[index].clear();
    drinkQuantities[index].clear();
    isSelected[index] = !isSelected[index];
    Fluttertoast.showToast(
        msg: "تم اضافة المنتج الى السلة",
        backgroundColor: Colors.green,
        textColor: Colors.white,
        timeInSecForIosWeb: 3);
  }

  Future<void> fetchProducts(String query,
      {Map<String, dynamic>? filters}) async {
    // Avoid doing any work if widget is already disposed
    if (!mounted) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      // Construct the URL with the query parameter
      final Map<String, String> myParam = {
        'query': query,
      };

      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            myParam[key] = value.toString();
          }
        });
      }

      // Make the API call with the updated parameters
      var response = await http
          .get(Uri.parse('https://hrsps.com/login/api/search').replace(
        queryParameters: myParam,
      ));
      print(Uri.parse('https://hrsps.com/login/api/search').replace(
        queryParameters: myParam,
      ));

      if (!mounted) return; // Widget removed while waiting for response

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print(data);
        final products = data['products'] is List ? data['products'] : [];
        final restaurants =
            data['restaurants'] is List ? data['restaurants'] : [];

        if (mounted) {
          setState(() {
            allProducts = products;
            allRestaurants = restaurants;
            noData = (allProducts.isEmpty && allRestaurants.isEmpty);

            // Reset or set other variables accordingly
            isSelected = List<bool>.filled(allProducts.length, false);
            selectedComponents = List<List<List<String>>>.generate(
                allProducts.length, (_) => []);
            selectedSizes = List<List<List<String>>>.generate(
              allProducts.length,
              (_) => [],
            );
            componentQuantities =
                List<List<List<int>>>.generate(allProducts.length, (_) => []);
            selectedDrinks = List<List<List<String>>>.generate(
                allProducts.length, (_) => []);
            drinkQuantities =
                List<List<List<int>>>.generate(allProducts.length, (_) => []);
            quantities = List<int>.filled(allProducts.length, 0);
            applyToAll = List<bool>.filled(allProducts.length, false);
            showComponents = List<bool>.filled(allProducts.length, true);
            applyToAllDrinks = List<bool>.filled(allProducts.length, false);
            finalPrice = List<double>.filled(allProducts.length, 0);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
        print('Failed to load products and restaurants: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      print('Error fetching products: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void showFilterBottomSheet() async {
    // Show a bottom sheet for filtering
    Map<String, dynamic>? selectedFilters =
        await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return FilterBottomSheet(appliedFilters: appliedFilters);
      },
    );

    // Apply filters if provided
    if (selectedFilters != null) {
      setState(() {
        appliedFilters = selectedFilters;
      });
      fetchProducts(_searchController.text, filters: appliedFilters);
    }
  }

  Widget buildProductAndRestaurantGrid() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (allProducts.isNotEmpty)
              ProductsSection(
                products: allProducts,
                buildProductTile: buildProductTile,
              ),
            if (allRestaurants.isNotEmpty)
              RestaurantsSection(
                restaurants: allRestaurants,
                noDelivery: widget.noDelivery,
                changeTab: widget.changeTab,
              )
          ],
        ),
        if (allProducts.isEmpty && allRestaurants.isEmpty && !noData)
          Center(
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                ),
                Image.asset(
                  'assets/images/fastfood.png',
                  width: 200,
                  height: 200,
                ),
                Text(
                  "ابحث لرؤية أشهى وألذ الوجبات",
                  style: TextStyle(fontSize: 20, color: mainColor),
                ),
              ],
            ),
          ),
        if (allProducts.isEmpty && allRestaurants.isEmpty && noData)
          Center(
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                ),
                Image.asset(
                  'assets/images/noresults.png',
                  width: 200,
                  height: 200,
                ),
                Text(
                  "لا يوجد مطعم او وجبة بهذا الاسم",
                  style: TextStyle(fontSize: 20, color: mainColor),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 100,
        )
      ],
    );
  }

  Widget buildProductTile(
    dynamic product,
    int index,
    String imgUrl,
    String name,
    String price,
    String originalPrice,
    String discount,
    String dis,
    List<dynamic> drinks,
    List<dynamic> components,
    List<dynamic> sizes,
  ) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        List<CartItem> cartItems = cartProvider.cartItems;
        return InkWell(
          onTap: () {
            setState(() {
              if (!isSelected[index]) {
                isSelected[index] = !isSelected[index];
                if (!isSelected[index]) {
                  // Clear the content while keeping the structure
                  quantities[index] = 0;
                  selectedComponents[index].clear();
                  selectedDrinks[index].clear();
                  componentQuantities[index].clear();
                  drinkQuantities[index].clear();
                  selectedSizes[index].clear();
                } else {
                  // Ensure lists are initialized when reopening
                  if (selectedComponents[index].isEmpty) {
                    selectedComponents[index].add([]);
                  }
                  if (componentQuantities[index].isEmpty) {
                    componentQuantities[index].add([]);
                  }
                  if (selectedDrinks[index].isEmpty) {
                    selectedDrinks[index].add([]);
                  }
                  if (drinkQuantities[index].isEmpty) {
                    drinkQuantities[index].add([]);
                  }

                  quantities[index]++;
                }
                updateFinalPriceForIndex(index);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image on the right
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Stack(alignment: Alignment.topCenter, children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                          child: FancyShimmerImage(
                              imageUrl: imgUrl,
                              boxFit: BoxFit.cover,
                              width: 90,
                              height: 90,
                              errorWidget: Image.asset(
                                "assets/images/logo2.png",
                                fit: BoxFit.cover,
                                height: 100,
                                width: double.infinity,
                              )),
                        ),
                        Visibility(
                          visible: discount != "0",
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6.0),
                                child: Center(
                                  child: Text(
                                    "${discount}%-",
                                    style: TextStyle(
                                        color: mainColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      ]),
                    ),
                    // Product info on the left
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                color: Color(0xff5E5E5E),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              dis,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.7),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Row(
                              children: [
                                Visibility(
                                  visible: discount != "0",
                                  child: Stack(children: [
                                    Text(
                                      originalPrice,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            Color(0xff616163).withOpacity(0.5),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      child: Text(
                                        '_' *
                                            {double.parse(originalPrice.trim())}
                                                .toString()
                                                .length,
                                      ),
                                    ),
                                  ]),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  price,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    color: Color(0xff616163),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "${quantities[index]}X",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: mainColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Increment and Decrement Buttons
                    Visibility(
                      visible: isSelected[index],
                      child: Column(
                        children: [
                          SizedBox(height: 15),
                          Container(
                            height: 70,
                            width: 35,
                            decoration: BoxDecoration(
                              color: Color(0xffDCDCDC),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      quantities[index]++;
                                      if (applyToAll[index]) {
                                        // print(selectedComponents);
                                        selectedComponents[index].clear();
                                        selectedComponents[index].add([]);
                                        componentQuantities[index].add([]);
                                      }
                                    });
                                    updateFinalPriceForIndex(index);
                                  },
                                  child: Container(
                                    height: 35,
                                    width: 35,
                                    decoration: BoxDecoration(
                                      color: mainColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '+',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (quantities[index] > 0) {
                                        quantities[index]--;
                                        if (selectedSizeIndices[index].length >
                                            quantities[index]) {
                                          selectedSizeIndices[index]
                                              .removeLast();
                                        }
                                        if (quantities[index] == 0) {
                                          setState(() {
                                            isSelected[index] = false;
                                          });
                                        }
                                      }
                                      if (applyToAll[index]) {
                                        selectedComponents[index].clear();
                                        selectedComponents[index].add([]);
                                        componentQuantities[index].add([]);
                                      }
                                      updateFinalPriceForIndex(index);
                                    });
                                  },
                                  child: Container(
                                    height: 30,
                                    width: 30,
                                    child: Center(
                                      child: Baseline(
                                        baseline: 15,
                                        baselineType: TextBaseline.ideographic,
                                        child: Text(
                                          '-',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
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
                      ),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                Visibility(
                  visible: sizes.isNotEmpty,
                  child:
                      // applyToAll[index]
                      //     ? _buildAllSizesSection(
                      //         "الحجم",
                      //         sizes,
                      //         selectedSizes,
                      //         index,
                      //       )
                      //     :
                      _buildIndividualSizesSection(
                    "الحجم",
                    sizes,
                    selectedSizes,
                    index,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                if (quantities[index] > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 10,
                      ),
                      Visibility(
                        visible: components.isNotEmpty,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              showComponents[index] = true;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: showComponents[index]
                                    ? mainColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 3),
                              child: Text(
                                "المكونات",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: showComponents[index]
                                      ? Colors.white
                                      : Colors.black.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Visibility(
                        visible: drinks.isNotEmpty,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              showComponents[index] = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: !showComponents[index]
                                    ? mainColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 3),
                              child: Text(
                                "المشروبات",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: !showComponents[index]
                                      ? Colors.white
                                      : Colors.black.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  showComponents[index]
                      ? Visibility(
                          visible: components.isNotEmpty,
                          child: Row(
                            children: [
                              SizedBox(width: 10),
                              RoundedCheckbox(
                                value: applyToAll[index],
                                borderColor: mainColor,
                                borderRadius: 4.0,
                                activeColor: Colors.white,
                                checkColor: mainColor,
                                onChanged: (value) {
                                  setState(() {
                                    applyToAll[index] = value ?? false;

                                    if (applyToAll[index]) {
                                      if (selectedComponents[index]
                                          .isNotEmpty) {
                                        List<String> firstRowComponents =
                                            List.from(
                                                selectedComponents[index][0]);
                                        List<int> firstRowQuantities =
                                            componentQuantities[index]
                                                    .isNotEmpty
                                                ? List.from(
                                                    componentQuantities[index]
                                                        [0])
                                                : [];

                                        selectedComponents[index].clear();
                                        componentQuantities[index].clear();

                                        for (int i = 0;
                                            i < quantities[index];
                                            i++) {
                                          selectedComponents[index].add(
                                              List.from(firstRowComponents));
                                          componentQuantities[index].add(
                                              List.from(firstRowQuantities));
                                        }
                                      }
                                    }

                                    updateFinalPriceForIndex(index);
                                  });
                                },
                              ),
                              SizedBox(width: 10),
                              Text(
                                "تكرار المكونات لكافة الطلبات",
                                style: TextStyle(color: Color(0xff6D6D6D)),
                              ),
                            ],
                          ),
                        )
                      : Visibility(
                          visible: drinks.isNotEmpty,
                          child: Row(
                            children: [
                              SizedBox(width: 10),
                              RoundedCheckbox(
                                value: applyToAllDrinks[index],
                                borderColor: mainColor,
                                borderRadius: 4.0,
                                activeColor: Colors.white,
                                checkColor: mainColor,
                                onChanged: (value) {
                                  setState(() {
                                    applyToAllDrinks[index] = value ?? false;

                                    if (applyToAllDrinks[index]) {
                                      if (selectedDrinks[index].isNotEmpty) {
                                        // Copy the first row's drinks and quantities
                                        List<String> firstRowDrinks =
                                            List.from(selectedDrinks[index][0]);
                                        List<int> firstRowDrinkQuantities =
                                            drinkQuantities[index].isNotEmpty
                                                ? List.from(
                                                    drinkQuantities[index][0])
                                                : [];

                                        // Clear current selections and quantities
                                        selectedDrinks[index].clear();
                                        drinkQuantities[index].clear();

                                        // Replicate the first row's data across all rows
                                        for (int i = 0;
                                            i < quantities[index];
                                            i++) {
                                          selectedDrinks[index]
                                              .add(List.from(firstRowDrinks));
                                          drinkQuantities[index].add(List.from(
                                              firstRowDrinkQuantities));
                                        }
                                      }
                                    }

                                    updateFinalPriceForIndex(index);
                                  });
                                },
                              ),
                              SizedBox(width: 10),
                              Text(
                                "تكرار المشروبات لكافة الطلبات",
                                style: TextStyle(color: Color(0xff6D6D6D)),
                              ),
                            ],
                          ),
                        ),
                  if (showComponents[index]) ...[
                    if (applyToAll[index])
                      _buildAllItemsSection(
                        "مكونات جميع الطلبات",
                        components,
                        selectedComponents,
                        componentQuantities,
                        index,
                      )
                    else
                      _buildIndividualItemsSection(
                        "مكونات الطلب",
                        components,
                        selectedComponents,
                        componentQuantities,
                        index,
                      )
                  ] else if (applyToAllDrinks[index])
                    _buildAllItemsSection(
                      "مشروبات جميع الطلبات",
                      drinks,
                      selectedDrinks,
                      drinkQuantities,
                      index,
                    )
                  else
                    _buildIndividualItemsSection(
                      "مشروبات الطلب",
                      drinks,
                      selectedDrinks,
                      drinkQuantities,
                      index,
                    ),
                  InkWell(
                    onTap: () {
                      final bool isOpenByHours = isStoreOpenByWorkingHours(
                          product['store'], product['store']['is_open']);

                      if (isOpenByHours) {
                        if (cartItems.isNotEmpty) {
                          String firstStoreId = cartItems[0].storeID;
                          bool allSameStore =
                              firstStoreId == product['store']['id'].toString();
                          if (allSameStore) {
                            _addToCart(cartProvider, index);
                          } else {
                            Dialogs.materialDialog(
                              msg:
                                  'لا يمكنك الطلب من اكثر من مطعم واحد بنفس الوقت',
                              title: "تنبيه",
                              color: Colors.white,
                              titleStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              msgStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black.withOpacity(0.6),
                              ),
                              msgAlign: TextAlign.center,
                              context: context,
                              actions: [
                                IconsButton(
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  },
                                  text: 'الغاء',
                                  iconData: Icons.cancel_outlined,
                                  textStyle: TextStyle(color: Colors.white),
                                  iconColor: Colors.white,
                                  color: Colors.blue,
                                ),
                                IconsButton(
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                    cartProvider.clearCart();
                                    _addToCart(cartProvider, index);
                                  },
                                  text: 'حذف واستمرار',
                                  iconData: Icons.delete,
                                  color: mainColor,
                                  textStyle: TextStyle(color: Colors.white),
                                  iconColor: Colors.white,
                                ),
                              ],
                            );
                          }
                        } else {
                          _addToCart(cartProvider, index);
                        }
                      } else {
                        Fluttertoast.showToast(
                            msg: "لا يمكنك الطلب الان ،المحل مغلق",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 3,
                            backgroundColor: const Color(0xffE74C3C),
                            textColor: Colors.white,
                            fontSize: 16.0);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8.0),
                      height: 25,
                      decoration: BoxDecoration(
                        color: fourthColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: fourthColor,
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(14),
                                ),
                              ),
                              alignment: Alignment.centerRight,
                              child: Text(
                                "الاجمالي: ${finalPrice[index]}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: mainColor,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(14),
                                bottomLeft: Radius.circular(14),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: const Text(
                                "اضافة الى السلة",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllItemsSection(
    String title,
    List<dynamic> items,
    List<List<List<String>>> selectedItems,
    List<List<List<int>>> itemQuantities,
    int index,
  ) {
    return Visibility(
      visible: items.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(right: 5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                title,
                style: TextStyle(color: Color(0xff6D6D6D)),
              ),
            ),
            const SizedBox(height: 5),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((item) {
                  return _buildItemCard(
                    item,
                    selectedItems[index][0],
                    itemQuantities[index][0],
                    index,
                    (isSelected, itemName, itemIndex) {
                      setState(() {
                        if (isSelected) {
                          for (var row in selectedItems[index]) {
                            row.remove(itemName);
                          }
                          for (var row in itemQuantities[index]) {
                            if (itemIndex < row.length) {
                              row.removeAt(itemIndex);
                            }
                          }
                        } else {
                          for (int row = 0; row < quantities[index]; row++) {
                            selectedItems[index][row].add(itemName);
                            itemQuantities[index][row].add(1);
                          }
                        }
                        updateFinalPriceForIndex(index);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualItemsSection(
    String rowTitlePrefix,
    List<dynamic> items,
    List<List<List<String>>> selectedItems,
    List<List<List<int>>> itemQuantities,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Column(
        children: List.generate(quantities[index], (rowIndex) {
          // Ensure the selectedItems and itemQuantities are properly initialized for this row
          if (selectedItems[index].length <= rowIndex) {
            selectedItems[index].add([]);
            itemQuantities[index].add([]);
          }

          return Visibility(
            visible: items.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    "$rowTitlePrefix ${rowIndex + 1}",
                    style: TextStyle(color: Color(0xff6D6D6D)),
                  ),
                ),
                const SizedBox(height: 5),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.map((item) {
                      return _buildItemCard(
                        item,
                        selectedItems[index][rowIndex],
                        itemQuantities[index][rowIndex],
                        index,
                        (isSelected, itemName, itemIndex) {
                          setState(() {
                            if (isSelected) {
                              selectedItems[index][rowIndex]
                                  .removeAt(itemIndex);
                              itemQuantities[index][rowIndex]
                                  .removeAt(itemIndex);
                            } else {
                              selectedItems[index][rowIndex].add(itemName);
                              itemQuantities[index][rowIndex].add(1);
                            }
                            updateFinalPriceForIndex(index);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildItemCard(
    Map<String, dynamic> item,
    List<String> selectedRow,
    List<int> quantitiesRow,
    int index,
    Function(bool isSelected, String itemName, int itemIndex) onItemTap,
  ) {
    if (item['component_details'] == null && item['drink_details'] == null) {
      return _buildNoItemsAvailable();
    }

    String itemName = item['component_details']?["name"] ??
        item['drink_details']?["name"] ??
        "Unknown";

    String itemPrice = item['com_price'] != null
        ? "₪${item['com_price']}"
        : item["drink_price"] != null
            ? "₪${item["drink_price"]}"
            : "₪0";

    String? itemImage =
        item['component_details']?["image"] ?? item['drink_details']?["image"];

    bool isSelected = selectedRow.contains(itemName);
    int itemIndex = selectedRow.indexOf(itemName);
    int maxOrderNum = item['max_order_num'] ?? 15;

    return GestureDetector(
      onTap: () => onItemTap(isSelected, itemName, itemIndex),
      child: Card(
        elevation: 5,
        color: isSelected ? mainColor : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(4),
          width: 110,
          height: isSelected ? 115 : 90,
          decoration: BoxDecoration(
            color: isSelected ? mainColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: isSelected
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  itemImage ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      "assets/images/logo2.png",
                      width: 50,
                      height: 50,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : mainColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      itemPrice,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Color(0xff6D6D6D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) const SizedBox(height: 4),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (quantitiesRow[itemIndex] < maxOrderNum) {
                            quantitiesRow[itemIndex]++;
                            updateFinalPriceForIndex(index);
                            setState(() {});
                          }
                        },
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'X${quantitiesRow[itemIndex]}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      GestureDetector(
                        onTap: () {
                          if (quantitiesRow[itemIndex] > 1) {
                            quantitiesRow[itemIndex]--;
                            updateFinalPriceForIndex(index);
                            setState(() {});
                          }
                        },
                        child: const Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 20,
                        ),
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

  Widget _buildIndividualSizesSection(
    String title,
    List<dynamic> items,
    List<List<List<String>>> selectedSizes,
    int index,
  ) {
    // Ensure selectedSizeIndices has enough lists for `index`
    while (selectedSizeIndices.length <= index) {
      selectedSizeIndices.add([]);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Column(
        children: List.generate(quantities[index], (dropdownIndex) {
          // Ensure selectedSizes[index] has a list for `dropdownIndex`
          if (selectedSizes[index].length <= dropdownIndex) {
            selectedSizes[index].add([]);
          }

          // Ensure selectedSizeIndices[index] has a default value (-1 for no selection)
          while (selectedSizeIndices[index].length <= dropdownIndex) {
            selectedSizeIndices[index].add(-1);
          }

          return Visibility(
            visible: items.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    "$title ${dropdownIndex + 1}",
                    style: const TextStyle(
                        color: Color(0xff6D6D6D), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.asMap().entries.map((entry) {
                      final int sizeIndex = entry.key;
                      final item = entry.value;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            final String itemId = item['id'].toString();
                            final bool isSelected = selectedSizes[index]
                                    [dropdownIndex]
                                .contains(itemId);

                            if (isSelected) {
                              selectedSizes[index][dropdownIndex]
                                  .remove(itemId);
                              selectedSizeIndices[index][dropdownIndex] = -1;
                            } else {
                              selectedSizes[index][dropdownIndex].clear();
                              selectedSizes[index][dropdownIndex].add(itemId);
                              selectedSizeIndices[index][dropdownIndex] =
                                  sizeIndex;
                            }
                            print(selectedSizeIndices);
                            updateFinalPriceForIndex(index);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: selectedSizes[index][dropdownIndex]
                                          .contains(item['id'].toString())
                                      ? mainColor
                                      : const Color(0xffD5D5D5),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['size'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: selectedSizes[index][dropdownIndex]
                                        .contains(item['id'].toString())
                                    ? mainColor
                                    : const Color(0xff6D6D6D),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNoItemsAvailable() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange),
          const SizedBox(height: 10),
          Text(
            "لا يوجد مكونات او مشروبات",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SearchInput(
                      controller: _searchController,
                      onFilterTap: showFilterBottomSheet,
                      onChanged: (query) {
                        // When the field is cleared, remove results immediately.
                        if (query.isEmpty) {
                          setState(() {
                            allProducts = [];
                            allRestaurants = [];
                            noData = false;
                          });
                        }
                      },
                    ),
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _hasError
                            ? Center(child: Text("Error fetching data"))
                            : buildProductAndRestaurantGrid(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
