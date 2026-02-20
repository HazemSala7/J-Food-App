import 'dart:async';

import 'package:j_food_updated/views/resturant_page/add_box.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/views/resturant_page/add_food.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductsPage extends StatefulWidget {
  const ProductsPage(
      {super.key,
      required this.storeId,
      required this.categoryId,
      required this.status,
      required this.restaurantName,
      required this.restaurantImage,
      required this.restaurantAddress,
      required this.deliveryPrice,
      required this.userId,
      required this.scrollController,
      required this.storeCloseTime,
      required this.storeOpenTime});
  final String storeId;
  final String categoryId;
  final String userId;
  final String status;
  final String restaurantName;
  final String restaurantImage;
  final String restaurantAddress;
  final String deliveryPrice;
  final String storeCloseTime;
  final String storeOpenTime;
  final ScrollController scrollController;
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool loading = true;
  List products = [];
  List packages = [];
  Map<String, bool> productStatuses = {};
  Map<String, bool> packageStatuses = {};
  Map<int, double> _dragOffsets = {};
  Map<int, double> _packageDragOffsets = {};
  final double _maxOffset = 120.0;
  int selectedTabIndex = 0;
  TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool isLoadingMore = false;
  int currentPage = 1;
  int lastPage = 1;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController.hasClients) {
      widget.scrollController.addListener(_scrollListener);
    }
    _fetchProducts();
    _fetchPackages();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 300) {
      if (!isLoadingMore && currentPage < lastPage) {
        setState(() {
          isLoadingMore = true;
        });
        _fetchProducts(page: currentPage + 1);
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _fetchProducts(name: _searchController.text.trim());
    });
  }

  Future<void> _fetchProducts({String name = '', int page = 1}) async {
    try {
      final uri = Uri.parse(
        "https://hrsps.com/login/api/product_talabat_by_restaurant_id/${widget.storeId}?page=$page&name=$name",
      );

      var response = await http.get(uri);
      if (response.statusCode == 200) {
        var responseData = utf8.decode(response.bodyBytes);
        var res = json.decode(responseData);

        List<dynamic> newProducts = res['products']['data'];

        setState(() {
          if (page == 1) {
            products = newProducts;
          } else {
            products.addAll(newProducts);
          }

          for (var product in newProducts) {
            productStatuses[product['id'].toString()] =
                product['active'] == "true";
          }

          currentPage = res['products']['current_page'];
          lastPage = res['products']['last_page'];
          loading = false;

          isLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products. Please try again later.'),
        ),
      );
    }
  }

  Future<void> _fetchPackages() async {
    try {
      var response = await http.get(Uri.parse(
          "https://hrsps.com/login/api/restaurant-packages-by-id/${widget.storeId}"));
      if (response.statusCode == 200) {
        var responseData = utf8.decode(response.bodyBytes);
        var res = json.decode(responseData);
        setState(() {
          packages = res['data'];
          // for (var package in packages) {
          //   packageStatuses[package['id'].toString()] =
          //       package['active'] == "true";
          // }
          // loading = false;
        });
      } else {
        throw Exception('Failed to load packages');
      }
    } catch (e) {
      print('Error fetching packages: $e');
      // setState(() {
      //   loading = false;
      // });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading packages. Please try again later.')));
    }
  }

  // Delete a product
  Future<void> _deleteProduct(String productId, int index) async {
    try {
      var response = await http.delete(Uri.parse(
          "https://hrsps.com/login/api/products_talabat/${productId}"));
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'تم حذف المنتج');
        setState(() {
          _dragOffsets[index] = 0.0;
          products.removeAt(index);
          productStatuses.remove(productId);
        });
      } else {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting product. Please try again later.')));
    }
  }

  Future<void> _deletePackage(String pakageId, int index) async {
    try {
      var response = await http.delete(Uri.parse(
          "https://hrsps.com/login/api/restaurant-packages/${pakageId}"));
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'تم حذف البوكس بنجاح');
        setState(() {
          _packageDragOffsets[index] = 0.0;
          packages.removeAt(index);
          // packageStatuses.remove(pakageId);
        });
      } else {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting product. Please try again later.')));
    }
  }

  // Update product status
  Future<void> _updateProductStatus(String productId, bool status) async {
    try {
      var response = await http.post(
        Uri.parse('https://hrsps.com/login/api/update_product_status'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'product_id': productId,
          'active': status.toString(),
        }),
      );
      if (response.statusCode == 200) {
        print('Status updated successfully');
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      print('Error updating product status: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error updating product status. Please try again later.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        loading
            ? Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                    ),
                    CircularProgressIndicator(),
                  ],
                ))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedTabIndex = 0;
                                    });
                                  },
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: selectedTabIndex == 0
                                              ? mainColor
                                              : Color(0xffB1B1B1),
                                          width:
                                              selectedTabIndex == 0 ? 2 : 1.0,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "الوجبات",
                                        style: TextStyle(
                                            color: selectedTabIndex == 0
                                                ? mainColor
                                                : Color(0xffB1B1B1),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedTabIndex = 1;
                                    });
                                  },
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: selectedTabIndex == 1
                                              ? mainColor
                                              : Color(0xffB1B1B1),
                                          width: selectedTabIndex == 1 ? 2 : 1,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "البكجات",
                                        style: TextStyle(
                                            color: selectedTabIndex == 0
                                                ? mainColor
                                                : Color(0xffB1B1B1),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return Container(
                              height: 30,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12)),
                              child: TextFormField(
                                controller: _searchController,
                                obscureText: false,
                                decoration: InputDecoration(
                                  hintStyle: TextStyle(
                                      fontSize: 12, color: Color(0xffB1B1B1)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: mainColor, width: 1.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        width: 1.0,
                                        color: Color(0xffD6D3D3),
                                      )),
                                  hintText: "ابحث عن المنتج",
                                ),
                              ),
                            );
                          }),
                        )
                      ],
                    ),
                  ),
                  IndexedStack(
                    index: selectedTabIndex,
                    children: [
                      _buildProductList(),
                      _buildPackageList(),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  if (isLoadingMore) CircularProgressIndicator()
                ],
              ),
        // SizedBox(
        //   height: 40,
        // )
      ],
    );
  }

  // Build product list
  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
      itemCount: products.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildProductItem(index);
      },
    );
  }

  Widget _buildPackageList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
      itemCount: packages.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildpPackageItem(index);
      },
    );
  }

  // Build each product item
  Widget _buildProductItem(int index) {
    String productId = products[index]['id'].toString();
    String imageUrl = products[index]['images'].isNotEmpty
        ? products[index]['images'][0]['url']
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Stack(children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
                    onTap: () => _editProduct(index),
                    child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Color(0xff8AC43E),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Image.asset("assets/images/edit-button.png")),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  InkWell(
                    onTap: () => _confirmDelete(index),
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
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffsets[index] =
                  (_dragOffsets[index] ?? 0.0) + details.delta.dx;
              _dragOffsets[index] =
                  _dragOffsets[index]!.clamp(-_maxOffset, 0.0);
            });
          },
          onHorizontalDragEnd: (details) {
            setState(() {
              if ((_dragOffsets[index]?.abs() ?? 0) < _maxOffset / 2) {
                _dragOffsets[index] = 0.0;
              } else {
                _dragOffsets[index] = -_maxOffset;
              }
            });
          },
          child: Transform.translate(
            offset: Offset(_dragOffsets[index] ?? 0.0, 0),
            child: InkWell(
              child: Card(
                elevation: 3,
                color: Colors.white,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FancyShimmerImage(
                          imageUrl: imageUrl,
                          width: 70,
                          height: 70,
                          boxFit: BoxFit.cover,
                          errorWidget: Image.asset(
                            "assets/images/logo2.png",
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${products[index]['name']}",
                            style: TextStyle(
                                color: Color(0xff5E5E5E),
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "${products[index]['description']}",
                            style: TextStyle(
                                color: Colors.black.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("₪${products[index]['price']}",
                                    style: TextStyle(
                                        color: Color(0xff5E5E5E),
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                                Stack(alignment: Alignment.center, children: [
                                  FlutterSwitch(
                                    width: 45.0,
                                    height: 20.0,
                                    toggleSize: 20.0,
                                    borderRadius: 15.0,
                                    activeColor: mainColor,
                                    inactiveColor: Color(0xffB1B1B1),
                                    value: productStatuses[productId] ?? true,
                                    onToggle: (val) {
                                      setState(() {
                                        productStatuses[productId] = val;
                                      });
                                      _updateProductStatus(productId, val);
                                    },
                                  ),
                                  Positioned(
                                    left: productStatuses[productId] ?? true
                                        ? 5
                                        : 30,
                                    top: productStatuses[productId] ?? true
                                        ? 2
                                        : 5,
                                    child: productStatuses[productId] ?? true
                                        ? Image.asset(
                                            "assets/images/check.png",
                                            width: 15,
                                            height: 15,
                                          )
                                        : Text(
                                            "X",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                          ),
                                  ),
                                ]),
                              ],
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
      ]),
    );
  }

  Widget _buildpPackageItem(int index) {
    String productId = packages[index]['id'].toString();
    String imageUrl = packages[index]['package_image'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Stack(children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
                    onTap: () => _editPackage(index),
                    child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Color(0xff8AC43E),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Image.asset("assets/images/edit-button.png")),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  InkWell(
                    onTap: () => _confirmDeletePackage(index),
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
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _packageDragOffsets[index] =
                  (_packageDragOffsets[index] ?? 0.0) + details.delta.dx;
              _packageDragOffsets[index] =
                  _packageDragOffsets[index]!.clamp(-_maxOffset, 0.0);
            });
          },
          onHorizontalDragEnd: (details) {
            setState(() {
              if ((_packageDragOffsets[index]?.abs() ?? 0) < _maxOffset / 2) {
                _packageDragOffsets[index] = 0.0;
              } else {
                _packageDragOffsets[index] = -_maxOffset;
              }
            });
          },
          child: Transform.translate(
            offset: Offset(_packageDragOffsets[index] ?? 0.0, 0),
            child: InkWell(
              child: Card(
                elevation: 3,
                color: Colors.white,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FancyShimmerImage(
                          imageUrl: imageUrl,
                          width: 70,
                          height: 70,
                          boxFit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${packages[index]['package_name']}",
                            style: TextStyle(
                                color: Color(0xff5E5E5E),
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "${packages[index]['package_description']}",
                            style: TextStyle(
                                color: Colors.black.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("₪${packages[index]['package_price']}",
                                    style: TextStyle(
                                        color: Color(0xff5E5E5E),
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                                // Stack(alignment: Alignment.center, children: [
                                //   FlutterSwitch(
                                //     width: 45.0,
                                //     height: 20.0,
                                //     toggleSize: 20.0,
                                //     borderRadius: 15.0,
                                //     activeColor: mainColor,
                                //     inactiveColor: Color(0xffB1B1B1),
                                //     value: productStatuses[productId] ?? true,
                                //     onToggle: (val) {
                                //       setState(() {
                                //         productStatuses[productId] = val;
                                //       });
                                //       _updateProductStatus(productId, val);
                                //     },
                                //   ),
                                //   Positioned(
                                //     left: productStatuses[productId] ?? true
                                //         ? 5
                                //         : 30,
                                //     top: productStatuses[productId] ?? true
                                //         ? 2
                                //         : 5,
                                //     child: productStatuses[productId] ?? true
                                //         ? Image.asset(
                                //             "assets/images/check.png",
                                //             width: 15,
                                //             height: 15,
                                //           )
                                //         : Text(
                                //             "X",
                                //             style: TextStyle(
                                //                 color: Colors.white,
                                //                 fontWeight: FontWeight.bold,
                                //                 fontSize: 12),
                                //           ),
                                //   ),
                                // ]),
                              ],
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
      ]),
    );
  }

  // Navigate to edit product page
  void _editProduct(int index) async {
    bool? result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AddFood(
        isEditing: true,
        productId: products[index]['id'].toString(),
        categoryId: widget.categoryId,
        userId: widget.userId,
        storeCloseTime: widget.storeCloseTime,
        storeOpenTime: widget.storeOpenTime,
        restaurantId: widget.storeId,
        deliveryPrice: widget.deliveryPrice,
        restaurantAddress: widget.restaurantAddress,
        restaurantImage: widget.restaurantImage,
        restaurantName: widget.restaurantName,
        status: widget.status,
      ),
    ));
    if (result == true) {
      _fetchProducts();
    }
  }

  void _editPackage(int index) async {
    bool? result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AddBox(
        isEditing: true,
        productId: packages[index]['id'].toString(),
        categoryId: widget.categoryId,
        restaurantId: widget.storeId,
        userId: widget.userId,
        deliveryPrice: widget.deliveryPrice,
        storeCloseTime: widget.storeCloseTime,
        storeOpenTime: widget.storeOpenTime,
        restaurantAddress: widget.restaurantAddress,
        restaurantImage: widget.restaurantImage,
        restaurantName: widget.restaurantName,
        status: widget.status,
      ),
    ));
    if (result == true) {
      _fetchProducts();
    }
  }

  // Confirm deletion of a product
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Text("هل تريد بالتأكيد حذف هذه الوجبة من المطعم؟",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProduct(products[index]['id'].toString(), index);

                    // Fluttertoast.showToast(msg: "تم حذف الوجبة بنجاح");
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

  void _confirmDeletePackage(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Text("هل تريد بالتأكيد حذف هذا البوكس من المطعم؟",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _deletePackage(packages[index]['id'].toString(), index);

                    // Fluttertoast.showToast(msg: "تم حذف الوجبة بنجاح");
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
}
