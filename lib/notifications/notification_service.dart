import 'dart:convert';
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
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings("logo2");

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
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
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
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
        ),
      );
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
    sound: RawResourceAndroidNotificationSound('notification'),
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

void setupFirebaseMessaging() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      showNotification(message);
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
        sound: RawResourceAndroidNotificationSound('notification'),
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
