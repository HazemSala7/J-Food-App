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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class AddFood extends StatefulWidget {
  final bool isEditing;
  final String? productId;
  final String categoryId;
  final String userId;
  final String restaurantId;
  final String status;
  final String restaurantName;
  final String restaurantImage;
  final String restaurantAddress;
  final String storeCloseTime;
  final String storeOpenTime;
  final String deliveryPrice;
  const AddFood(
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
  State<AddFood> createState() => _AddFoodState();
}

class _AddFoodState extends State<AddFood> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  List<XFile> _images = [];
  List<Map<String, TextEditingController>> _components = [];
  List<Map<String, TextEditingController>> _drinks = [];
  bool _loading = false;
  bool addLoading = false;
  bool photoField = false;
  bool priceField = false;
  Map<int, bool> drinkPriceField = {};
  Map<int, bool> componentCountField = {};
  Map<int, bool> componentPriceField = {};
  bool desField = false;
  bool nameField = false;
  bool selectedMealTypeField = false;
  bool selectedMealSizeField = false;
  bool subCategoriesField = false;
  List<String> networkImages = [];
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

  List<Pair> availableComponents = [];
  List<Pair> availableDrinks = [];
  Map<String, bool> componentCheckboxStates = {};
  Map<String, bool> drinkCheckboxStates = {};

  List<Pair> selectedComponents = [];
  List<Pair> selectedDrinks = [];
  Map<int, TextEditingController> priceControllers = {};
  Map<int, TextEditingController> componentCountControllers = {};
  Map<int, TextEditingController> drinkPriceControllers = {};

  @override
  void initState() {
    super.initState();
    print(widget.productId);
    _loadSubCategories();
    _fetchDrinks();
    _fetchComponents();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    widget.isEditing ? changePhoto = false : changePhoto = true;
    if (widget.isEditing && widget.productId != null) {
      _fetchProductData();
    }
    for (var component in availableComponents) {
      componentCheckboxStates[component.text] = false;
    }
    for (var drink in availableDrinks) {
      drinkCheckboxStates[drink.text] = false;
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
          availableDrinks = res.map<Pair>((drink) {
            String id = drink['id'].toString();
            String name = drink['name'] ?? 'Unnamed Drink';
            String imageUrl =
                (drink['image'] != null && drink['image'].toString().isNotEmpty)
                    ? drink['image']
                    : '';
            return Pair(id, name, imageUrl);
          }).toList();

          availableDrinks.removeWhere((drink) =>
              selectedDrinks.any((selected) => selected.id == drink.id));
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

  Future<void> _fetchComponents() async {
    try {
      var response =
          await http.get(Uri.parse("https://hrsps.com/login/api/components"));
      if (response.statusCode == 200) {
        var responseData = utf8.decode(response.bodyBytes);
        var res = json.decode(responseData);

        setState(() {
          availableComponents = res.map<Pair>((component) {
            String id = component['id'].toString();
            String name = component['name'] ?? 'Unnamed component';
            String imageUrl = (component['image'] != null &&
                    component['image'].toString().isNotEmpty)
                ? component['image']
                : '';
            return Pair(id, name, imageUrl);
          }).toList();
        });

        availableComponents.removeWhere((component) =>
            selectedComponents.any((selected) => selected.id == component.id));
      } else {
        throw Exception('Failed to load components');
      }
    } catch (e) {
      print('Error fetching components: $e');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading components. Please try again later.')));
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
            "https://hrsps.com/login/api/show-product/${widget.productId}"),
      );
      if (response.statusCode == 200) {
        var responseData = utf8.decode(response.bodyBytes);
        var res = json.decode(responseData);
        var data = res["product"];
        setState(() {
          _nameController.text = data['name'];
          _priceController.text = data['price'];
          _descriptionController.text = data['description'];
          int? fetchedSubCategoryId = data['sub_category_id'];
          selectedMealSize = data['size_type'] == "single" ? "فردي" : "عائلي";
          additionalOptions['طعام صحي'] =
              data['is_healthy'] == "true" ? true : false;
          additionalOptions['طعام نباتي'] =
              data['is_vegetarian'] == "true" ? true : false;
          _discountController.text = data['discount_percentage'] != null
              ? data['discount_percentage'].toString()
              : "0";
          double discountPercentage =
              double.tryParse(data['discount_percentage'].toString()) ?? 0.0;

          _priceAfterDiscountController.text =
              (double.parse(_priceController.text) -
                      (double.parse(_priceController.text) *
                          (discountPercentage / 100)))
                  .toString();

          selectedMealType = data['time_type'] == "lunch"
              ? "غذاء"
              : data['time_type'] == "dinner"
                  ? "عشاء"
                  : data['time_type'] == "breakfast"
                      ? "فطور"
                      : "وجبة خفيفة";
          List<dynamic> productSizes = data['product_sizes'];
          if (productSizes.isNotEmpty) {
            sizes = [];
            isAddingSize = true;
            for (var size in data['product_sizes']) {
              sizes.add({
                "name": TextEditingController(text: size['size']),
                "price": TextEditingController(text: size['size_price_nis']),
              });
            }
          }
          selectedSubCategoryId = subCategories.any(
                  (subcategory) => subcategory['id'] == fetchedSubCategoryId)
              ? fetchedSubCategoryId
              : null;

          if (data['images'] != null && data['images'].isNotEmpty) {
            print("========");
            print(data['images']);
            networkImages =
                List<String>.from(data['images'].map((image) => image['url']));
          } else {
            networkImages = [
              'https://img.icons8.com/?size=100&id=53386&format=png&color=000000'
            ];
          }

          if (data['components'] != null) {
            selectedComponents = data['components'].map<Pair>((component) {
              int componentId = component['component_id'];
              String name =
                  component['component']['name'] ?? 'Unnamed Component';
              String imageUrl =
                  component['component']['image'] ?? 'assets/images/logo2.png';
              int maxOrderNumber = component['max_order_number'] ?? 1;
              double componentPrice =
                  double.tryParse(component['component_price'].toString()) ??
                      0.0;

              // Populate component controllers
              componentCountControllers[name.hashCode] =
                  TextEditingController(text: maxOrderNumber.toString());
              priceControllers[name.hashCode] =
                  TextEditingController(text: componentPrice.toString());

              return Pair(componentId.toString(), name, imageUrl);
            }).toList();

            availableComponents.removeWhere((component) => selectedComponents
                .any((selected) => selected.id == component.id));
          }

          if (data['drinks'] != null) {
            selectedDrinks = data['drinks'].map<Pair>((drink) {
              int drinkId = drink['drink_id'];
              String name = drink['drink']['name'] ?? 'Unnamed Drink';
              String imageUrl =
                  drink['drink']['image'] ?? 'assets/images/logo2.png';
              double drinkPrice =
                  double.tryParse(drink['drink_price'].toString()) ?? 0.0;

              drinkPriceControllers[name.hashCode] =
                  TextEditingController(text: drinkPrice.toString());
              print(drinkPriceControllers[drinkId]);
              return Pair(drinkId.toString(), name, imageUrl);
            }).toList();

            availableDrinks.removeWhere((drink) =>
                selectedDrinks.any((selected) => selected.id == drink.id));
          }
        });
      } else {
        throw Exception('Failed to load product data');
      }
    } catch (e) {
      print('Error fetching product data: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خلل في جلب معلومات المنتج'),
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

  Future<void> _submitForm() async {
    setState(() {
      addLoading = true;
    });

    try {
      var uri = widget.isEditing
          ? Uri.parse(
                  'https://hrsps.com/login/api/products_talabat/${widget.productId}')
              .replace(queryParameters: {'_method': 'PUT'})
          : Uri.parse('https://hrsps.com/login/api/products_talabat');

      var request = http.MultipartRequest('POST', uri);

      request.fields['name'] = _nameController.text;
      request.fields['price'] = _priceController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['store_id'] = widget.restaurantId;
      request.fields['restaurent_id'] = widget.restaurantId;
      request.fields['sub_category_id'] = selectedSubCategoryId == null
          ? '0'
          : selectedSubCategoryId.toString();
      request.fields['admin_status'] = "pending";
      request.fields['updated_status'] = "pending";
      request.fields['available'] = "true";
      request.fields['discount_percentage'] =
          _discountController.text.isEmpty ? "0" : _discountController.text;
      request.fields['type'] = widget.isEditing ? "edit" : "add";
      request.fields['category_id'] = selectedSubCategoryId == null
          ? '0'
          : selectedSubCategoryId!.toString();

      if (widget.isEditing && !changePhoto)
        for (int i = 0; i < networkImages.length; i++) {
          request.fields['image[$i]'] = networkImages[i];
        }
      else {
        for (int i = 0; i < _images.length; i++) {
          var filePath = _images[i].path;
          var multipartFile =
              await http.MultipartFile.fromPath('image[$i]', filePath);
          request.files.add(multipartFile);
        }
      }

      for (int i = 0; i < selectedComponents.length; i++) {
        final component = selectedComponents[i];

        String price = priceControllers[component.text.hashCode]?.text ?? '';
        String quantity =
            componentCountControllers[component.text.hashCode]?.text ?? '';

        request.fields['component_id[$i]'] = component.id;
        request.fields['com_price[$i]'] = price;
        request.fields['max_order_num_component[$i]'] = quantity;
      }

      for (int i = 0; i < selectedDrinks.length; i++) {
        final drink = selectedDrinks[i];
        String price = drinkPriceControllers[drink.text.hashCode]?.text ?? '';
        request.fields['drink_id[$i]'] = drink.id;
        request.fields['drink_price[$i]'] = price;
        print('Drink ID: ${drink.id}');
      }

      if (isAddingSize) {
        for (int i = 0; i < sizes.length; i++) {
          request.fields['size[$i]'] = sizes[i]['name']?.text ?? '';
          request.fields['size_price_nis[$i]'] = sizes[i]['price']?.text ?? '';
        }
      }

      request.fields['is_offer'] =
          (selectedStartDate != null) ? 'true' : 'false';
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
      print('Request Fields:');
      print(request.fields);

      var response = await request.send();
      print(response.statusCode);
      var responseBody = await response.stream.bytesToString();
      print('Response Body: $responseBody');
      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(
            msg: widget.isEditing ? 'تم التحديث' : 'تم الاضافة');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => RestaurantPage(
                  storeId: widget.restaurantId,
                  userId: widget.userId,
                  categoryId: widget.categoryId,
                  status: widget.status,
                  restaurantName: widget.restaurantName,
                  storeCloseTime: widget.storeCloseTime,
                  storeOpenTime: widget.storeOpenTime,
                  restaurantImage: widget.restaurantImage,
                  restaurantAddress: widget.restaurantAddress,
                  deliveryPrice: widget.deliveryPrice)),
          (route) => false,
        );
      } else {
        var responseBody = await response.stream.bytesToString();
        var errorData = jsonDecode(responseBody);
        if (response.statusCode == 422) {
          List errors = errorData['errors'];
          for (var error in errors) {
            if (error['field'] == "price") {
              setState(() {
                priceField = true;
              });
            }
            if (error['field'] == "name") {
              setState(() {
                nameField = true;
              });
            }
            if (error['field'] == "image") {
              print("------------");
              setState(() {
                photoField = true;
              });
              if (error['message'] ==
                  "The image.0 must not be greater than 2048 kilobytes.") {
                Fluttertoast.showToast(
                    msg: "يجب ان تكون الصورة اقل من ٢ ميغا",
                    timeInSecForIosWeb: 4);
              }
            }
          }
        }
        if (errorData["error"] == "Invalid argument supplied for foreach()") {
          setState(() {
            photoField = true;
          });
        }
        print('Failed to submit form: ${response.reasonPhrase}');
        print('Response: $response');
        Fluttertoast.showToast(msg: 'حدث خطأ أثناء إرسال البيانات');
      }
    } catch (e) {
      print('Error: $e');
      Fluttertoast.showToast(msg: 'حدث خطأ أثناء إرسال البيانات');
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
                                        ? 'تعديل منتج'
                                        : 'اضافة منتج جديد ',
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
                              Visibility(
                                  visible: subCategories.isNotEmpty,
                                  child: subCategoriesWidget()),
                              SizedBox(
                                height: 10,
                              ),
                              offerWidget(),
                              SizedBox(height: 10),
                              componentsWidget(),
                              SizedBox(height: 10),
                              drinksWidget(),
                              SizedBox(height: 10),
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
                          "أسم المنتج",
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
                            hintText: "ادخل اسم المنتج",
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
                          "وصف المنتج",
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
                            hintText: "ادخل وصف المنتج",
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
                          child: widget.isEditing &&
                                  !changePhoto &&
                                  networkImages.isNotEmpty
                              ? Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Image.network(
                                      networkImages[0],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          "assets/images/logo2.png",
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            networkImages.removeAt(0);
                                            changePhoto = true;
                                          });
                                        },
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            color: fourthColor,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "x",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
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
                        flex: 2,
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
                                  _discountController.text.isNotEmpty
                                      ? _priceAfterDiscountController
                                          .text = (double.parse(
                                                  _priceController.text) -
                                              ((double.parse(_discountController
                                                          .text) /
                                                      100) *
                                                  double.parse(
                                                      _priceController.text)))
                                          .toString()
                                      : _priceAfterDiscountController.text =
                                          double.parse(_priceController.text)
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
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xffD0D0D0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: MaterialButton(
                            onPressed: () {
                              setState(() {
                                isAddingSize = true;
                              });
                              print(sizes.length);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "اضافة حجم",
                              style:
                                  TextStyle(color: secondColor, fontSize: 12),
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
        if (isAddingSize)
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
                              color: textColor2),
                        ),
                        SizedBox(width: 2),
                        Text(
                          "الحجم",
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: List.generate(sizes.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: TextFormField(
                                    controller: sizes[index]["name"],
                                    onTap: () {
                                      setState(() {
                                        isAddingSizeField = false;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: "الحجم",
                                      hintStyle: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xffB1B1B1)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: mainColor,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          width: 1.0,
                                          color: isAddingSizeField
                                              ? Colors.red
                                              : Color(0xffD6D3D3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: TextFormField(
                                    controller: sizes[index]["price"],
                                    onTap: () {
                                      setState(() {
                                        isAddingSizeField = false;
                                      });
                                    },
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: InputDecoration(
                                      hintText: "السعر",
                                      hintStyle: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xffB1B1B1)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: mainColor,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          width: 1.0,
                                          color: isAddingSizeField
                                              ? Colors.red
                                              : Color(0xffD6D3D3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                child: Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Color(0xffD0D0D0)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: MaterialButton(
                                    onPressed: () {
                                      setState(() {
                                        sizes.add({
                                          "name": TextEditingController(),
                                          "price": TextEditingController(),
                                        });
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "+",
                                      style: TextStyle(
                                        color: secondColor,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          )
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
                      "اختر تصنيف المنتج",
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

  Widget offerWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: Color(0xffF8F8F8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "عرض/خصم",
                    style: TextStyle(
                        fontSize: 12,
                        color: textColor2,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8)),
                      child: TextFormField(
                        controller: _discountController,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _priceAfterDiscountController
                                  .text = (double.parse(_priceController.text) -
                                      ((double.parse(value) / 100) *
                                          double.parse(_priceController.text)))
                                  .toString();
                            });
                          } else {
                            setState(() {
                              _priceAfterDiscountController.text =
                                  _priceController.text;
                            });
                          }
                        },
                        obscureText: false,
                        decoration: InputDecoration(
                          hintStyle:
                              TextStyle(fontSize: 12, color: Color(0xffB1B1B1)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: mainColor, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                width: 1.0, color: Color(0xffB1B1B1)),
                          ),
                          hintText: "النسبة %",
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        controller: _priceAfterDiscountController,
                        obscureText: false,
                        enabled: false,
                        decoration: InputDecoration(
                          hintStyle:
                              TextStyle(fontSize: 10, color: Color(0xffB1B1B1)),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: mainColor, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                width: 1.0, color: Color(0xffB1B1B1)),
                          ),
                          hintText: "السعر بعد الخصم",
                        ),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "مدة العرض",
                    style: TextStyle(
                        fontSize: 12,
                        color: textColor2,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: discountField
                                ? Colors.red
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          DateTime? selectedDate =
                              await DatePicker.showDateTimePicker(
                            context,
                            showTitleActions: true,
                            minTime: DateTime.now(),
                            onConfirm: (date) {
                              setState(() {
                                selectedStartDate = date;
                              });
                            },
                            currentTime: selectedStartDate ?? DateTime.now(),
                            locale: LocaleType.ar,
                          );
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: selectedStartDate != null
                                  ? "${selectedStartDate!.day}/${selectedStartDate!.month}/${selectedStartDate!.year}"
                                  : "بداية العرض",
                            ),
                            style: TextStyle(
                                color: selectedStartDate != null
                                    ? Colors.black
                                    : Color(0xffB1B1B1),
                                fontSize: 12),
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: mainColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    width: 1.0, color: Color(0xffB1B1B1)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: discountField
                                ? Colors.red
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          DateTime? selectedDate =
                              await DatePicker.showDateTimePicker(
                            context,
                            showTitleActions: true,
                            minTime: selectedStartDate ?? DateTime.now(),
                            onConfirm: (date) {
                              setState(() {
                                selectedEndDate = date;
                              });
                            },
                            currentTime: selectedEndDate ?? DateTime.now(),
                            locale: LocaleType.ar,
                          );
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: selectedEndDate != null
                                  ? "${selectedEndDate!.day}/${selectedEndDate!.month}/${selectedEndDate!.year}"
                                  : "نهاية العرض",
                            ),
                            style: TextStyle(
                                fontSize: 12,
                                color: selectedEndDate != null
                                    ? Colors.black
                                    : Color(0xffB1B1B1)),
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: mainColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    width: 1.0, color: Color(0xffB1B1B1)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
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
                    "المكونات",
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
                searchHintText: 'ابحث عن المكون الذي تريده',
                items: availableComponents.map((e) => e.text).toList(),
                onChanged: (value) {
                  final selected = availableComponents.firstWhere(
                    (element) => element.text == value,
                  );
                  if (!priceControllers.containsKey(selected.text.hashCode)) {
                    priceControllers[selected.text.hashCode] =
                        TextEditingController();
                    componentCountControllers[selected.text.hashCode] =
                        TextEditingController();
                  }
                  setState(() {
                    availableComponents.remove(selected);
                    selectedComponents.add(selected);
                  });
                },
              ),
              Column(
                children: selectedComponents.map((component) {
                  return Row(
                    children: [
                      RoundedCheckbox(
                          value:
                              componentCheckboxStates[component.text] ?? false,
                          activeColor: Colors.white,
                          borderColor: mainColor,
                          onChanged: (bool? value) {
                            setState(() {
                              componentCheckboxStates[component.text] = value!;
                            });
                          },
                          checkColor: mainColor),
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedComponents.remove(component);
                            availableComponents.add(component);
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
                                          imageUrl: component.image,
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
                                    component.text,
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
                      Expanded(
                        child: Card(
                          elevation: 2,
                          color: Colors.white,
                          child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8)),
                              child: TextFormField(
                                controller:
                                    priceControllers[component.text.hashCode],
                                obscureText: false,
                                onTap: () {
                                  setState(() {
                                    componentPriceField[
                                        component.text.hashCode] = false;
                                  });
                                },
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: InputDecoration(
                                  hintStyle: TextStyle(
                                      fontSize: 12, color: Color(0xffB1B1B1)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: mainColor, width: 1.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      width: 1.0,
                                      color: componentPriceField.containsKey(
                                                  component.text.hashCode) &&
                                              componentPriceField[component
                                                      .text.hashCode] ==
                                                  true
                                          ? Colors.red
                                          : Color(0xffD6D3D3),
                                    ),
                                  ),
                                  hintText: "السعر",
                                ),
                              )),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          elevation: 2,
                          color: Colors.white,
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)),
                            child: TextFormField(
                              controller: componentCountControllers[
                                  component.text.hashCode],
                              obscureText: false,
                              onTap: () {
                                setState(() {
                                  componentCountField[component.text.hashCode] =
                                      false;
                                });
                              },
                              decoration: InputDecoration(
                                hintStyle: TextStyle(
                                    fontSize: 12, color: Color(0xffB1B1B1)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: mainColor, width: 1.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      width: 1.0,
                                      color: componentCountField.containsKey(
                                                  component.text.hashCode) &&
                                              componentCountField[component
                                                      .text.hashCode] ==
                                                  true
                                          ? Colors.red
                                          : Color(0xffD6D3D3),
                                    )),
                                hintText: "العدد",
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
                    "المشروبات",
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
                  print(drinkPriceControllers
                      .containsKey(selected.text.hashCode));
                  if (!drinkPriceControllers
                      .containsKey(selected.text.hashCode)) {
                    drinkPriceControllers[selected.text.hashCode] =
                        TextEditingController();
                  }

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
                      RoundedCheckbox(
                          value: drinkCheckboxStates[drink.text] ?? false,
                          activeColor: Colors.white,
                          borderColor: mainColor,
                          onChanged: (bool? value) {
                            setState(() {
                              drinkCheckboxStates[drink.text] = value!;
                            });
                          },
                          checkColor: mainColor),
                      const SizedBox(width: 5),
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
                      Expanded(
                        child: Card(
                          elevation: 2,
                          color: Colors.white,
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)),
                            child: TextFormField(
                              controller:
                                  drinkPriceControllers[drink.text.hashCode],
                              obscureText: false,
                              onTap: () {
                                setState(() {
                                  drinkPriceField[drink.text.hashCode] = false;
                                });
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: InputDecoration(
                                hintStyle: TextStyle(
                                    fontSize: 12, color: Color(0xffB1B1B1)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: mainColor, width: 1.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      width: 1.0,
                                      color: drinkPriceField.containsKey(
                                                  drink.text.hashCode) &&
                                              drinkPriceField[
                                                      drink.text.hashCode] ==
                                                  true
                                          ? Colors.red
                                          : Color(0xffD6D3D3),
                                    )),
                                hintText: "السعر",
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
            setState(() {
              // Reset all validation maps
              drinkPriceField = {};
              componentPriceField = {};
              componentCountField = {};
            });

            bool isAnyPriceEmpty = false;
            bool isAnyComponentCountEmpty = false;
            bool isAnyDrinkPriceEmpty = false;

            // Check for empty fields in priceControllers
            priceControllers.forEach((key, controller) {
              if (controller.text.isEmpty) {
                componentPriceField[key] = true;
                isAnyPriceEmpty = true;
              }
            });

            // Check for empty fields in componentCountControllers
            componentCountControllers.forEach((key, controller) {
              if (controller.text.isEmpty) {
                componentCountField[key] = true;
                isAnyComponentCountEmpty = true;
              }
            });

            // Check for empty fields in drinkPriceControllers
            drinkPriceControllers.forEach((key, controller) {
              if (controller.text.isEmpty) {
                drinkPriceField[key] = true;
                isAnyDrinkPriceEmpty = true;
              }
            });

            // Overall validation check
            if ((isAddingSize && sizes.isEmpty) ||
                isAnyPriceEmpty ||
                isAnyComponentCountEmpty ||
                isAnyDrinkPriceEmpty ||
                _nameController.text.isEmpty ||
                _descriptionController.text.isEmpty ||
                (subCategories.isNotEmpty && selectedSubCategoryId == null) ||
                (networkImages.length + _images.length == 0) ||
                selectedMealType == null ||
                selectedMealSize == null) {
              if (isAddingSize && sizes.isEmpty) {
                setState(() {
                  isAddingSizeField = true;
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

              if (subCategories.isNotEmpty && selectedSubCategoryId == null) {
                setState(() {
                  subCategoriesField = true;
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
                  widget.isEditing ? 'حفظ التعديلات' : 'اضافه منتج جديد',
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
  final String id;
  final String text;
  final String image;

  Pair(this.id, this.text, this.image);
}
