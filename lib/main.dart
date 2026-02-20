import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:j_food_updated/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
// import 'package:uni_links2/uni_links.dart';
import 'package:path_provider/path_provider.dart';
import 'LocalDB/Provider/CartProvider.dart';
import 'LocalDB/Provider/PackageCartProvider.dart';
import 'LocalDB/Provider/FavouriteProvider.dart';
import 'views/storescreen/store_provider/store_provider.dart';
import 'views/resturant_page/order_provider/store_detail_provider.dart';
import 'views/resturant_page/order_provider/order_provider.dart';
import 'views/orders_screen/orders_provider.dart';
import 'views/resturant_page/restaurant_page.dart';
import 'views/storescreen/store_screen.dart';
import 'views/homescreen/homescreen.dart';
import 'services/timer_calss.dart';
import 'notifications/notification_service.dart';

Future<void> _firebaseOrderMessagingBackgroundHandler(
    RemoteMessage message) async {
  await showOrderStatusNotification(
    message.notification?.title ?? 'New Notification',
    message.notification?.body ?? 'You have a new notification',
    message.data['orderId'],
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background message received: ${message.notification?.title}");
}

Future<void> clearCache() async {
  try {
    final directory = await getTemporaryDirectory();
    final cacheFiles = Directory(directory.path);
    if (await cacheFiles.exists()) {
      await cacheFiles.delete(recursive: true);
    }
  } catch (e) {
    print('Failed to clear cache: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await clearCache();
  setupLocalNotification();

  try {
    if (Platform.isIOS) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: 'AIzaSyDXBSsEvwOzWFqjPnsPXBHXM-xLcxuYwl8',
          appId: '1:547928555422:ios:4a252a5161d5630f44208f',
          messagingSenderId: '547928555422',
          projectId: 'j-food-2a4d7',
          storageBucket: 'j-food-2a4d7.appspot.com',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    await FirebaseAppCheck.instance.activate();

    FirebaseMessaging.onBackgroundMessage(
        _firebaseOrderMessagingBackgroundHandler);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    setupFirebaseMessaging();
    setupOrderFirebaseMessaging();
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => StoreDetailsProvider()),
          ChangeNotifierProvider(create: (_) => TimerService()),
        ],
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription? _sub;
  bool signIn = false;
  String restuarantID = "";
  String categoryId = "";
  String status = "";
  String restaurantName = "";
  String restaurantUserId = "";
  String restaurantImage = "";
  String restaurantAddress = "";
  String delivery_price = "";
  String storeOpenTime = "";
  String storeCloseTime = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initUniLinks();
    loadData();
    requestFirebasePermissions();
    setupFirebaseMessaging();
    setupInAppMessaging();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      signIn = prefs.getBool('sign_in') ?? false;
      restuarantID = prefs.getString('restaurant_id') ?? "";
      storeCloseTime = prefs.getString('storeCloseTime') ?? "";
      storeOpenTime = prefs.getString('storeOpenTime') ?? "";
      categoryId = prefs.getString('category_id') ?? "";
      status = prefs.getString('status') ?? "";
      restaurantName = prefs.getString('restaurant_name') ?? "";
      restaurantImage = prefs.getString('restaurant_image') ?? "";
      restaurantAddress = prefs.getString('restaurant_address') ?? "";
      delivery_price = prefs.getString('delivery_price') ?? "";
      restaurantUserId = prefs.getString('restaurant_user_id') ?? "";
    });
  }

  Future<void> requestFirebasePermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void setupFirebaseMessaging() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification tapped: ${message.data}");
      if (message.data.containsKey('dynamic_link')) {
        final dynamicLink = message.data['dynamic_link'];
        if (dynamicLink is String) handleLink(dynamicLink);
      }
    });
  }

  void initUniLinks() async {
    try {
      // uni_links2 functionality temporarily disabled due to Android compatibility issues
      // final initialLink = await getInitialLink();
      // if (initialLink != null) handleLink(initialLink);
      print('UniLinks functionality temporarily disabled');
    } catch (e) {
      print('Failed to get initial link: $e');
    }

    // _sub = linkStream.listen((String? link) {
    //   if (link != null) handleLink(link);
    // });
  }

  void handleLink(String link) async {
    final uri = Uri.parse(link);
    if (uri.pathSegments.contains('refer')) {
      final restaurantId = uri.queryParameters['code'];
      if (restaurantId != null) {
        try {
          final response = await http.get(
            Uri.parse(
                'https://hrsps.com/login/api/restaurant-data-by-id-v2/$restaurantId'),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final restaurant = data['restaurant'];

            widget.navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  create: (_) =>
                      StoreProvider()..fetchStoreDetails(restaurantId),
                  child: StoreScreen(
                    category_id: restaurant['category_id'] ?? "0",
                    category_name: "",
                    open: restaurant['is_open'],
                    store_address: restaurant['address'],
                    store_cover_image: restaurant['cover_image'],
                    store_id: restaurant['id'].toString(),
                    store_image: restaurant['image'],
                    store_name: restaurant['name'],
                    changeTab: (i) {},
                    noDelivery: false,
                  ),
                ),
              ),
            );
          }
        } catch (e) {
          print('Failed to fetch restaurant details: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => PackageCartProvider()),
        ChangeNotifierProvider(create: (_) => FavouriteProvider()),
        ChangeNotifierProvider(create: (_) => FavouriteProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              OrderProvider(storeId: restuarantID, categoryId: categoryId),
        ),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => TimerService()),
      ],
      child: MaterialApp(
        navigatorKey: widget.navigatorKey,
        title: 'J-food',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        locale: Locale("ar"),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Tajawal',
          scaffoldBackgroundColor: Color(0xFFFAFAF8),
        ),
        home: PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;

            final shouldExit = await _showExitDialog(context);
            if (shouldExit) {
              SystemNavigator.pop();
            }
          },
          child: signIn
              ? RestaurantPage(
                  storeId: restuarantID,
                  categoryId: categoryId,
                  status: status,
                  userId: restaurantUserId,
                  storeCloseTime: storeCloseTime,
                  storeOpenTime: storeOpenTime,
                  restaurantAddress: restaurantAddress,
                  restaurantImage: restaurantImage,
                  deliveryPrice: delivery_price,
                  restaurantName: restaurantName,
                )
              : HomeScreen(fromOrderConfirm: false),
        ),
      ),
    );
  }

  void setupInAppMessaging() {
    // Firebase In-App Messaging is automatically enabled after Firebase initialization
    // In-app messages will be displayed automatically when targeting criteria are met
    print('Firebase In-App Messaging ready');
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              'تأكيد الخروج',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'هل تريد بالتأكيد الخروج من التطبيق؟',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
