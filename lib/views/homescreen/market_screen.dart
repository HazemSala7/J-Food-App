import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:j_food_updated/views/homescreen/widgets/category.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MarketScreen extends StatefulWidget {
  final bool noDelivery;
  final Function(int) changeTab;
  const MarketScreen(
      {super.key, required this.noDelivery, required this.changeTab});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      print("Fetching categories...");
      final response = await fetchCategoriesFromAPI();

      if (!mounted) return; // ⛔️ Prevent setState after dispose

      setState(() {
        _categories = response['categories'];
        _isLoading = false;
        _hasError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<Map<String, dynamic>> fetchCategoriesFromAPI() async {
    const String apiUrl = '${AppLink.categories}';

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to load categories: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fourthColor,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: fourthColor,
          body: Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 8, top: 25),
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Center(child: CircularProgressIndicator()))
                  : _hasError
                      ? Container(
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "حدث خلل اثناء جلب البيانات الرجاء اعادة المحاولة",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: mainColor,
                                ),
                              ),
                              SizedBox(height: 10),
                              MaterialButton(
                                color: mainColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                onPressed: () {
                                  _fetchCategories();
                                },
                                child: Text(
                                  "اعد المحاولة",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 16.0, top: 20),
                                child: Row(
                                  children: [
                                    Text(
                                      "الماركت",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: Color(0xff982C2A)),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: CategoryWidget(
                                  cat: _categories,
                                  noDelivery: widget.noDelivery,
                                  fromMarket: true,
                                  ramadanTime: true,
                                  changeTab: widget.changeTab,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
