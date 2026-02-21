import 'package:j_food_updated/LocalDB/Models/CartItem.dart';
import 'package:j_food_updated/LocalDB/Models/PackageCartItem.dart';
import 'package:j_food_updated/LocalDB/Provider/CartProvider.dart';
import 'package:j_food_updated/LocalDB/Provider/PackageCartProvider.dart';
import 'package:j_food_updated/component/check_box/check_box.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_dialogs/dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ignore: must_be_immutable
class ItemWidget extends StatefulWidget {
  final void Function() changeConfirmOrder;

  ItemWidget({
    Key? key,
    required this.data,
    required this.packageData,
    required this.storeId,
    required this.storeName,
    required this.storeDeliveryPrice,
    required this.open,
    required this.changeConfirmOrder,
    required this.storeImage,
    required this.storeLocation,
    required this.orderId,
    required this.isResturant,
    required this.changePackagePage,
    required this.storeOpenTime,
    required this.storeCloseTime,
    required this.workingHours,
    required this.isOpen,
  }) : super(key: key);

  final bool isResturant;
  final String storeId;
  final String orderId;
  final String storeName;
  final String storeOpenTime;
  final String storeCloseTime;
  final String workingHours;
  final bool isOpen;
  final String storeImage;
  final String storeLocation;
  final String storeDeliveryPrice;
  final bool open;
  List data = [];
  List packageData = [];
  final Function changePackagePage;

  @override
  State<ItemWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  late List<bool> isSelected;
  late List<List<List<String>>> selectedComponents;
  late List<List<List<String>>> selectedComponentsPackages;
  late List<List<List<String>>> selectedComponentsPackagesCopy;
  late List<List<List<String>>> componentPrices;
  late List<List<List<String>>> componentPricesPackages;
  late List<List<List<String>>> componentIds;
  late List<List<List<String>>> selectedSizes;
  late List<int> quantities;
  late List<int> packagesQuantity;
  late List<bool> applyToAll;
  late List<bool> showComponents;
  late List<List<List<int>>> componentQuantities;
  late List<List<List<String>>> selectedDrinks;
  late List<List<List<String>>> selectedPackagesDrinks;
  late List<List<List<String>>> drinkPrices;
  late List<List<List<String>>> drinkPackagesPrices;
  late List<List<List<String>>> drinkPackagesIds;
  late List<List<List<int>>> drinkQuantities;
  late List<List<List<int>>> drinkPackagesQuantities;
  late List<bool> applyToAllDrinks;
  late List<double> finalPrice;
  late double finalPricePackages;
  bool confirmOrder = false;
  bool loading = false;
  bool packageOpen = false;
  Map<String, dynamic>? selectedPackage;
  int? packageIndex;
  late List<Map<String, dynamic>> allProducts;
  late List<Map<String, dynamic>> selectedProducts;
  late List<Map<String, dynamic>?> selectedValues;
  int? expandedIndex;
  late Map<int, String?> checkedProducts;
  late int? selectedProductIndex;
  List<dynamic>? components;
  late List<double> selectedProductPrices;
  List<Map<String, dynamic>> selectedComponentsData = [];
  List<String> selectedProductsNames = [];
  List<String> selectedProductsIds = [];
  int sizeIndex = 0;
  int counter = 0;
  late List<TextEditingController> noteControllers;
  late List<bool> showNoteFields;
  List<List<int>> selectedSizeIndices = [];

  bool isStoreOpenByWorkingHours() {
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

      final workingHoursList = jsonDecode(widget.workingHours) as List<dynamic>;
      final todaySchedule = workingHoursList.firstWhere(
        (schedule) => schedule['day'] == currentDay,
        orElse: () => null,
      );

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

      return now.isAfter(openTime) && now.isBefore(closeTime);
    } catch (e) {
      debugPrint("Error checking working hours: $e");
      return widget.isOpen;
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint("widget.data.length on initState: ${widget.data.length}");
    _initializeLists();
  }

  void _initializeLists() {
    isSelected = List<bool>.filled(widget.data.length, false);

    selectedComponents = List<List<List<String>>>.generate(
      widget.data.length,
      (_) => [],
    );

    componentPrices = List<List<List<String>>>.generate(
      widget.data.length,
      (_) => [],
    );

    drinkPrices = List<List<List<String>>>.generate(
      widget.data.length,
      (_) => [],
    );
    selectedSizes = List<List<List<String>>>.generate(
      widget.data.length,
      (_) => [],
    );
    componentQuantities = List<List<List<int>>>.generate(
      widget.data.length,
      (_) => [],
    );

    selectedDrinks = List<List<List<String>>>.generate(
      widget.data.length,
      (_) => [],
    );
    drinkQuantities = List<List<List<int>>>.generate(
      widget.data.length,
      (_) => [],
    );
    checkedProducts = {};
    quantities = List<int>.filled(widget.data.length, 0);
    packagesQuantity = List<int>.filled(widget.packageData.length, 0);
    applyToAll = List<bool>.filled(widget.data.length, false);
    showComponents = List<bool>.filled(widget.data.length, true);
    applyToAllDrinks = List<bool>.filled(widget.data.length, false);
    finalPrice = List<double>.filled(widget.data.length, 0);
    finalPricePackages = 0;
    noteControllers = List<TextEditingController>.generate(
      widget.data.length,
      (_) => TextEditingController(),
    );
    showNoteFields = List<bool>.filled(widget.data.length, false);
  }

  @override
  void didUpdateWidget(covariant ItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize lists if data length changes (pagination)
    if (oldWidget.data.length != widget.data.length ||
        oldWidget.packageData.length != widget.packageData.length) {
      debugPrint(
          "Data updated: old length=${oldWidget.data.length}, new length=${widget.data.length}");
      _initializeLists();
    }
  }

  void _onProductSelected(int index, Map<String, dynamic> product) {
    setState(() {
      selectedProductIndex = index;
      checkedProducts[index] = product['id'].toString();
      if (product.containsKey('product_components')) {
        components = product['product_components'];
      } else {
        components = [];
      }
    });
  }

  void _confirmProductSelection(int index) {
    setState(() {
      if (checkedProducts.containsKey(index) &&
          checkedProducts[index] != null) {
        String? selectedProductId = checkedProducts[index];
        if (selectedProductId == null) return;
        Map<String, dynamic>? selectedProduct = allProducts.firstWhere(
          (p) => p['id'].toString() == selectedProductId,
          orElse: () => <String, dynamic>{},
        );
        if (selectedProduct.isNotEmpty) {
          selectedValues[index] = selectedProduct;
          selectedProductsNames[index] = selectedProduct['name'];
          selectedProductsIds[index] = selectedProduct['id'].toString();
          print(selectedProductsIds);
          selectedProducts
              .removeWhere((p) => p['id'].toString() == selectedProductId);
          expandedIndex = null;
          checkedProducts.remove(index);
        }
      }
    });
  }

  void _removeSelectedProduct(int index) {
    setState(() {
      if (selectedValues.isNotEmpty && selectedValues[index] != null) {
        finalPricePackages -= selectedProductPrices[index];

        selectedProductPrices[index] = 0.0;
        selectedProducts.add(selectedValues[index]!);
        selectedValues[index] = null;
      }
    });
  }

  void updateFinalPricePackages(int index) {
    setState(() {
      double orderPrice =
          double.parse(widget.packageData[index]['package_price']) *
              packagesQuantity[index].toDouble();
      finalPricePackages = orderPrice;
    });
  }

  void updateFinalPriceForIndex(int index) {
    String discount = widget.data[index]['discount_percentage'] != null
        ? widget.data[index]['discount_percentage'].toString()
        : "0";
    double orderPrice = 0;

    if (widget.data[index]['product_sizes'].isEmpty) {
      orderPrice = discount == "0"
          ? double.parse(widget.data[index]['price']) *
              quantities[index].toDouble()
          : (double.parse(widget.data[index]['price']) -
                  (double.parse(widget.data[index]['price']) *
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
            double sizePrice = double.parse(widget.data[index]['product_sizes']
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
        final component = widget.data[index]['product_components'].firstWhere(
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
        final drink = widget.data[index]['product_drinks'].firstWhere(
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
    print("widget.workingHours");
    print(widget.workingHours);
    if (selectedSizeIndices[index].contains(-1) &&
        widget.data[index]['product_sizes'].isNotEmpty) {
      Fluttertoast.showToast(
          msg: "يجب اختيار الحجم لجميع الوجبات", timeInSecForIosWeb: 4);
      return;
    }
    final productData = widget.data[index];
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
      // Selected components and drinks for the current order
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

      // Process selected drinks for the current order
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
      double orderBasePrice = 0;
      String? size;
      String? sizeId;
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

      // Create a new cart item for the current order
      final newItem = CartItem(
          storeDeliveryPrice: widget.storeDeliveryPrice.toString(),
          storeID: widget.storeId.toString(),
          storeName: widget.storeName.toString(),
          storeImage: widget.storeImage,
          storeLocation: widget.storeLocation,
          total: orderTotalPrice.toString(),
          price: orderBasePrice.toString(),
          size: size ?? "",
          sizeId: sizeId ?? "",
          components_names: allComponentsNames,
          components_prices: allComponentsPrices,
          storeCloseTime: widget.storeCloseTime,
          storeOpenTime: widget.storeOpenTime,
          workingHours: widget.workingHours,
          isOpen: widget.isOpen,
          selected_components_names: orderComponentsNames,
          selected_components_prices: orderComponentsPrices,
          drinks_names: allDrinksNames,
          drinks_prices: allDrinksPrices,
          selected_drinks_names: orderDrinksNames,
          selected_drinks_prices: orderDrinksPrices,
          name: productData["name"] ?? 'Unnamed Product',
          productId: productData["id"] ?? 0,
          image: productData['images'].isNotEmpty
              ? productData['images'][0]['url'] ??
                  'https://example.com/default.jpg'
              : 'https://example.com/default.jpg',
          quantity: 1,
          selected_drinks_id: orderDrinksId,
          selected_components_id: orderComponentsId,
          selected_drinks_qty: orderDrinksQty,
          selected_components_qty: orderComponentsQty,
          components_images: allComponentsImages,
          drinks_images: allDrinksImages,
          selected_components_images: orderComponentsImages,
          selected_drinks_images: orderDrinksImages,
          note: noteControllers[index].text.isEmpty
              ? null
              : noteControllers[index].text);

      // Add the current order to the cart
      cartProvider.addToCart(newItem);
    }

    quantities[index] = 0;
    selectedComponents[index].clear();
    selectedDrinks[index].clear();
    drinkQuantities[index].clear();
    isSelected[index] = !isSelected[index];
    noteControllers[index].clear();
    showNoteFields[index] = false;
    widget.changeConfirmOrder();
  }

  Future<void> sendOrderDetails(int index) async {
    if (selectedSizeIndices[index].contains(-1) &&
        widget.data[index]['product_sizes'].isNotEmpty) {
      Fluttertoast.showToast(
          msg: "يجب اختيار الحجم لجميع الوجبات", timeInSecForIosWeb: 4);
      return;
    }
    setState(() {
      loading = true;
    });

    final url =
        Uri.parse('${AppLink.addProducttoOrder}/${widget.orderId}/add-product');

    List<int> productIds = [];
    List<List<int>> componentIds = [];
    List<List<int>> componentIdsQty = [];
    List<List<int>> drinkIds = [];
    List<List<int>> drinkIdsQty = [];
    List<int> prices = [];
    List<int> sizes = [];
    List<int> qty = [];
    List<int> sum = [];

    int sizeId = 0;
    try {
      for (int orderIndex = 0; orderIndex < quantities[index]; orderIndex++) {
        final productData = widget.data[index];

        List<int> orderComponentIds = [];
        List<int> orderComponentQty = [];
        List<int> orderDrinkIds = [];
        List<int> orderDrinkQty = [];

        print(productData['product_components']);
        print(productData['product_drinks']);
        if (orderIndex < selectedComponents[index].length &&
            selectedComponents[index][orderIndex].isNotEmpty) {
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
              orderComponentIds
                  .add(int.parse(component['component_id']?.toString() ?? '0'));
              orderComponentQty.add(int.parse(componentQuantities[index]
                      [orderIndex][componentIndex]
                  .toString()));
            }
          }
        }

        if (orderIndex < selectedDrinks[index].length &&
            selectedDrinks[index][orderIndex].isNotEmpty) {
          for (int drinkIndex = 0;
              drinkIndex < selectedDrinks[index][orderIndex].length;
              drinkIndex++) {
            String drinkName = selectedDrinks[index][orderIndex][drinkIndex];
            final drink = productData['product_drinks'].firstWhere(
              (d) => d['drink_details']['name'] == drinkName,
              orElse: () => null,
            );

            if (drink != null) {
              orderDrinkIds
                  .add(int.parse(drink['drink_id']?.toString() ?? '0'));
              orderDrinkQty.add(int.parse(
                  drinkQuantities[index][orderIndex][drinkIndex].toString()));
            }
          }
        }

        String discount = productData['discount_percentage'] == null
            ? "0"
            : productData['discount_percentage'].toString();
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
            sizeId = productData['product_sizes'][selectedSizeIndex]['id'];
            double sizePrice = double.parse(productData['product_sizes']
                [selectedSizeIndex]['size_price_nis']);
            orderBasePrice = discount == "0"
                ? sizePrice
                : (sizePrice - (sizePrice * (double.parse(discount) / 100)));
          }
        }

        double componentsTotalPrice = 0;
        for (int i = 0; i < orderComponentQty.length; i++) {
          componentsTotalPrice += orderComponentQty[i] *
              double.parse(productData['product_components'][i]['com_price']
                      ?.toString() ??
                  '0');
        }

        double drinksTotalPrice = 0;
        for (int i = 0; i < orderDrinkQty.length; i++) {
          drinksTotalPrice += orderDrinkQty[i] *
              double.parse(
                  productData['product_drinks'][i]['drink_price']?.toString() ??
                      '0');
        }

        double orderTotalPrice =
            orderBasePrice + componentsTotalPrice + drinksTotalPrice;

        productIds.add(int.parse(productData['id']?.toString() ?? '0'));
        componentIds.add(orderComponentIds);
        componentIdsQty.add(orderComponentQty);
        drinkIds.add(orderDrinkIds);
        drinkIdsQty.add(orderDrinkQty);

        prices.add(orderBasePrice.toInt());
        sizes.add(sizeId);
        sum.add(orderTotalPrice.toInt());
        qty.add(1);
      }

      // Create the JSON body
      Map<String, dynamic> body = {
        "product_id": productIds,
        "component_id": componentIds,
        "component_ids_qty": componentIdsQty,
        "drink_id": drinkIds,
        "drink_ids_qty": drinkIdsQty,
        "price": prices,
        "size_id": sizes,
        "qty": qty,
        "sum": sum,
        "restaurant_id": widget.storeId,
      };
      print(body);
      // Send the POST request
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(
            msg: "تم إضافة المنتج للطلب بنجاح", timeInSecForIosWeb: 3);
        Navigator.pop(context, true);
        print('Order details submitted successfully: ${response.body}');
      } else {
        Fluttertoast.showToast(
            msg: "حدثت مشكلة اثناء إضافة المنتج للطلب", timeInSecForIosWeb: 3);
        print(
            'Failed to submit order details. Status code: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "حدثت مشكلة اثناء إضافة المنتج للطلب", timeInSecForIosWeb: 3);
      print('Error occurred: $e');
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty && widget.packageData.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            SizedBox(
              height: 200,
            ),
            Text(
              "لا يوجد منتجات متوفرة بهذا القسم",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Container(
        // height: MediaQuery.of(context).size.height,
        child: packageOpen && selectedPackage != null
            ? buildPackage(selectedPackage!, packageIndex!, selectedValues,
                selectedProducts, allProducts)
            : Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.packageData.length,
                    itemBuilder: (context, index) {
                      String imageUrl =
                          widget.packageData[index]['package_image'] != null &&
                                  widget.packageData[index]['package_image']
                                      .isNotEmpty
                              ? widget.packageData[index]['package_image']
                              : '';

                      String price =
                          widget.packageData[index]['package_price'] != null
                              ? "₪${widget.packageData[index]['package_price']}"
                              : "₪0";

                      String name = widget.packageData[index]['package_name'] ??
                          "No name available";
                      String dis = widget.packageData[index]
                              ['package_description'] ??
                          "No description available";

                      return Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                packageOpen = true;
                                selectedPackage = widget.packageData[index];
                                packagesQuantity[index]++;
                                packageIndex = index;
                                counter = 0;
                                widget.changePackagePage();
                                allProducts = List<Map<String, dynamic>>.from(
                                    widget.packageData[packageIndex!]
                                        ['products']);

                                selectedProducts = List.from(allProducts);
                                int productsQty = int.tryParse(
                                        selectedPackage!['products_qty']
                                            .toString()) ??
                                    0;
                                int drinksQty = int.tryParse(
                                        selectedPackage!['drinks_qty']
                                            .toString()) ??
                                    0;
                                selectedComponentsPackages =
                                    List<List<List<String>>>.generate(
                                  productsQty,
                                  (_) => [],
                                );

                                selectedPackagesDrinks =
                                    List<List<List<String>>>.generate(
                                  drinksQty,
                                  (_) => [],
                                );
                                drinkPackagesIds =
                                    List<List<List<String>>>.generate(
                                  drinksQty,
                                  (_) => [],
                                );
                                drinkPackagesPrices =
                                    List<List<List<String>>>.generate(
                                  drinksQty,
                                  (_) => [],
                                );
                                drinkPackagesQuantities =
                                    List<List<List<int>>>.generate(
                                  drinksQty,
                                  (_) => [],
                                );

                                componentPricesPackages =
                                    List<List<List<String>>>.generate(
                                  productsQty,
                                  (_) => [],
                                );
                                componentIds =
                                    List<List<List<String>>>.generate(
                                  productsQty,
                                  (_) => [],
                                );
                                selectedProductsNames = List<String>.generate(
                                  productsQty,
                                  (_) => "",
                                );
                                selectedProductsIds = List<String>.generate(
                                  productsQty,
                                  (_) => "",
                                );
                                selectedComponentsData =
                                    List<Map<String, dynamic>>.generate(
                                  productsQty,
                                  (_) => {},
                                );

                                selectedComponentsPackagesCopy =
                                    List<List<List<String>>>.generate(
                                  productsQty,
                                  (_) => [],
                                );
                                selectedProductPrices = List.filled(
                                    productsQty, 0.0,
                                    growable: true);
                                selectedValues = List.filled(
                                    int.tryParse(widget
                                            .packageData[packageIndex!]
                                                ['products_qty']
                                            .toString()) ??
                                        0,
                                    null);
                                updateFinalPricePackages(packageIndex!);
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
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            _showPhotoViewDialog(
                                                context, imageUrl);
                                          },
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                            child: FancyShimmerImage(
                                              imageUrl: imageUrl,
                                              boxFit: BoxFit.cover,
                                              width: 90,
                                              height: 90,
                                              errorWidget: Image.asset(
                                                "assets/images/logo2.png",
                                                fit: BoxFit.cover,
                                                width: 90,
                                                height: 90,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
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
                                                maxLines: 4,
                                                // overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black
                                                      .withOpacity(0.7),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    price,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      color: Color(0xff616163),
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "${packagesQuantity[index]}X",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: mainColor,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.data.length,
                    itemBuilder: (context, index) {
                      String imageUrl = widget.data[index]['images'] != null &&
                              widget.data[index]['images'].isNotEmpty
                          ? widget.data[index]['images'][0]['url']
                          : '';

                      String discount = widget.data[index]
                                  ['discount_percentage'] !=
                              null
                          ? widget.data[index]['discount_percentage'].toString()
                          : "0";
                      String originalPrice = widget.data[index]['price'] != null
                          ? widget.data[index]['price']
                          : "0";
                      String price = widget.data[index]['price'] != null
                          ? discount == "0"
                              ? "₪${widget.data[index]['price']}"
                              : "₪${double.parse(widget.data[index]['price']) - (double.parse(widget.data[index]['price']) * (double.parse(discount) / 100))}"
                          : "₪0";

                      String name =
                          widget.data[index]['name'] ?? "No name available";

                      String dis = widget.data[index]['description'] ??
                          "No description available";

                      List<dynamic> components =
                          widget.data[index]['product_components'] ?? [];

                      List<dynamic> drinks =
                          widget.data[index]['product_drinks'] ?? [];
                      List<dynamic> sizes =
                          widget.data[index]['product_sizes'] ?? [];
                      return Consumer2<CartProvider, PackageCartProvider>(
                        builder:
                            (context, cartProvider, packageCartProvider, _) {
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Image on the right
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Stack(
                                            alignment: Alignment.topCenter,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  _showPhotoViewDialog(
                                                      context, imageUrl);
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(10),
                                                  ),
                                                  child: FancyShimmerImage(
                                                    imageUrl: imageUrl,
                                                    boxFit: BoxFit.cover,
                                                    width: 90,
                                                    height: 90,
                                                    errorWidget: Image.asset(
                                                      "assets/images/logo2.png",
                                                      fit: BoxFit.cover,
                                                      width: 90,
                                                      height: 90,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Visibility(
                                                visible: discount != "0",
                                                child: Align(
                                                  alignment:
                                                      Alignment.topCenter,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16)),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6.0),
                                                      child: Center(
                                                        child: Text(
                                                          "${discount}%-",
                                                          style: TextStyle(
                                                              color: mainColor,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            // mainAxisAlignment:
                                            //     MainAxisAlignment.spaceBetween,
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
                                                maxLines: 7,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black
                                                      .withOpacity(0.7),
                                                  fontWeight: FontWeight.w600,
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
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: Color(
                                                                  0xff616163)
                                                              .withOpacity(0.5),
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                      Positioned(
                                                        bottom: 6,
                                                        child: Text(
                                                          '_' *
                                                              {
                                                                double.parse(
                                                                    originalPrice
                                                                        .trim())
                                                              }
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      color: Color(0xff616163),
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "${quantities[index]}X",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: mainColor,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Increment and Decrement Buttons
                                      increaseDecreaseButton(index),
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
                                            discount),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  if (quantities[index] > 0) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 3),
                                                child: Text(
                                                  "المكونات",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: showComponents[index]
                                                        ? Colors.white
                                                        : Colors.black
                                                            .withOpacity(0.7),
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
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 3),
                                                child: Text(
                                                  "المشروبات",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        !showComponents[index]
                                                            ? Colors.white
                                                            : Colors.black
                                                                .withOpacity(
                                                                    0.7),
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
                                        ? componentsCheckBox(index, components)
                                        : drinksCheckBox(index, drinks),
                                    if (showComponents[index]) ...[
                                      if (applyToAll[index])
                                        _buildAllItemsSection(
                                            "مكونات جميع الطلبات",
                                            components,
                                            selectedComponents,
                                            componentQuantities,
                                            index,
                                            sizes)
                                      else
                                        _buildIndividualItemsSection(
                                            "مكونات الطلب",
                                            components,
                                            selectedComponents,
                                            componentQuantities,
                                            index,
                                            sizes)
                                    ] else if (applyToAllDrinks[index])
                                      _buildAllItemsSection(
                                          "مشروبات جميع الطلبات",
                                          drinks,
                                          selectedDrinks,
                                          drinkQuantities,
                                          index,
                                          sizes)
                                    else
                                      _buildIndividualItemsSection(
                                          "مشروبات الطلب",
                                          drinks,
                                          selectedDrinks,
                                          drinkQuantities,
                                          index,
                                          sizes),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0, vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Visibility(
                                            visible: !showNoteFields[index],
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  showNoteFields[index] = true;
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12.0,
                                                        vertical: 8.0),
                                                decoration: BoxDecoration(
                                                  color: fourthColor,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.note_add,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'اضافة ملاحظة',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Visibility(
                                            visible: showNoteFields[index],
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 8),
                                                TextField(
                                                  controller:
                                                      noteControllers[index],
                                                  minLines: 2,
                                                  maxLines: 4,
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'اضافة ملاحظة (اختياري)',
                                                    hintTextDirection:
                                                        TextDirection.rtl,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: mainColor,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 12.0,
                                                            vertical: 8.0),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      showNoteFields[index] =
                                                          false;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12.0,
                                                        vertical: 6.0),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[400],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      'اخفاء',
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
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
                                    InkWell(
                                      onTap: () {
                                        if (widget.isResturant) {
                                          sendOrderDetails(index);
                                        } else {
                                          final bool isOpenByHours =
                                              isStoreOpenByWorkingHours();
                                          final bool isOpenByBackend =
                                              widget.isOpen;
                                          final bool canOrder =
                                              isOpenByHours && isOpenByBackend;

                                          if (canOrder) {
                                            if (cartItems.isNotEmpty) {
                                              List<PackageCartItem>
                                                  packageItems =
                                                  packageCartProvider
                                                      .packageCartItems;
                                              String firstStoreId =
                                                  cartItems[0].storeID;

                                              String firstPackageStoreId =
                                                  packageItems.isNotEmpty
                                                      ? packageItems[0].storeID
                                                      : widget.storeId;
                                              bool allSameStore =
                                                  firstStoreId ==
                                                          widget.storeId &&
                                                      firstPackageStoreId ==
                                                          widget.storeId;
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
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                  ),
                                                  msgAlign: TextAlign.center,
                                                  context: context,
                                                  actions: [
                                                    IconsButton(
                                                      onPressed: () {
                                                        Navigator.of(context,
                                                                rootNavigator:
                                                                    true)
                                                            .pop();
                                                      },
                                                      text: 'الغاء',
                                                      iconData:
                                                          Icons.cancel_outlined,
                                                      textStyle: TextStyle(
                                                          color: Colors.white),
                                                      iconColor: Colors.white,
                                                      color: Colors.blue,
                                                    ),
                                                    IconsButton(
                                                      onPressed: () {
                                                        Navigator.of(context,
                                                                rootNavigator:
                                                                    true)
                                                            .pop();
                                                        cartProvider
                                                            .clearCart();
                                                        packageCartProvider
                                                            .clearCart();
                                                        _addToCart(cartProvider,
                                                            index);
                                                      },
                                                      text: 'حذف واستمرار',
                                                      iconData: Icons.delete,
                                                      color: mainColor,
                                                      textStyle: TextStyle(
                                                          color: Colors.white),
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
                                                msg:
                                                    "لا يمكنك الطلب الان ،المحل مغلق",
                                                toastLength: Toast.LENGTH_LONG,
                                                gravity: ToastGravity.BOTTOM,
                                                timeInSecForIosWeb: 3,
                                                backgroundColor: const Color(0xffE74C3C),
                                                textColor: Colors.white,
                                                fontSize: 16.0);
                                          }
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
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: fourthColor,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    bottomRight:
                                                        Radius.circular(14),
                                                  ),
                                                ),
                                                alignment:
                                                    Alignment.centerRight,
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
                                                  bottomLeft:
                                                      Radius.circular(14),
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10.0),
                                                child: Text(
                                                  widget.isResturant
                                                      ? "اضافة الى الطلب"
                                                      : "اضافة الى السلة",
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
                                    ),
                                    Visibility(
                                        visible: loading,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ))
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget increaseDecreaseButton(int index) {
    return Visibility(
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
                InkWell(
                  onTap: () {
                    setState(() {
                      quantities[index]++;
                      if (applyToAll[index]) {
                        if (selectedComponents[index].isNotEmpty) {
                          List<String> firstRowComponents =
                              List.from(selectedComponents[index][0]);
                          List<int> firstRowQuantities =
                              componentQuantities[index].isNotEmpty
                                  ? List.from(componentQuantities[index][0])
                                  : [];

                          selectedComponents[index].clear();
                          componentQuantities[index].clear();

                          for (int i = 0; i < quantities[index]; i++) {
                            selectedComponents[index]
                                .add(List.from(firstRowComponents));
                            componentQuantities[index]
                                .add(List.from(firstRowQuantities));
                          }
                        }
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
                InkWell(
                  onTap: () {
                    setState(() {
                      if (quantities[index] > 0) {
                        quantities[index]--;
                        if (selectedSizeIndices[index].length >
                            quantities[index]) {
                          selectedSizeIndices[index].removeLast();
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
                      if (applyToAllDrinks[index]) {
                        selectedDrinks[index].clear();
                        selectedDrinks[index].add([]);
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
    );
  }

  Widget _buildAllItemsSection(
    String title,
    List<dynamic> items,
    List<List<List<String>>> selectedItems,
    List<List<List<int>>> itemQuantities,
    int index,
    List<dynamic> sizes,
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
    List<dynamic> sizes,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: List.generate(quantities[index], (dropdownIndex) {
              if (selectedItems[index].length <= dropdownIndex) {
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
                        "$rowTitlePrefix ${dropdownIndex + 1}",
                        style: TextStyle(color: Color(0xff6D6D6D)),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((item) {
                          return _buildItemCard(
                            item,
                            selectedItems[index][dropdownIndex],
                            itemQuantities[index][dropdownIndex],
                            index,
                            (isSelected, itemName, itemIndex) {
                              setState(() {
                                if (isSelected) {
                                  selectedItems[index][dropdownIndex]
                                      .removeAt(itemIndex);
                                  itemQuantities[index][dropdownIndex]
                                      .removeAt(itemIndex);
                                } else {
                                  selectedItems[index][dropdownIndex]
                                      .add(itemName);
                                  itemQuantities[index][dropdownIndex].add(1);
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
        ],
      ),
    );
  }

  Widget _buildItemCard(
    Map<String, dynamic>? item,
    List<String> selectedRow,
    List<int> quantitiesRow,
    int index,
    Function(bool isSelected, String itemName, int itemIndex) onItemTap,
  ) {
    if (item == null ||
        (item['component_details'] == null && item['drink_details'] == null)) {
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
          // height: isSelected ? 115 : 90,
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
                      "assets/images/drinks.png",
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

  Widget componentsCheckBox(int index, List<dynamic> components) {
    return Visibility(
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
                  if (selectedComponents[index].isNotEmpty) {
                    List<String> firstRowComponents =
                        List.from(selectedComponents[index][0]);
                    List<int> firstRowQuantities =
                        componentQuantities[index].isNotEmpty
                            ? List.from(componentQuantities[index][0])
                            : [];

                    selectedComponents[index].clear();
                    componentQuantities[index].clear();

                    for (int i = 0; i < quantities[index]; i++) {
                      selectedComponents[index]
                          .add(List.from(firstRowComponents));
                      componentQuantities[index]
                          .add(List.from(firstRowQuantities));
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

  Widget _buildAllSizesSection(
    String title,
    List<dynamic> items,
    List<List<List<String>>> selectedSizes,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              color: Color(0xff6D6D6D),
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.asMap().entries.map((entry) {
            int sizeIdx = entry.key;
            var item = entry.value;
            final bool isSelected =
                selectedSizeIndices[index].contains(sizeIdx);

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedSizeIndices[index].clear();
                  if (!isSelected) {
                    for (int i = 0; i < quantities[index]; i++) {
                      selectedSizeIndices[index].add(sizeIdx);
                    }
                  }
                });

                updateFinalPriceForIndex(index);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: isSelected ? mainColor : const Color(0xffD5D5D5),
                        width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item['size'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? mainColor : const Color(0xff6D6D6D),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIndividualSizesSection(
    String title,
    List<dynamic> items,
    List<List<List<String>>> selectedSizes,
    int index,
    String discount,
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
                      double sizePrice = double.parse(item['size_price_nis']);
                      double finalPrice = (discount == "0")
                          ? sizePrice
                          : (sizePrice -
                              (sizePrice * (double.parse(discount) / 100)));
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
                            child: Column(
                              children: [
                                Text(
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
                                Text(
                                  "₪${finalPrice}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: selectedSizes[index][dropdownIndex]
                                            .contains(item['id'].toString())
                                        ? mainColor
                                        : const Color(0xff6D6D6D),
                                  ),
                                ),
                              ],
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

  Widget drinksCheckBox(int index, List<dynamic> drinks) {
    return Visibility(
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
                    List<String> firstRowDrinks =
                        List.from(selectedDrinks[index][0]);
                    List<int> firstRowDrinkQuantities =
                        drinkQuantities[index].isNotEmpty
                            ? List.from(drinkQuantities[index][0])
                            : [];

                    selectedDrinks[index].clear();
                    drinkQuantities[index].clear();

                    for (int i = 0; i < quantities[index]; i++) {
                      selectedDrinks[index].add(List.from(firstRowDrinks));
                      drinkQuantities[index]
                          .add(List.from(firstRowDrinkQuantities));
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
    );
  }

  Widget buildPackage(
    Map<String, dynamic> package,
    int index,
    List<Map<String, dynamic>?> selectedValues,
    List<Map<String, dynamic>> selectedProducts,
    List<Map<String, dynamic>> allProducts,
  ) {
    return Consumer2<CartProvider, PackageCartProvider>(
        builder: (context, cartProvider, packageCartProvider, _) {
      int productsQty = int.tryParse(package['products_qty'].toString()) ?? 0;
      int drinksQty = int.tryParse(package['drinks_qty'].toString()) ?? 0;
      List<dynamic> drinks =
          package['package_drinks'] != null ? package['package_drinks'] : [];

      if (selectedValues.length != productsQty) {
        selectedValues = List.filled(productsQty, null);
      }
      List<String> packageDrinksNames = [];
      List<String> packageDrinksPrices = [];
      List<String> packageDrinksId = [];
      List<String> packageDrinksQty = [];
      return Column(
        children: [
          Container(
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
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                        child: FancyShimmerImage(
                          imageUrl: package['package_image'],
                          boxFit: BoxFit.cover,
                          width: 90,
                          height: 90,
                          errorWidget: Image.asset(
                            "assets/images/logo2.png",
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              package['package_name'],
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
                              package['package_description'],
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
                                Text(
                                  "₪${package['package_price']}",
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
                                  "${packagesQuantity[index]}X",
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
                    Column(
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
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (packagesQuantity[index] < 1) {
                                      packagesQuantity[index]++;
                                    } else {
                                      Fluttertoast.showToast(
                                          msg: "يمكنك طلب كل بكج لوحده");
                                    }
                                  });
                                  updateFinalPricePackages(index);
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
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (packagesQuantity[index] > 0)
                                      packagesQuantity[index]--;
                                    if (packagesQuantity[index] == 0) {
                                      packageOpen = false;
                                      packagesQuantity[index] = 0;
                                      widget.changePackagePage();
                                      expandedIndex = null;
                                      components = [];
                                      checkedProducts = {};
                                      selectedComponentsData = [];
                                    }
                                  });
                                  updateFinalPricePackages(index);
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
                    SizedBox(width: 10),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                ...List.generate(productsQty, (dropdownIndex) {
                  Map<String, dynamic>? selectedProduct =
                      selectedValues[dropdownIndex];
                  bool isExpanded = expandedIndex == dropdownIndex;
                  bool isValidSelection = selectedProduct != null;
                  bool isChecked = checkedProducts.containsKey(dropdownIndex);

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isValidSelection) {
                            } else {
                              expandedIndex = isExpanded ? null : dropdownIndex;
                            }
                            if (isExpanded) {
                              checkedProducts = {};
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              isValidSelection
                                  ? Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            _showPhotoViewDialog(
                                                context,
                                                selectedProduct['images'][0]
                                                    ['url']);
                                          },
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: FancyShimmerImage(
                                                imageUrl:
                                                    selectedProduct['images'][0]
                                                        ['url'],
                                                width: 30,
                                                height: 30,
                                                boxFit: BoxFit.cover,
                                                errorWidget: Image.asset(
                                                  "assets/images/logo2.png",
                                                  fit: BoxFit.cover,
                                                  width: 30,
                                                  height: 30,
                                                )),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          selectedProduct['name'],
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      "الصنف ${dropdownIndex + 1}",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff6D6D6D)),
                                    ),
                              isValidSelection
                                  ? InkWell(
                                      onTap: () {
                                        selectedComponentsData[dropdownIndex] =
                                            ({});
                                        setState(() {
                                          counter--;
                                        });
                                        _removeSelectedProduct(dropdownIndex);
                                      },
                                      child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: Color(0xffA51E22),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(8)),
                                          ),
                                          child: Image.asset(
                                              "assets/images/delete-button.png")),
                                    )
                                  : Image.asset(
                                      isExpanded
                                          ? "assets/images/arrow-up.png"
                                          : "assets/images/arrow-down.png",
                                      width: 25,
                                      height: 10,
                                    ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: Column(
                            children: selectedProducts.map((product) {
                              bool isChecked = checkedProducts[dropdownIndex] ==
                                  product['id'].toString();

                              return InkWell(
                                onTap: () {
                                  selectedComponentsPackages[dropdownIndex]
                                      .clear();
                                  componentIds[dropdownIndex].clear();
                                  componentPricesPackages[dropdownIndex]
                                      .clear();
                                  componentQuantities[dropdownIndex].clear();
                                  finalPricePackages -=
                                      selectedProductPrices[dropdownIndex];
                                  selectedProductPrices[dropdownIndex] = 0;
                                  _onProductSelected(dropdownIndex, product);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 12),
                                    margin: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isChecked
                                          ? fourthColor
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.black.withOpacity(0.7)),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 5),
                                        Container(
                                          width: 25,
                                          height: 25,
                                          padding: EdgeInsets.all(0),
                                          child: Checkbox(
                                            value: isChecked,
                                            onChanged: (value) {
                                              selectedComponentsPackages[index]
                                                  .clear();
                                              componentPricesPackages[index]
                                                  .clear();
                                              componentQuantities[index]
                                                  .clear();
                                              componentIds[index].clear();
                                              finalPricePackages -=
                                                  selectedProductPrices[
                                                      dropdownIndex];
                                              selectedProductPrices[
                                                  dropdownIndex] = 0;
                                              _onProductSelected(
                                                  dropdownIndex, product);
                                            },
                                            checkColor: mainColor,
                                            activeColor: Colors.white,
                                            hoverColor: Colors.white,
                                            side: BorderSide(
                                                width: 0,
                                                color: Colors.black
                                                    .withOpacity(0.7)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: FancyShimmerImage(
                                              imageUrl: product['images'][0]
                                                  ['url'],
                                              width: 30,
                                              height: 30,
                                              boxFit: BoxFit.cover,
                                              errorWidget: Image.asset(
                                                "assets/images/logo2.png",
                                                fit: BoxFit.cover,
                                                height: 30,
                                                width: 30,
                                              )),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          product['name'],
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: mainColor,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      if (isChecked && isExpanded)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              _buildCompnentsSection(
                                "مكونات الصنف ${dropdownIndex + 1}",
                                components!,
                                selectedComponentsPackages,
                                componentQuantities,
                                componentPricesPackages,
                                componentIds,
                                index,
                                dropdownIndex,
                                0,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              InkWell(
                                onTap: () {
                                  _confirmProductSelection(dropdownIndex);

                                  for (int i = 0;
                                      i <
                                          selectedComponentsPackages[
                                                  dropdownIndex]
                                              .length;
                                      i++) {
                                    selectedComponentsData[dropdownIndex] = ({
                                      'name': selectedComponentsPackages[
                                          dropdownIndex][i],
                                      'price':
                                          componentPricesPackages[dropdownIndex]
                                              [i],
                                      'quantity':
                                          componentQuantities[dropdownIndex][i],
                                      'id': componentIds[dropdownIndex][i],
                                    });
                                  }
                                  setState(() {
                                    counter++;
                                  });
                                  print(drinks);
                                  selectedComponentsPackages[dropdownIndex]
                                      .clear();
                                  componentQuantities[dropdownIndex].clear();
                                  componentPricesPackages[dropdownIndex]
                                      .clear();
                                  componentIds[dropdownIndex].clear();
                                },
                                child: Container(
                                  width: 50,
                                  height: 30,
                                  decoration: BoxDecoration(
                                      color: mainColor,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Center(
                                    child: Text("تأكيد",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }),
                SizedBox(
                  height: 15,
                ),
                Visibility(
                  visible: counter == productsQty && drinksQty != 0,
                  child: _buildCompnentsSection(
                      "اختر ${drinksQty} من المشروبات",
                      drinks,
                      selectedPackagesDrinks,
                      drinkPackagesQuantities,
                      drinkPackagesPrices,
                      drinkPackagesIds,
                      index,
                      0,
                      drinksQty),
                ),
                InkWell(
                  onTap: () {
                    if (!widget.isResturant) {
                      List<CartItem> cartItems = cartProvider.cartItems;
                      List<PackageCartItem> packageItems =
                          packageCartProvider.packageCartItems;
                      String firstStoreId = cartItems.isNotEmpty
                          ? cartItems[0].storeID
                          : widget.storeId;
                      String firstPackageStoreId = packageItems.isNotEmpty
                          ? packageItems[0].storeID
                          : widget.storeId;
                      bool allSameStore = firstStoreId == widget.storeId &&
                          firstPackageStoreId == widget.storeId;
                      if (allSameStore) {
                        if (counter != productsQty) {
                          Fluttertoast.showToast(
                              msg: "يجب اختيار جميع اصناف البكج",
                              timeInSecForIosWeb: 3);
                        } else {
                          for (int orderIndex = 0;
                              orderIndex < packagesQuantity[index];
                              orderIndex++) {
                            // if (orderIndex <
                            //     selectedPackagesDrinks[index].length) {
                            print(selectedPackagesDrinks);
                            for (int drinkIndex = 0;
                                drinkIndex <
                                    selectedPackagesDrinks[0][orderIndex]
                                        .length;
                                drinkIndex++) {
                              String drinkName = selectedPackagesDrinks[0]
                                  [orderIndex][drinkIndex];

                              final drink = package['package_drinks'] != null
                                  ? package['package_drinks'].firstWhere(
                                      (d) {
                                        final isMatch = d['name'] == drinkName;
                                        return isMatch;
                                      },
                                      orElse: () => null,
                                    )
                                  : [];

                              if (drink != null) {
                                packageDrinksNames.add(drinkName);
                                packageDrinksPrices.add('0');
                                packageDrinksId
                                    .add(drink['id']?.toString() ?? '0');
                                packageDrinksQty.add(drinkPackagesQuantities[0]
                                        [orderIndex][drinkIndex]
                                    .toString());
                              }
                              // }
                            }
                          }
                          if (packageDrinksNames.isEmpty && drinksQty != 0) {
                            Fluttertoast.showToast(
                                msg: "يجب اختيار المشروبات",
                                timeInSecForIosWeb: 3);
                          } else {
                            final packageProvider =
                                Provider.of<PackageCartProvider>(
                              context,
                              listen: false,
                            );
                            List<String> productNames = [];
                            List<String> productIds = [];
                            Map<String, Component> productComponents = {};
                            for (int i = 0;
                                i < selectedProductsNames.length;
                                i++) {
                              String productName = selectedProductsNames[i];
                              String productId = selectedProductsIds[i];
                              if (i < selectedComponentsData.length) {
                                var component = selectedComponentsData[i];
                                productComponents[productName] = Component(
                                  name: component['name'].toString(),
                                  price: component['price'].toString(),
                                  qty: component['quantity'].toString(),
                                  id: component['id'].toString(),
                                );
                              }
                              productNames.add(productName);
                              productIds.add(productId);
                            }

                            PackageCartItem packageItem = PackageCartItem(
                              id: package['id'],
                              packageId: package['id'],
                              packageName: package['package_name'],
                              packageImage: package['package_image'],
                              storeCloseTime: widget.storeCloseTime,
                              storeOpenTime: widget.storeOpenTime,
                              workingHours: widget.workingHours,
                              isOpen: widget.isOpen,
                              total: finalPricePackages.toString(),
                              packagePrice: package['package_price'],
                              storeID:
                                  package['products'][0]['store_id'].toString(),
                              storeName: widget.storeName,
                              storeImage: widget.storeImage,
                              storeLocation: widget.storeLocation,
                              storeDeliveryPrice: widget.storeDeliveryPrice,
                              quantity: packagesQuantity[index],
                              productNames: productNames,
                              productIds: productIds,
                              productComponents: productComponents,
                              selected_drinks_names: packageDrinksNames,
                              selected_drinks_prices: packageDrinksPrices,
                              selected_drinks_qty: packageDrinksQty,
                              selected_drinks_id: packageDrinksId,
                            );

                            packageProvider.addToCart(packageItem);
                            Fluttertoast.showToast(
                              msg: "تمت إضافة البكج إلى السلة",
                              timeInSecForIosWeb: 3,
                            );
                            setState(() {
                              packageOpen = false;
                              packagesQuantity[index] = 0;
                              widget.changePackagePage();
                              expandedIndex = null;
                              components = [];
                              checkedProducts = {};
                              selectedComponentsData = [];
                            });
                            widget.changeConfirmOrder();
                          }
                        }
                      } else {
                        Dialogs.materialDialog(
                          msg: 'لا يمكنك الطلب من اكثر من مطعم واحد بنفس الوقت',
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
                                packageCartProvider.clearCart();
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
                      Fluttertoast.showToast(msg: "هذه العملية غير متاحة الان");
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: fourthColor,
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(14),
                              ),
                            ),
                            alignment: Alignment.centerRight,
                            child: Text(
                              "الاجمالي: ${finalPricePackages}",
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
                            child: Text(
                              widget.isResturant
                                  ? "اضافة الى الطلب"
                                  : "اضافة الى السلة",
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
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCompnentsSection(
    String rowTitlePrefix,
    List<dynamic> items,
    List<List<List<String>>> selectedItems,
    List<List<List<int>>> itemQuantities,
    List<List<List<String>>> itemPrices,
    List<List<List<String>>> itemIds,
    int index,
    int dropdownIndex,
    int drinkQty,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Column(
        children: List.generate(packagesQuantity[index], (rowIndex) {
          if (selectedItems[dropdownIndex].length <= rowIndex) {
            selectedItems[dropdownIndex].add([]);
            itemQuantities[dropdownIndex].add([]);
            itemPrices[dropdownIndex].add([]);
            itemIds[dropdownIndex].add([]);
          }

          return Visibility(
            visible: items.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    "$rowTitlePrefix",
                    style: TextStyle(
                        color: Color(0xff6D6D6D), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.map((item) {
                      return _buildPackageItemCard(
                        item,
                        selectedItems[dropdownIndex][rowIndex],
                        itemQuantities[dropdownIndex][rowIndex],
                        itemPrices[dropdownIndex][rowIndex],
                        itemIds[dropdownIndex][rowIndex],
                        rowIndex,
                        drinkQty,
                        (isSelected, itemName, itemIndex, itemPrice, itemId) {
                          setState(() {
                            if (isSelected) {
                              selectedItems[dropdownIndex][rowIndex]
                                  .removeAt(itemIndex);
                              itemPrices[dropdownIndex][rowIndex]
                                  .removeAt(itemIndex);
                              itemIds[dropdownIndex][rowIndex]
                                  .removeAt(itemIndex);
                              itemQuantities[dropdownIndex][rowIndex]
                                  .removeAt(itemIndex);
                              finalPricePackages -= double.parse(itemPrice);
                              selectedProductPrices[dropdownIndex] -=
                                  double.parse(itemPrice);
                            } else {
                              if (drinkQty == 0 ||
                                  selectedItems[dropdownIndex][rowIndex]
                                          .length <
                                      drinkQty) {
                                selectedItems[dropdownIndex][rowIndex]
                                    .add(itemName);
                                itemPrices[dropdownIndex][rowIndex]
                                    .add(itemPrice);
                                itemIds[dropdownIndex][rowIndex].add(itemId);
                                itemQuantities[dropdownIndex][rowIndex].add(1);
                                selectedProductPrices[dropdownIndex] +=
                                    double.parse(itemPrice);
                                finalPricePackages += double.parse(itemPrice);
                              }
                            }
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

  Widget _buildPackageItemCard(
    Map<String, dynamic> item,
    List<String> selectedRow,
    List<int> quantitiesRow,
    List<String> priceRow,
    List<String> idRow,
    int dropdownIndex,
    int drinkQty,
    Function(bool isSelected, String itemName, int itemIndex, String itemPrice,
            String itemId)
        onItemTap,
  ) {
    String itemName = item['component_details'] != null
        ? item['component_details']["name"]
        : item['name'] ?? "Unknown";

    String itemPrice =
        item['component_details'] != null ? "₪${item['com_price']}" : "₪0";

    String price =
        item['component_details'] != null ? "${item['com_price']}" : "0";
    String id = item['component_details'] != null
        ? "${item['component_details']['id'].toString()}"
        : item['id'].toString();

    String? itemImage = item['component_details'] != null
        ? item['component_details']["image"]
        : item["image"];

    bool isSelected = selectedRow.contains(itemName);
    int itemIndex = selectedRow.indexOf(itemName);

    int? maxOrderNum = item['max_order_num'] ?? 15;

    return GestureDetector(
      onTap: () {
        if (isSelected || drinkQty == 0 || selectedRow.length < drinkQty) {
          onItemTap(isSelected, itemName, itemIndex, price, id);
        }
      },
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
                child: itemImage != null
                    ? Image.network(
                        itemImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "assets/images/drinks.png",
                            width: 50,
                            height: 50,
                          );
                        },
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[600],
                          size: 30,
                        ),
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
              if (isSelected && drinkQty == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (maxOrderNum == null ||
                              quantitiesRow[itemIndex] < maxOrderNum) {
                            if (drinkQty == 0) {
                              quantitiesRow[itemIndex]++;
                            } else {
                              for (int i = 0; i < quantitiesRow.length; i++) {
                                quantitiesRow[i] = drinkQty;
                              }
                            }
                            selectedProductPrices[dropdownIndex] +=
                                double.parse(price);
                            finalPricePackages += double.parse(price);
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
                            if (drinkQty == 0) {
                              quantitiesRow[itemIndex]--;
                            } else {
                              for (int i = 0; i < quantitiesRow.length; i++) {
                                quantitiesRow[i] = drinkQty;
                              }
                            }
                            selectedProductPrices[dropdownIndex] -=
                                double.parse(price);
                            finalPricePackages -= double.parse(price);
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

  void _showPhotoViewDialog(BuildContext context, String image) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return Stack(
          children: [
            Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(10),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(image),
              ),
            ),
            Positioned(
              top: 15,
              right: 15,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                iconSize: 35,
                color: Colors.white,
                icon: Icon(Icons.close_rounded),
              ),
            ),
          ],
        );
      },
    );
  }
}
