import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Your custom notification payload (optional)
class NotificationBody {
  final String? id;
  NotificationBody({this.id});

  Map<String, dynamic> toJson() => {'id': id};
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void setupLocalNotification() {
  try {
    // Use the app's launcher icon
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings("@mipmap/launcher_icon");

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'channel_id',
            'channel_name',
            description: 'Channel for custom sound notifications',
            importance: Importance.high,
          ),
        );

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'order_status_channel',
            'Order Status Updates',
            description: 'Notifies about order status changes',
            importance: Importance.high,
          ),
        );

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'new_order_alert_channel',
            'تنبيهات الطلبات الجديدة',
            description: 'تنبيه صوتي عند وصول طلب جديد',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('order_alarm'),
            enableVibration: true,
          ),
        );

    print('Local notifications initialized successfully');
  } catch (e) {
    print('Error initializing local notifications: $e');
  }
}

Future<void> showBigTextNotification(
  String? title,
  String body,
  NotificationBody? notificationBody,
  FlutterLocalNotificationsPlugin fln,
) async {
  BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
    body,
    htmlFormatBigText: true,
    contentTitle: title,
    htmlFormatContentTitle: true,
  );

  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    importance: Importance.max,
    priority: Priority.high,
    styleInformation: bigTextStyleInformation,
    playSound: true,
  );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
    sound: 'notification.mp3',
  );

  NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await fln.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload:
        notificationBody != null ? jsonEncode(notificationBody.toJson()) : null,
  );
}

Future<void> showNotification(RemoteMessage message) async {
  final title = message.notification?.title;
  final body = message.notification?.body;
  if (title != null && body != null) {
    await showBigTextNotification(
        title, body, null, flutterLocalNotificationsPlugin);
  }
}

/// Loud, attention-grabbing notification for restaurant owners
Future<void> showRestaurantPushNotification(
  String title,
  String body,
) async {
  BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
    body,
    htmlFormatBigText: true,
    contentTitle: title,
    htmlFormatContentTitle: true,
  );

  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'new_order_alert_channel',
    'تنبيهات الطلبات الجديدة',
    channelDescription: 'تنبيه صوتي عند وصول طلب جديد',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('order_alarm'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500, 200, 500]),
    enableLights: true,
    ledColor: const Color.fromARGB(255, 255, 0, 0),
    ledOnMs: 300,
    ledOffMs: 300,
    fullScreenIntent: true,
    ongoing: true,
    styleInformation: bigTextStyleInformation,
    ticker: 'طلب جديد!',
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    autoCancel: false,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    sound: 'order_alarm.wav',
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.critical,
  );

  NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    platformDetails,
  );
}

void setupFirebaseMessaging() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (message.notification != null) {
      final prefs = await SharedPreferences.getInstance();
      final bool isRestaurant = prefs.getBool('sign_in') ?? false;

      if (isRestaurant) {
        await showRestaurantPushNotification(
          message.notification?.title ?? 'طلب جديد!',
          message.notification?.body ?? 'لديك إشعار جديد',
        );
      } else {
        showNotification(message);
      }
    }
  });
}

Future<void> showOrderStatusNotification(
    String title, String body, String orderId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? lastShownStatus = prefs.getString('order_status_$orderId');

  if (lastShownStatus != body) {
    try {
      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        sound: 'notification.mp3',
      );

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'order_status_channel',
        'Order Status Updates',
        channelDescription: 'Notifies about order status changes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        styleInformation: bigTextStyleInformation,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
      );

      await prefs.setString('order_status_$orderId', body);
    } catch (e) {
      print('Error showing notification: $e');
    }
  }
}

void setupOrderFirebaseMessaging() {
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      String? orderId = message.data['orderId'];
      if (orderId != null) {
        showOrderStatusNotification(
          message.notification?.title ?? 'New Notification',
          message.notification?.body ?? 'You have a new notification',
          orderId,
        );
      }
    }
  });

  FirebaseMessaging.onMessage.listen((message) {
    if (message.notification != null) {
      String? orderId = message.data['orderId'];
      if (orderId != null) {
        showOrderStatusNotification(
          message.notification?.title ?? 'New Notification',
          message.notification?.body ?? 'You have a new notification',
          orderId,
        );
      }
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    print('Notification was tapped: ${message.data}');
  });
}
