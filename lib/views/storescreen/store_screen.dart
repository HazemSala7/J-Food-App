import 'dart:async';
import 'dart:convert';
import 'package:j_food_updated/LocalDB/Models/FavoriteItem.dart';
import 'package:j_food_updated/LocalDB/Provider/CartProvider.dart';
import 'package:j_food_updated/LocalDB/Provider/FavouriteProvider.dart';
import 'package:j_food_updated/LocalDB/Provider/PackageCartProvider.dart';
import 'package:j_food_updated/views/favorite/favorite_screen.dart';
import 'package:j_food_updated/views/storescreen/resturant_stories.dart';
import 'package:j_food_updated/views/storescreen/store_provider/store_provider.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'widgets/items.dart';
import 'package:add_to_cart_animation/add_to_cart_animation.dart';
// import 'package:no_screenshot/no_screenshot.dart';
// import 'package:story_view/story_view.dart';

class StoreScreen extends StatefulWidget {
  final bool noDelivery;
  StoreScreen({
    Key? key,
    required this.store_id,
    required this.store_name,
    required this.open,
    required this.store_address,
    required this.store_image,
    required this.store_cover_image,
    required this.category_id,
    required this.category_name,
    required this.noDelivery,
    required this.changeTab,
  }) : super(key: key);

  final String store_id;
  final bool open;
  final String store_name;
  final String store_address;
  final String store_image;
  final String store_cover_image;
  final String category_id;
  final String category_name;
  final Function(int) changeTab;
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  GlobalKey<CartIconKey> cartKey = GlobalKey<CartIconKey>();
  late Function(GlobalKey) runAddToCartAnimation;
  GlobalKey keyButton = GlobalKey();
  TextEditingController searchController = TextEditingController();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    print(widget.store_id);

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      Provider.of<StoreProvider>(context, listen: false)
          .fetchStoreDetails(widget.store_id);
    });
  }

  void _onScroll() {
    if (!mounted) return;

    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    // Check if we're near the bottom and not already loading
    if (!storeProvider.isLoadingMore &&
        storeProvider.hasMoreProducts &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      // Trigger pagination only if not already loading
      storeProvider.loadMoreProducts(widget.store_id);
    }
  }

  void addToCartClick(GlobalKey widgetKey) async {
    if (mounted) {
      await runAddToCartAnimation(widgetKey);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, storeProvider, child) {
        return Container(
          color: fourthColor,
          child: SafeArea(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Scaffold(
                backgroundColor: fourthColor,
                body: AddToCartAnimation(
                  cartKey: cartKey,
                  dragAnimation:
                      const DragToCartAnimationOptions(rotation: true),
                  jumpAnimation: const JumpAnimationOptions(),
                  createAddToCartAnimation: (addToCart) {
                    runAddToCartAnimation = addToCart;
                  },
                  child: storeProvider.isLoading
                      ? storeMethod(
                          open: widget.open,
                          image: widget.store_image,
                          name: widget.store_name,
                          address: widget.store_address,
                          storeId: int.parse(widget.store_id),
                          coverImage: widget.store_cover_image,
                          waiting: true,
                          openTime: '',
                          closeTime: '',
                          deliveryPrice: '',
                          deliveryTime: '',
                          subCategories: [
                            {"id": 0, "name": "الكل"}
                          ],
                        )
                      : storeProvider.hasError
                          ? const Center(
                              child: Text('Failed to load store details'),
                            )
                          : storeMethod(
                              open: storeProvider.storeData?["restaurant"]
                                      ["is_open"] ??
                                  widget.open,
                              image: storeProvider.storeData?["restaurant"]
                                      ["image"] ??
                                  widget.store_image,
                              name: storeProvider.storeData?["restaurant"]
                                      ["name"] ??
                                  widget.store_name,
                              address: storeProvider.storeData?["restaurant"]
                                      ["address"] ??
                                  widget.store_address,
                              storeId: storeProvider.storeData?["restaurant"]
                                      ["id"] ??
                                  int.parse(widget.store_id),
                              coverImage: storeProvider.storeData?["restaurant"]
                                      ["cover_image"] ??
                                  widget.store_cover_image,
                              waiting: false,
                              subCategories: storeProvider.apiSubCategories ??
                                  [
                                    {"id": 0, "name": "الكل"}
                                  ],
                              openTime: storeProvider.storeData?["restaurant"]
                                      ["open_time"] ??
                                  '',
                              closeTime: storeProvider.storeData?["restaurant"]
                                      ["close_time"] ??
                                  '',
                              deliveryPrice:
                                  storeProvider.storeData?["restaurant"]
                                          ["delivery_price"] ??
                                      '',
                              deliveryTime:
                                  storeProvider.storeData?["restaurant"]
                                          ["delivery_time"] ??
                                      '',
                            ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget storeMethod({
    required String image,
    required String name,
    required bool open,
    required String openTime,
    required String closeTime,
    required String deliveryPrice,
    required String deliveryTime,
    required int storeId,
    required String address,
    required String coverImage,
    required List<Map<String, dynamic>> subCategories,
    required bool waiting,
  }) {
    return Consumer<StoreProvider>(
      builder: (context, storeProvider, _) {
        return Stack(
          children: [
            ListView(
              controller: _scrollController,
              children: [
                /// ================= HEADER CARD =================
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 35),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(25),
                        top: Radius.circular(4),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        /// --- Store Image / Stories ---
                        Positioned(
                          top: -45,
                          left: (MediaQuery.of(context).size.width / 2) - 70,
                          child: storeProvider.restaurantStories.isNotEmpty
                              ? InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RestaurantStories(
                                          storiesData:
                                              storeProvider.restaurantStories,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _buildStoryCircle(image),
                                )
                              : CircleAvatar(
                                  radius: 45,
                                  backgroundColor: fourthColor,
                                  child: ClipOval(
                                    child: Image.network(
                                      image,
                                      fit: BoxFit.cover,
                                      width: 80,
                                      height: 80,
                                    ),
                                  ),
                                ),
                        ),

                        /// --- Favorite Button ---
                        Positioned(
                          top: 0,
                          right: 40,
                          child: InkWell(
                            onTap: () async {
                              final favProvider =
                                  Provider.of<FavouriteProvider>(context,
                                      listen: false);
                              bool isFavorite =
                                  favProvider.isProductFavorite(storeId);

                              if (isFavorite) {
                                await favProvider.removeFromFavorite(storeId);
                                Fluttertoast.showToast(
                                  msg: "تم حذف هذا المطعم من المفضلة بنجاح",
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                );
                              } else {
                                final int categoryID =
                                    int.tryParse(widget.category_id ?? '') ?? 0;

                                // Get working hours from storeProvider
                                final storeProvider =
                                    Provider.of<StoreProvider>(context,
                                        listen: false);
                                final workingHoursData =
                                    storeProvider.storeData?["restaurant"]
                                            ["working_hours"] ??
                                        [];
                                final isOpenStatus = storeProvider
                                        .storeData?["restaurant"]["is_open"] ??
                                    false;

                                // Convert working hours to JSON string
                                final String workingHoursJson =
                                    jsonEncode(workingHoursData);

                                final newItem = FavoriteItem(
                                  categoryID: categoryID,
                                  categoryName: widget.category_name,
                                  storeId: storeId,
                                  storeImage: image,
                                  storeName: name,
                                  openTime: openTime,
                                  closeTime: closeTime,
                                  storeLocation: address,
                                  workingHours: workingHoursJson,
                                  isOpen: isOpenStatus,
                                );

                                await favProvider.addToFavorite(newItem);
                                Fluttertoast.showToast(
                                  msg: "تمت اضافة المطعم الى المفضلة بنجاح",
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                );
                              }
                            },
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Center(
                                child: Consumer<FavouriteProvider>(
                                  builder: (context, favProvider, _) {
                                    bool isFav =
                                        favProvider.isProductFavorite(storeId);
                                    return Image.asset(
                                      isFav
                                          ? "assets/images/remove-fav.png"
                                          : "assets/images/add-fav.png",
                                      fit: BoxFit.contain,
                                      width: 25,
                                      height: 25,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        /// --- Back Button ---
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xffFFC300),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ),

                        /// --- Store Info ---
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _buildIconButton('assets/images/share.png', () {
                                  // Share functionality temporarily disabled
                                  print(
                                      'Share: Check out this restaurant: https://j-food-2a4d7.web.app/refer/?code=$storeId');
                                  // Share.share(
                                  //   'Check out this restaurant: https://j-food-2a4d7.web.app/refer/?code=$storeId',
                                  // );
                                }),
                                const SizedBox(width: 5),
                                _buildIconButton(
                                    'assets/images/history2.png', () {}),
                                const SizedBox(width: 5),
                                _buildIconButton('assets/images/fav.png', () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FavoriteScreen(
                                        noDelivery: widget.noDelivery,
                                        changeTab: widget.changeTab,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 27),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff323232),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: secondColor, width: 1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: secondColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                /// ================= BODY =================
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(25)),
                    ),
                    child: Column(
                      children: [
                        if (!storeProvider.packagePage)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'وقت التوصيل : $deliveryTime د',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: mainColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'تكلفة التوصيل : $deliveryPrice₪',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: mainColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        /// --- Search ---
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Container(
                            height: 30,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: searchController,
                              onChanged: (value) =>
                                  storeProvider.searchItems(value.trim()),
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
                                      width: 1.0, color: Color(0xffD6D3D3)),
                                ),
                                hintText: "ابحث عن منتج معين",
                              ),
                            ),
                          ),
                        ),

                        /// --- Category Filter ---
                        if (subCategories.length > 1 &&
                            !storeProvider.packagePage) ...[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              children: [
                                Text(
                                  'القسم:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 40,
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: subCategories.length,
                              itemBuilder: (context, index) {
                                String category = subCategories[index]["name"];
                                int id = subCategories[index]["id"];
                                return GestureDetector(
                                  onTap: () => storeProvider.filterByCategory(
                                      id, category),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Card(
                                      elevation: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            width: storeProvider
                                                        .selectedCategoryId ==
                                                    id
                                                ? 2
                                                : 1,
                                            color: storeProvider
                                                        .selectedCategoryId ==
                                                    id
                                                ? mainColor
                                                : Colors.black.withOpacity(0.5),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Center(
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              color: storeProvider
                                                          .selectedCategoryId ==
                                                      id
                                                  ? mainColor
                                                  : const Color(0xff616163),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        /// --- Products List / Loading ---
                        waiting || storeProvider.isLoading
                            ? _buildShimmerLoader()
                            : ItemWidget(
                                storeDeliveryPrice: deliveryPrice,
                                storeName: name,
                                data: storeProvider.displayedProducts,
                                packageData: storeProvider.displayedPackages,
                                storeId: storeId.toString(),
                                open: open,
                                storeCloseTime: closeTime,
                                storeOpenTime: openTime,
                                workingHours: jsonEncode(
                                    storeProvider.storeData?["restaurant"]
                                            ["working_hours"] ??
                                        []),
                                isOpen: storeProvider.storeData?["restaurant"]
                                        ["is_open"] ??
                                    false,
                                storeImage: image,
                                storeLocation: address,
                                changeConfirmOrder:
                                    storeProvider.changeConfirmOrder,
                                orderId: "",
                                isResturant: false,
                                changePackagePage:
                                    storeProvider.changePackagePage,
                              ),

                        /// --- Loading More Indicator ---
                        if (storeProvider.isLoadingMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(mainColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            /// ================= OVERLAYS =================
            if (storeProvider.showSuccessMessage) _buildSuccessMessageOverlay(),
            if (storeProvider.confirmOrder) _buildCartSummaryOverlay(context),
          ],
        );
      },
    );
  }

  /// ================= HELPERS =================

  Widget _buildStoryCircle(String image) {
    return Container(
      width: 90,
      height: 90,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
            Color(0xFF515BD4),
            Color(0xFFF58529),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: CircleAvatar(
          radius: 45,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: Image.network(
              image,
              fit: BoxFit.cover,
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) => const Icon(Icons.image),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: const Color.fromARGB(255, 196, 196, 196),
      highlightColor: const Color.fromARGB(255, 129, 129, 129),
      child: Column(
        children: List.generate(
          10,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 15),
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white, // This is overridden by Shimmer
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessageOverlay() {
    return Positioned(
      bottom: 70,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xffB7B7B7),
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "تم اضافة الطلب بنجاح",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummaryOverlay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Consumer2<CartProvider, PackageCartProvider>(
          builder: (context, cartProvider, packageCartProvider, _) {
            final cartItems = cartProvider.cartItems;
            final packageItems = packageCartProvider.packageCartItems;

            int itemCount = cartItems.length;
            double totalPrice = cartItems.fold(
              0.0,
              (sum, item) => sum + double.parse(item.total),
            );
            for (var pkg in packageItems) {
              totalPrice += double.parse(pkg.total);
            }

            return InkWell(
              onTap: () {
                widget.changeTab(1);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 25),
                decoration: BoxDecoration(
                  color: mainColor,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Text(
                            "$itemCount",
                            style: TextStyle(
                              color: mainColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "الذهاب للسلة",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.0),
                        color: Colors.white,
                      ),
                      child: Text(
                        "₪${totalPrice.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageButton(String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        // padding: EdgeInsets.all(6),
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: Color(0xffFFC300)),
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
