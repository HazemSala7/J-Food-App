import 'package:j_food_updated/LocalDB/Database/Database.dart';
import 'package:j_food_updated/LocalDB/Models/CategoryItem.dart';
import 'package:j_food_updated/component/check_box/check_box.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> appliedFilters;

  FilterBottomSheet({required this.appliedFilters});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  List<CategoryItem> categories = [];
  String? selectedCategory;
  RangeValues priceRange = RangeValues(10, 100);
  RangeValues timeRange = RangeValues(10, 60);
  String? selectedMealType;
  final List<String> mealTypes = ['فطور', 'غذاء', 'عشاء', 'وجبة خفيفة'];
  String? selectedMealSize;
  final List<String> mealSizes = ['فردي', 'عائلي'];
  Map<String, bool> additionalOptions = {
    'طعام صحي': false,
    'طعام نباتي': false,
    'عروضات': false,
  };

  @override
  void initState() {
    super.initState();
    fetchCategoriesFromDb();
  }

  void clearAllFilters() {
    setState(() {
      selectedCategory = null;
      priceRange = RangeValues(10, 100);
      timeRange = RangeValues(10, 60);
      selectedMealType = null;
      selectedMealSize = null;
      additionalOptions = {
        'طعام صحي': false,
        'طعام نباتي': false,
        'عروضات': false,
      };
    });
  }

  Future<void> fetchCategoriesFromDb() async {
    try {
      final dbHelper = CartDatabaseHelper();
      final List<CategoryItem> categoryItems =
          await dbHelper.getAllCategories();
      setState(() {
        categories = categoryItems;
      });
    } catch (e) {
      print('Error fetching categories from DB: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Text("التصنيف",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainColor)),
            ),
            SizedBox(height: 10),

            categories.isNotEmpty
                ? Card(
                    elevation: 3,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Text("القسم",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: mainColor)),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xffE1E1E1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              items: categories
                                  .map((category) => DropdownMenuItem<String>(
                                        value: category.id.toString(),
                                        child: Text(
                                          category.name,
                                          style: TextStyle(color: mainColor),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value;
                                });
                              },
                              decoration: InputDecoration(
                                labelStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                labelText: 'الكل',
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    width: 0.0,
                                    color: Color(0xffE1E1E1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    width: 0.0,
                                    color: Color(0xffE1E1E1),
                                  ),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10),
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                              ),
                              dropdownColor: Colors.white,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Center(child: Text("")),
            SizedBox(height: 6),

            Card(
              color: Colors.white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('السعر ',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: mainColor)),
                        Text(
                            "₪${priceRange.start.toInt()}-${priceRange.end.toInt()}",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffE1E1E1)))
                      ],
                    ),
                    RangeSlider(
                      values: priceRange,
                      min: 0,
                      max: 200,
                      labels: RangeLabels(
                        '\$${priceRange.start.toInt()}',
                        '\$${priceRange.end.toInt()}',
                      ),
                      activeColor: mainColor,
                      inactiveColor: Color(0xffE1E1E1),
                      onChanged: (values) {
                        setState(() {
                          priceRange = values;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 6),

            Card(
              color: Colors.white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('وقت التحضير ',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: mainColor)),
                        Text(
                            "${timeRange.start.toInt()}-${timeRange.end.toInt()} دقيقة",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffE1E1E1)))
                      ],
                    ),
                    RangeSlider(
                      values: timeRange,
                      min: 0,
                      max: 100,
                      labels: RangeLabels(
                        '\$${timeRange.start.toInt()}',
                        '\$${timeRange.end.toInt()}',
                      ),
                      activeColor: mainColor,
                      inactiveColor: Color(0xffE1E1E1),
                      onChanged: (values) {
                        setState(() {
                          timeRange = values;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6),

            // Meal Type
            Card(
              color: Colors.white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Text("الوجبة",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: mainColor)),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: mealTypes.map((type) {
                        bool isSelected = type == selectedMealType;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedMealType = type;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? mainColor : Color(0xffE1E1E1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6),

            // Meal Size
            Card(
              color: Colors.white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Text("الحجم",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: mainColor)),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: mealSizes.map((size) {
                        bool isSelected = size == selectedMealSize;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMealSize = size;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? mainColor : Color(0xffE1E1E1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                size,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),

            Card(
              color: Colors.white,
              elevation: 3,
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
                            borderRadius: 4.0,
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
                                color: Color(0xffE1E1E1),
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
            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MaterialButton(
                  minWidth: 50,
                  color: mainColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onPressed: () {
                    final filters = {
                      'category_id': selectedCategory,
                      'price_from': priceRange.start.toString(),
                      'price_to': priceRange.end.toString(),
                      // 'time_from': timeRange.start.toString(),
                      // 'time_to': timeRange.end.toString(),
                      'time_type': selectedMealType == null
                          ? ""
                          : selectedMealType == "فطور"
                              ? "breakfast"
                              : selectedMealType == "غذاء"
                                  ? "lunch"
                                  : selectedMealType == "عشاء"
                                      ? "dinner"
                                      : "snack",
                      'size_type': selectedMealSize == null
                          ? ""
                          : selectedMealSize == "فردي"
                              ? "single"
                              : "family",
                      'is_offer': additionalOptions['عروضات'].toString(),
                      'is_vegetarian':
                          additionalOptions['طعام نباتي'].toString(),
                      'is_healthy': additionalOptions['طعام صحي'].toString(),
                    };
                    Navigator.pop(context, filters);
                  },
                  child: Text(
                    "حفظ",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                MaterialButton(
                  minWidth: 50,
                  color: mainColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onPressed: () {
                    clearAllFilters();
                  },
                  child: Text(
                    "مسح الكل",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
