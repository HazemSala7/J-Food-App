import 'dart:io';
import 'package:j_food_updated/component/check_box/check_box.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/views/resturant_page/restaurant_page.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class AddBox extends StatefulWidget {
  final bool isEditing;
  final String? productId;
  final String categoryId;
  final String restaurantId;
  final String status;
  final String restaurantName;
  final String userId;
  final String restaurantImage;
  final String restaurantAddress;
  final String storeCloseTime;
  final String storeOpenTime;
  final String deliveryPrice;
  const AddBox(
      {super.key,
      required this.isEditing,
      this.productId,
      required this.categoryId,
      required this.restaurantId,
      required this.status,
      required this.restaurantName,
      required this.restaurantImage,
      required this.restaurantAddress,
      required this.deliveryPrice,
      required this.userId,
      required this.storeCloseTime,
      required this.storeOpenTime});

  @override
  State<AddBox> createState() => _AddBoxState();
}

class _AddBoxState extends State<AddBox> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _drinkQuantityController;
  late TextEditingController _descriptionController;
  List<XFile> _images = [];
  List<Map<String, TextEditingController>> _components = [];
  List<Map<String, TextEditingController>> _drinks = [];
  bool _loading = false;
  bool addLoading = false;
  bool photoField = false;
  bool priceField = false;
  bool quantityField = false;
  bool drinkQuantityField = false;
  bool desField = false;
  bool nameField = false;
  bool selectedMealTypeField = false;
  bool selectedMealSizeField = false;
  bool subCategoriesField = false;
  String networkImages = "";
  List<Map<String, dynamic>> subCategories = [];
  int? selectedSubCategoryId;
  late bool changePhoto;
  bool isAddingSize = false;
  bool isAddingSizeField = false;
  List<Map<String, TextEditingController>> sizes = [
    {
      "name": TextEditingController(),
      "price": TextEditingController(),
    }
  ];
  final List<String> mealTypes = ['فطور', 'غذاء', 'عشاء', 'وجبة خفيفة'];
  final List<String> mealSizes = ['فردي', 'عائلي'];
  Map<String, bool> additionalOptions = {
    'طعام صحي': false,
    'طعام نباتي': false,
  };
  String? selectedMealType;
  String? selectedMealSize;
  TextEditingController _discountController = TextEditingController();
  TextEditingController _priceAfterDiscountController = TextEditingController();
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  bool discountField = false;
  bool priceAfterDiscountField = false;

  List<ProductsPair> availableProducts = [];
  List<ProductsPair> availableDrinks = [];
  Map<String, bool> componentCheckboxStates = {};
  Map<String, bool> drinkCheckboxStates = {};
  List products = [];
  Map<String, bool> productStatuses = {};
  bool loading = true;

  List<ProductsPair> selectedProducts = [];
  List<ProductsPair> selectedDrinks = [];
  Map<int, TextEditingController> priceControllers = {};
  Map<int, TextEditingController> componentCountControllers = {};
  Map<int, TextEditingController> drinkPriceControllers = {};

  @override
  void initState() {
    super.initState();
    print(widget.productId);
    _loadSubCategories();

    _fetchProducts();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    _drinkQuantityController = TextEditingController();
    _descriptionController = TextEditingController();
    widget.isEditing ? changePhoto = false : changePhoto = true;
  }

  Future<void> _fetchProducts() async {
    if (widget.isEditing && widget.productId != null) {
      setState(() {
        _loading = true;
      });
    }
    await _fetchDrinks();
    try {
      var response = await http.get(Uri.parse(
          "https://hrsps.com/login/api/product_talabat_by_restaurant_id/${widget.restaurantId}"));
      if (response.statusCode == 200) {
        var responseData = utf8.decode(response.bodyBytes);
        var res = json.decode(responseData);
        setState(() {
          products = res['products'];
          for (var product in products) {
            productStatuses[product['id'].toString()] =
                product['active'] == "true";
          }
          availableProducts = products.map<ProductsPair>((product) {
            int id = product['id'] ?? 0;
            String name = product['name'] ?? 'Unnamed Product';
            String imageUrl =
                (product['images'] != null && product['images'].isNotEmpty)
                    ? product['images'][0]['url']
                    : 'assets/images/placeholder.png';

            return ProductsPair(id, name, imageUrl);
          }).toList();
          if (widget.isEditing && widget.productId != null) {
            _fetchProductData();
          }
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading products. Please try again later.')));
    }
  }

  Future<void> _fetchDrinks() async {
    try {
      var response =
          await http.get(Uri.parse("https://hrsps.com/login/api/drinks"));
      if (response.statusCode == 200) {
        var responseData = utf8.decode(response.bodyBytes);
        var res = json.decode(responseData);

        setState(() {
          availableDrinks = res.map<ProductsPair>((drink) {
            int id = drink['id'] ?? 0;
            String name = drink['name'] ?? 'Unnamed Drink';
            String imageUrl = drink['image'] ?? 'assets/images/logo2.png';
            return ProductsPair(id, name, imageUrl);
          }).toList();
        });
      } else {
        throw Exception('Failed to load drinks');
      }
    } catch (e) {
      print('Error fetching drinks: $e');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading drinks. Please try again later.')));
    }
  }

  Future<void> _loadSubCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? subCategoriesJson = prefs.getString('sub_categories');
    if (subCategoriesJson != null) {
      List<dynamic> loadedSubCategories = jsonDecode(subCategoriesJson);
      setState(() {
        subCategories = loadedSubCategories
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    }
  }

  Future<void> _fetchProductData() async {
    setState(() {
      _loading = true;
    });
    try {
      var response = await http.get(
        Uri.parse(
            "https://hrsps.com/login/api/restaurant-packages/${widget.productId}"),
      );
      if (response.statusCode == 200) {
        var responseData = utf8.decode(response.bodyBytes);
        var res = json.decode(responseData);
        var data = res["data"];
        setState(() {
          _nameController.text = data['package_name'];
          _priceController.text = data['package_price'];
          _descriptionController.text = data['package_description'];
          // int? fetchedSubCategoryId = data['sub_category_id'];
          selectedMealSize = data['size_type'] == "single" ? "فردي" : "عائلي";
          additionalOptions['طعام صحي'] =
              data['is_healthy'] == "true" ? true : false;
          additionalOptions['طعام نباتي'] =
              data['is_vegetarian'] == "true" ? true : false;
          _discountController.text = data['discount_percentage'] != null
              ? data['discount_percentage'].toString()
              : "0";

          selectedMealType = data['time_type'] == "lunch"
              ? "غذاء"
              : data['time_type'] == "dinner"
                  ? "عشاء"
                  : data['time_type'] == "breakfast"
                      ? "فطور"
                      : "وجبة خفيفة";

          networkImages = data['package_image'];
          _quantityController.text = data['products_qty'];
          _drinkQuantityController.text = data['drinks_qty'];

          String packageProductIds = "";
          String packageDrinkIds = "";

          if (data['package_products_ids'] != null) {
            packageProductIds = data['package_products_ids'];
          }

          if (data['package_drinks_ids'] != null) {
            packageDrinkIds = data['package_drinks_ids'];
          }
          List<String> productIdList = packageProductIds.split(',');
          List<String> drinkIdList = packageDrinkIds.split(',');

          setState(() {
            // Move matching products to selectedProducts
            for (var productId in productIdList) {
              var matchingProduct = availableProducts.firstWhere(
                (product) => product.id.toString() == productId.trim(),
                orElse: () => ProductsPair(0, "", ""),
              );

              availableProducts.remove(matchingProduct);
              selectedProducts.add(matchingProduct);
            }

            // Move matching drinks to selectedDrinks
            for (var drinkId in drinkIdList) {
              var matchingDrink = availableDrinks.firstWhere(
                (drink) => drink.id.toString() == drinkId.trim(),
                orElse: () => ProductsPair(0, "", ""),
              );

              availableDrinks.remove(matchingDrink);
              selectedDrinks.add(matchingDrink);
            }
          });
        });
      } else {
        throw Exception('Failed to load product data');
      }
    } catch (e) {
      print('Error fetching product data: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خلل في جلب معلومات البوكس'),
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      photoField = false;
    });
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      setState(() {
        _images.clear();
        _images.add(selectedImage);
      });
    }
  }

  Future<File> downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    final documentDirectory = await getTemporaryDirectory();
    final file = File('${documentDirectory.path}/temp_image.jpg');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  Future<void> _submitForm() async {
    setState(() {
      addLoading = true;
    });

    try {
      var uri = widget.isEditing
          ? Uri.parse(
                  'https://hrsps.com/login/api/restaurant-packages/${widget.productId}')
              .replace(queryParameters: {'_method': 'PUT'})
          : Uri.parse('https://hrsps.com/login/api/restaurant-packages');

      var request = http.MultipartRequest('POST', uri);
      var productIds = selectedProducts.map((e) => e.id.toString()).join(',');
      var drinksIds = selectedDrinks.map((e) => e.id.toString()).join(',');
      request.fields['package_name'] = _nameController.text;
      request.fields['package_price'] = _priceController.text;
      request.fields['package_description'] = _descriptionController.text;

      request.fields['restaurant_id'] = widget.restaurantId;
      request.fields['products_qty'] = _quantityController.text;
      request.fields['drinks_qty'] = _drinkQuantityController.text;
      request.fields['sub_category_id'] = selectedSubCategoryId == null
          ? '0'
          : selectedSubCategoryId.toString();

      if (widget.isEditing && !changePhoto) {
        File imageFile = await downloadImage(networkImages);
        request.files.add(
            await http.MultipartFile.fromPath('package_image', imageFile.path));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
            'package_image', _images[0].path));
      }

      request.fields['package_products_ids'] = productIds;
      request.fields['package_drinks_ids'] = drinksIds;

      request.fields['is_vegetarian'] =
          additionalOptions['طعام نباتي'] == true ? 'true' : 'false';
      request.fields['is_healthy'] =
          additionalOptions['طعام صحي'] == true ? 'true' : 'false';
      request.fields['size_type'] =
          selectedMealSize == "عائلي" ? "family" : "single";
      request.fields['time_type'] = selectedMealType == "عشاء"
          ? "dinner"
          : selectedMealType == "غذاء"
              ? "lunch"
              : selectedMealType == "فطور"
                  ? "breakfast"
                  : "snack";
      var response = await request.send();
      print(response.statusCode);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(
            msg: widget.isEditing ? 'تم التحديث' : 'تم الاضافة');

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => RestaurantPage(
                  storeId: widget.restaurantId,
                  categoryId: widget.categoryId,
                  userId: widget.userId,
                  storeCloseTime: widget.storeCloseTime,
                  storeOpenTime: widget.storeOpenTime,
                  status: widget.status,
                  restaurantName: widget.restaurantName,
                  restaurantImage: widget.restaurantImage,
                  restaurantAddress: widget.restaurantAddress,
                  deliveryPrice: widget.deliveryPrice)),
          (route) => false,
        );
      } else {
        var responseBody = await response.stream.bytesToString();
        var errorData = jsonDecode(responseBody);

        if (errorData["error"] == "Invalid argument supplied for foreach()") {
          setState(() {
            photoField = true;
          });
        }
        print('Failed to submit form: ${response.reasonPhrase}');
        print('Response body: $responseBody');
        throw Exception('Failed to submit form');
      }
    } catch (e) {
      print('Error submitting form: $e');
      Fluttertoast.showToast(
          msg: "يرجى التأكد من أن جميع الحقول المطلوبة معبئة وبشكل صحيح");
    } finally {
      setState(() {
        addLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _drinkQuantityController.dispose();
    _descriptionController.dispose();
    for (var component in _components) {
      component['name']?.dispose();
      component['price']?.dispose();
    }
    for (var drink in _drinks) {
      drink['name']?.dispose();
      drink['price']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fourthColor,
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: fourthColor,
            body: _loading
                ? Padding(
                    padding:
                        const EdgeInsets.only(right: 8.0, left: 8, top: 25),
                    child: Container(
                        height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Center(child: CircularProgressIndicator())),
                  )
                : Padding(
                    padding:
                        const EdgeInsets.only(right: 8.0, left: 8, top: 25),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 20, right: 15, left: 15),
                                  child: Text(
                                    widget.isEditing
                                        ? 'تعديل البوكس'
                                        : 'اضافة بوكس جديد ',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: mainColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              nameImageWidget(),
                              SizedBox(
                                height: 10,
                              ),
                              priceSizeWidget(),
                              SizedBox(height: 10),
                              quantityWidget(),
                              SizedBox(height: 10),
                              componentsWidget(),
                              SizedBox(height: 10),
                              drinkQuantityWidget(),
                              SizedBox(height: 10),
                              drinksWidget(),
                              SizedBox(height: 10),
                              // Visibility(
                              //     visible: subCategories.isNotEmpty,
                              //     child: subCategoriesWidget()),
                              // SizedBox(
                              //   height: 10,
                              // ),
                              mealTypeWidget(),
                              SizedBox(height: 10),
                              mealSizeWidget(),
                              SizedBox(height: 10),
                              mealCheckBoxWidget(),
                              SizedBox(
                                height: 30,
                              ),
                              buttonWidget(),
                              SizedBox(
                                height: 100,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget nameImageWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: Color(0xffF8F8F8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "*",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor2),
                        ),
                        SizedBox(
                          width: 2,
                        ),
                        Text(
                          "أسم البوكس",
                          style: TextStyle(
                              fontSize: 12,
                              color: textColor2,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                      return Container(
                        height: 30,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: TextFormField(
                          controller: _nameController,
                          obscureText: false,
                          onTap: () {
                            setState(() {
                              nameField = false;
                            });
                          },
                          decoration: InputDecoration(
                            hintStyle: TextStyle(
                                fontSize: 12, color: Color(0xffB1B1B1)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: mainColor, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 1.0,
                                  color: !nameField
                                      ? Color(0xffD6D3D3)
                                      : Colors.red,
                                )),
                            hintText: "ادخل اسم البوكس",
                          ),
                        ),
                      );
                    }),
                    SizedBox(
                      height: 5,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "*",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor2),
                        ),
                        SizedBox(
                          width: 2,
                        ),
                        Text(
                          "وصف البوكس",
                          style: TextStyle(
                              fontSize: 12,
                              color: textColor2,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                      return Container(
                        // height: 30,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        width: double.infinity,
                        child: TextFormField(
                          controller: _descriptionController,
                          obscureText: false,
                          minLines: 1,
                          maxLines: null,
                          onTap: () {
                            setState(
                              () {
                                desField = false;
                              },
                            );
                          },
                          decoration: InputDecoration(
                            hintStyle: TextStyle(
                                color: Color(0xffB1B1B1), fontSize: 12),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: mainColor, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  width: 1.0,
                                  color: desField
                                      ? Colors.red
                                      : Color(0xffD6D3D3)),
                            ),
                            hintText: "ادخل وصف البوكس",
                          ),
                        ),
                      );
                    })
                  ],
                ),
              ),
              SizedBox(
                width: 5,
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "*",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor2),
                        ),
                        SizedBox(
                          width: 2,
                        ),
                        Text(
                          "اضافة صورة",
                          style: TextStyle(
                              fontSize: 12,
                              color: textColor2,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    DottedBorder(
                      strokeWidth: 1,
                      dashPattern: [6, 3],
                      color: photoField ? Colors.red : Colors.black,
                      borderType: BorderType.RRect,
                      radius: Radius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                          child: widget.isEditing && !changePhoto
                              ? Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    networkImages.isNotEmpty
                                        ? Image.network(
                                            networkImages,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Placeholder(
                                            fallbackHeight: 100,
                                            fallbackWidth: double.infinity,
                                          ),
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            networkImages = "";
                                            changePhoto = true;
                                          });
                                        },
                                        child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                color: fourthColor),
                                            child: Center(
                                                child: Text(
                                              "x",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold),
                                            ))),
                                      ),
                                    ),
                                  ],
                                )
                              : _images.isEmpty
                                  ? InkWell(
                                      onTap: _pickImage,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            "assets/images/add-image.png",
                                            width: 60,
                                            height: 60,
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            "اضافة صورة",
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Stack(clipBehavior: Clip.none, children: [
                                      Image.file(
                                        File(_images[0].path),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _images = [];
                                            });
                                          },
                                          child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100),
                                                  color: fourthColor),
                                              child: Center(
                                                  child: Text(
                                                "x",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ))),
                                        ),
                                      ),
                                    ]),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget priceSizeWidget() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Color(0xffF8F8F8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "*",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor2,
                        ),
                      ),
                      SizedBox(width: 2),
                      Text(
                        "السعر",
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        // flex: 2,
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: TextFormField(
                            controller: _priceController,
                            obscureText: false,
                            onTap: () {
                              setState(() {
                                priceField = false;
                              });
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  _priceAfterDiscountController.text =
                                      (double.parse(_priceController.text) -
                                              ((double.parse(value) / 100) *
                                                  double.parse(
                                                      _priceController.text)))
                                          .toString();
                                });
                              } else {
                                setState(() {
                                  _priceAfterDiscountController.text =
                                      _priceController.text;
                                });
                              }
                            },
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                  color: Color(0xffB1B1B1), fontSize: 12),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 1.0,
                                  color: priceField
                                      ? Colors.red
                                      : Color(0xffD6D3D3),
                                ),
                              ),
                              hintText: "السعر",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget quantityWidget() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Color(0xffF8F8F8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "*",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor2,
                        ),
                      ),
                      SizedBox(width: 2),
                      Text(
                        "كمية المنتجات داخل البوكس",
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        // flex: 2,
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: TextFormField(
                            controller: _quantityController,
                            obscureText: false,
                            onTap: () {
                              setState(() {
                                quantityField = false;
                              });
                            },
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                  color: Color(0xffB1B1B1), fontSize: 12),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 1.0,
                                  color: quantityField
                                      ? Colors.red
                                      : Color(0xffD6D3D3),
                                ),
                              ),
                              hintText: "الكمية",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget drinkQuantityWidget() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Color(0xffF8F8F8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "*",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor2,
                        ),
                      ),
                      SizedBox(width: 2),
                      Text(
                        "كمية المشروبات داخل البوكس",
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: TextFormField(
                            controller: _drinkQuantityController,
                            obscureText: false,
                            onTap: () {
                              setState(() {
                                drinkQuantityField = false;
                              });
                            },
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                  color: Color(0xffB1B1B1), fontSize: 12),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 1.0,
                                  color: drinkQuantityField
                                      ? Colors.red
                                      : Color(0xffD6D3D3),
                                ),
                              ),
                              hintText: "الكمية",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget subCategoriesWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: Color(0xffF8F8F8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "*",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor2),
                  ),
                  SizedBox(width: 2),
                  Text(
                    "التصنيف",
                    style: TextStyle(
                        fontSize: 12,
                        color: textColor2,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(
                height: 5,
              ),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color:
                          subCategoriesField ? Colors.red : Color(0xffD6D3D3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: DropdownButton<int>(
                    value: selectedSubCategoryId,
                    hint: Text(
                      "اختر تصنيف البوكس",
                      style: TextStyle(fontSize: 14, color: Color(0xffB1B1B1)),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 24, color: Color(0xffB1B1B1)),
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Colors.black),
                    underline: Container(),
                    dropdownColor: Colors.white,
                    items:
                        subCategories.map<DropdownMenuItem<int>>((subcategory) {
                      return DropdownMenuItem<int>(
                        value: subcategory['id'],
                        child: Text(subcategory['name']),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedSubCategoryId = newValue;
                        subCategoriesField = false;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget componentsWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xffF8F8F8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "*",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor2),
                  ),
                  SizedBox(width: 2),
                  Text(
                    "اختر منتجات البوكس",
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              CustomDropdown.search(
                hintText: 'بحث',
                searchHintText: 'ابحث عن المنتج الذي تريده',
                items: availableProducts.map((e) => e.text).toList(),
                onChanged: (value) {
                  final selected = availableProducts.firstWhere(
                    (element) => element.text == value,
                  );

                  setState(() {
                    availableProducts.remove(selected);
                    selectedProducts.add(selected);
                  });
                },
              ),
              Column(
                children: selectedProducts.map((product) {
                  return Row(
                    children: [
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedProducts.remove(product);
                            availableProducts.add(product);
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(0xffA51E22),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Image.asset("assets/images/delete-button.png"),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 2,
                        child: Card(
                          color: Colors.white,
                          elevation: 2,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: FancyShimmerImage(
                                          imageUrl: product.image,
                                          width: 30,
                                          height: 30,
                                          boxFit: BoxFit.cover,
                                          errorWidget: Image.asset(
                                            "assets/images/logo2.png",
                                            fit: BoxFit.cover,
                                            width: 30,
                                            height: 30,
                                          ))),
                                  const SizedBox(width: 5),
                                  Text(
                                    product.text,
                                    style: TextStyle(
                                        color: textColor2,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget drinksWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xffF8F8F8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "*",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor2),
                  ),
                  SizedBox(width: 2),
                  Text(
                    "اختر مشروبات البوكس",
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              CustomDropdown.search(
                hintText: 'بحث',
                searchHintText: 'ابحث عن المشروب الذي تريده',
                items: availableDrinks.map((e) => e.text).toList(),
                onChanged: (value) {
                  final selected = availableDrinks.firstWhere(
                    (element) => element.text == value,
                  );

                  setState(() {
                    availableDrinks.remove(selected);
                    selectedDrinks.add(selected);
                  });
                },
              ),
              Column(
                children: selectedDrinks.map((drink) {
                  return Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedDrinks.remove(drink);
                            availableDrinks.add(drink);
                          });
                        },
                        child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Color(0xffA51E22),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                            child:
                                Image.asset("assets/images/delete-button.png")),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 2,
                        child: Card(
                          color: Colors.white,
                          elevation: 2,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: FancyShimmerImage(
                                          imageUrl: drink.image,
                                          width: 30,
                                          height: 30,
                                          boxFit: BoxFit.cover,
                                          errorWidget: Image.asset(
                                            "assets/images/logo2.png",
                                            fit: BoxFit.cover,
                                            width: 30,
                                            height: 30,
                                          ))),
                                  const SizedBox(width: 5),
                                  Text(
                                    drink.text,
                                    style: TextStyle(
                                        color: textColor2,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget mealTypeWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xffF8F8F8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "*",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor2),
                  ),
                  SizedBox(
                    width: 2,
                  ),
                  Text(
                    "نوع الوجبة",
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color:
                        selectedMealTypeField ? Colors.red : Color(0xffD6D3D3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: DropdownButton<String>(
                    value: selectedMealType,
                    hint: Text(
                      "اختر نوع الوجبة",
                      style: TextStyle(fontSize: 14, color: Color(0xffB1B1B1)),
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 24,
                      color: Color(0xffB1B1B1),
                    ),
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Colors.black),
                    underline: Container(),
                    dropdownColor: Colors.white,
                    items: mealTypes
                        .map<DropdownMenuItem<String>>((String mealType) {
                      return DropdownMenuItem<String>(
                        value: mealType,
                        child: Text(mealType),
                      );
                    }).toList(),
                    onTap: () {
                      setState(() {
                        selectedMealTypeField = false;
                      });
                    },
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMealType = newValue;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget mealSizeWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xffF8F8F8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "*",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor2),
                  ),
                  SizedBox(
                    width: 2,
                  ),
                  Text(
                    "حجم الوجبة",
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color:
                        selectedMealSizeField ? Colors.red : Color(0xffD6D3D3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: DropdownButton<String>(
                    value: selectedMealSize,
                    hint: Text(
                      "اختر حجم الوجبة",
                      style: TextStyle(fontSize: 14, color: Color(0xffB1B1B1)),
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 24,
                      color: Color(0xffB1B1B1),
                    ),
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Colors.black),
                    underline: Container(),
                    dropdownColor: Colors.white,
                    items: mealSizes
                        .map<DropdownMenuItem<String>>((String mealSize) {
                      return DropdownMenuItem<String>(
                        value: mealSize,
                        child: Text(mealSize),
                      );
                    }).toList(),
                    onTap: () {
                      setState(() {
                        selectedMealSizeField = false;
                      });
                    },
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMealSize = newValue;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget mealCheckBoxWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xffF8F8F8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: additionalOptions.keys.map((key) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    RoundedCheckbox(
                      value: additionalOptions[key]!,
                      borderColor: mainColor,
                      borderRadius: 3.0,
                      activeColor: Colors.white,
                      checkColor: mainColor,
                      onChanged: (value) {
                        setState(() {
                          additionalOptions[key] = value!;
                        });
                      },
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      "${key}",
                      style: TextStyle(
                          color: textColor2,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget buttonWidget() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 5),
        child: MaterialButton(
          onPressed: () {
            if (_priceController.text.isEmpty ||
                _nameController.text.isEmpty ||
                _descriptionController.text.isEmpty ||
                (networkImages.isEmpty && _images.length == 0) ||
                selectedMealType == null ||
                selectedMealSize == null) {
              if (_priceController.text.isEmpty) {
                setState(() {
                  priceField = true;
                });
              }
              if (_descriptionController.text.isEmpty) {
                setState(() {
                  desField = true;
                });
              }

              if (_nameController.text.isEmpty) {
                setState(() {
                  nameField = true;
                });
              }
              if (networkImages.length + _images.length == 0) {
                setState(() {
                  photoField = true;
                });
              }
              if (selectedMealType == null) {
                setState(() {
                  selectedMealTypeField = true;
                });
              }
              if (selectedMealSize == null) {
                setState(() {
                  selectedMealSizeField = true;
                });
              }

              Fluttertoast.showToast(
                  msg: "الرجاء تعبئة الحقول المطلوبة", timeInSecForIosWeb: 3);
            } else {
              _submitForm();
            }
          },
          child: addLoading
              ? Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Text(
                  widget.isEditing ? 'حفظ التعديلات' : 'اضافه بوكس جديد',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: mainColor,
        ),
      ),
    );
  }
}

class Pair {
  final String text;
  final String image;

  Pair(this.text, this.image);
}

class ProductsPair {
  final int id;
  final String text;
  final String image;

  ProductsPair(this.id, this.text, this.image);
}
