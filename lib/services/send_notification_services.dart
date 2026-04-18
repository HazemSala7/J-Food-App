import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

Future<String> getAccessToken() async {
  final jsonString = await rootBundle.loadString(
    'assets/notifications_key/testsignin-1a319-f951911b6a71.json',
  );

  final accountCredentials =
      auth.ServiceAccountCredentials.fromJson(jsonString);

  final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  final client = await auth.clientViaServiceAccount(accountCredentials, scopes);

  return client.credentials.accessToken.data;
}

Future<void> sendNotification(
    {required String token,
    required String title,
    required String body,
    required Map<String, String> data}) async {
  final String accessToken = await getAccessToken();
  final String fcmUrl =
      'https://fcm.googleapis.com/v1/projects/"PROJECT_ID"/messages:send';

  final response = await http.post(
    Uri.parse(fcmUrl),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode(<String, dynamic>{
      'message': {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data,

        'android': {
          'notification': {
            "sound": "notification",
            'click_action':
                'FLUTTER_NOTIFICATION_CLICK', 
            'channel_id': 'high_importance_channel'
          },
        },
        'apns': {
          'payload': {
            'aps': {"sound": "notification.caf", 'content-available': 1},
          },
        },
      },
    }),
  );

  if (response.statusCode == 200) {
    print('Notification sent successfully');
  } else {
    print('Failed to send notification: ${response.body}');
  }
}

/// Send a loud, attention-grabbing notification to a restaurant device
Future<void> sendRestaurantNotification({
  required String token,
  required String title,
  required String body,
  required Map<String, String> data,
}) async {
  final String accessToken = await getAccessToken();
  final String fcmUrl =
      'https://fcm.googleapis.com/v1/projects/"PROJECT_ID"/messages:send';

  final response = await http.post(
    Uri.parse(fcmUrl),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode(<String, dynamic>{
      'message': {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data,
        'android': {
          'priority': 'high',
          'notification': {
            'sound': 'order_alarm',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'channel_id': 'new_order_alert_channel',
            'default_vibrate_timings': false,
            'vibrate_timings': [
              '0s',
              '0.5s',
              '0.2s',
              '0.5s',
              '0.2s',
              '0.5s'
            ],
            'default_light_settings': false,
            'light_settings': {
              'color': {'red': 1, 'green': 0, 'blue': 0, 'alpha': 1},
              'light_on_duration': '0.3s',
              'light_off_duration': '0.3s',
            },
            'notification_priority': 'PRIORITY_MAX',
            'visibility': 'PUBLIC',
          },
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
          },
          'payload': {
            'aps': {
              'sound': 'order_alarm.wav',
              'content-available': 1,
              'interruption-level': 'critical',
            },
          },
        },
      },
    }),
  );

  if (response.statusCode == 200) {
    print('Restaurant notification sent successfully');
  } else {
    print('Failed to send restaurant notification: ${response.body}');
  }
}
