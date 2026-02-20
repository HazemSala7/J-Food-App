import 'package:j_food_updated/views/favorite/favorite_screen.dart';
import 'package:j_food_updated/views/homescreen/search_page.dart';
import 'package:j_food_updated/views/orders_screen/orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Header extends StatefulWidget {
  final bool fromAllResturant;
  final bool noDelivery;
  final Function(int) changeTab;

  const Header({
    super.key,
    required this.fromAllResturant,
    required this.noDelivery,
    required this.changeTab,
  });

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late String greeting;
  String userName = '';

  @override
  void initState() {
    super.initState();
    greeting = _getGreeting();
    _loadUserName();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 2 && hour < 12) {
      return 'صباح الخير';
    } else {
      return 'مساء الخير';
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userName = prefs.getString('name') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isAllRestaurants = widget.fromAllResturant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: isAllRestaurants
          ? null
          : const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
      clipBehavior: isAllRestaurants ? Clip.none : Clip.antiAlias,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: isAllRestaurants ? 1 : 3,
            child: Row(
              children: [
                // Back button only when fromAllResturant == true
                Visibility(
                  visible: isAllRestaurants,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xffFFC300),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 7.0),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: isAllRestaurants,
                  child: const SizedBox(width: 5),
                ),

                Container(
                  child: isAllRestaurants
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: userName == "" ? 5.0 : 0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    greeting,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.waving_hand,
                                    color: Color(0xffFFC509),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: userName == "" ? 5.0 : 0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    greeting,
                                    style: const TextStyle(
                                      color: Color(0xff606060),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  if (userName != "")
                                    Padding(
                                      padding: const EdgeInsets.only(left: 5),
                                      child: Text(
                                        userName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xff606060),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.waving_hand,
                                    color: Color(0xffFFC509),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // Right buttons (same in both designs)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildImageButton('assets/images/history.png', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => OrdersScreen()),
                  );
                }),
                const SizedBox(width: 5),
                _buildImageButton('assets/images/fav.png', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FavoriteScreen(
                        noDelivery: widget.noDelivery,
                        changeTab: widget.changeTab,
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 5),
                _buildImageButton('assets/images/search2.png', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SearchPage(
                        noDelivery: widget.noDelivery,
                        changeTab: widget.changeTab,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton(String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xffFFC300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Image.asset(
            imagePath,
            width: 17,
            height: 17,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
