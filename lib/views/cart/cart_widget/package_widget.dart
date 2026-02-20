import 'package:j_food_updated/LocalDB/Models/PackageCartItem.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/resources/font_manager.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';

class PackageProductMethod extends StatefulWidget {
  final PackageCartItem item;
  final Function removeProduct;
  final Function editProduct;

  PackageProductMethod({
    required this.item,
    required this.removeProduct,
    required this.editProduct,
  });

  @override
  _PackageProductMethodState createState() => _PackageProductMethodState();
}

class _PackageProductMethodState extends State<PackageProductMethod> {
  double _dragOffset = 0.0;
  final double _maxOffset = 60.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 30,
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
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            content: Text(
                                "هل تريد بالتأكيد حذف هذا البكج من الطلبيه؟"),
                            actions: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.removeProduct();
                                      setState(() {
                                        _dragOffset = 0;
                                      });
                                      Fluttertoast.showToast(
                                          msg: "تم حذف البكج بنجاح");
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
                        },
                      );
                    },
                    child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Color(0xffA51E22),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Image.asset("assets/images/delete-button.png")),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Foreground: The sliding card
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              // Update drag offset but keep it between 0 and -_maxOffset
              _dragOffset =
                  (_dragOffset + details.delta.dx).clamp(-_maxOffset, 0.0);
            });
          },
          onHorizontalDragEnd: (details) {
            setState(() {
              // Snap back to original position if dragged less than halfway
              if (_dragOffset.abs() < _maxOffset / 2) {
                _dragOffset = 0.0;
              } else {
                _dragOffset = -_maxOffset;
              }
            });
          },
          child: Transform.translate(
            offset: Offset(_dragOffset, 0), // Apply sliding effect
            child: InkWell(
              onTap: () {
                _showDetailsDialog();
              },
              child: Card(
                elevation: 2,
                color: Colors.white,
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: mainColor.withOpacity(0.1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FancyShimmerImage(
                            imageUrl: widget.item.packageImage,
                            width: 90,
                            height: 90,
                            boxFit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.packageName.length > 20
                                  ? "${widget.item.packageName.substring(0, 20)}..."
                                  : widget.item.packageName,
                              style: TextStyle(
                                color: Color(0xff5E5E5E),
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            Visibility(
                              visible: widget.item.productNames.isNotEmpty,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        "الوجبات : ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: mainColor,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          widget.item.productNames.join(", "),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: FontSize.s12,
                                            color: textColor.withOpacity(0.4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xffEAEAEA)),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              child: Text(
                                "₪${widget.item.total}",
                                style: TextStyle(
                                  color: mainColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: FontSize.s14,
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
        ),
      ],
    );
  }

  void _showDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double totalPrice = double.parse(widget.item.total);

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
                                widget.item.packageImage,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              "${widget.item.packageName}",
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
                          "₪${widget.item.packagePrice}",
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
                              "${widget.item.quantity}",
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
                              "₪${widget.item.packagePrice} ${widget.item.quantity}x",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7)),
                            ),
                            Text(
                              "₪${double.parse(widget.item.packagePrice) * widget.item.quantity}",
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
                ProductWithComponentsWidget(
                  item: widget.item,
                  textColor: textColor,
                  mainColor: mainColor,
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                      color: Color(0xffF8F8F8),
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              "₪${_calculateTotalPrice()}",
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateTotalPrice() {
    // Calculate the total for components with their quantities
    double componentTotal = 0.0;
    // for (int i = 0; i < widget.item.selected_components_prices.length; i++) {
    //   double price = double.parse(widget.item.selected_components_prices[i]);
    //   int quantity = int.parse(widget.item.selected_components_qty[i]);
    //   componentTotal += price * quantity;
    // }

    // Calculate the total for drinks with their quantities
    double drinkTotal = 0.0;
    // for (int i = 0; i < widget.item.selected_drinks_prices.length; i++) {
    //   double price = double.parse(widget.item.selected_drinks_prices[i]);
    //   int quantity = int.parse(widget.item.selected_drinks_qty[i]);
    //   drinkTotal += price * quantity;
    // }

    return componentTotal + drinkTotal;
  }
}

class ProductWithComponentsWidget extends StatelessWidget {
  final PackageCartItem item;
  final Color textColor;
  final Color mainColor;

  const ProductWithComponentsWidget({
    Key? key,
    required this.item,
    required this.textColor,
    required this.mainColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // printPackageData(item);
    print("item.selectedDrinksNames.length");
    print(item.selected_drinks_names.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.productNames.isNotEmpty) ...[
          Column(
            children: List.generate(item.productNames.length, (index) {
              String productName = item.productNames[index];
              Component? component = item.productComponents[productName];

              if (component == null) {
                return SizedBox.shrink();
              }
              List<String> componentNames =
                  parseComponentString(component.name);
              List<int> componentPrices = parseComponentString(component.price)
                  .map((e) => int.tryParse(e) ?? 0)
                  .toList();
              List<int> componentQuantities =
                  parseComponentString(component.qty)
                      .map((e) => int.tryParse(e) ?? 0)
                      .toList();

              return Container(
                decoration: BoxDecoration(
                    color: Color(0xffF8F8F8),
                    borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.symmetric(vertical: 3),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15.0, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "الصنف ${index + 1} : ${productName}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: mainColor,
                        ),
                      ),
                      SizedBox(height: 6),
                      Column(
                        children: List.generate(componentNames.length, (i) {
                          return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: componentNames[i] != ""
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            componentNames[i],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          "₪${componentPrices[i]} X ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.black.withOpacity(0.7),
                                          ),
                                        ),
                                        Text(
                                          "${componentQuantities[i]}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.black.withOpacity(0.7),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 20,
                                        ),
                                        Text(
                                          "₪${componentPrices[i] * componentQuantities[i]}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.black.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "لا يوجد مكونات بهذا الصنف",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: textColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      ],
                                    ));
                        }),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          Container(
            decoration: BoxDecoration(
                color: Color(0xffF8F8F8),
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "بالاضافة الى",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor),
                  ),
                  Column(
                    children: List.generate(
                      item.selected_drinks_names.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.selected_drinks_names[index],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor),
                            ),
                            Text(
                              "₪${item.selected_drinks_prices[index]} ${item.selected_drinks_qty[index]}x",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7)),
                            ),
                            Text(
                              "₪${double.parse(item.selected_drinks_prices[index]) * double.parse(item.selected_drinks_qty[index])}",
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
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<String> parseComponentString(String componentString) {
    componentString =
        componentString.replaceAll('[', '').replaceAll(']', '').trim();
    return componentString.split(',').map((e) => e.trim()).toList();
  }

  void printPackageData(PackageCartItem packageItem) {
    print("\n🛒 PACKAGE DETAILS");
    print("📦 Package ID: ${packageItem.packageId}");
    print("🏪 Store: ${packageItem.storeName}");
    print("💰 Package Price: ₪${packageItem.packagePrice}");
    print("🔢 Quantity: ${packageItem.quantity}");

    print("\n📌 PRODUCTS IN PACKAGE:");
    for (int i = 0; i < packageItem.productNames.length; i++) {
      String productName = packageItem.productNames[i];
      Component? component = packageItem.productComponents[productName];
      print("\n🔹 Product ${i + 1}: $productName");
      print("   Components:");
      if (component == null) {
        print("   ❌ No Components");
      } else {
        print(
            "   - ${component.name} | Price: ₪${component.price} | Qty: ${component.qty}");
      }
    }

    print("\n🥤 SELECTED DRINKS:");
    for (int i = 0; i < packageItem.selected_drinks_names.length; i++) {
      print(
          "   - ${packageItem.selected_drinks_names[i]} | Price: ₪${packageItem.selected_drinks_prices[i]} | Qty: ${packageItem.selected_drinks_qty[i]}");
    }

    print("\n=====================================\n");
  }
}
