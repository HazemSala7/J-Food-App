import 'package:flutter/material.dart';
import 'package:j_food_updated/views/allresturants/allresturants.dart';
import '../../../server/functions/functions.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class CategoryWidget extends StatelessWidget {
  CategoryWidget({
    super.key,
    required this.cat,
    required this.noDelivery,
    required this.fromMarket,
    required this.ramadanTime,
    required this.changeTab,
  });
  final Function(int) changeTab;
  final bool noDelivery;
  final bool fromMarket;
  final bool ramadanTime;
  final List cat;

  // Categories specific to the market
  final List<Map<String, dynamic>> marketCategories = [
    {'name': 'مول', 'crossAxis': 2, 'mainAxis': 2},
    {'name': 'خضار وفواكه', 'crossAxis': 1, 'mainAxis': 1},
    {'name': 'عنايه وتجميل', 'crossAxis': 1, 'mainAxis': 1},
    {'name': 'حيوانات اليفه', 'crossAxis': 2, 'mainAxis': 2},
    {'name': 'لحوم واسماك', 'crossAxis': 2, 'mainAxis': 1},
  ];

  final List<Map<String, dynamic>> otherCategories = [
    {'name': 'برجر', 'crossAxis': 2, 'mainAxis': 2},
    {'name': 'مشاوي', 'crossAxis': 1, 'mainAxis': 1},
    {'name': 'حلويات', 'crossAxis': 1, 'mainAxis': 1},
    {'name': 'شاورما', 'crossAxis': 2, 'mainAxis': 2},
    {'name': 'بـيتزا', 'crossAxis': 2, 'mainAxis': 1},
    {'name': 'سلطات', 'crossAxis': 1, 'mainAxis': 1},
    {'name': 'مأكولات شعبية', 'crossAxis': 2, 'mainAxis': 1},
    {'name': 'معجنات', 'crossAxis': 1, 'mainAxis': 1},
    {'name': 'بروست كرسبي', 'crossAxis': 1, 'mainAxis': 1},
    {'name': 'ساندويشات', 'crossAxis': 1, 'mainAxis': 1},
    {'name': 'مشروبات بارد كوكتيل بوظة', 'crossAxis': 2, 'mainAxis': 2},
    {'name': 'حمص فلافل', 'crossAxis': 2, 'mainAxis': 1},
    {'name': 'أكل آسيوي', 'crossAxis': 2, 'mainAxis': 1},
    {'name': 'أكل صحي', 'crossAxis': 2, 'mainAxis': 1},
  ];

  final List<Map<String, dynamic>> ramadanCategories = [
    {'name': 'مول', 'crossAxis': 2, 'mainAxis': 2},
    {'name': 'خضار وفواكه', 'crossAxis': 1, 'mainAxis': 1},
    {'name': 'عنايه وتجميل', 'crossAxis': 1, 'mainAxis': 1},
    {'name': 'حيوانات اليفه', 'crossAxis': 2, 'mainAxis': 2},
    {'name': 'لحوم واسماك', 'crossAxis': 2, 'mainAxis': 1},
  ];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> selectedCategories = fromMarket
        ? marketCategories
        : ramadanTime
            ? ramadanCategories
            : otherCategories;

    final filteredCategories = cat
        .where((category) => selectedCategories
            .any((selected) => selected['name'] == category['name']))
        .toList();
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children:
          _buildCategoryTiles(context, filteredCategories, selectedCategories),
    );
  }

  // Build tiles for the selected categories
  List<StaggeredGridTile> _buildCategoryTiles(
    BuildContext context,
    List filteredCategories,
    List<Map<String, dynamic>> selectedCategories,
  ) {
    return selectedCategories.map<StaggeredGridTile>((category) {
      final data = filteredCategories.firstWhere(
        (item) => item['name'] == category['name'],
        orElse: () => null,
      );

      String categoryImage = _getStaticImage(category['name']);
      String homeImage = _getHomeImage(category['name']);

      if (data != null) {
        return StaggeredGridTile.count(
          crossAxisCellCount: category['crossAxis'],
          mainAxisCellCount: category['mainAxis'],
          child: InkWell(
            onTap: () {
              print(categoryImage);
              NavigatorFunction(
                context,
                AllResturants(
                  storesArray: data['restaurants'],
                  title: data['name'],
                  image: categoryImage,
                  noDelivery: noDelivery,
                  changeTab: changeTab,
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xffEFEFF0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  homeImage,
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      }

      return StaggeredGridTile.count(
        crossAxisCellCount: 1,
        mainAxisCellCount: 1,
        child: const SizedBox.shrink(),
      );
    }).toList();
  }

  // Function to return a static image based on the category name
  String _getStaticImage(String categoryName) {
    Map<String, String> staticImages = {
      'برجر': 'assets/images/burger.png',
      'مشاوي': 'assets/images/mshawi.png',
      'حلويات': 'assets/images/delicious.png',
      'شاورما': 'assets/images/shawirma.png',
      'بـيتزا': 'assets/images/pizza.png',
      'سلطات': 'assets/images/salata.png',
      'مأكولات شعبية': 'assets/images/sha3bi.png',
      'معجنات': 'assets/images/mo3agnat.png',
      'بروست كرسبي': 'assets/images/krisbe.png',
      'ساندويشات': 'assets/images/sandwich.png',
      'مشروبات بارد كوكتيل بوظة': 'assets/images/ice-drinks.png',
      'حمص فلافل': 'assets/images/hommos.png',
      'لحوم واسماك': 'assets/images/fish.png',
      'خضار وفواكه': 'assets/images/fruits.png',
      'عنايه وتجميل': 'assets/images/beauty.png',
      'حيوانات اليفه': 'assets/images/dogs.png',
      'مول': 'assets/images/mool2.png',
      'أكل صحي': 'assets/images/healthy-food2.png',
      'أكل آسيوي': 'assets/images/asia-food2.png',
    };

    return staticImages[categoryName] ?? 'assets/images/logo2.png';
  }

  String _getHomeImage(String categoryName) {
    Map<String, String> staticImages = {
      'برجر': 'assets/images/burger2.png',
      'مشاوي': 'assets/images/mshawi2.png',
      'حلويات': 'assets/images/sweets.png',
      'شاورما': 'assets/images/shwarima2.png',
      'بـيتزا': 'assets/images/pizza2.png',
      'سلطات': 'assets/images/salatat.png',
      'مأكولات شعبية': 'assets/images/sha3bi2.png',
      'معجنات': 'assets/images/mo3aganat.png',
      'بروست كرسبي': 'assets/images/krisbe2.png',
      'ساندويشات': 'assets/images/sandwich2.png',
      'مشروبات بارد كوكتيل بوظة': 'assets/images/mashrobat.png',
      'حمص فلافل': 'assets/images/hommos2.png',
      'لحوم واسماك': 'assets/images/meat.png',
      'خضار وفواكه': 'assets/images/fruits2.png',
      'عنايه وتجميل': 'assets/images/beauty2.png',
      'حيوانات اليفه': 'assets/images/dogs-food.png',
      'مول': 'assets/images/mool.png',
      'أكل صحي': 'assets/images/healthy-food.png',
      'أكل آسيوي': 'assets/images/asia-food.png',
    };

    return staticImages[categoryName] ?? 'assets/images/logo2.png';
  }
}
