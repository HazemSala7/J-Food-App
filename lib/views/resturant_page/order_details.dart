import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/models/order.dart';
import 'package:flutter/material.dart';

class OrderDetails extends StatefulWidget {
  final Order order;

  const OrderDetails({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  @override
  Widget build(BuildContext context) {
    print(widget.order.items.last.componentIdsQty);
    return Container(
      color: mainColor,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: mainColor,
            iconTheme: IconThemeData(color: Colors.white),
            title:
                Text('تفاصيل الطلبية', style: TextStyle(color: Colors.white)),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الاسم: ${widget.order.customerName}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('العنوان: ${widget.order.address}',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('رقم الهاتف: ${widget.order.mobile}',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('المجموع الكلي: ${widget.order.total}',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    'طريقة الاستلام: ${widget.order.checkoutType == "pickup" ? "استلام من المطعم" : "التوصيل للبيت"}',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Visibility(
                    visible: widget.order.notes != null,
                    child: SizedBox(height: 10)),
                Visibility(
                  visible: widget.order.notes != null,
                  child: Text('*ملاحظات: ${widget.order.notes}',
                      style: TextStyle(
                          color: mainColor,
                          fontSize: 19,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 20),
                Divider(
                  thickness: 3,
                ),
                Text(
                  'الطلب:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.order.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.order.items[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4.0,
                              spreadRadius: 1.0,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.product.name}',
                              style: TextStyle(
                                color: mainColor,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${item.product.description}',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              item.componentsAsString.isEmpty
                                  ? "بدون مكونات"
                                  : 'المكونات:',
                              style: TextStyle(fontSize: 14),
                            ),
                            Visibility(
                                visible: item.componentsAsString.isNotEmpty,
                                child: SizedBox(height: 4)),
                            Visibility(
                              visible: item.componentsAsString.isNotEmpty,
                              child: Text(
                                '${item.componentsAsString}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              item.drinksAsString.isEmpty
                                  ? "بدون مشروبات"
                                  : 'المشروبات:',
                              style: TextStyle(fontSize: 14),
                            ),
                            Visibility(
                                visible: item.drinksAsString.isNotEmpty,
                                child: SizedBox(height: 4)),
                            Visibility(
                              visible: item.drinksAsString.isNotEmpty,
                              child: Text(
                                '${item.drinksAsString}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'الكمية: ${item.qty}',
                              style: TextStyle(fontSize: 18, color: mainColor),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'السعر: ${item.price}',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'المجموع: ${double.parse(item.qty.trim()) * double.parse(item.price.trim()) + item.totalComponentsPrice + item.totalDrinksPrice}',
                              style: TextStyle(
                                fontSize: 15,
                                color: mainColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
