import 'package:j_food_updated/LocalDB/Provider/CartProvider.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/resources/font_manager.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:provider/provider.dart';
import '../../../LocalDB/Models/CartItem.dart';

class CartProductMethod extends StatefulWidget {
  final CartItem item;
  final Function removeProduct;
  final Function editProduct;

  CartProductMethod({
    required this.item,
    required this.removeProduct,
    required this.editProduct,
  });

  @override
  _CartProductMethodState createState() => _CartProductMethodState();
}

class _CartProductMethodState extends State<CartProductMethod> {
  double _dragOffset = 0.0;
  final double _maxOffset = 110.0;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: true);

    Future<void> deleteItem() async {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: Text("هل تريد بالتأكيد حذف هذه الوجبة من الطلبيه؟"),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context); // close dialog
                      widget.removeProduct(); // remove item
                      setState(() {
                        _dragOffset = 0;
                      });
                      Fluttertoast.showToast(msg: "تم حذف الوجبة بنجاح");
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
        },
      );
    }

    return Stack(
      children: [
        // Container(
        //   margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        //   decoration: BoxDecoration(
        //     color: Colors.transparent,
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   child: Column(
        //     children: [
        //       SizedBox(
        //         height: 30,
        //       ),
        //       Row(
        //         mainAxisAlignment: MainAxisAlignment.start,
        //         crossAxisAlignment: CrossAxisAlignment.center,
        //         children: [
        //           SizedBox(
        //             width: 5,
        //           ),
        //           InkWell(
        //             onTap: () {
        //               widget.editProduct();
        //             },
        //             child: Container(
        //                 width: 45,
        //                 height: 45,
        //                 decoration: BoxDecoration(
        //                   color: Color(0xff8AC43E),
        //                   borderRadius: BorderRadius.all(Radius.circular(8)),
        //                 ),
        //                 child: Image.asset("assets/images/edit-button.png")),
        //           ),
        //           SizedBox(
        //             width: 5,
        //           ),
        //           InkWell(
        //             onTap: () {
        //               deleteItem();
        //             },
        //             child: Container(
        //                 width: 45,
        //                 height: 45,
        //                 decoration: BoxDecoration(
        //                   color: Color(0xffA51E22),
        //                   borderRadius: BorderRadius.all(Radius.circular(8)),
        //                 ),
        //                 child: Image.asset("assets/images/delete-button.png")),
        //           ),
        //         ],
        //       ),
        //     ],
        //   ),
        // ),

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
                  child: Column(
                    children: [
                      Row(
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
                                imageUrl: widget.item.image,
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
                                  widget.item.name.length > 20
                                      ? "${widget.item.name.substring(0, 20)}..."
                                      : widget.item.name,
                                  style: TextStyle(
                                    color: Color(0xff5E5E5E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                Visibility(
                                  visible: widget.item.selected_components_names
                                      .isNotEmpty,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Text(
                                            "المكونات : ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: mainColor,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              widget.item
                                                  .selected_components_names
                                                  .join(", "),
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: FontSize.s12,
                                                color:
                                                    textColor.withOpacity(0.4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: widget
                                      .item.selected_drinks_names.isNotEmpty,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "المشروبات: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: mainColor,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              widget.item.selected_drinks_names
                                                  .join(", "),
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: FontSize.s12,
                                                color:
                                                    textColor.withOpacity(0.4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: widget.item.note != null &&
                                      widget.item.note!.isNotEmpty,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            "ملاحظات: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: mainColor,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              widget.item.note ?? "",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: FontSize.s12,
                                                color:
                                                    textColor.withOpacity(0.4),
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
                                    border:
                                        Border.all(color: Color(0xffEAEAEA)),
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
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Color(0xffF5F5F5),
                            ),
                            width: 30,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    cartProvider.increaseQuantity(widget.item);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: mainColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "+",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "${widget.item.quantity}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 10),
                                InkWell(
                                  onTap: () {
                                    if (widget.item.quantity == 1)
                                      deleteItem();
                                    else
                                      cartProvider
                                          .decreaseQuantity(widget.item);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: mainColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "-",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
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
                              widget.editProduct();
                            },
                            child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Color(0xff8AC43E),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                child: Image.asset(
                                    "assets/images/edit-button.png")),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          InkWell(
                            onTap: () {
                              deleteItem();
                            },
                            child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Color(0xffA51E22),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
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
                                widget.item.image,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              "${widget.item.name}",
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
                          "₪${widget.item.price}",
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
                          visible: widget.item.size != "",
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
                                "${widget.item.size}",
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
                              "₪${widget.item.price} ${widget.item.quantity}x",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7)),
                            ),
                            Text(
                              "₪${double.parse(widget.item.price) * widget.item.quantity}",
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
                  visible: (widget.item.note != null &&
                      widget.item.note!.isNotEmpty),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                            color: Color(0xffF8F8F8),
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ملاحظات",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor),
                              ),
                              SizedBox(height: 5),
                              Text(
                                widget.item.note ?? "",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: textColor.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Visibility(
                  visible: widget.item.selected_components_names.isNotEmpty ||
                      widget.item.selected_drinks_names.isNotEmpty,
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
                          if (widget
                              .item.selected_components_names.isNotEmpty) ...[
                            Text(
                              "المكونات",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor),
                            ),
                            Column(
                              children: List.generate(
                                widget.item.selected_components_names.length,
                                (index) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        widget.item
                                            .selected_components_names[index],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: textColor),
                                      ),
                                      Text(
                                        "₪${widget.item.selected_components_prices[index]} ${widget.item.selected_components_qty[index]}x",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color:
                                                Colors.black.withOpacity(0.7)),
                                      ),
                                      Text(
                                        "₪${double.parse(widget.item.selected_components_prices[index]) * double.parse(widget.item.selected_components_qty[index])}",
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
                          if (widget.item.selected_drinks_names.isNotEmpty) ...[
                            Text(
                              "المشروبات",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor),
                            ),
                            Column(
                              children: List.generate(
                                widget.item.selected_drinks_names.length,
                                (index) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        widget
                                            .item.selected_drinks_names[index],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: textColor),
                                      ),
                                      Text(
                                        "₪${widget.item.selected_drinks_prices[index]} ${widget.item.selected_drinks_qty[index]}x",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color:
                                                Colors.black.withOpacity(0.7)),
                                      ),
                                      Text(
                                        "₪${double.parse(widget.item.selected_drinks_prices[index]) * double.parse(widget.item.selected_drinks_qty[index])}",
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

  double _calculateTotalPrice() {
    // Calculate the total for components with their quantities
    double componentTotal = 0.0;
    for (int i = 0; i < widget.item.selected_components_prices.length; i++) {
      double price = double.parse(widget.item.selected_components_prices[i]);
      int quantity = int.parse(widget.item.selected_components_qty[i]);
      componentTotal += price * quantity;
    }

    // Calculate the total for drinks with their quantities
    double drinkTotal = 0.0;
    for (int i = 0; i < widget.item.selected_drinks_prices.length; i++) {
      double price = double.parse(widget.item.selected_drinks_prices[i]);
      int quantity = int.parse(widget.item.selected_drinks_qty[i]);
      drinkTotal += price * quantity;
    }

    return componentTotal + drinkTotal;
  }
}
