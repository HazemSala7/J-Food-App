import 'dart:convert';
import 'dart:io';
import 'package:j_food_updated/LocalDB/Provider/CartProvider.dart';
import 'package:j_food_updated/LocalDB/Provider/PackageCartProvider.dart';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/views/cart/cartscreen.dart';
import 'package:j_food_updated/views/homescreen/market_screen.dart';
import 'package:j_food_updated/views/homescreen/profile_page.dart';
import 'package:flutter_update_dialog/update_dialog.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_screen.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final bool fromOrderConfirm;
  const HomeScreen({Key? key, required this.fromOrderConfirm})
      : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  bool showMediaIcons = false;
  final ValueNotifier<bool> noDelivery = ValueNotifier<bool>(false);
  final ValueNotifier<bool> ramadanTime = ValueNotifier<bool>(false);
  final ValueNotifier<bool> appHasError = ValueNotifier<bool>(false);
  UpdateDialog? dialog;
  static bool _updateDialogShownThisSession = false;

  late AnimationController _animationController;
  // late Animation<double> _fadeAnimation;
  // late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _screens = [
      MainScreen(
          changeDelivery: changeDelivery,
          changeRamadanTime: changeRamadanTime,
          changeAppError: changeAppError,
          noDelivery: noDelivery.value,
          changeTab: changeTab),
      ValueListenableBuilder<bool>(
        valueListenable: noDelivery,
        builder: (context, noDeliveryValue, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: ramadanTime,
            builder: (context, ramadanTimeValue, child) {
              return CartScreen(
                fromHome: true,
                noDelivery: noDeliveryValue,
                ramadanTime: ramadanTimeValue,
                changeTab: changeTab,
              );
            },
          );
        },
      ),
      Container(color: Colors.transparent),
      ValueListenableBuilder<bool>(
        valueListenable: noDelivery,
        builder: (context, noDeliveryValue, child) {
          return MarketScreen(
            noDelivery: noDeliveryValue,
            changeTab: changeTab,
          );
        },
      ),
      ValueListenableBuilder<bool>(
          valueListenable: appHasError,
          builder: (context, hasError, child) {
            return ProfilePage(
                noDelivery: false, changeTab: changeTab, appHasError: hasError);
          })
    ];

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Animations commented out as they are not used
    // _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    //   CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    // );
    //
    // _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
    //   CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    // );

    _selectedIndex = widget.fromOrderConfirm ? 1 : 0;

    checkForUpdate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void changeTab(int index) => setState(() => _selectedIndex = index);
  void changeDelivery() => noDelivery.value = !noDelivery.value;
  void changeRamadanTime(bool value) => ramadanTime.value = value;
  void changeAppError(bool value) => appHasError.value = value;

  void _toggleMediaIcons() {
    setState(() {
      showMediaIcons = !showMediaIcons;
    });
    if (showMediaIcons) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<Map<String, dynamic>> getUpdateStatus() async {
    String version = "3";

    final response = await http.post(
      Uri.parse(AppLink.CheckVersion),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'app_version': version}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Update check failed: ${response.statusCode} - ${response.body}");
      return {
        "update_required": false,
        "latest_version": version,
        "your_version": version
      };
    }
  }

  void checkForUpdate() async {
    if (_updateDialogShownThisSession) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final storedVersion = prefs.getString('app_version');

    if (storedVersion != currentVersion) {
      prefs.setString('app_version', currentVersion);
      prefs.remove('update_first_required_time');
    }

    final response = await getUpdateStatus();
    bool updateRequired = response['update_required'] ?? false;
    if (!updateRequired) {
      prefs.remove('update_first_required_time');
      return;
    }

    final updateFirstRequiredStr =
        prefs.getString('update_first_required_time');
    DateTime updateFirstRequiredTime =
        DateTime.tryParse(updateFirstRequiredStr ?? '') ?? now;

    if (updateFirstRequiredStr == null) {
      updateFirstRequiredTime = now;
      prefs.setString('update_first_required_time',
          updateFirstRequiredTime.toIso8601String());
    }

    const optionalDuration = Duration(days: 3);
    final timeSinceFirstRequired = now.difference(updateFirstRequiredTime);
    final isWithinOptionalPeriod = timeSinceFirstRequired < optionalDuration;
    final remaining = isWithinOptionalPeriod
        ? optionalDuration - timeSinceFirstRequired
        : Duration.zero;

    _updateDialogShownThisSession = true;
    showUpdateDialog(
        force: !isWithinOptionalPeriod, remainingDuration: remaining);
  }

  void showUpdateDialog(
      {required bool force, Duration? remainingDuration}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (dialog != null && dialog!.isShowing()) return;

    dialog = UpdateDialog.showUpdate(
      context,
      width: 300,
      title: "التحديث مطلوب",
      updateContent:
          'تتوفر نسخة جديدة من التطبيق.\nيرجى التحديث لمواصلة استخدام التطبيق.${!force ? "\nبعد 3 ايام سيصبح التحديث اجباري" : ""}',
      titleTextSize: 16,
      contentTextSize: 14,
      buttonTextSize: 14,
      topImage: Image.asset('assets/images/update.png', fit: BoxFit.cover),
      extraHeight: 10,
      radius: 12,
      themeColor: mainColor,
      progressBackgroundColor: Color(0x55808080),
      isForce: true,
      updateButtonText: "التحديث الان",
      ignoreButtonText: "لاحقا",
      enableIgnore: !force,
      onIgnore: () async {
        prefs.setString(
            'last_skipped_update', DateTime.now().toIso8601String());
        await Future.delayed(Duration(milliseconds: 100));
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      onUpdate: () async {
        final url = Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=j.food.com'
            : 'https://apps.apple.com/app/id6538722890';

        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          print('Could not launch update URL');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: mainColor,
      child: SafeArea(
        child: Scaffold(
          body: ValueListenableBuilder<bool>(
              valueListenable: appHasError,
              builder: (context, hasError, child) {
                return Stack(
                  children: [
                    IndexedStack(index: _selectedIndex, children: _screens),
                    // if (showMediaIcons)
                    //   MediaIconsOverlay(
                    //       fadeAnimation: _fadeAnimation,
                    //       scaleAnimation: _scaleAnimation,
                    //       onClose: _toggleMediaIcons),
                  ],
                );
              }),
          bottomNavigationBar: _buildConvexStyleBottomBar(),
        ),
      ),
    );
  }

  Widget _buildConvexStyleBottomBar() {
    final int cartItemCount =
        Provider.of<CartProvider>(context).cartItems.length;
    final int packageItemCount =
        Provider.of<PackageCartProvider>(context).packageCartItems.length;
    final int count = cartItemCount + packageItemCount;

    return ValueListenableBuilder<bool>(
      valueListenable: appHasError,
      builder: (context, hasError, child) {
        return Opacity(
          opacity: hasError ? 0.5 : 1.0,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, -2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IgnorePointer(
                  ignoring: hasError,
                  child: _buildTabItem(
                      index: 0,
                      icon: 'assets/images/home-button.png',
                      label: "الرئيسية"),
                ),
                IgnorePointer(
                  ignoring: hasError,
                  child: _buildTabItem(
                      index: 1,
                      icon: 'assets/images/cart2.png',
                      label: "السلة",
                      cartItemCount: count),
                ),
                _buildPlusTab(),
                IgnorePointer(
                  ignoring: hasError,
                  child: _buildTabItem(
                      index: 3,
                      icon: 'assets/images/market.png',
                      label: "ماركت"),
                ),
                _buildTabItem(
                    index: 4, icon: 'assets/images/user.png', label: "حسابي"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabItem(
      {required int index,
      required String icon,
      required String label,
      int? cartItemCount}) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() {
        _selectedIndex = index;
        if (showMediaIcons) _toggleMediaIcons();
      }),
      child: Container(
        width: 60,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ImageIcon(AssetImage(icon),
                      size: isSelected ? 24.0 : 22.0,
                      color: isSelected ? secondColor : Color(0xffDCDCDC)),
                  const SizedBox(height: 4),
                  Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? secondColor : Color(0xffDCDCDC))),
                ],
              ),
              if (label == "السلة" && (cartItemCount ?? 0) > 0)
                Positioned(
                  left: -3,
                  top: -15,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Baseline(
                      baseline: 15,
                      baselineType: TextBaseline.ideographic,
                      child: Text(cartItemCount.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlusTab() {
    final bool isSelected = showMediaIcons;
    return InkWell(
      onTap: _toggleMediaIcons,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: ImageIcon(
            AssetImage(isSelected
                ? 'assets/images/close.png'
                : 'assets/images/plus.png'),
            size: 28,
            color: isSelected ? secondColor : const Color(0xffFFC509)),
      ),
    );
  }
}

class MediaIconsOverlay extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final VoidCallback onClose;

  const MediaIconsOverlay(
      {Key? key,
      required this.fadeAnimation,
      required this.scaleAnimation,
      required this.onClose})
      : super(key: key);

  @override
  _MediaIconsOverlayState createState() => _MediaIconsOverlayState();
}

class _MediaIconsOverlayState extends State<MediaIconsOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            onTap: widget.onClose,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff323232).withOpacity(0.0),
                    Color(0xff323232).withOpacity(0.8)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: widget.fadeAnimation,
            child: ScaleTransition(
              scale: widget.scaleAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMediaWhats(),
                  Column(
                    children: [
                      _buildMediaPhone(),
                      const SizedBox(height: 70),
                    ],
                  ),
                  _buildMediaFace(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaFace() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              launch("https://www.facebook.com/profile.php?id=61563311812885"),
          child:
              Image.asset("assets/images/facebook.png", width: 40, height: 40),
        ),
      );

  Widget _buildMediaPhone() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => launch("tel://+972503050099"),
          child: Image.asset("assets/images/phone-call.png",
              width: 40, height: 40),
        ),
      );

  Widget _buildMediaWhats() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            var contact = "+972503050099";
            var androidUrl =
                "whatsapp://send?phone=$contact&text=Hi, I need some help";
            var iosUrl =
                "https://wa.me/$contact?text=${Uri.parse('Hi, I need some help')}";

            try {
              if (Platform.isIOS) {
                await launchUrl(Uri.parse(iosUrl));
              } else {
                await launchUrl(Uri.parse(androidUrl));
              }
            } on Exception {
              Fluttertoast.showToast(msg: "WhatsApp is not installed.");
            }
          },
          child:
              Image.asset("assets/images/whatsapp.png", width: 40, height: 40),
        ),
      );
}
