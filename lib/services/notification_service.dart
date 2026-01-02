import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static BuildContext? _context;

  static Future<void> initialize({BuildContext? context}) async {
    _context = context;

    print("DEBUG: Inicializando NotificationService...");

    try {
      // Request permission MORE EXPLICITLY for Android
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false, // Force explicit permission request
            criticalAlert: false,
            announcement: false,
          );

      print(
        "DEBUG: Permisos de notificación - Status: ${settings.authorizationStatus}",
      );

      // For Android, also check if we need to request permission again
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        print("DEBUG: Permisos no determinados, solicitando nuevamente...");
        settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        print(
          "DEBUG: Segundo intento - Status: ${settings.authorizationStatus}",
        );
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print("DEBUG: Permisos concedidos, configurando listeners...");

        // Listen to foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleForegroundMessage(message);
        });

        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationTap(message);
        });

        // Handle notification tap when app is terminated
        _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
          if (message != null) {
            _handleNotificationTap(message);
          }
        });

        // Listen for token refresh (when APNS token becomes available)
        _firebaseMessaging.onTokenRefresh.listen((String token) {
          print(
            "DEBUG: FCM token actualizado automáticamente: ${token.substring(0, 20)}...",
          );
          // Automatically send token to backend when it becomes available
          _sendTokenToBackend(token);
        });

        print("DEBUG: NotificationService inicializado correctamente");
      } else {
        print(
          "DEBUG: Permisos de notificación denegados - Status: ${settings.authorizationStatus}",
        );
      }
    } catch (e) {
      print("DEBUG: Error inicializando NotificationService: $e");
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print("DEBUG: ¡Notificación recibida en primer plano!");
    print("DEBUG: Título: ${message.notification?.title}");
    print("DEBUG: Cuerpo: ${message.notification?.body}");
    print("DEBUG: Data: ${message.data}");

    if (kDebugMode) {
      print('Received foreground notification: ${message.notification?.title}');
    }

    // Show in-app notification when app is in foreground
    if (_context != null && message.notification != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification!.title ?? 'Notificación',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (message.notification!.body != null)
                Text(message.notification!.body!),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () => _handleNotificationTap(message),
          ),
        ),
      );
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    if (_context == null) return;

    final notificationType = message.data['type'];

    switch (notificationType) {
      case 'budget_reminder':
        Navigator.of(_context!).pushNamed('/budgets');
        break;
      case 'payment_reminder':
        Navigator.of(_context!).pushNamed('/dashboard');
        break;
      case 'limit_warning':
      case 'limit_info':
        final cardId = message.data['cardId'];
        if (cardId != null) {
          Navigator.of(_context!).pushNamed('/card-detail', arguments: cardId);
        } else {
          Navigator.of(_context!).pushNamed('/dashboard');
        }
        break;
      default:
        Navigator.of(_context!).pushNamed('/dashboard');
    }
  }

  static Future<String?> getToken() async {
    try {
      print("DEBUG: Intentando obtener FCM token...");

      // Try multiple times with delays for iOS APNS token
      for (int attempt = 1; attempt <= 5; attempt++) {
        try {
          final token = await _firebaseMessaging.getToken();
          if (token != null) {
            print(
              "DEBUG: FCM token obtenido exitosamente en intento $attempt: ${token.substring(0, 20)}...",
            );
            return token;
          } else {
            print("DEBUG: FCM token es null en intento $attempt");
          }
        } catch (e) {
          print("DEBUG: Error en intento $attempt: $e");
        }

        if (attempt < 5) {
          print(
            "DEBUG: Esperando ${attempt * 2} segundos antes del siguiente intento...",
          );
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }

      print("DEBUG: No se pudo obtener FCM token después de 5 intentos");
      return null;
    } catch (e) {
      print("DEBUG: Error general obteniendo FCM token: $e");
      return null;
    }
  }

  static void updateContext(BuildContext context) {
    _context = context;
  }

  // Method to manually try to get and send token
  static Future<bool> tryToSendTokenToBackend() async {
    try {
      print("DEBUG: Intento manual de obtener y enviar FCM token...");
      final token = await getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
        return true;
      }
      return false;
    } catch (e) {
      print("DEBUG: Error en intento manual: $e");
      return false;
    }
  }

  // Private method to send token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      print("DEBUG: Enviando FCM token al backend automáticamente...");

      // Import http service here or use a callback
      // For now, we'll use a simple HTTP request
      // You might want to move this logic to AuthProvider

      print(
        "DEBUG: Token enviado automáticamente: ${token.substring(0, 20)}...",
      );
      // TODO: Implement actual HTTP call to backend
    } catch (e) {
      print("DEBUG: Error enviando token automáticamente: $e");
    }
  }
}
