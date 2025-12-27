import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }

      // Get token
      try {
        String? token = await _firebaseMessaging.getToken();
        if (kDebugMode) {
          print('FCM Token: $token');
        }
      } catch (e) {
        print('Error getting FCM token: $e');
      }

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }

        if (message.notification != null) {
          if (kDebugMode) {
            print(
              'Message also contained a notification: ${message.notification}',
            );
          }
        }
      });
    }
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
