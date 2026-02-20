import 'package:j_food_updated/LocalDB/Models/CartItem.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:flutter/material.dart';

class EditOrderWidget extends StatefulWidget {
  final CartItem item;
  final Function(CartItem) onUpdate;

  EditOrderWidget({required this.item, required this.onUpdate});

  @override
  _EditOrderWidgetState createState() => _EditOrderWidgetState();
}

class _EditOrderWidgetState extends State<EditOrderWidget> {
  late Map<int, int> componentQty;
  late Map<int, int> drinkQty;
  late TextEditingController notesController;
  bool showComponents = true;

  @override
  void initState() {
    super.initState();
    _initializeQuantities();
    notesController = TextEditingController(text: widget.item.note ?? "");
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  void _initializeQuantities() {
    componentQty = {
      for (int i = 0;
          i < widget.item.components_names.length;
          i++) // Use the full list of components
        i: widget.item.selected_components_names
                .contains(widget.item.components_names[i])
            ? int.parse(widget.item.selected_components_qty[widget
                .item.selected_components_names
                .indexOf(widget.item.components_names[i])])
            : 0,
    };

    drinkQty = {
      for (int i = 0; i < widget.item.drinks_names.length; i++)
        i: widget.item.selected_drinks_names
                .contains(widget.item.drinks_names[i])
            ? int.parse(widget.item.selected_drinks_qty[widget
                .item.selected_drinks_names
                .indexOf(widget.item.drinks_names[i])])
            : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Visibility(
                    visible: widget.item.components_names.isNotEmpty,
                    child: _buildTabButton("المكونات", showComponents, true)),
                const SizedBox(width: 20),
                Visibility(
                    visible: widget.item.drinks_names.isNotEmpty,
                    child:
                        _buildTabButton("المشروبات", !showComponents, false)),
              ],
            ),
            // const SizedBox(height: 10),
            Visibility(
              visible: showComponents
                  ? widget.item.components_names.isNotEmpty
                  : widget.item.drinks_names.isNotEmpty,
              child: showComponents
                  ? _buildHorizontalList(
                      "المكونات المختارة:",
                      widget.item.components_names,
                      widget.item.components_prices,
                      widget.item.components_images,
                      componentQty,
                    )
                  : _buildHorizontalList(
                      "المشروبات المختارة:",
                      widget.item.drinks_names,
                      widget.item.drinks_prices,
                      widget.item.drinks_images,
                      drinkQty,
                    ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ملاحظات (اختياري)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: "أضف ملاحظاتك حول هذه الوجبة...",
                      hintStyle: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: mainColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.0),
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
                        "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _saveUpdates();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: mainColor,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: const Text(
                          "حفظ التعديل",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildTabButton(String label, bool isActive, bool showCompTab) {
    return GestureDetector(
      onTap: () {
        setState(() {
          showComponents = showCompTab;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? mainColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.black.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(
    String title,
    List<String> items,
    List<String> prices,
    List<String> image,
    Map<int, int> quantities,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(items.length, (index) {
              String itemName = items[index];
              String itemPrice = prices[index];
              String itemImage = image[index];
              bool isSelected = quantities[index]! > 0;

              return _buildSelectableItem(
                itemName,
                itemImage,
                itemPrice,
                isSelected,
                (selected) {
                  setState(() {
                    if (selected) {
                      if (quantities[index] == 0) {
                        quantities[index] = widget.item.quantity;
                      }
                    } else {
                      quantities[index] = 0;
                    }
                  });
                },
                (isAdding) {
                  setState(() {
                    if (isAdding) {
                      quantities[index] = (quantities[index]! + 1);
                    } else if (quantities[index]! > 1) {
                      quantities[index] = (quantities[index]! - 1);
                    }
                  });
                },
                quantities[index]!,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableItem(
    String name,
    String image,
    String price,
    bool isSelected,
    Function(bool) onSelect,
    Function(bool) onQuantityChange,
    int quantity,
  ) {
    return GestureDetector(
      onTap: () => onSelect(!isSelected),
      child: Card(
        elevation: 5,
        color: isSelected ? mainColor : Colors.white,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? mainColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          width: 100,
          // height: isSelected ? 110 : 90,
          // padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image,
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      "assets/images/logo2.png",
                      width: 50,
                      height: 50,
                    );
                  },
                ),
              ),
              SizedBox(
                height: 3,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
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
                      "₪$price",
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
                          onQuantityChange(true);
                          setState(() {});
                        },
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          onQuantityChange(false);
                          setState(() {});
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

  void _saveUpdates() {
    widget.item.selected_components_names.clear();
    widget.item.selected_components_prices.clear();
    widget.item.selected_components_qty = [];
    componentQty.forEach((index, qty) {
      if (qty > 0) {
        widget.item.selected_components_names
            .add(widget.item.components_names[index]);
        widget.item.selected_components_prices
            .add(widget.item.components_prices[index]);
        widget.item.selected_components_qty.add(qty.toString());
      }
    });

    widget.item.selected_drinks_names.clear();
    widget.item.selected_drinks_prices.clear();
    widget.item.selected_drinks_qty = [];
    drinkQty.forEach((index, qty) {
      if (qty > 0) {
        widget.item.selected_drinks_names.add(widget.item.drinks_names[index]);
        widget.item.selected_drinks_prices
            .add(widget.item.drinks_prices[index]);
        widget.item.selected_drinks_qty.add(qty.toString());
      }
    });

    // Save notes
    widget.item.note = notesController.text.trim().isEmpty
        ? null
        : notesController.text.trim();

    double totalPrice = widget.item.quantity * double.parse(widget.item.price);

    for (int i = 0; i < widget.item.selected_components_names.length; i++) {
      double price = double.parse(widget.item.selected_components_prices[i]);
      int qty = int.parse(widget.item.selected_components_qty[i]);
      totalPrice += price * qty;
    }

    for (int i = 0; i < widget.item.selected_drinks_names.length; i++) {
      double price = double.parse(widget.item.selected_drinks_prices[i]);
      int qty = int.parse(widget.item.selected_drinks_qty[i]);
      totalPrice += price * qty;
    }

    widget.item.total = totalPrice.toString();
    widget.onUpdate(widget.item);
  }
}
